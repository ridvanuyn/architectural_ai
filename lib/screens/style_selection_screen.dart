import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/models/specialty_world.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../core/services/world_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import 'processing_screen.dart';
import 'store_screen.dart';

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

  bool _customMode = false;
  int _currentStep = 0;
  String _selectedTier = 'pro';
  int _styleTab = 0; // 0 = All, 1 = Premium, 2 = Worlds
  List<SpecialtyWorld> _worlds = [];
  SpecialtyWorld? _selectedWorld;

  static const int _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    final appProvider = context.read<AppProvider>();
    _selectedTier = appProvider.tier;
    _loadWorlds();

    // If coming from store with a world prompt already set, skip style selection
    if (appProvider.selectedWorldPrompt != null && appProvider.selectedWorldPrompt!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToStep(1); // Jump to Custom Instructions step
      });
    }
  }

  Future<void> _loadWorlds() async {
    // First load defaults (same as store), then try API
    setState(() => _worlds = StoreScreen.getDefaultWorlds());
    try {
      final worlds = await WorldService().getWorlds();
      if (mounted && worlds.isNotEmpty) {
        setState(() => _worlds = worlds);
      }
    } catch (_) {
      // Keep defaults
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    setState(() => _currentStep = step);
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
      Navigator.pop(context);
    } else {
      _goToStep(_currentStep - 1);
    }
  }

  int get _tokenCost {
    final appProvider = context.read<AppProvider>();
    final isPremStyle = appProvider.selectedStyle != null && _isStylePremium(appProvider.selectedStyle!.id);
    final styleMul = isPremStyle ? 2 : 1;
    final tierMul = AppProvider.tierMultipliers[_selectedTier] ?? 1;
    final customMul = _customMode ? 2 : 1;
    return tierMul * customMul * styleMul;
  }

  Future<void> _showImageSourceDialog() async {
    HapticService.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Your Room Photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a new photo or choose from gallery',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
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
                    label: 'Gallery',
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
        appProvider.setSelectedImage(File(pickedFile.path));
        HapticService.success();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _startDesign() {
    final appProvider = context.read<AppProvider>();

    if (appProvider.selectedImage == null) {
      _showImageSourceDialog();
      return;
    }

    if (appProvider.tokenBalance < _tokenCost) {
      HapticService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Need $_tokenCost tokens. Buy more to continue.')),
      );
      return;
    }

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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            leading: IconButton(
              onPressed: () {
                HapticService.lightImpact();
                _prevStep();
              },
              icon: const Icon(Icons.arrow_back_ios, size: 20),
            ),
            title: Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tagBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.token, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${appProvider.tokenBalance}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
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
                // Step indicator dots
                _buildStepIndicator(),
                const SizedBox(height: 8),
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentStep = index);
                    },
                    children: [
                      _buildStep1ChooseStyle(appProvider),
                      _buildStep2CustomInstructions(appProvider),
                      _buildStep3ChooseQuality(appProvider),
                      _buildStep4Confirm(appProvider),
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

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : isCompleted
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── STEP 1: Choose Style ──────────────────────────────────────────

  Widget _buildTab(int index, IconData icon, String label, String badge, Color activeColor) {
    final isActive = _styleTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.selectionClick();
          setState(() => _styleTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive ? activeColor : AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? activeColor : AppColors.textMuted),
              ),
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: isActive ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isActive ? activeColor : AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorldsGrid() {
    return GridView.builder(
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
              // Clear style selection when picking a world
              context.read<AppProvider>().setSelectedStyle(null);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFFEF4444) : AppColors.cardBorder,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: world.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.background),
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
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                    ),
                  // World badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
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
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(world.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(world.description, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.8))),
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

  static const _premiumStyleIds = {
    'art-deco', 'mid-century', 'cyberpunk', 'luxury', 'tropical', 'mediterranean',
  };

  bool _isStylePremium(String id) => _premiumStyleIds.contains(id);

  Widget _buildStep1ChooseStyle(AppProvider appProvider) {
    final allStyles = appProvider.styles;
    final selectedStyle = appProvider.selectedStyle;

    final standardStyles = allStyles.where((s) => !_isStylePremium(s.id)).toList();
    final premiumStyles = allStyles.where((s) => _isStylePremium(s.id)).toList();
    final displayedStyles = _styleTab == 0 ? standardStyles : premiumStyles;
    final hasWorldPrompt = appProvider.selectedWorldPrompt != null && appProvider.selectedWorldPrompt!.isNotEmpty;
    final hasSelection = selectedStyle != null || _selectedWorld != null || hasWorldPrompt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Your Style',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // Tab bar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTab(0, Icons.grid_view, 'Styles', '${standardStyles.length}', AppColors.primary),
                    _buildTab(1, Icons.diamond, 'Premium', 'x2', const Color(0xFF6C63FF)),
                    _buildTab(2, Icons.storefront, 'Store', '${_worlds.length}', const Color(0xFFEF4444)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _styleTab == 2
                ? _buildWorldsGrid()
                : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: displayedStyles.length,
              itemBuilder: (context, index) {
                final style = displayedStyles[index];
                final isSelected = selectedStyle?.id == style.id;
                final isPremStyle = _isStylePremium(style.id);
                return GestureDetector(
                  onTap: () {
                    appProvider.setSelectedStyle(style);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? (isPremStyle ? const Color(0xFF6C63FF) : AppColors.primary)
                            : AppColors.cardBorder,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (isPremStyle ? const Color(0xFF6C63FF) : AppColors.primary).withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                SkeletonImage(
                                  imageUrl: style.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                                if (isSelected)
                                  Container(
                                    color: (isPremStyle ? const Color(0xFF6C63FF) : AppColors.primary).withValues(alpha: 0.15),
                                    alignment: Alignment.topRight,
                                    padding: const EdgeInsets.all(8),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isPremStyle ? const Color(0xFF6C63FF) : AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                                    ),
                                  ),
                                // Premium badge
                                if (isPremStyle)
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6C63FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.diamond, size: 10, color: Colors.white),
                                          SizedBox(width: 3),
                                          Text('x2', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? (isPremStyle ? const Color(0xFF6C63FF) : AppColors.primary)
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                style.description,
                                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Next button
        _buildBottomButton(
          label: 'Next',
          icon: Icons.arrow_forward,
          enabled: hasSelection,
          onPressed: _nextStep,
        ),
      ],
    );
  }

  // ─── STEP 2: Custom Instructions ──────────────────────────────────

  Widget _buildStep2CustomInstructions(AppProvider appProvider) {
    final selectedStyle = appProvider.selectedStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Custom Instructions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add specific changes you want (optional)',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Selected style card
        if (selectedStyle != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SkeletonImage(
                      imageUrl: selectedStyle.imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedStyle.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          selectedStyle.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        // Custom mode toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () {
              HapticService.selectionClick();
              setState(() => _customMode = !_customMode);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _customMode
                    ? const Color(0xFFFFF7ED)
                    : AppColors.tagBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _customMode
                      ? Colors.orange.shade300
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 22,
                    color: _customMode ? Colors.orange.shade700 : AppColors.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable Custom Instructions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _customMode ? Colors.orange.shade800 : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Costs 2x tokens for personalized results',
                          style: TextStyle(
                            fontSize: 11,
                            color: _customMode ? Colors.orange.shade600 : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _customMode ? Colors.orange : AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _customMode ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _customMode ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Text field (shown when custom mode is on)
        if (_customMode) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _customPromptController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. "Add a wooden bookshelf on the left wall, change the sofa to navy blue"',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange.shade300, width: 2),
                ),
              ),
            ),
          ),
        ],
        const Spacer(),
        // Skip / Next buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticService.lightImpact();
                    setState(() {
                      _customMode = false;
                      _customPromptController.clear();
                    });
                    _nextStep();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    HapticService.lightImpact();
                    _nextStep();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _customMode ? Colors.orange.shade600 : AppColors.primary,
                    minimumSize: const Size(0, 52),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_customMode ? 'Next with Custom' : 'Next'),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── STEP 3: Choose Quality Tier ──────────────────────────────────

  Widget _buildStep3ChooseQuality(AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Quality',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select the quality tier for your design',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildTierCard(
                  tierId: 'free',
                  label: 'FREE',
                  subtitle: 'Fast & Free',
                  description: 'Quick results with standard quality. Great for exploring different styles.',
                  baseTokens: 1,
                  gradient: null,
                  color: Colors.grey.shade600,
                  bgColor: Colors.grey.shade50,
                  borderColor: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                _buildTierCard(
                  tierId: 'pro',
                  label: 'PRO+',
                  subtitle: 'Better Quality',
                  description: 'Enhanced detail and accuracy. Recommended for most designs.',
                  baseTokens: 2,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                  ),
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFF5F3FF),
                  borderColor: const Color(0xFFDDD6FE),
                ),
                const SizedBox(height: 12),
                _buildTierCard(
                  tierId: 'best',
                  label: 'BEST',
                  subtitle: 'Best Quality',
                  description: 'Maximum detail, photorealistic results. Best for final designs.',
                  baseTokens: 3,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                  ),
                  color: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        _buildBottomButton(
          label: 'Next',
          icon: Icons.arrow_forward,
          enabled: true,
          onPressed: _nextStep,
        ),
      ],
    );
  }

  Widget _buildTierCard({
    required String tierId,
    required String label,
    required String subtitle,
    required String description,
    required int baseTokens,
    required Gradient? gradient,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    final isSelected = _selectedTier == tierId;
    final tokenCost = baseTokens * (_customMode ? 2 : 1);

    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        setState(() => _selectedTier = tierId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Tier badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                color: gradient == null ? Colors.grey.shade200 : null,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: tierId == 'best' ? 11 : 12,
                  fontWeight: FontWeight.w900,
                  color: gradient != null ? Colors.white : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Token cost + check
            Column(
              children: [
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBorder, width: 2),
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.1) : AppColors.tagBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$tokenCost tk',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 4: Confirm ──────────────────────────────────────────────

  Widget _buildStep4Confirm(AppProvider appProvider) {
    final selectedStyle = appProvider.selectedStyle;
    final selectedImage = appProvider.selectedImage;
    final tierLabel = _selectedTier == 'free'
        ? 'FREE'
        : _selectedTier == 'pro'
            ? 'PRO+'
            : 'BEST';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm Your Design',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Review your selections before starting',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Photo
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: selectedImage != null
                            ? Image.file(
                                selectedImage,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 72,
                                height: 72,
                                color: AppColors.tagBackground,
                                child: Icon(Icons.add_a_photo, color: AppColors.primary),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedImage != null ? 'Room Photo' : 'No Photo Selected',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedImage != null ? 'Tap to change' : 'Tap to add a photo',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (selectedImage != null)
                        Icon(Icons.check_circle, color: AppColors.success, size: 22)
                      else
                        Icon(Icons.warning_amber, color: Colors.orange, size: 22),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 12),
                // Style
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      if (selectedStyle != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SkeletonImage(
                            imageUrl: selectedStyle.imageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Style',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedStyle?.name ?? _selectedWorld?.name ?? appProvider.selectedWorldPrompt?.split(' ').take(3).join(' ') ?? 'None',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (selectedStyle != null)
                              Text(
                                selectedStyle.description,
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Tier
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: _selectedTier == 'pro'
                              ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9333EA)])
                              : _selectedTier == 'best'
                                  ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)])
                                  : null,
                          color: _selectedTier == 'free' ? Colors.grey.shade200 : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tierLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: _selectedTier == 'free' ? Colors.grey.shade700 : Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quality Tier',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tierLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Custom instructions (if any)
                if (_customMode && _customPromptController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.edit_note, size: 20, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Custom Instructions',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _customPromptController.text.trim(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade900,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Token cost summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tagBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.token, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Total Cost',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$_tokenCost Token${_tokenCost > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (appProvider.tokenBalance < _tokenCost) ...[
                  const SizedBox(height: 12),
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
                            'You need $_tokenCost tokens but only have ${appProvider.tokenBalance}. Buy more to continue.',
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
        Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: appProvider.tokenBalance < _tokenCost
              ? ElevatedButton(
                  onPressed: () {
                    HapticService.mediumImpact();
                    Navigator.pushNamed(context, '/purchase');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Get More Tokens',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: selectedImage == null ? _showImageSourceDialog : null,
                  child: ElevatedButton(
                    onPressed: selectedImage != null
                        ? _startDesign
                        : _showImageSourceDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _customMode ? Colors.orange.shade600 : AppColors.primary,
                      disabledBackgroundColor: AppColors.cardBorder,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedImage == null
                              ? Icons.add_a_photo
                              : Icons.auto_awesome,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          selectedImage == null ? 'Select Photo First' : 'Start Design',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_tokenCost Token${_tokenCost > 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ─── Shared bottom button ─────────────────────────────────────────

  Widget _buildBottomButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.cardBorder,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 18),
          ],
        ),
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
          color: AppColors.tagBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
