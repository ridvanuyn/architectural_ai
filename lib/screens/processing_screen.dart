import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/localization_extension.dart';
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
  late List<String> _messages;

  List<String> _getContextMessages(AppProvider appProvider) {
    final style = appProvider.selectedStyle?.id ?? '';
    final worldPrompt = appProvider.selectedWorldPrompt ?? '';

    // Harry Potter themed
    if (worldPrompt.toLowerCase().contains('harry potter') || worldPrompt.toLowerCase().contains('hogwarts') || worldPrompt.toLowerCase().contains('gryffindor')) {
      return [
        'Summoning the Room of Requirement...',
        'Consulting the Sorting Hat for your style...',
        'Casting Lumos on every corner...',
        'Enchanting the furniture with magic...',
        'Professor McGonagall approves this layout...',
        'Adding floating candles above...',
        'The portraits are watching with interest...',
        'Dobby is arranging the decor...',
      ];
    }

    // Matrix themed
    if (worldPrompt.toLowerCase().contains('matrix') || worldPrompt.toLowerCase().contains('neo') || worldPrompt.toLowerCase().contains('construct')) {
      return [
        'Loading the construct...',
        'Bending the rules of interior design...',
        'There is no spoon, but there is style...',
        'Downloading furniture blueprints...',
        'The Oracle predicted this design...',
        'Agents are inspecting the layout...',
        'Choosing between the red and blue pillow...',
        'Reality is being redesigned...',
      ];
    }

    // Post-apocalyptic
    if (worldPrompt.toLowerCase().contains('apocal') || worldPrompt.toLowerCase().contains('bunker') || worldPrompt.toLowerCase().contains('survival')) {
      return [
        'Scanning for the safest layout...',
        'Reinforcing the shelter walls...',
        'Salvaging premium materials...',
        'Installing emergency lighting...',
        'Fortifying your living space...',
        'Making the wasteland beautiful...',
        'Apocalypse-proofing in progress...',
        'Finding beauty after the end...',
      ];
    }

    // Clean/Modern/Minimalist design tips
    if (style == 'modern' || style == 'minimalist' || style == 'scandinavian') {
      return [
        'Less is more — removing visual noise...',
        'Natural light is the best designer...',
        'Choosing the perfect neutral palette...',
        'Clean lines create calm spaces...',
        'Balancing form and function...',
        'Every piece earns its place...',
        'Breathing room makes rooms breathe...',
        'Simplicity is the ultimate sophistication...',
      ];
    }

    // Default architectural tips
    return [
      'Analyzing your room layout...',
      'Understanding the architecture...',
      'Selecting materials & textures...',
      'Arranging furniture placement...',
      'Applying lighting effects...',
      'Adding decorative elements...',
      'Refining color palette...',
      'Enhancing photorealism...',
      'Polishing final details...',
      'Your dream space is forming...',
    ];
  }

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

    // Initialize messages with context-aware content
    final appProvider = context.read<AppProvider>();
    _messages = _getContextMessages(appProvider);

    // Rotate messages every 3 seconds
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
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
      // Check if we should show rating dialog
      final shouldRate = await _shouldShowRating();
      if (shouldRate && mounted) {
        await _showRatingDialog();
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, BeforeAfterScreen.routeName);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appProvider.error ?? context.tr('create_design_failed')),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  /// Check if rating dialog should be shown
  Future<bool> _shouldShowRating() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRated = prefs.getBool('has_rated_app') ?? false;
    if (hasRated) return false;

    final designCount = prefs.getInt('total_designs_created') ?? 0;
    final newCount = designCount + 1;
    await prefs.setInt('total_designs_created', newCount);

    // Show on 1st design, then every 3rd design
    return newCount == 1 || newCount % 3 == 0;
  }

  /// Show rating dialog
  Future<void> _showRatingDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RatingDialog(
        onRate: (stars) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_rated_app', true);
          await prefs.setInt('app_rating', stars);
          if (ctx.mounted) Navigator.pop(ctx);
          HapticService.success();
        },
        onLater: () {
          Navigator.pop(ctx);
        },
      ),
    );
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
            title: Text(
              context.tr('ai_redesign'),
              style: const TextStyle(
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
                  // Rotating magic message — fixed height to prevent layout jumps
                  SizedBox(
                    height: 50,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _messages[_messageIndex],
                        key: ValueKey(_messageIndex),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
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
                        context.tr('tokens_will_be_used'),
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

class _RatingDialog extends StatefulWidget {
  final Future<void> Function(int stars) onRate;
  final VoidCallback onLater;

  const _RatingDialog({required this.onRate, required this.onLater});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _selectedStars = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4400B6), Color(0xFF5D21DF)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.auto_awesome, size: 30, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(
              context.tr('enjoying_app'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1C1D)),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('rating_dialog_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 20),
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStars = starIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      starIndex <= _selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 40,
                      color: starIndex <= _selectedStars ? Colors.amber : const Color(0xFFD1D5DB),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Rate button
            GestureDetector(
              onTap: _selectedStars > 0 ? () => widget.onRate(_selectedStars) : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _selectedStars > 0
                      ? const LinearGradient(colors: [Color(0xFF4400B6), Color(0xFF5D21DF)])
                      : null,
                  color: _selectedStars > 0 ? null : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  context.tr('rate_see_design'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _selectedStars > 0 ? Colors.white : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Later button
            TextButton(
              onPressed: widget.onLater,
              child: Text(
                context.tr('maybe_later'),
                style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
