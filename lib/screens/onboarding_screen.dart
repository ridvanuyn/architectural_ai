import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/localization_extension.dart';
import '../core/models/specialty_world.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/world_service.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _pageIndex = 0;
  static const int _totalPages = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    HapticService.lightImpact();
    if (_pageIndex < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _goBack() {
    HapticService.lightImpact();
    if (_pageIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _skip() {
    HapticService.lightImpact();
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await HapticService.success();

    if (mounted) {
      final provider = context.read<AppProvider>();
      await provider.completeOnboarding();
      await provider.grantWelcomeTokensIfFirstTime();
    }

    await NotificationService().showWelcomeBonus();

    if (mounted) {
      Navigator.pushReplacementNamed(context, HomeShell.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  if (_pageIndex > 0)
                    GestureDetector(
                      onTap: _goBack,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                    )
                  else
                    const SizedBox(width: 34),
                  const Spacer(),
                  // Step indicator - always visible
                  Builder(
                    builder: (context) {
                      final stepText = context.tr('step_of')
                          .replaceFirst('%s', '${_pageIndex + 1}')
                          .replaceFirst('%s', '$_totalPages');
                      return Text(
                        stepText,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  // Hide skip on last 2 pages (3 and 4)
                  if (_pageIndex < 2)
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        context.tr('skip'),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 50),
                ],
              ),
            ),
            // Progress bar - show on all pages
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Row(
                children: List.generate(_totalPages, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _pageIndex
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Content
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _pageIndex = index);
                },
                children: [
                  const _UnlimitedPossibilitiesPage(),
                  const _DreamsSavedPage(),
                  _ReadyToSeeMagicPage(),
                  const _InteractiveDemoPage(),
                ],
              ),
            ),
            // Bottom section - show on all pages
            Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Page indicators (only for page 1)
                    if (_pageIndex == 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_totalPages, (index) {
                            final isActive = _pageIndex == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.primary : AppColors.cardBorder,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ),
                    // Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goNext,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_pageIndex == _totalPages - 1 ? context.tr('get_started') : context.tr('next')),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                    if (_pageIndex == 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          context.tr('onboarding_terms_notice'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Page 1: Unlimited Possibilities - Style Grid
class _UnlimitedPossibilitiesPage extends StatelessWidget {
  const _UnlimitedPossibilitiesPage();

  static const List<_StylePreview> _styles = [
    _StylePreview('Boho', Color(0xFF2D5A27), 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=300'),
    _StylePreview('Industrial', Color(0xFF4A4A4A), 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=300'),
    _StylePreview('Minimal', Color(0xFF8B9A7D), 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=300'),
    _StylePreview('Classic', Color(0xFFB8860B), 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=300'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            context.tr('onboarding_themes_title'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('onboarding_themes_desc'),
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          // Style grid
          Expanded(
            child: Stack(
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _styles.length,
                  itemBuilder: (context, index) {
                    final style = _styles[index];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(style.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              style.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Floating sparkle icon
                Positioned(
                  right: 0,
                  top: 80,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Token info badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.token, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('token_per_style'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StylePreview {
  const _StylePreview(this.name, this.color, this.imageUrl);
  final String name;
  final Color color;
  final String imageUrl;
}

// Page 2: Your dreams are always saved
class _DreamsSavedPage extends StatelessWidget {
  const _DreamsSavedPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Main image card
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=600',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Saved badge
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.tr('saved_badge'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Storage info
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone_iphone, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr('on_device_storage'),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              context.tr('fully_private'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            context.tr('onboarding_vision_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('onboarding_vision_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Feature list
          _FeatureCheckItem(text: context.tr('onboarding_feature_styles')),
          const SizedBox(height: 12),
          _FeatureCheckItem(text: context.tr('onboarding_feature_tokens')),
        ],
      ),
    );
  }
}

class _FeatureCheckItem extends StatelessWidget {
  const _FeatureCheckItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Page 3: Iconic Worlds — random featured worlds from store
class _ReadyToSeeMagicPage extends StatefulWidget {
  const _ReadyToSeeMagicPage();

  @override
  State<_ReadyToSeeMagicPage> createState() => _ReadyToSeeMagicPageState();
}

class _ReadyToSeeMagicPageState extends State<_ReadyToSeeMagicPage> {
  final WorldService _worldService = WorldService();
  List<SpecialtyWorld> _featured = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedWorlds();
  }

  Future<void> _loadFeaturedWorlds() async {
    try {
      final worlds = await _worldService.getWorlds();
      if (mounted && worlds.isNotEmpty) {
        final shuffled = List<SpecialtyWorld>.from(worlds)..shuffle();
        setState(() {
          _featured = shuffled.take(4).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Failed to load worlds for onboarding: $e');
    }
    // Fallback to store defaults
    if (mounted) {
      final defaults = List<SpecialtyWorld>.from(
        _fallbackWorlds(),
      )..shuffle();
      setState(() {
        _featured = defaults.take(4).toList();
        _isLoading = false;
      });
    }
  }

  static List<SpecialtyWorld> _fallbackWorlds() {
    return [
      SpecialtyWorld(id: 'hobbit-hole', name: 'Hobbit Hole', description: 'Middle Earth Style', category: 'fantasy', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/hobbit-hole.jpg', prompt: ''),
      SpecialtyWorld(id: 'gryffindor-room', name: 'Gryffindor Room', description: 'Bravery & Gold', category: 'fantasy', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/gryffindor-room.jpg', prompt: ''),
      SpecialtyWorld(id: 'cyberpunk-2077', name: 'Cyberpunk 2077', description: 'Neon Night City', category: 'futuristic', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/cyberpunk-2077.jpg', prompt: ''),
      SpecialtyWorld(id: 'victorian-1800s', name: '1800s Victorian', description: 'Gothic Elegance', category: 'historical', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/victorian-1800s.jpg', prompt: ''),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final names = _featured.map((w) => w.name).join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4400B6), Color(0xFF5D21DF)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(context.tr('iconic_worlds_badge'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 2x2 grid of featured worlds
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: _featured.map((world) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        world.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.cardBackground),
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
                      Positioned(
                        left: 8, bottom: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              world.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Text(
                              world.category,
                              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('iconic_worlds_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('iconic_worlds_desc').replaceFirst('%s', names),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Page 4: Interactive Demo - Try it yourself
class _InteractiveDemoPage extends StatefulWidget {
  const _InteractiveDemoPage();

  @override
  State<_InteractiveDemoPage> createState() => _InteractiveDemoPageState();
}

class _InteractiveDemoPageState extends State<_InteractiveDemoPage>
    with SingleTickerProviderStateMixin {
  double _sliderPosition = 0.5;
  int _selectedStyleIndex = 0;
  bool _isGenerating = false;

  static const _originalUrl =
      'https://architectural-ai-demo.s3.eu-central-1.amazonaws.com/demo/original.jpg';

  static const _demoStyles = [
    {
      'id': 'japandi',
      'name': 'Japandi',
      'url':
          'https://architectural-ai-demo.s3.eu-central-1.amazonaws.com/demo/japandi.jpg'
    },
    {
      'id': 'gryffindor',
      'name': 'Gryffindor',
      'url':
          'https://architectural-ai-demo.s3.eu-central-1.amazonaws.com/demo/v2/gryffindor.jpg'
    },
    {
      'id': 'cyberpunk',
      'name': 'Cyberpunk',
      'url':
          'https://architectural-ai-demo.s3.eu-central-1.amazonaws.com/demo/cyberpunk.jpg'
    },
    {
      'id': 'minecraft',
      'name': 'Minecraft',
      'url':
          'https://architectural-ai-demo.s3.eu-central-1.amazonaws.com/demo/v2/minecraft.jpg'
    },
    {
      'id': 'anime',
      'name': 'Anime',
      'url':
          'https://architectural-ai-demo.s3.eu-central-1.amazonaws.com/demo/anime.jpg'
    },
  ];

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _selectStyle(int index) {
    if (index == _selectedStyleIndex || _isGenerating) return;
    HapticService.lightImpact();
    setState(() {
      _isGenerating = true;
      _selectedStyleIndex = index;
    });
    _shimmerController.repeat();

    // Fake generation delay, then reveal
    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _shimmerController.stop();
        setState(() => _isGenerating = false);
        HapticService.lightImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedStyle = _demoStyles[_selectedStyleIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              context.tr('interactive_demo'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('try_yourself'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('tap_style_slide'),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          // Style chips - horizontal scrollable row
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _demoStyles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final style = _demoStyles[index];
                final isSelected = index == _selectedStyleIndex;
                return GestureDetector(
                  onTap: () => _selectStyle(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.auto_awesome,
                                size: 14, color: Colors.white),
                          ),
                        Text(
                          style['name']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          // Before/After slider
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;

                    return GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _sliderPosition += details.delta.dx / width;
                          _sliderPosition =
                              _sliderPosition.clamp(0.05, 0.95);
                        });
                      },
                      child: Stack(
                        children: [
                          // After image (selected style result)
                          Positioned.fill(
                            child: Image.network(
                              selectedStyle['url']!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey.shade200),
                            ),
                          ),
                          // Before image (original)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: width * _sliderPosition,
                            child: ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.centerLeft,
                                maxWidth: width,
                                child: SizedBox(
                                  width: width,
                                  height: height,
                                  child: Image.network(
                                    _originalUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        color: Colors.brown.shade200),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Shimmer overlay during "generation"
                          if (_isGenerating)
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _shimmerAnimation,
                                builder: (context, child) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment(
                                            _shimmerAnimation.value - 1, 0),
                                        end: Alignment(
                                            _shimmerAnimation.value + 1, 0),
                                        colors: [
                                          Colors.white
                                              .withValues(alpha: 0.0),
                                          Colors.white
                                              .withValues(alpha: 0.4),
                                          Colors.white
                                              .withValues(alpha: 0.0),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.6),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              context.tr('generating'),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          // Original tag
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                context.tr('original_badge'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Style tag (dynamic based on selection)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                selectedStyle['name']!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Separator line
                          Positioned(
                            left: width * _sliderPosition - 1.5,
                            top: 0,
                            bottom: 0,
                            child: Container(
                                width: 3, color: Colors.white),
                          ),
                          // Slider handle
                          Positioned(
                            left: width * _sliderPosition - 20,
                            top: height / 2 - 20,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.swap_horiz,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Info text
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('onboarding_demo_info'),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
