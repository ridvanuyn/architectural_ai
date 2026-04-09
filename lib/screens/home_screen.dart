import 'dart:io';
import 'dart:math' show sin;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/localization/localization_extension.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import 'before_after_screen.dart';
import 'inspiration_screen.dart';
import 'style_selection_screen.dart';
import 'store_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_CategoryItem> _categories = [
    _CategoryItem(name: 'Harry Potter', imageUrl: 'https://images.unsplash.com/photo-1551269901-5c5e14c25df7?w=400', icon: Icons.auto_fix_high),
    _CategoryItem(name: 'Star Wars', imageUrl: 'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?w=400', icon: Icons.rocket_launch),
    _CategoryItem(name: 'The Matrix', imageUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400', icon: Icons.code),
    _CategoryItem(name: 'Game of Thrones', imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400', icon: Icons.shield),
    _CategoryItem(name: 'Stranger Things', imageUrl: 'https://images.unsplash.com/photo-1509248961895-b23aad4f24b4?w=400', icon: Icons.lightbulb),
    _CategoryItem(name: 'Cyberpunk', imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400', icon: Icons.memory),
    _CategoryItem(name: 'Fantasy Worlds', imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400', icon: Icons.castle),
    _CategoryItem(name: 'Historical', imageUrl: 'https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=400', icon: Icons.account_balance),
  ];

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    HapticService.lightImpact();
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null && context.mounted) {
      final appProvider = context.read<AppProvider>();
      appProvider.setSelectedImage(File(pickedFile.path));
      
      HapticService.mediumImpact();
      
      Navigator.pushNamed(context, StyleSelectionScreen.routeName);
    }
  }

  void _showImageSourceSheet(BuildContext context) {
    HapticService.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            // Camera
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(context, ImageSource.camera);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F3F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 22, color: Colors.grey.shade700),
                    const SizedBox(width: 16),
                    Text('Camera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Gallery
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(context, ImageSource.gallery);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F3F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 22, color: Colors.grey.shade700),
                    const SizedBox(width: 16),
                    Text('Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPickerOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildMasonryGrid(BuildContext context, AppProvider appProvider) {
    final recentDesigns = appProvider.designs.take(6).toList();
    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];

    for (int i = 0; i < recentDesigns.length; i++) {
      final design = recentDesigns[i];
      final height = i % 3 == 0 ? 200.0 : i % 3 == 1 ? 160.0 : 180.0;
      final card = _DesignMasonryCard(
        design: design,
        height: height,
        onTap: () {
          HapticService.lightImpact();
          appProvider.setCurrentDesign(design);
          Navigator.pushNamed(context, BeforeAfterScreen.routeName);
        },
      );
      if (i % 2 == 0) {
        leftColumn.add(card);
      } else {
        rightColumn.add(card);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: leftColumn)),
        const SizedBox(width: 12),
        Expanded(child: Column(children: rightColumn)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header with token badge and tier toggle
                Row(
                  children: [
                    // Token badge
                    GestureDetector(
                      onTap: () {
                        HapticService.lightImpact();
                        Navigator.pushNamed(context, StoreScreen.routeName);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.tagBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.token, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${appProvider.tokenBalance} Tokens',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                context.tr('buy'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Tier toggle: FREE → PRO+ → BEST
                    GestureDetector(
                      onTap: () {
                        appProvider.togglePremium();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: appProvider.tier == 'best'
                              ? const Color(0xFFEF4444)
                              : appProvider.tier == 'pro'
                                  ? const Color(0xFF6C63FF)
                                  : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              appProvider.tier == 'best'
                                  ? Icons.diamond
                                  : appProvider.tier == 'pro'
                                      ? Icons.star
                                      : Icons.star_border,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${appProvider.tierLabel} · ${appProvider.tierMultiplier}T',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Upload / Selected Photo Card
                appProvider.selectedImage != null
                    ? GestureDetector(
                        onTap: () => _showImageSourceSheet(context),
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(appProvider.selectedImage!, fit: BoxFit.cover),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.4),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.swap_horiz, size: 16),
                                              SizedBox(width: 6),
                                              Text('Change', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          HapticService.lightImpact();
                                          appProvider.clearSelectedImage();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => _showImageSourceSheet(context),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F3F8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 6.28),
                                duration: const Duration(seconds: 3),
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 3 * sin(value)),
                                    child: child,
                                  );
                                },
                                child: Icon(Icons.add_photo_alternate_outlined, size: 36, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                const SizedBox(height: 28),
                // Recent designs
                if (appProvider.designs.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('recent_designs'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticService.lightImpact();
                          // Navigate to history
                        },
                        child: Text(
                          context.tr('see_all'),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMasonryGrid(context, appProvider),
                  const SizedBox(height: 28),
                ],
                // Inspiration Gallery
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('inspiration_gallery'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticService.lightImpact();
                        Navigator.pushNamed(
                          context,
                          InspirationScreen.routeName,
                          arguments: {'category': 'Fantasy Worlds'},
                        );
                      },
                      child: Text(
                        context.tr('see_all'),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Category grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return GestureDetector(
                      onTap: () {
                        HapticService.lightImpact();
                        Navigator.pushNamed(
                          context,
                          InspirationScreen.routeName,
                          arguments: {'category': category.name},
                        );
                      },
                      child: _CategoryCard(category: category),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _CategoryItem {
  const _CategoryItem({
    required this.name,
    required this.imageUrl,
    this.icon = Icons.palette,
  });

  final String name;
  final String imageUrl;
  final IconData icon;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final _CategoryItem category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SkeletonImage(
              imageUrl: category.imageUrl,
              fit: BoxFit.cover,
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
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(category.icon, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to explore',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
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

class _DesignMasonryCard extends StatelessWidget {
  const _DesignMasonryCard({
    required this.design,
    required this.height,
    required this.onTap,
  });

  final dynamic design;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = design.transformedImageUrl ?? design.originalImageUrl;
    final isLocalFile = imageUrl != null && imageUrl.startsWith('/');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isLocalFile)
                  Image.file(
                    File(imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                else
                  SkeletonImage(
                    imageUrl: imageUrl ?? '',
                    fit: BoxFit.cover,
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          design.styleName ?? 'Design',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(design.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.8),
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
