import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import 'home_shell.dart';
import 'result_detail_screen.dart';

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

        return PopScope(
          canPop: false,
          child: Scaffold(
          backgroundColor: const Color(0xFFF9F9FB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9F9FB),
            elevation: 0,
            automaticallyImplyLeading: false,
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
              icon: const Icon(Icons.close, size: 22, color: Color(0xFF1A1C1D)),
            ),
            title: const Text(
              'Architectural AI',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1C1D),
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5D21DF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'AI POWERED',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF5D21DF)),
                                ),
                                child: Text(
                                  styleName.toUpperCase(),
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF5D21DF), letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            styleName,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1D)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Subtitle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Your space transformed with $styleName aesthetic — a beautiful blend of style and functionality.',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Before/After comparison (full width, keep existing slider logic)
                        SizedBox(
                          height: 300,
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
                                          color: const Color(0xFF5D21DF).withValues(alpha: 0.8),
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
                                      left: width * _sliderValue - 20, top: 0, bottom: 0,
                                      child: Center(
                                        child: Container(
                                          width: 40, height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF5D21DF),
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                                          ),
                                          child: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Save & Share row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _toggleSave,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                                          size: 18,
                                          color: _isSaved ? const Color(0xFF5D21DF) : const Color(0xFF1A1C1D),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isSaved ? 'Saved' : 'Save',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1C1D)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _shareDesign,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.share_outlined, size: 18, color: Color(0xFF1A1C1D)),
                                        SizedBox(width: 6),
                                        Text('Share', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1C1D))),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                // Bottom action buttons (fixed at bottom)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    children: [
                      // Create Better Version with 50% OFF
                      GestureDetector(
                        onTap: () {
                          HapticService.mediumImpact();
                          Navigator.pushNamed(context, '/styles');
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF4400B6), Color(0xFF5D21DF)]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5D21DF).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              const Text('Create Better Version', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.yellowAccent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('50% OFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF4400B6))),
                              ),
                            ],
                          ),
                        ),
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
}
