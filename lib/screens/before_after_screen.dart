import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/rating_dialog.dart';
import 'home_shell.dart';
import 'result_detail_screen.dart';
import 'style_selection_screen.dart';

class BeforeAfterScreen extends StatefulWidget {
  const BeforeAfterScreen({super.key});

  static const routeName = '/before-after';

  @override
  State<BeforeAfterScreen> createState() => _BeforeAfterScreenState();
}

class _BeforeAfterScreenState extends State<BeforeAfterScreen> {
  double _sliderValue = 0.5;
  bool _isSaved = false;
  double _lastHapticPosition = 0.5;

  @override
  void initState() {
    super.initState();
    // Success haptic when screen loads (design complete!)
    Future.delayed(const Duration(milliseconds: 300), () {
      HapticService.success();
    });
  }

  /// Build an image widget that handles both local file paths and network URLs.
  Widget _buildImage(String url, File? fallbackFile, Color placeholderColor) {
    // If it's a local file path
    if (url.startsWith('/') || url.startsWith('file://')) {
      final file = File(url.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    // If we have a fallback local file (e.g. selectedImage)
    if ((url.isEmpty) && fallbackFile != null && fallbackFile.existsSync()) {
      return Image.file(fallbackFile, fit: BoxFit.cover);
    }
    // Network URL
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: placeholderColor),
      );
    }
    // Placeholder
    return Container(
      color: placeholderColor,
      child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
    );
  }

  void _onSliderDrag(double delta, double width) {
    setState(() {
      _sliderValue += delta / width;
      _sliderValue = _sliderValue.clamp(0.05, 0.95);
    });

    // Light haptic feedback at 25%, 50%, 75% positions
    final position = _sliderValue;
    if ((position - 0.25).abs() < 0.02 && (_lastHapticPosition - 0.25).abs() > 0.05 ||
        (position - 0.50).abs() < 0.02 && (_lastHapticPosition - 0.50).abs() > 0.05 ||
        (position - 0.75).abs() < 0.02 && (_lastHapticPosition - 0.75).abs() > 0.05) {
      HapticService.lightImpact();
      _lastHapticPosition = position;
    }
  }

  void _toggleSave() {
    HapticService.mediumImpact();
    setState(() => _isSaved = !_isSaved);
    
    if (_isSaved) {
      // Navigate to detail
      Navigator.pushNamed(context, ResultDetailScreen.routeName);
    }
  }

  Future<void> _shareDesign() async {
    HapticService.lightImpact();
    final appProvider = context.read<AppProvider>();
    final imageUrl = appProvider.currentDesign?.transformedImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return;

    try {
      String filePath;
      if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
        filePath = imageUrl.replaceFirst('file://', '');
      } else {
        final response = await http.get(Uri.parse(imageUrl));
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/share_design_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(response.bodyBytes);
        filePath = file.path;
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Check out my AI redesigned room!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  List<Widget> _buildUpgradeOffers(AppProvider appProvider) {
    final currentTier = appProvider.tier;
    // x5 is highest — no upgrades to show
    if (currentTier == 'best') return [];

    final offers = <Widget>[];

    // Tier upgrade configs — half price of the target tier
    final upgrades = [
      if (currentTier == 'free') ...[
        {'tier': 'pro', 'label': 'Recreate with PRO+', 'cost': 1, 'originalCost': 2, 'colors': [const Color(0xFF6C63FF), const Color(0xFF3B82F6)]},
        {'tier': 'best', 'label': 'Recreate with BEST', 'cost': 2, 'originalCost': 3, 'colors': [const Color(0xFFEF4444), const Color(0xFFDC2626)]},
      ],
      if (currentTier == 'pro') ...[
        {'tier': 'best', 'label': 'Recreate with BEST', 'cost': 2, 'originalCost': 3, 'colors': [const Color(0xFFEF4444), const Color(0xFFDC2626)]},
      ],
    ];

    for (final upgrade in upgrades) {
      final tier = upgrade['tier'] as String;
      final label = upgrade['label'] as String;
      final cost = upgrade['cost'] as int;
      final originalCost = upgrade['originalCost'] as int;
      final colors = upgrade['colors'] as List<Color>;

      offers.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              HapticService.mediumImpact();
              appProvider.setTier(tier);
              Navigator.pushReplacementNamed(context, '/processing');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$cost', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.greenAccent.shade200)),
                        Text(' / $originalCost', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5), decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 4),
                        const Text('50%', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.yellowAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return offers;
  }

  void _retryWithNewStyle() {
    HapticService.mediumImpact();
    Navigator.pushNamed(context, StyleSelectionScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final currentDesign = appProvider.currentDesign;
        final styleName = currentDesign?.styleName ?? 'Redesigned';
        
        // Get actual image sources from design
        // originalImageUrl may be a local file path or a network URL
        final beforeImageUrl = currentDesign?.originalImageUrl ?? '';
        final afterImageUrl = currentDesign?.transformedImageUrl ?? '';

        // Also check if user has a selected image file (local flow)
        final selectedFile = appProvider.selectedImage;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            leading: IconButton(
              onPressed: () {
                HapticService.lightImpact();
                appProvider.clearSelection();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  HomeShell.routeName,
                  (route) => false,
                );
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
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.tagBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  styleName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Before/After image comparison — full width
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final height = constraints.maxHeight;
                      return GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          _onSliderDrag(details.delta.dx, width);
                        },
                        child: Stack(
                          children: [
                            // After image
                            Positioned.fill(
                              child: _buildImage(afterImageUrl, null, Colors.grey.shade200),
                            ),
                            // Before image (clipped)
                            Positioned(
                              left: 0, top: 0, bottom: 0,
                              width: width * _sliderValue,
                              child: ClipRect(
                                child: OverflowBox(
                                  alignment: Alignment.centerLeft,
                                  maxWidth: width,
                                  child: SizedBox(
                                    width: width,
                                    height: height,
                                    child: _buildImage(beforeImageUrl, selectedFile, Colors.brown.shade200),
                                  ),
                                ),
                              ),
                            ),
                            // BEFORE label
                            Positioned(
                              left: 12, top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('BEFORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                              ),
                            ),
                            // AFTER label
                            Positioned(
                              right: 12, top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('AFTER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                              ),
                            ),
                            // Divider line
                            Positioned(
                              left: width * _sliderValue - 1.5, top: 0, bottom: 0,
                              child: Container(width: 3, color: Colors.white),
                            ),
                            // Slider handle
                            Positioned(
                              left: width * _sliderValue - 24, top: 0, bottom: 0,
                              child: Center(
                                child: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                  ),
                                  child: const Icon(Icons.swap_horiz, color: Colors.white, size: 24),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Bottom controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    children: [
                      // Upgrade offers — show higher tiers at half price
                      ..._buildUpgradeOffers(appProvider),
                      // Retry
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _retryWithNewStyle,
                          child: const Text('Retry with New Style'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Save & Share
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _toggleSave,
                              icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_outline, size: 18, color: _isSaved ? AppColors.primary : AppColors.textPrimary),
                              label: Text(_isSaved ? 'Saved' : 'Save'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _shareDesign,
                              icon: Icon(Icons.share_outlined, size: 18, color: AppColors.textPrimary),
                              label: const Text('Share'),
                            ),
                          ),
                        ],
                      ),
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
}
