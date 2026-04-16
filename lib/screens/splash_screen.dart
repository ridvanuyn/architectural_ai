import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/localization/localization_extension.dart';
import '../core/providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();

    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (!mounted) return;
    
    final appProvider = context.read<AppProvider>();
    
    // Always show onboarding for testing
    Navigator.pushReplacementNamed(context, OnboardingScreen.routeName);
    
    // TODO: Restore this for production:
    // if (appProvider.onboardingCompleted) {
    //   Navigator.pushReplacementNamed(context, HomeShell.routeName);
    // } else {
    //   Navigator.pushReplacementNamed(context, OnboardingScreen.routeName);
    // }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // App Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4400B6), Color(0xFF5D21DF)]),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.architecture, size: 56, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // App Name
                const Text(
                  'Architectural AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Tagline
                Text(
                  context.tr('splash_tagline'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const Spacer(flex: 3),
                // Progress bar
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF4400B6), Color(0xFF5D21DF)]),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('splash_initializing'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                // Footer
                Text(
                  context.tr('splash_powered_by_ai'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}
