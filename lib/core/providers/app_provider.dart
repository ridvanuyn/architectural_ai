import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../localization/app_localizations.dart';
import '../models/design.dart';
import '../models/style.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/design_service.dart';
import '../services/style_service.dart';
import '../services/token_service.dart';
import '../services/haptic_service.dart';
import '../services/notification_service.dart';
import '../services/revenue_cat_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DesignService _designService = DesignService();
  final StyleService _styleService = StyleService();
  final TokenService _tokenService = TokenService();

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
  bool _isLoading = false;
  String? _error;
  bool _onboardingCompleted = false;
  // Model tiers: 'free' (1 token), 'pro' (2 tokens), 'best' (3 tokens)
  String _tier = 'pro'; // default: Better Quality
  bool _isPremium = true; // legacy compat
  Locale _locale = const Locale('en');

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
  int get tokenBalance => _tokenBalance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get hasEnoughTokens => _tokenBalance >= 1;
  bool get isPremium => _tier != 'free';
  String get tier => _tier;
  int get tierMultiplier => tierMultipliers[_tier] ?? 1;
  String get tierLabel => _tier == 'free' ? 'FREE' : _tier == 'pro' ? 'PRO+' : 'BEST';
  Locale get locale => _locale;
  SupportedLanguage get currentLanguage => SupportedLanguage.fromCode(_locale.languageCode);

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
    
    // TEST MODE: Start with 50 tokens, persist across sessions so you can watch them decrease
    _tokenBalance = prefs.getInt('token_balance') ?? 50;
    if (_tokenBalance < 5) _tokenBalance = 50; // auto-refill when low
    await prefs.setInt('token_balance', _tokenBalance);
    
    // Load saved language
    final savedLanguage = prefs.getString('app_language') ?? 'en';
    _locale = Locale(savedLanguage);
    
    // Initialize RevenueCat with unique device ID
    try {
      await RevenueCatService().init();
    } catch (e) {
      debugPrint('RevenueCat init failed: $e');
    }

    // Load styles
    await loadStyles();
    
    // Load designs from local storage
    await loadDesigns();
    
    notifyListeners();
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
    _onboardingCompleted = false;
    
    // Give welcome tokens if first time
    if (!prefs.containsKey('welcome_tokens_given')) {
      _tokenBalance = 2;
      await prefs.setInt('token_balance', 2);
      await prefs.setBool('welcome_tokens_given', true);
    }
    
    notifyListeners();
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

  /// Set selected image
  void setSelectedImage(File? image) {
    _selectedImage = image;
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
    const premiumStyleIds = {'art-deco', 'mid-century', 'cyberpunk', 'luxury', 'tropical', 'mediterranean'};
    final styleMultiplier = (_selectedStyle != null && premiumStyleIds.contains(_selectedStyle!.id)) ? 2 : 1;
    final tokenCost = tierMultiplier * customMultiplier * styleMultiplier;
    if (_tokenBalance < tokenCost) {
      _error = 'Not enough tokens';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Get style name for notifications and title
    final styleName = _selectedStyle?.name ?? _selectedWorldName ?? 'Design';

    try {
      // Show processing notification
      await NotificationService().showDesignProcessing(
        styleName: styleName,
      );

      Design design;
      
      // Always try to use backend API first
      try {
        // Upload image to backend
        final uploadResult = await _designService.uploadImage(_selectedImage!);
        
        // Create design via API (tokens deducted server-side)
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

        _currentDesign = design;
        notifyListeners();

        // Poll for completion
        await _pollDesignStatus(design.id);
        
        // Update token balance
        _tokenBalance -= tokenCost;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('token_balance', _tokenBalance);
      } catch (e) {
        // Fallback to local simulation if backend fails
        debugPrint('Backend error, using simulation: $e');

        // Deduct tokens locally
        _tokenBalance -= tokenCost;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('token_balance', _tokenBalance);

        // Create locally (simulated)
        final tierSuffix = _isPremium ? ' (Pro)' : ' (Free)';
        design = Design(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'local_user',
          styleId: _selectedStyle?.id ?? 'world',
          styleName: '$styleName$tierSuffix',
          originalImageUrl: _selectedImage!.path,
          transformedImageUrl: null,
          status: 'processing',
          isFavorite: false,
          tokensUsed: 2,
          createdAt: DateTime.now(),
        );
        
        _designs.insert(0, design);
        _currentDesign = design;
        notifyListeners();

        // Simulate processing with placeholder
        await Future.delayed(const Duration(seconds: 3));
        _currentDesign = design.copyWith(
          status: 'completed',
          transformedImageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
        );
        final index = _designs.indexWhere((d) => d.id == design.id);
        if (index != -1) {
          _designs[index] = _currentDesign!;
          await _saveLocalDesigns();
        }
      }

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
      
      // Refund tokens on error (only if local)
      if (!_authService.isAuthenticated) {
        _tokenBalance += tokenCost;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('token_balance', _tokenBalance);
      }
      
      await NotificationService().showDesignFailed(designId: 'error');
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

  /// Poll design status until complete
  Future<void> _pollDesignStatus(String designId) async {
    const maxAttempts = 60; // 5 minutes max
    const pollInterval = Duration(seconds: 5);

    for (int i = 0; i < maxAttempts; i++) {
      try {
        final statusData = await _designService.getDesignStatus(designId);
        final status = statusData['status'] as String;

        if (status == 'completed') {
          // Fetch complete design
          _currentDesign = await _designService.getDesign(designId);
          
          // Update in designs list
          final index = _designs.indexWhere((d) => d.id == designId);
          if (index != -1) {
            _designs[index] = _currentDesign!;
          } else {
            _designs.insert(0, _currentDesign!);
          }
          notifyListeners();
          return;
        } else if (status == 'failed') {
          _error = statusData['processing']?['error'] ?? 'Design processing failed';
          notifyListeners();
          return;
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
  }

  /// Refresh token balance from server
  Future<void> _refreshTokenBalance() async {
    try {
      final response = await _tokenService.getBalance();
      _tokenBalance = response['balance'] as int;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('token_balance', _tokenBalance);
      notifyListeners();
    } catch (e) {
      // Keep local balance on error
    }
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

