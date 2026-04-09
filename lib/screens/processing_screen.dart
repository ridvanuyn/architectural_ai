import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../core/services/notification_service.dart';
import '../theme/app_theme.dart';
import 'before_after_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  static const routeName = '/processing';

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  double _progress = 0;
  Timer? _timer;
  Timer? _messageTimer;
  bool _isCreating = false;
  int _messageIndex = 0;

  static const _magicMessages = [
    'Analyzing your room layout...',
    'Understanding the architecture...',
    'Selecting materials & textures...',
    'Arranging furniture placement...',
    'Applying lighting effects...',
    'Adding decorative elements...',
    'Refining color palette...',
    'Enhancing photorealism...',
    'Polishing final details...',
    'Almost there, magic happening...',
    'Your dream space is forming...',
    'Fine-tuning the atmosphere...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(); // continuous rotation, no reverse

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial haptic
    HapticService.mediumImpact();

    // Rotate messages every 3 seconds
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _magicMessages.length;
        });
      }
    });

    // Start design creation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDesignCreation();
    });
  }

  Future<void> _startDesignCreation() async {
    if (_isCreating) return;
    _isCreating = true;

    final appProvider = context.read<AppProvider>();
    final styleName = appProvider.selectedStyle?.name ?? 'Unknown';

    // Show processing notification
    await NotificationService().showDesignProcessing(styleName: styleName);

    // Animate progress slowly — will jump to 100% when design completes
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_progress < 0.85) {
        setState(() {
          // Slow down as we approach 85%
          _progress += 0.01 * (1 - _progress);
        });

        final progressPercent = (_progress * 100).toInt();
        if (progressPercent == 25 || progressPercent == 50 || progressPercent == 75) {
          HapticService.lightImpact();
        }
      }
    });

    // Start actual design creation in parallel with animation
    final design = await appProvider.createDesign();

    // Design done — complete progress
    _timer?.cancel();
    setState(() => _progress = 1.0);

    await NotificationService().cancelProcessingNotification();

    if (design != null && mounted) {
      Navigator.pushReplacementNamed(context, BeforeAfterScreen.routeName);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appProvider.error ?? 'Failed to create design'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _timer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
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
                NotificationService().cancelProcessingNotification();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close, size: 24),
            ),
            title: const Text(
              'AI Redesign',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Spacer(),
                  // Animated processing visualization
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer rotating ring
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _controller.value * 6.28,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  width: 3,
                                ),
                              ),
                              child: CustomPaint(
                                painter: _ArcPainter(
                                  progress: _controller.value,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Inner pulsing circle with icon
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.1),
                                    AppColors.primary.withValues(alpha: 0.05),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Rotating magic message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _magicMessages[_messageIndex],
                      key: ValueKey(_messageIndex),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + i * 150),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(
                            alpha: (_messageIndex % 3 == i) ? 1.0 : 0.3,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  // Progress section — clean, no border
                  Column(
                    children: [
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 6,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Footer note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '2 tokens will be used for this render',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, progress * 6.28, 2.0, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.progress != progress;
}
