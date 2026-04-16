import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/localization/localization_extension.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../core/services/paywall_helper.dart';
import '../core/services/recommendation_service.dart';
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
  List<RecommendationItem> _recommendations = [];
  bool _loadingRecommendations = true;
  int _mainImageRetry = 0;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final appProvider = context.read<AppProvider>();
    final currentDesign = appProvider.currentDesign;
    if (currentDesign == null) {
      setState(() => _loadingRecommendations = false);
      return;
    }

    try {
      final recs = await RecommendationService().getRecommendations(
        currentStyleId: currentDesign.styleId,
        currentStyleName: currentDesign.styleName,
        userDesigns: appProvider.designs,
      );
      if (mounted) {
        setState(() {
          _recommendations = recs;
          _loadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRecommendations = false);
    }
  }

  Widget _errorPlaceholder(String reason) {
    return GestureDetector(
      onTap: () {
        HapticService.lightImpact();
        setState(() => _mainImageRetry++);
      },
      child: Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image, size: 40, color: Colors.grey),
            const SizedBox(height: 6),
            Text(
              context.tr('error_label'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              reason,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('tap_to_retry'),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartImage(String? url) {
    if (url == null || url.isEmpty) {
      return _errorPlaceholder('no image');
    }
    if (url.startsWith('/') || url.startsWith('file://')) {
      final file = File(url.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, e, __) {
            debugPrint('[result_detail] local image error: $e for $url');
            return _errorPlaceholder('local error');
          },
        );
      }
      return _errorPlaceholder('file missing');
    }
    if (url.startsWith('http')) {
      final bustedUrl = _mainImageRetry > 0
          ? '$url${url.contains('?') ? '&' : '?'}_r=$_mainImageRetry'
          : url;
      return Image.network(
        bustedUrl,
        key: ValueKey('$url#$_mainImageRetry'),
        fit: BoxFit.cover,
        errorBuilder: (_, e, __) {
          debugPrint('[result_detail] network image error for $url: $e');
          return _errorPlaceholder('network error');
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }
    return _errorPlaceholder('unsupported');
  }

  Future<void> _exportHighRes(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('no_image_export'))),
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
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(context.tr('saved_to_photos')),
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
            content: Text('${context.tr('save_failed')}: ${e.toString()}'),
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
            title: Text(
              context.tr('result_detail'),
              style: const TextStyle(
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
                      Expanded(
                        child: Text(
                          context.tr('redesign_another'),
                          style: const TextStyle(
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
                        child: Text(
                          context.tr('new_room'),
                          style: const TextStyle(
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        context.tr('ai_enhanced'),
                                        style: const TextStyle(
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
                              label: context.tr('new_photo'),
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
                              label: context.tr('new_style'),
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
                              label: context.tr('share'),
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
                                    text: context.tr('share_design_short'),
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
                          label: Text(_isExporting ? context.tr('saving') : context.tr('export_hires')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Recreate button
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () async {
                            HapticService.mediumImpact();
                            final canProceed = await ensureTokensOrPaywall(context);
                            if (!canProceed || !context.mounted) return;
                            Navigator.pushNamed(context, '/styles');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF4400B6), Color(0xFF5D21DF)]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5D21DF).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(context.tr('create_better_version'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                const SizedBox(width: 10),
                                Text(context.tr('fifty_percent_off'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.yellowAccent)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Recommended Styles
                      if (!_loadingRecommendations && _recommendations.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('recommended_styles'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('recommended_desc'),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.95, // 20% shorter than store's 0.75
                          ),
                          itemCount: _recommendations.length,
                          itemBuilder: (context, index) {
                            final item = _recommendations[index];
                            return GestureDetector(
                              onTap: () async {
                                HapticService.lightImpact();
                                final appProvider = context.read<AppProvider>();
                                if (item.isWorld) {
                                  // World: push the prompt + name into provider
                                  // so the Style Selection preview and create
                                  // flow pick this recommendation, not the old one.
                                  appProvider.setSelectedStyle(null);
                                  appProvider.setSelectedWorldPrompt(
                                    item.prompt,
                                    worldName: item.name,
                                  );
                                } else {
                                  // Style: match against provider.styles by id.
                                  final match = appProvider.styles
                                      .cast<dynamic>()
                                      .firstWhere(
                                        (s) => s.id == item.id,
                                        orElse: () => null,
                                      );
                                  if (match != null) {
                                    appProvider.setSelectedStyle(match);
                                    appProvider.clearWorldPrompt();
                                  }
                                }
                                if (!context.mounted) return;
                                Navigator.pushNamed(
                                  context,
                                  StyleSelectionScreen.routeName,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: item.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: AppColors.cardBackground),
                                        errorWidget: (_, __, ___) => Container(
                                          color: AppColors.cardBackground,
                                          child: const Icon(Icons.image, color: Colors.grey),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.7),
                                            ],
                                            stops: const [0.4, 1.0],
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
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (item.description.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                item.description,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white.withValues(alpha: 0.8),
                                                ),
                                                maxLines: 1,
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
                          },
                        ),
                        const SizedBox(height: 20),
                      ] else if (_loadingRecommendations) ...[
                        const SizedBox(height: 32),
                        const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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
