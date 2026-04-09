import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';
import 'style_selection_screen.dart';

class ResultDetailScreen extends StatefulWidget {
  const ResultDetailScreen({super.key});

  static const routeName = '/result';

  @override
  State<ResultDetailScreen> createState() => _ResultDetailScreenState();
}

class _ResultDetailScreenState extends State<ResultDetailScreen> {
  bool _isFavorite = false;
  bool _isExporting = false;

  Widget _buildSmartImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
      );
    }
    if (url.startsWith('/') || url.startsWith('file://')) {
      final file = File(url.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
        ),
      );
    }
    return Container(color: Colors.grey.shade200);
  }

  Future<void> _exportHighRes(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image available to export')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      String filePath;

      if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
        // Already a local file
        filePath = imageUrl.replaceFirst('file://', '');
      } else {
        // Download from network
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to download image');
        }
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/design_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await file.writeAsBytes(response.bodyBytes);
        filePath = file.path;
      }

      await Gal.putImage(filePath);
      await HapticService.success();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Saved to Photos'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      await HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final currentDesign = appProvider.currentDesign;
        final designs = appProvider.designs;
        final styleName = currentDesign?.styleName ?? 'Japandi';

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
              'Result Detail',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  HapticService.mediumImpact();
                  if (currentDesign != null) {
                    appProvider.toggleFavorite(currentDesign.id);
                  }
                  setState(() => _isFavorite = !_isFavorite);
                },
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : null,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Top action bar - Redesign other rooms
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.tagBackground,
                    border: Border(
                      bottom: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Want to redesign another room?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticService.mediumImpact();
                          appProvider.clearSelection();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            HomeShell.routeName,
                            (route) => false,
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'New Room',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Main image
                      Container(
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildSmartImage(currentDesign?.transformedImageUrl),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'AI Enhanced',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(height: 20),
                      // Quick actions
                      Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.camera_alt,
                              label: 'New Photo',
                              onTap: () {
                                HapticService.lightImpact();
                                appProvider.clearSelection();
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  HomeShell.routeName,
                                  (route) => false,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.style,
                              label: 'New Style',
                              onTap: () {
                                HapticService.lightImpact();
                                Navigator.pushNamed(
                                  context,
                                  StyleSelectionScreen.routeName,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.share,
                              label: 'Share',
                              onTap: () async {
                                HapticService.lightImpact();
                                final url = currentDesign?.transformedImageUrl;
                                if (url == null || url.isEmpty) return;
                                try {
                                  String filePath;
                                  if (url.startsWith('/') || url.startsWith('file://')) {
                                    filePath = url.replaceFirst('file://', '');
                                  } else {
                                    final resp = await http.get(Uri.parse(url));
                                    final dir = await getTemporaryDirectory();
                                    final f = File('${dir.path}/share_${DateTime.now().millisecondsSinceEpoch}.jpg');
                                    await f.writeAsBytes(resp.bodyBytes);
                                    filePath = f.path;
                                  }
                                  await Share.shareXFiles(
                                    [XFile(filePath)],
                                    text: 'My AI redesigned room!',
                                  );
                                } catch (_) {}
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Export button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isExporting
                              ? null
                              : () {
                                  HapticService.mediumImpact();
                                  _exportHighRes(currentDesign?.transformedImageUrl);
                                },
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download, size: 18),
                          label: Text(_isExporting ? 'Saving...' : 'Export High-Res'),
                        ),
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

class _ThumbnailCard extends StatelessWidget {
  const _ThumbnailCard({
    required this.imageUrl,
    required this.label,
    required this.isSelected,
  });

  final String imageUrl;
  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.cardBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  const _FeatureTag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
