import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/localization/localization_extension.dart';
import '../core/models/specialty_world.dart';
import '../core/models/style.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../core/services/world_service.dart';
import '../core/services/paywall_helper.dart';
import '../core/services/revenue_cat_service.dart';
import '../widgets/skeleton_loader.dart';
import 'home_shell.dart';
import 'processing_screen.dart';
import 'store_screen.dart';

// Design system constants
const _kSurfaceBg = Color(0xFFF9F9FB);
const _kCardBg = Color(0xFFFFFFFF);
const _kTextPrimary = Color(0xFF1A1C1D);
const _kTextSecondary = Color(0xFF6B7280);
const _kTextMuted = Color(0xFF9CA3AF);
const _kGradientStart = Color(0xFF4400B6);
const _kGradientEnd = Color(0xFF5D21DF);
const _kGradient = LinearGradient(colors: [_kGradientStart, _kGradientEnd]);

class StyleSelectionScreen extends StatefulWidget {
  const StyleSelectionScreen({super.key});

  static const routeName = '/styles';

  @override
  State<StyleSelectionScreen> createState() => _StyleSelectionScreenState();
}

class _StyleSelectionScreenState extends State<StyleSelectionScreen> {
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();
  final TextEditingController _customPromptController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();

  bool _customMode = false;
  int _currentStep = 0;
  String _selectedTier = 'pro';
  int _styleTab = 0; // 0 = Styles, 1 = Premium, 2 = Store
  List<SpecialtyWorld> _worlds = [];
  SpecialtyWorld? _selectedWorld;

  static const int _totalSteps = 4;

  static const _quickSuggestions = [
    'Golden Hour',
    'Sustainable Tech',
    'Artistic Flair',
    'Biophilic Design',
  ];

  @override
  void initState() {
    super.initState();
    final appProvider = context.read<AppProvider>();
    _selectedTier = appProvider.tier;
    _loadWorlds();

    // If photo already selected (coming from home), skip to step 1 (Choose Aesthetic)
    if (appProvider.selectedImage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToStep(1);
      });
    }
    // If coming from store with a world prompt already set, skip to step 2
    if (appProvider.selectedWorldPrompt != null && appProvider.selectedWorldPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToStep(appProvider.selectedImage != null ? 2 : 1);
      });
    }
  }

  Future<void> _loadWorlds() async {
    // Show defaults while loading
    setState(() => _worlds = StoreScreen.getDefaultWorlds());
    try {
      final worlds = await WorldService().getWorlds();
      if (mounted && worlds.isNotEmpty) {
        // FULLY replace defaults with API data (includes S3 image URLs)
        setState(() => _worlds = worlds);
      }
    } catch (_) {
      // Keep defaults on error
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customPromptController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    _goToStep(_currentStep + 1);
  }

  void _prevStep() {
    if (_currentStep == 0) {
      // If pushed via Navigator from another screen, pop back.
      // If we're on the Create tab (IndexedStack has no route), switch to Home tab.
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        HomeShell.of(context)?.setTab(0);
      }
    } else {
      _goToStep(_currentStep - 1);
    }
  }

  int get _tokenCost {
    // Premium style multiplier removed — all aesthetics cost the same base now.
    final tierMul = AppProvider.tierMultipliers[_selectedTier] ?? 1;
    final customMul = _customMode ? 2 : 1;
    return tierMul * customMul;
  }

  Future<void> _showImageSourceDialog() async {
    HapticService.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kTextMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('select_room_photo_title'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('take_or_choose_photo'),
              style: const TextStyle(
                fontSize: 14,
                color: _kTextMuted,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.camera_alt,
                    label: context.tr('camera'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.photo_library,
                    label: context.tr('gallery'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final appProvider = context.read<AppProvider>();
        await appProvider.setSelectedImage(File(pickedFile.path));
        HapticService.success();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('pick_image_failed')}: $e')),
        );
      }
    }
  }

  Future<void> _startDesign() async {
    final appProvider = context.read<AppProvider>();

    if (appProvider.selectedImage == null) {
      _showImageSourceDialog();
      return;
    }

    final canProceed = await ensureTokensOrPaywall(context, requiredTokens: _tokenCost);
    if (!canProceed || !mounted) return;

    // Set the tier on appProvider before navigating
    appProvider.setTier(_selectedTier);

    // Set world prompt if a specialty world was selected in wizard
    if (_selectedWorld != null) {
      final worldPrompt = _selectedWorld!.prompt;
      final customExtra = _customMode && _customPromptController.text.trim().isNotEmpty
          ? '. ${_customPromptController.text.trim()}'
          : '';
      appProvider.setSelectedWorldPrompt('$worldPrompt$customExtra', worldName: _selectedWorld!.name);
    } else if (_customMode && _customPromptController.text.trim().isNotEmpty) {
      // Append custom instructions to existing world prompt (from store) or set new
      final existing = appProvider.selectedWorldPrompt ?? '';
      final custom = _customPromptController.text.trim();
      if (existing.isNotEmpty) {
        appProvider.setSelectedWorldPrompt('$existing. $custom');
      } else {
        appProvider.setSelectedWorldPrompt(custom);
      }
    }
    // Don't clear world prompt if it was set by store

    HapticService.mediumImpact();
    Navigator.pushNamed(context, ProcessingScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          backgroundColor: _kSurfaceBg,
          appBar: AppBar(
                backgroundColor: _kSurfaceBg,
                elevation: 0,
                leading: IconButton(
                  onPressed: () {
                    HapticService.lightImpact();
                    _prevStep();
                  },
                  icon: const Icon(Icons.arrow_back_ios, size: 20, color: _kTextPrimary),
                ),
                title: Text(
                  context.tr('step_x_of_y')
                      .replaceFirst('%s', '${_currentStep + 1}')
                      .replaceFirst('%s', '$_totalSteps'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kTextSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                centerTitle: true,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kGradientEnd.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.token, size: 14, color: _kGradientEnd),
                        const SizedBox(width: 4),
                        Text(
                          '${appProvider.tokenBalance}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kGradientEnd,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          body: SafeArea(
            child: Column(
              children: [
                // Segmented progress bar
                _buildSegmentedProgressBar(),
                const SizedBox(height: 4),
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentStep = index);
                    },
                    children: [
                      _buildStep0CapturePhoto(appProvider),
                      _buildStep1ChooseStyle(appProvider),
                      _buildStep2RefineVision(appProvider),
                      _buildStep3ReviewSelection(appProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Segmented Progress Bar ───────────────────────────────────────

  Widget _buildSegmentedProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              decoration: BoxDecoration(
                gradient: (isActive || isCompleted) ? _kGradient : null,
                color: (!isActive && !isCompleted) ? _kTextMuted.withValues(alpha: 0.2) : null,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Gradient Button ──────────────────────────────────────────────

  Widget _buildGradientButton({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GestureDetector(
        onTap: enabled
            ? () {
                HapticService.lightImpact();
                onPressed();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: enabled ? _kGradient : null,
            color: enabled ? null : _kTextMuted.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: _kGradientStart.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: enabled ? Colors.white : _kTextMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ─── STEP 0: Capture Your Space ───────────────────────────────────

  Widget _buildStep0CapturePhoto(AppProvider appProvider) {
    final selectedImage = appProvider.selectedImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  context.tr('capture_space'),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _kTextPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('capture_space_desc'),
                  style: const TextStyle(fontSize: 14, color: _kTextSecondary),
                ),
                const SizedBox(height: 24),
                // Photo preview if selected
                if (selectedImage != null) ...[
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(selectedImage, fit: BoxFit.cover),
                            Positioned(
                              bottom: 12, right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.swap_horiz, size: 14),
                                    const SizedBox(width: 4),
                                    Text(context.tr('change_photo'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Camera option
                GestureDetector(
                  onTap: () async {
                    final file = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
                    if (file != null && mounted) {
                      await context.read<AppProvider>().setSelectedImage(File(file.path));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: const BoxDecoration(
                            gradient: _kGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('live_camera'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kTextPrimary)),
                              const SizedBox(height: 2),
                              Text(context.tr('live_camera_desc'), style: const TextStyle(fontSize: 12, color: _kTextSecondary)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: _kTextMuted, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Gallery option
                GestureDetector(
                  onTap: () async {
                    final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
                    if (file != null && mounted) {
                      await context.read<AppProvider>().setSelectedImage(File(file.path));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('photo_gallery'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kTextPrimary)),
                              const SizedBox(height: 2),
                              Text(context.tr('photo_gallery_desc'), style: const TextStyle(fontSize: 12, color: _kTextSecondary)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: _kTextMuted, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Pro Capture Tips
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: _kGradientEnd),
                    const SizedBox(width: 6),
                    Text(context.tr('pro_capture_tips'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGradientEnd, letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTip(Icons.wb_sunny_outlined, context.tr('tip_lighting_title'), context.tr('tip_lighting_desc')),
                const SizedBox(height: 10),
                _buildTip(Icons.crop_free, context.tr('tip_angles_title'), context.tr('tip_angles_desc')),
                const SizedBox(height: 10),
                _buildTip(Icons.cleaning_services_outlined, context.tr('tip_clutter_title'), context.tr('tip_clutter_desc')),
              ],
            ),
          ),
        ),
        // Next button
        _buildGradientButton(
          label: context.tr('next'),
          enabled: selectedImage != null,
          onPressed: _nextStep,
        ),
      ],
    );
  }

  Widget _buildTip(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _kTextSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextPrimary)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: _kTextSecondary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── STEP 1: Choose Your Aesthetic ────────────────────────────────

  Widget _buildTab(int index, IconData icon, String label, String badge, Color activeColor) {
    final isActive = _styleTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticService.selectionClick();
            setState(() => _styleTab = index);
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? _kCardBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: isActive ? activeColor : _kTextMuted),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? activeColor : _kTextMuted),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: isActive ? 0.15 : 0.06),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: isActive ? activeColor : _kTextMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorldsGrid() {
    return GridView.builder(
      controller: _contentScrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _worlds.length,
      itemBuilder: (context, index) {
        final world = _worlds[index];
        final isSelected = _selectedWorld?.id == world.id;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedWorld = world;
              context.read<AppProvider>().setSelectedStyle(null);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [BoxShadow(color: _kGradientEnd.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: world.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: _kSurfaceBg),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  // Dark gradient overlay at bottom
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Selection border overlay
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kGradientEnd, width: 3),
                      ),
                    ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: _kGradientEnd, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                    ),
                  // Stacked top-left tags with spacing
                  Positioned(
                    top: 6,
                    left: 6,
                    right: 40,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.public, size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(world.category, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
                            ],
                          ),
                        ),
                        if (world.isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                          ),
                      ],
                    ),
                  ),
                  // Name and description at bottom
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          world.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          world.description.isNotEmpty ? world.description : world.category,
                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Curated design styles for the Design tab. Japanese-influenced first 4.
  // Anything else in WorldService falls into the World tab (fictional/thematic).
  static const List<String> _designWorldIds = [
    // Japanese-influenced first 4
    'japandi',
    'wabi-sabi-modern',
    'zen-minimalism',
    'wabi-sabi-japanese',
    // Clean / minimal
    'minimalism',
    'scandinavian-hygge',
    'art-deco-glamour',
    'mid-century-modern',
    'coastal-modern',
    'coastal-hampton',
    'coastal-grandma',
    'spanish-mediterranean-modern',
    'hollywood-regency',
    // Regional / period
    'french-provence',
    'french-parisian',
    'italian-tuscan',
    'mexican-hacienda',
    'moroccan-riad',
    'wes-anderson-hotel',
    'rustic-farmhouse',
    'grandmillennial',
    'cottagecore',
    'cottagecore-dark',
    'dark-academia',
    // Industrial / raw
    'british-industrial-loft',
    'brutalist',
    'steampunk',
    'rustic',
    // Botanical / nature
    'biophilic',
    'tropical-paradise',
    'maximalist-botanical',
    'zen-tea-room',
    // Busy / fun / futuristic last
    'memphis-design',
    'barbiecore',
    'bohemian',
    'eclectic',
    'maximalism',
    'futuristic-scifi',
  ];

  Widget _buildStep1ChooseStyle(AppProvider appProvider) {
    final selectedStyle = appProvider.selectedStyle;
    final hasWorldPrompt = appProvider.selectedWorldPrompt != null && appProvider.selectedWorldPrompt!.isNotEmpty;
    final hasSelection = selectedStyle != null || _selectedWorld != null || hasWorldPrompt;

    // Design tab follows the _designWorldIds order exactly (clean -> busy).
    // World tab keeps the API order for everything else.
    final worldsById = {for (final w in _worlds) w.id: w};
    final designItems = <_AestheticItem>[
      for (final id in _designWorldIds)
        if (worldsById[id] != null) _AestheticItem.world(worldsById[id]!),
    ];
    final designIdSet = _designWorldIds.toSet();
    final worldItems = _worlds
        .where((w) => !designIdSet.contains(w.id))
        .map((w) => _AestheticItem.world(w))
        .toList();
    // _styleTab: 0 = Design, 1 = World
    final displayedItems = _styleTab == 0 ? designItems : worldItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                context.tr('choose_aesthetic'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('choose_aesthetic_desc'),
                style: const TextStyle(
                  fontSize: 15,
                  color: _kTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _kSurfaceBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildTab(0, Icons.grid_view, context.tr('tab_design'), '${designItems.length}', _kGradientEnd),
                    _buildTab(1, Icons.storefront, context.tr('tab_world'), '${worldItems.length}', const Color(0xFFEF4444)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              key: ValueKey('aesthetic_grid_$_styleTab'),
              controller: _contentScrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: displayedItems.length,
              itemBuilder: (context, index) {
                final item = displayedItems[index];
                return _AestheticCard(
                  item: item,
                  isSelected: item.isStyle
                      ? selectedStyle?.id == item.style!.id
                      : _selectedWorld?.id == item.world!.id,
                  onTap: () {
                    if (item.isStyle) {
                      setState(() => _selectedWorld = null);
                      appProvider.setSelectedStyle(item.style);
                      // Clear any stale world prompt from a previous selection.
                      appProvider.clearWorldPrompt();
                    } else {
                      setState(() {
                        _selectedWorld = item.world;
                      });
                      appProvider.setSelectedStyle(null);
                      // Sync immediately so preview + create use the right world.
                      appProvider.setSelectedWorldPrompt(
                        item.world!.prompt,
                        worldName: item.world!.name,
                      );
                    }
                  },
                );
              },
            ),
          ),
        ),
        _buildGradientButton(
          label: '${context.tr('next')} \u2192',
          enabled: hasSelection,
          onPressed: _nextStep,
        ),
      ],
    );
  }

  // ─── STEP 2: Refine Vision (Custom Instructions + Quality) ────────

  Widget _buildStep2RefineVision(AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  context.tr('refine_vision'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('refine_vision_desc'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: _kTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Custom Instructions Section ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('custom_instructions'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr('custom_instructions_desc'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _customMode ? _kGradientEnd : _kTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Toggle switch
                          Switch(
                            value: _customMode,
                            onChanged: (val) {
                              HapticService.selectionClick();
                              setState(() => _customMode = val);
                            },
                            activeThumbColor: _kGradientEnd,
                            activeTrackColor: _kGradientEnd.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: _customMode
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _customPromptController,
                                    maxLines: 4,
                                    style: const TextStyle(fontSize: 14, color: _kTextPrimary),
                                    decoration: InputDecoration(
                                      hintText: context.tr('custom_prompt_hint'),
                                      hintStyle: const TextStyle(fontSize: 13, color: _kTextMuted),
                                      filled: true,
                                      fillColor: _kSurfaceBg,
                                      contentPadding: const EdgeInsets.all(14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: _kGradientEnd, width: 1.5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(context.tr('quick_suggestions'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTextMuted, letterSpacing: 0.5)),
                                  const SizedBox(height: 8),
                                  // Quick Suggestions
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _quickSuggestions.map((suggestion) {
                                      return GestureDetector(
                                        onTap: () {
                                          HapticService.selectionClick();
                                          final current = _customPromptController.text;
                                          final addition = current.isEmpty ? suggestion : '$current, $suggestion';
                                          _customPromptController.text = addition;
                                          _customPromptController.selection = TextSelection.fromPosition(
                                            TextPosition(offset: addition.length),
                                          );
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _kGradientEnd.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            suggestion,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: _kGradientEnd,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Choose Quality Section ──
                Text(
                  context.tr('choose_quality'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Standard option
                _buildQualityCard(
                  tierId: 'free',
                  label: context.tr('quality_standard'),
                  description: context.tr('quality_standard_desc'),
                  icon: Icons.speed,
                ),
                const SizedBox(height: 10),
                // Ultra HD option
                _buildQualityCard(
                  tierId: 'pro',
                  label: context.tr('quality_ultra_hd'),
                  description: context.tr('quality_ultra_hd_desc'),
                  icon: Icons.hd,
                ),
                const SizedBox(height: 10),
                // PRO+ option
                _buildQualityCard(
                  tierId: 'best',
                  label: context.tr('quality_pro_plus'),
                  description: context.tr('quality_pro_plus_desc'),
                  icon: Icons.diamond,
                ),

                const SizedBox(height: 20),

                // Pro Tip
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 18, color: _kGradientEnd),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('pro_tip'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kGradientEnd)),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('pro_tip_desc'),
                              style: TextStyle(fontSize: 12, color: _kTextSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _buildGradientButton(
          label: '${context.tr('continue_btn')} \u2192',
          enabled: true,
          onPressed: _nextStep,
        ),
      ],
    );
  }

  Widget _buildQualityCard({
    required String tierId,
    required String label,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedTier == tierId;
    final isPro = tierId == 'pro';
    final isBest = tierId == 'best';
    final accentColor = isBest ? const Color(0xFFEF4444) : _kGradientEnd;

    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        setState(() => _selectedTier = tierId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ((isPro || isBest) ? accentColor.withValues(alpha: 0.06) : _kCardBg) : _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: accentColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? accentColor : _kTextMuted, width: 2),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isSelected ? (isBest ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]) : _kGradient) : null,
                color: isSelected ? null : _kSurfaceBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : _kTextMuted,
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? accentColor : _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected ? (isBest ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]) : _kGradient) : null,
                border: isSelected ? null : Border.all(color: _kTextMuted.withValues(alpha: 0.4), width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 3: Review Selection ─────────────────────────────────────

  Widget _buildStep3ReviewSelection(AppProvider appProvider) {
    final selectedStyle = appProvider.selectedStyle;
    final selectedImage = appProvider.selectedImage;
    final tierLabel = _selectedTier == 'free' ? context.tr('quality_standard') : _selectedTier == 'best' ? context.tr('quality_pro_plus') : context.tr('quality_ultra_hd');

    // Token breakdown (premium style multiplier removed)
    final baseCost = AppProvider.tierMultipliers[_selectedTier] ?? 1;
    const premMul = 1;
    final totalTokens = _tokenCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  context.tr('review_selection'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Original (photo preview) ──
                Text(
                  context.tr('original'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTextSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [_kGradientStart, _kGradientEnd, Color(0xFF8B5CF6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kGradientEnd.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: selectedImage != null
                              ? Image.file(
                                  selectedImage,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Container(
                                  color: _kSurfaceBg,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_a_photo, color: _kGradientEnd.withValues(alpha: 0.5), size: 36),
                                        const SizedBox(height: 8),
                                        Text(context.tr('tap_add_photo'), style: const TextStyle(color: _kTextMuted, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          top: 12, left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_camera, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(context.tr('original_canvas'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Style + Quality side by side ──
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Style card
                      Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('style_label'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTextMuted),
                            ),
                            const SizedBox(height: 6),
                            if (selectedStyle != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SkeletonImage(
                                  imageUrl: selectedStyle.imageUrl,
                                  width: double.infinity,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              )
                            else if (_selectedWorld != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: _selectedWorld!.imageUrl,
                                  width: double.infinity,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _kSurfaceBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _kSurfaceBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.image, color: _kTextMuted, size: 20),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              selectedStyle?.name
                                  ?? _selectedWorld?.name
                                  ?? appProvider.selectedWorldName
                                  ?? context.tr('none'),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Quality card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('quality'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTextMuted),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: _selectedTier == 'best'
                                    ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                                    : _selectedTier == 'pro' ? _kGradient : null,
                                color: _selectedTier == 'free' ? _kSurfaceBg : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                _selectedTier == 'best' ? Icons.diamond : _selectedTier == 'pro' ? Icons.hd : Icons.speed,
                                color: _selectedTier != 'free' ? Colors.white : _kTextMuted,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tierLabel,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  ),
                ),

                // Custom instructions summary
                if (_customMode && _customPromptController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kGradientEnd.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.edit_note, size: 18, color: _kGradientEnd.withValues(alpha: 0.7)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('custom_instructions'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kGradientEnd),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _customPromptController.text.trim(),
                                style: const TextStyle(fontSize: 12, color: _kTextSecondary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Token breakdown ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTokenRow(context.tr('base_transformation'), baseCost),
                      if (_customMode)
                        _buildTokenRow(context.tr('custom_instructions_2x'), baseCost * premMul),
                      const SizedBox(height: 8),
                      Container(
                        height: 1,
                        color: _kSurfaceBg,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('total_tokens'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _kTextPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: _kGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$totalTokens',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                if (appProvider.tokenBalance < _tokenCost) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, size: 18, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr('not_enough_tokens_msg')
                                .replaceFirst('%s', '$_tokenCost')
                                .replaceFirst('%s', '${appProvider.tokenBalance}'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        // Start Design / Get More Tokens button
        if (appProvider.tokenBalance < _tokenCost)
          _buildGradientButton(
            label: context.tr('get_more_tokens'),
            enabled: true,
            onPressed: () async {
              HapticService.mediumImpact();
              await RevenueCatService().presentPaywall(context, appProvider: appProvider);
            },
          )
        else
          _buildGradientButton(
            label: selectedImage == null ? context.tr('select_photo_first') : context.tr('start_design'),
            enabled: true,
            onPressed: selectedImage != null ? _startDesign : _showImageSourceDialog,
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTokenRow(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Text('·  ', style: TextStyle(fontSize: 16, color: _kTextSecondary)),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: _kTextSecondary))),
          Text('$amount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextPrimary)),
          Text(context.tr('tokens_suffix'), style: const TextStyle(fontSize: 10, color: _kTextMuted)),
        ],
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _kSurfaceBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kGradientEnd.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _kGradientEnd, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unified item for the Step 1 aesthetic grid: wraps either a DesignStyle
/// (built-in aesthetics) or a SpecialtyWorld (Modern Architecture, Design
/// Styles, etc.) so they can coexist in a single grid.
class _AestheticItem {
  _AestheticItem.style(DesignStyle this.style) : world = null;
  _AestheticItem.world(SpecialtyWorld this.world) : style = null;

  final DesignStyle? style;
  final SpecialtyWorld? world;

  bool get isStyle => style != null;
  String get imageUrl => style?.imageUrl ?? world!.imageUrl;
  String get name => style?.name ?? world!.name;
  String get description => style?.description ?? world!.description;
  bool get isNew => world?.isNew ?? false;
  String get category => world?.category ?? style?.category ?? '';
}

class _AestheticCard extends StatelessWidget {
  const _AestheticCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _AestheticItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: _kGradientEnd.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              item.isStyle
                  ? SkeletonImage(imageUrl: item.imageUrl, fit: BoxFit.cover)
                  : CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: _kSurfaceBg),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kGradientEnd, width: 3),
                  ),
                ),
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: _kGradientEnd, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                ),
              if (item.isNew)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85), height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
