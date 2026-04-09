import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/localization_extension.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../core/services/notification_service.dart';
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
    // Celebration haptic for completing onboarding
    await HapticService.success();
    
    // Complete onboarding in provider
    if (mounted) {
      await context.read<AppProvider>().completeOnboarding();
    }
    
    // Show welcome bonus notification
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
                children: const [
                  _UnlimitedPossibilitiesPage(),
                  _DreamsSavedPage(),
                  _ReadyToSeeMagicPage(),
                  _InteractiveDemoPage(),
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
                            Text(_pageIndex == _totalPages - 1 ? 'Get Started' : 'Next'),
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
                          'By continuing, you agree to our Terms of Service and Privacy Policy regarding local data handling.',
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
          const Text(
            'Unlimited Possibilities',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '8 distinct styles to match your personality.',
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
                    '1 TOKEN PER STYLE',
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
                    child: const Text(
                      'SAVED',
                      style: TextStyle(
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
                              'ON-DEVICE STORAGE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Text(
                              '100% Private',
                              style: TextStyle(
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
          const Text(
            'Your dreams are always\nsaved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No sign-in required. Your architectural designs are stored securely on your device, giving you instant access to your creative history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Feature list
          _FeatureCheckItem(text: '8 Unique architectural styles'),
          const SizedBox(height: 12),
          _FeatureCheckItem(text: 'Token-based generation system'),
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

// Page 3: Ready to see the magic?
class _ReadyToSeeMagicPage extends StatelessWidget {
  const _ReadyToSeeMagicPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Tokens badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  '2 TOKENS GIFTED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://images.unsplash.com/photo-1600210492493-0946911123ea?w=800',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.cardBackground,
                  child: const Center(
                    child: Icon(Icons.home, size: 60, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          const Text(
            'Ready to see the magic?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Description
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: "We've given you "),
                TextSpan(
                  text: '2 free tokens',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' to start redesigning your space in 8 unique styles.'),
              ],
            ),
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

class _InteractiveDemoPageState extends State<_InteractiveDemoPage> {
  double _sliderPosition = 0.5;

  @override
  Widget build(BuildContext context) {
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
            child: const Text(
              'Interactive Demo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Try it yourself.',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Slide to see the transformation.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
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
                          _sliderPosition = _sliderPosition.clamp(0.05, 0.95);
                        });
                      },
                      child: Stack(
                        children: [
                          // After image (Japandi style)
                          Positioned.fill(
                            child: Image.network(
                              'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                            ),
                          ),
                          // Before image
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
                                    'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=800',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.brown.shade200),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Original tag
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ORIGINAL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Style tag
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'JAPANDI',
                                style: TextStyle(
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
                            child: Container(width: 3, color: Colors.white),
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
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
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
                  const SizedBox(height: 20),
                  // Info text
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Choose from 8 unique styles. Renders use 1 token each.',
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
