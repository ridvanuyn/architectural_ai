import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../localization/app_localizations.dart';
import '../models/design.dart';
import '../models/specialty_world.dart';
import '../models/style.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/design_service.dart';
import '../services/style_service.dart';
import '../services/token_service.dart';
import '../services/haptic_service.dart';
import '../utils/image_orientation.dart';
import '../services/engagement_notification_service.dart';
import '../services/notification_service.dart';
import '../services/revenue_cat_service.dart';
import '../services/world_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DesignService _designService = DesignService();
  final StyleService _styleService = StyleService();
  final TokenService _tokenService = TokenService();
  final WorldService _worldService = WorldService();

  // Review reward constants
  static const Duration kReviewRewardDelay = Duration(hours: 1);
  static const int kReviewRewardAmount = 5;
  static const String _kReviewPendingKey = 'review_reward_pending';
  static const String _kReviewTimestampKey = 'review_reward_timestamp';
  static const String _kReviewClaimedKey = 'review_reward_claimed';

  // State
  User? _user;
  List<DesignStyle> _styles = [];
  List<Design> _designs = [];
  Design? _currentDesign;
  File? _selectedImage;
  DesignStyle? _selectedStyle;
  String? _selectedWorldPrompt;
  String? _selectedWorldName;
  int _tokenBalance = 0;
  // Tokens reserved for an in-flight generation; subtracted from the displayed
  // balance but not yet removed from _tokenBalance. Finalized on completion.
  int _pendingDeduction = 0;
  bool _isLoading = false;
  String? _error;
  bool _onboardingCompleted = false;
  // Model tiers: 'free' (1 token), 'pro' (2 tokens), 'best' (3 tokens)
  String _tier = 'pro'; // default: Better Quality
  bool _isPremium = true; // legacy compat
  // Premium subscription status from RevenueCat (independent of _tier).
  bool _isPremiumSubscriber = false;
  int _premiumMonthlyGrant = 0;
  DateTime? _premiumGrantedAt;
  Locale _locale = const Locale('en');

  // Prefetched specialty worlds (populated lazily on init)
  List<SpecialtyWorld> _cachedWorlds = [];
  bool _worldsPrefetched = false;

  // Review reward state (loaded from SharedPreferences during init)
  bool _reviewRewardPending = false;
  DateTime? _reviewRewardTimestamp;
  bool _reviewRewardClaimed = false;

  // Tier token costs
  static const Map<String, int> tierMultipliers = {
    'free': 1,
    'pro': 2,
    'best': 3,
  };
  static const List<String> tierOrder = ['free', 'pro', 'best'];

  // Getters
  User? get user => _user;
  List<DesignStyle> get styles => _styles;
  List<Design> get designs => _designs;
  Design? get currentDesign => _currentDesign;
  File? get selectedImage => _selectedImage;
  DesignStyle? get selectedStyle => _selectedStyle;
  String? get selectedWorldPrompt => _selectedWorldPrompt;
  String? get selectedWorldName => _selectedWorldName;
  int get tokenBalance => _tokenBalance;
  /// Balance shown to the user — optimistic: reserves in-flight generation cost.
  int get displayedTokenBalance => (_tokenBalance - _pendingDeduction).clamp(0, 1 << 31);
  int get pendingDeduction => _pendingDeduction;
  bool get hasPendingDeduction => _pendingDeduction > 0;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get hasEnoughTokens => displayedTokenBalance >= 1;
  bool get isPremium => _tier != 'free';
  // RevenueCat-backed premium subscription (distinct from model tier).
  bool get isPremiumSubscriber => _isPremiumSubscriber;
  int get premiumMonthlyGrant => _premiumMonthlyGrant;
  DateTime? get premiumGrantedAt => _premiumGrantedAt;
  String get tier => _tier;
  int get tierMultiplier => tierMultipliers[_tier] ?? 1;
  String get tierLabel => _tier == 'free' ? 'FREE' : _tier == 'pro' ? 'PRO+' : 'BEST';
  Locale get locale => _locale;
  SupportedLanguage get currentLanguage => SupportedLanguage.fromCode(_locale.languageCode);

  // Prefetched worlds cache
  List<SpecialtyWorld> get prefetchedWorlds => List.unmodifiable(_cachedWorlds);
  bool get worldsPrefetched => _worldsPrefetched;

  // Review reward state
  bool get reviewRewardPending => _reviewRewardPending;
  DateTime? get reviewRewardTimestamp => _reviewRewardTimestamp;
  bool get reviewRewardClaimed => _reviewRewardClaimed;

  /// Returns true if a review reward is pending AND at least 1 hour has
  /// elapsed since the user tapped the review button.
  bool reviewRewardEligibleAt(DateTime now) {
    if (!_reviewRewardPending) return false;
    final ts = _reviewRewardTimestamp;
    if (ts == null) return false;
    return now.difference(ts) >= kReviewRewardDelay;
  }

  /// Initialize app
  Future<void> init() async {
    await ApiClient().init();

    final prefs = await SharedPreferences.getInstance();

    // DEV AUTO-LOGIN: inject test user JWT if not already authenticated
    if (!ApiClient().isAuthenticated) {
      await ApiClient().saveTokens(
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5ZDc4YWIwY2RlMDgyYzE3NmY3OWNmNiIsImlhdCI6MTc3NTczMzQyNCwiZXhwIjoxODA3MjY5NDI0fQ.J1TqTYiLyQE_9kMVCuOrxtFE3aSp3WOObj_P4dvtXQE',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5ZDc4YWIwY2RlMDgyYzE3NmY3OWNmNiIsImlhdCI6MTc3NTczMzQyNCwiZXhwIjoxODA3MjY5NDI0fQ.JxtgBvKa5M7zzz3YNtfx7GaV5z7EDHJGxSilisWKy1I',
      );
    }

    _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    // Tokens come from RevenueCat purchases (+ one-time welcome grant via
    // grantWelcomeTokensIfFirstTime() on onboarding completion).
    _tokenBalance = prefs.getInt('token_balance') ?? 0;

    // Premium subscription snapshot
    _isPremiumSubscriber = prefs.getBool('premium_subscriber') ?? false;
    _premiumMonthlyGrant = prefs.getInt('premium_monthly_grant') ?? 0;
    final grantedAtMs = prefs.getInt('premium_granted_at');
    _premiumGrantedAt = grantedAtMs != null
        ? DateTime.fromMillisecondsSinceEpoch(grantedAtMs)
        : null;

    // Load saved language
    final savedLanguage = prefs.getString('app_language') ?? 'en';
    _locale = Locale(savedLanguage);

    // Review reward snapshot
    _reviewRewardPending = prefs.getBool(_kReviewPendingKey) ?? false;
    final reviewTsMs = prefs.getInt(_kReviewTimestampKey);
    _reviewRewardTimestamp = reviewTsMs != null
        ? DateTime.fromMillisecondsSinceEpoch(reviewTsMs)
        : null;
    _reviewRewardClaimed = prefs.getBool(_kReviewClaimedKey) ?? false;

    // Fire-and-forget: try to claim any reward that has ripened while the app
    // was closed. Safe no-op when not eligible.
    // ignore: unawaited_futures
    claimReviewReward();

    // Fire-and-forget: prefetch specialty worlds so the All Collections page
    // opens instantly on the first navigation.
    // ignore: unawaited_futures
    _prefetchWorlds();

    // Initialize RevenueCat with unique device ID
    try {
      await RevenueCatService().init();
    } catch (e) {
      debugPrint('RevenueCat init failed: $e');
    }

    // Check engagement notifications
    try {
      await EngagementNotificationService().checkAndNotify(
        languageCode: _locale.languageCode,
        isSubscriber: _isPremium,
        tokenBalance: _tokenBalance,
      );
    } catch (e) {
      debugPrint('Engagement notification check failed: $e');
    }

    // Load styles
    await loadStyles();
    
    // Load designs from local storage
    await loadDesigns();
    
    notifyListeners();
  }

  /// Prefetch specialty worlds in the background. Populates [prefetchedWorlds]
  /// so the All Collections page can render instantly from cache.
  Future<void> _prefetchWorlds() async {
    try {
      final worlds = await _worldService.getWorlds();
      _cachedWorlds = worlds;
      _worldsPrefetched = true;
      notifyListeners();
    } catch (e) {
      // Leave cache empty; callers will fall back to an on-demand API call.
      debugPrint('World prefetch failed: $e');
    }
  }

  /// Public entry point to refresh the worlds cache (e.g. manual pull-to-refresh).
  Future<void> refreshWorldsCache() async {
    _worldsPrefetched = false;
    await _prefetchWorlds();
  }

  /// Record that the user tapped the in-app review button. Starts the 1-hour
  /// timer after which the +5 token reward becomes eligible to be claimed.
  ///
  /// Idempotent: a second tap after the first reward has been claimed is a
  /// no-op; a second tap before claiming refreshes the timestamp.
  Future<void> markReviewTapped() async {
    if (_reviewRewardClaimed) return;
    final prefs = await SharedPreferences.getInstance();
    _reviewRewardPending = true;
    _reviewRewardTimestamp = DateTime.now();
    await prefs.setBool(_kReviewPendingKey, true);
    await prefs.setInt(
      _kReviewTimestampKey,
      _reviewRewardTimestamp!.millisecondsSinceEpoch,
    );
    notifyListeners();
  }

  /// Attempts to claim the pending review reward. If eligible (pending flag
  /// set AND >= 1 hour since the tap), grants +5 tokens via the backend,
  /// increments the local balance, and clears the pending flag. No-op
  /// otherwise.
  Future<void> claimReviewReward() async {
    if (_reviewRewardClaimed) return;
    if (!reviewRewardEligibleAt(DateTime.now())) return;

    final prefs = await SharedPreferences.getInstance();
    try {
      // Backend-first: let the server create the transaction and return the
      // authoritative balance. Fall back to a local grant on failure so the
      // user is not penalized by transient network issues.
      try {
        final result = await _tokenService.grantTokens(
          amount: kReviewRewardAmount,
          reason: 'review',
        );
        if (result['tokens'] != null && result['tokens']['balance'] != null) {
          _tokenBalance = (result['tokens']['balance'] as num).toInt();
        } else {
          _tokenBalance += kReviewRewardAmount;
        }
      } catch (e) {
        debugPrint('Review reward backend grant failed, granting locally: $e');
        _tokenBalance += kReviewRewardAmount;
      }
      await prefs.setInt('token_balance', _tokenBalance);

      // Clear the pending flag and lock the claim so it cannot be redeemed
      // twice.
      _reviewRewardPending = false;
      _reviewRewardTimestamp = null;
      _reviewRewardClaimed = true;
      await prefs.setBool(_kReviewPendingKey, false);
      await prefs.remove(_kReviewTimestampKey);
      await prefs.setBool(_kReviewClaimedKey, true);

      HapticService.success();
      notifyListeners();
    } catch (e) {
      debugPrint('Review reward claim failed: $e');
    }
  }

  /// Change app language
  Future<void> changeLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    
    _locale = Locale(languageCode);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
    
    // Language is saved locally, backend sync can be added later
    
    HapticService.selectionClick();
    notifyListeners();
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    _onboardingCompleted = true;
    notifyListeners();
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', false);
    await prefs.remove('welcome_tokens_granted');
    _onboardingCompleted = false;
    notifyListeners();
  }

  /// Grant the one-time welcome bonus (3 tokens) the first time
  /// onboarding is completed. Subsequent calls are no-ops.
  Future<void> grantWelcomeTokensIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('welcome_tokens_granted') ?? false) return;
    _tokenBalance += 3;
    await prefs.setInt('token_balance', _tokenBalance);
    await prefs.setBool('welcome_tokens_granted', true);
    notifyListeners();
  }

  /// Map RevenueCat product identifiers to token counts and add to balance.
  /// Called by RevenueCatService after a successful consumable purchase.
  Future<void> grantTokensFromPurchase(String productId) async {
    const productToTokens = <String, int>{
      'tokens_10_pack': 10,
      'tokens_25_pack': 25,
      'tokens_100_pack': 100,
    };
    final amount = productToTokens[productId] ?? 0;
    if (amount <= 0) return;
    await addTokens(amount);
  }

  /// Load styles
  Future<void> loadStyles() async {
    try {
      // Try to load from API
      _styles = await _styleService.getStyles();
    } catch (e) {
      // Fallback to default styles
      _styles = _getDefaultStyles();
    }
    notifyListeners();
  }

  /// Load designs
  Future<void> loadDesigns() async {
    try {
      if (_authService.isAuthenticated) {
        _designs = await _designService.getDesigns();
      } else {
        // Load from local storage
        _designs = await _loadLocalDesigns();
      }
    } catch (e) {
      _designs = [];
    }
    notifyListeners();
  }

  /// Cycle through tiers: free → pro → x5 → free
  void togglePremium() {
    final idx = tierOrder.indexOf(_tier);
    _tier = tierOrder[(idx + 1) % tierOrder.length];
    _isPremium = _tier != 'free';
    HapticService.mediumImpact();
    notifyListeners();
  }

  /// Set a specific tier
  void setTier(String newTier) {
    if (tierOrder.contains(newTier)) {
      _tier = newTier;
      _isPremium = _tier != 'free';
      HapticService.selectionClick();
      notifyListeners();
    }
  }

  /// Set current design (for viewing in before/after screen)
  void setCurrentDesign(Design? design) {
    _currentDesign = design;
    notifyListeners();
  }

  /// Set selected image (bakes EXIF orientation into pixels so uploads don't rotate)
  Future<void> setSelectedImage(File? image) async {
    _selectedImage = image == null ? null : await bakeImageOrientation(image);
    HapticService.lightImpact();
    notifyListeners();
  }

  /// Set selected style
  void setSelectedStyle(DesignStyle? style) {
    _selectedStyle = style;
    HapticService.selectionClick();
    notifyListeners();
  }

  /// Set selected world prompt (from specialty worlds)
  void setSelectedWorldPrompt(String? prompt, {String? worldName}) {
    _selectedWorldPrompt = prompt;
    if (worldName != null) _selectedWorldName = worldName;
    notifyListeners();
  }

  /// Clear world prompt
  void clearWorldPrompt() {
    _selectedWorldPrompt = null;
    _selectedWorldName = null;
    notifyListeners();
  }

  /// Create design
  Future<Design?> createDesign() async {
    // Need image AND either a style or world prompt
    if (_selectedImage == null) {
      _error = 'Please select an image first';
      notifyListeners();
      return null;
    }
    
    if (_selectedStyle == null && (_selectedWorldPrompt == null || _selectedWorldPrompt!.isEmpty)) {
      _error = 'Please select a style or world first';
      notifyListeners();
      return null;
    }
    
    final customMultiplier = (_selectedWorldPrompt != null && _selectedWorldPrompt!.isNotEmpty) ? 2 : 1;
    // Premium style multiplier removed: Choose Your Aesthetic now treats
    // every style equally (and exposes specialty worlds alongside them).
    final tokenCost = tierMultiplier * customMultiplier;
    // Optimistic balance must cover the cost (existing reservations included).
    if (displayedTokenBalance < tokenCost) {
      // Give the review reward a chance to rescue this generation before we
      // bail out: if the user tapped "Review App" >= 1 hour ago, credit the
      // +5 tokens now and re-check the balance.
      if (reviewRewardEligibleAt(DateTime.now())) {
        await claimReviewReward();
      }
      if (displayedTokenBalance < tokenCost) {
        _error = 'Not enough tokens';
        notifyListeners();
        return null;
      }
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Get style name for notifications and title
    final styleName = _selectedStyle?.name ?? _selectedWorldName ?? 'Design';

    // Tokens are "consumable": we only finalize the local deduction when the
    // AI result actually arrives. In the meantime, we reserve the cost via
    // _pendingDeduction so the UI and hasEnoughTokens reflect the charge.
    bool tokensReserved = false;
    bool tokensDeducted = false;
    Design? design;
    try {
      // Show processing notification
      await NotificationService().showDesignProcessing(
        styleName: styleName,
      );

      // Upload image to backend — if this fails, no tokens are spent
      final uploadResult = await _designService.uploadImage(_selectedImage!);

      // Create design via API (backend deducts server-side on job accept).
      design = await _designService.createDesign(
        originalImageUrl: uploadResult['url'],
        originalImageKey: uploadResult['key'],
        styleId: _selectedStyle?.id,
        roomType: 'living_room',
        title: styleName,
        customPrompt: _selectedWorldPrompt,
        isPremium: _isPremium,
        tier: _tier,
      );

      // Reserve locally (don't persist yet — finalize on completion)
      _pendingDeduction += tokenCost;
      tokensReserved = true;

      _currentDesign = design;
      notifyListeners();

      // Poll for completion — only finalize if status becomes 'completed'
      final completed = await _pollDesignStatus(design.id);

      if (!completed) {
        // Polling timed out or design failed — release the reservation AND
        // request a refund from the backend (which already charged at accept).
        _pendingDeduction -= tokenCost;
        tokensReserved = false;
        notifyListeners();

        try {
          final refund = await _tokenService.refundTokens(
            designId: design.id,
            amount: tokenCost,
            reason: _error ?? 'Design processing did not complete',
          );
          if (refund['tokens'] != null && refund['tokens']['balance'] != null) {
            _tokenBalance = (refund['tokens']['balance'] as num).toInt();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('token_balance', _tokenBalance);
          }
        } catch (_) {
          // Best-effort refund; keep local balance unchanged if the endpoint fails.
        }

        await NotificationService().cancelProcessingNotification();
        await NotificationService().showDesignFailed(designId: design.id);
        await HapticService.error();

        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Completed — finalize the deduction locally and persist.
      _pendingDeduction -= tokenCost;
      tokensReserved = false;
      _tokenBalance -= tokenCost;
      tokensDeducted = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('token_balance', _tokenBalance);

      // Cancel processing notification and show completion
      await NotificationService().cancelProcessingNotification();
      await NotificationService().showDesignCompleted(
        styleName: styleName,
        designId: design.id,
      );

      // Celebration haptic
      await HapticService.celebration();

      _isLoading = false;
      notifyListeners();
      return _currentDesign;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;

      // Release any reservation we took (we never finalized here).
      if (tokensReserved) {
        _pendingDeduction -= tokenCost;
        tokensReserved = false;

        // Backend already deducted at createDesign success — refund.
        try {
          final refund = await _tokenService.refundTokens(
            designId: design?.id,
            amount: tokenCost,
            reason: e.toString(),
          );
          if (refund['tokens'] != null && refund['tokens']['balance'] != null) {
            _tokenBalance = (refund['tokens']['balance'] as num).toInt();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('token_balance', _tokenBalance);
          }
        } catch (_) {
          // Best-effort; leave balance unchanged.
        }
      }

      // Defensive: if for any reason we ever flipped tokensDeducted and still
      // hit this catch, keep the refund logic consistent.
      if (tokensDeducted) {
        _tokenBalance += tokenCost;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('token_balance', _tokenBalance);
      }

      await NotificationService().cancelProcessingNotification();
      await NotificationService().showDesignFailed(designId: design?.id ?? 'error');
      await HapticService.error();

      notifyListeners();
      return null;
    }
  }

  /// Toggle favorite
  Future<void> toggleFavorite(String designId) async {
    final index = _designs.indexWhere((d) => d.id == designId);
    if (index == -1) return;

    HapticService.mediumImpact();

    final design = _designs[index];
    _designs[index] = design.copyWith(isFavorite: !design.isFavorite);
    
    if (_currentDesign?.id == designId) {
      _currentDesign = _designs[index];
    }

    await _saveLocalDesigns();
    notifyListeners();
  }

  /// Delete design
  Future<void> deleteDesign(String designId) async {
    HapticService.mediumImpact();
    
    _designs.removeWhere((d) => d.id == designId);
    await _saveLocalDesigns();
    
    if (_currentDesign?.id == designId) {
      _currentDesign = null;
    }
    
    notifyListeners();
  }

  /// Add tokens
  Future<void> addTokens(int amount) async {
    HapticService.success();
    
    _tokenBalance += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('token_balance', _tokenBalance);
    notifyListeners();
  }

  /// Apply promo code
  Future<bool> applyPromoCode(String code) async {
    try {
      final response = await _tokenService.applyPromoCode(code);
      final tokens = response['tokens'] as int;
      await addTokens(tokens);
      return true;
    } catch (e) {
      HapticService.error();
      return false;
    }
  }

  /// Clear selected image and style
  void clearSelection() {
    _selectedImage = null;
    _selectedStyle = null;
    _selectedWorldPrompt = null;
    _selectedWorldName = null;
    notifyListeners();
  }

  /// Clear only selected image
  void clearSelectedImage() {
    _selectedImage = null;
    HapticService.lightImpact();
    notifyListeners();
  }

  /// Poll design status until complete. Returns `true` on 'completed', `false`
  /// on 'failed' or timeout. The AI response arrival is the trigger for
  /// finalizing the token deduction upstream.
  Future<bool> _pollDesignStatus(String designId) async {
    const maxAttempts = 60; // 5 minutes max
    const pollInterval = Duration(seconds: 5);

    for (int i = 0; i < maxAttempts; i++) {
      try {
        final statusData = await _designService.getDesignStatus(designId);
        final status = statusData['status'] as String;

        if (status == 'completed') {
          _currentDesign = await _designService.getDesign(designId);

          final index = _designs.indexWhere((d) => d.id == designId);
          if (index != -1) {
            _designs[index] = _currentDesign!;
          } else {
            _designs.insert(0, _currentDesign!);
          }
          // Persist so History survives a restart even when the backend is
          // unreachable or the auto-login token doesn't round-trip.
          await _saveLocalDesigns();
          notifyListeners();
          return true;
        } else if (status == 'failed') {
          _error = statusData['processing']?['error'] ?? 'Design processing failed';
          notifyListeners();
          return false;
        }

        // Still processing, wait and poll again
        await Future.delayed(pollInterval);
      } catch (e) {
        // Continue polling on network errors
        await Future.delayed(pollInterval);
      }
    }

    _error = 'Design processing timed out';
    notifyListeners();
    return false;
  }

  /// Refresh token balance from server
  Future<void> refreshTokenBalance() async {
    try {
      final response = await _tokenService.getBalance();
      final balance = response['balance'];
      if (balance != null) {
        _tokenBalance = (balance as num).toInt();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('token_balance', _tokenBalance);
        notifyListeners();
      }
    } catch (e) {
      // Keep local balance on error
    }
  }

  /// Activate premium subscription locally and optionally grant the monthly
  /// bonus token allotment (called by RevenueCatService after a successful
  /// subscription purchase / restore that flips the entitlement active).
  ///
  /// [monthlyGrant] is the number of bonus tokens to add. Default 100.
  /// [grantNow] controls whether the bonus is applied on this call (e.g. only
  /// the first time we detect a new active entitlement this month).
  Future<void> activatePremium({
    int monthlyGrant = 100,
    bool grantNow = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final wasPremium = _isPremiumSubscriber;
    _isPremiumSubscriber = true;
    _premiumMonthlyGrant = monthlyGrant;
    await prefs.setBool('premium_subscriber', true);
    await prefs.setInt('premium_monthly_grant', monthlyGrant);

    if (grantNow && !wasPremium) {
      // Ask backend to grant the tokens and create a transaction.
      try {
        final result = await _tokenService.grantTokens(
          amount: monthlyGrant,
          reason: 'Premium subscription monthly token grant',
        );
        if (result['tokens'] != null && result['tokens']['balance'] != null) {
          _tokenBalance = (result['tokens']['balance'] as num).toInt();
        } else {
          _tokenBalance += monthlyGrant;
        }
      } catch (_) {
        // Backend grant failed — fall back to a local grant so the user
        // still gets the tokens. Will sync on next balance refresh.
        _tokenBalance += monthlyGrant;
      }
      await prefs.setInt('token_balance', _tokenBalance);

      _premiumGrantedAt = DateTime.now();
      await prefs.setInt(
        'premium_granted_at',
        _premiumGrantedAt!.millisecondsSinceEpoch,
      );
    }

    HapticService.success();
    notifyListeners();
  }

  /// Mark premium subscription inactive (entitlement expired / cancelled).
  Future<void> deactivatePremium() async {
    _isPremiumSubscriber = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('premium_subscriber', false);
    notifyListeners();
  }

  // Local storage helpers using SharedPreferences + JSON
  Future<List<Design>> _loadLocalDesigns() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('local_designs');
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => Design.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Failed to load local designs: $e');
      return [];
    }
  }

  Future<void> _saveLocalDesigns() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _designs.map((d) => d.toJson()).toList();
    await prefs.setString('local_designs', jsonEncode(jsonList));
  }

  List<DesignStyle> _getDefaultStyles() {
    return [
      DesignStyle(
        id: 'modern',
        name: 'Modern',
        description: 'Clean lines, open light',
        imageUrl: 'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['minimal', 'contemporary'],
      ),
      DesignStyle(
        id: 'scandinavian',
        name: 'Scandinavian',
        description: 'Warm minimal, soft woods',
        imageUrl: 'https://images.unsplash.com/photo-1600210492493-0946911123ea?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['cozy', 'nordic'],
      ),
      DesignStyle(
        id: 'japandi',
        name: 'Japandi',
        description: 'Calm, natural balance',
        imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['zen', 'minimal'],
      ),
      DesignStyle(
        id: 'industrial',
        name: 'Industrial',
        description: 'Raw textures, bold edges',
        imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['urban', 'loft'],
      ),
      DesignStyle(
        id: 'classic',
        name: 'Classic',
        description: 'Elegant details, timeless',
        imageUrl: 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['traditional', 'elegant'],
      ),
      DesignStyle(
        id: 'bohemian',
        name: 'Bohemian',
        description: 'Layered, artistic comfort',
        imageUrl: 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['boho', 'eclectic'],
      ),
      DesignStyle(
        id: 'minimalist',
        name: 'Minimalist',
        description: 'Less is more',
        imageUrl: 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['simple', 'clean'],
      ),
      DesignStyle(
        id: 'japanese',
        name: 'Japanese',
        description: 'Zen minimalism, natural wood',
        imageUrl: 'https://images.unsplash.com/photo-1545083036-b175dd155a1d?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['zen', 'wabi-sabi'],
      ),
      DesignStyle(
        id: 'mediterranean',
        name: 'Mediterranean',
        description: 'Warm coastal vibes',
        imageUrl: 'https://images.unsplash.com/photo-1600585153490-76fb20a32601?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['coastal', 'terracotta'],
      ),
      DesignStyle(
        id: 'art-deco',
        name: 'Art Deco',
        description: 'Bold geometry, glamour',
        imageUrl: 'https://images.unsplash.com/photo-1600607687644-c7171b42498f?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'trending',
        tags: ['geometric', 'glamour'],
      ),
      DesignStyle(
        id: 'rustic',
        name: 'Rustic',
        description: 'Warm wood, country feel',
        imageUrl: 'https://images.unsplash.com/photo-1600210491892-03d54c0aaf87?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['farmhouse', 'natural'],
      ),
      DesignStyle(
        id: 'mid-century',
        name: 'Mid-Century',
        description: 'Retro modern, organic forms',
        imageUrl: 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'trending',
        tags: ['retro', '60s'],
      ),
      DesignStyle(
        id: 'coastal',
        name: 'Coastal',
        description: 'Beach house serenity',
        imageUrl: 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['beach', 'nautical'],
      ),
      DesignStyle(
        id: 'tropical',
        name: 'Tropical',
        description: 'Lush greens, paradise vibes',
        imageUrl: 'https://images.unsplash.com/photo-1600585154363-67eb9e2e2099?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['jungle', 'exotic'],
      ),
      DesignStyle(
        id: 'cyberpunk',
        name: 'Cyberpunk',
        description: 'Neon lights, futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'creative',
        tags: ['neon', 'futuristic'],
      ),
      DesignStyle(
        id: 'luxury',
        name: 'Luxury',
        description: 'Premium materials, glow',
        imageUrl: 'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?w=300',
        tokenCost: 1,
        isPremium: false,
        category: 'base',
        tags: ['opulent', 'premium'],
      ),
    ];
  }
}

