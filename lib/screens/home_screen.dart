import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import 'before_after_screen.dart';
import 'inspiration_screen.dart';
import 'style_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_CategoryItem> _categories = [
    _CategoryItem(name: 'Harry Potter', imageUrl: 'https://images.unsplash.com/photo-1551269901-5c5e14c25df7?w=400', icon: Icons.auto_fix_high),
    _CategoryItem(name: 'Star Wars', imageUrl: 'https://images.unsplash.com/photo-1547700055-b61cacebece9?w=400', icon: Icons.rocket_launch),
    _CategoryItem(name: 'The Matrix', imageUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400', icon: Icons.code),
    _CategoryItem(name: 'Game of Thrones', imageUrl: 'https://images.unsplash.com/photo-1533154683836-84ea7a0bc310?w=400', icon: Icons.shield),
    _CategoryItem(name: 'Anime Worlds', imageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400', icon: Icons.animation),
    _CategoryItem(name: 'Gaming Realms', imageUrl: 'https://images.unsplash.com/photo-1538481199705-c710c4e965fc?w=400', icon: Icons.sports_esports),
    _CategoryItem(name: 'Luxury Living', imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=400', icon: Icons.diamond),
    _CategoryItem(name: 'Time Travel', imageUrl: 'https://images.unsplash.com/photo-1461360370896-922624d12a74?w=400', icon: Icons.history_edu),
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
          backgroundColor: const Color(0xFFF9F9FB),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // App bar: "Architectural AI" left + avatar right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Architectural AI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1C1D),
                        letterSpacing: -0.3,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticService.lightImpact();
                        // Navigate to profile
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Hero Card / Selected Photo Card
                appProvider.selectedImage != null
                    ? GestureDetector(
                        onTap: () => _showImageSourceSheet(context),
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
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
                                        Colors.black.withValues(alpha: 0.4),
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
                                            color: Colors.white.withValues(alpha: 0.9),
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
                                            color: Colors.red.withValues(alpha: 0.8),
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
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF4400B6), Color(0xFF5D21DF), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, size: 28, color: Colors.white.withValues(alpha: 0.9)),
                                const SizedBox(height: 12),
                                const Text(
                                  'Redesign your\nspace',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'AI-powered magic for your room',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                // Recent Projects
                if (appProvider.designs.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Projects',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1C1D),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticService.lightImpact();
                          // Navigate to history
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF5D21DF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: appProvider.designs.length.clamp(0, 6),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final design = appProvider.designs[index];
                        return _RecentProjectCard(
                          design: design,
                          onTap: () {
                            HapticService.lightImpact();
                            appProvider.setCurrentDesign(design);
                            Navigator.pushNamed(context, BeforeAfterScreen.routeName);
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                // Discover Styles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discover Styles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1C1D),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticService.lightImpact();
                        Navigator.pushNamed(
                          context,
                          InspirationScreen.routeName,
                          arguments: {'category': 'all'},
                        );
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF5D21DF),
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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

class _RecentProjectCard extends StatelessWidget {
  const _RecentProjectCard({
    required this.design,
    required this.onTap,
  });

  final dynamic design;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = design.transformedImageUrl ?? design.originalImageUrl;
    final isLocalFile = imageUrl != null && imageUrl.startsWith('/');

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 180,
        height: 140,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isLocalFile)
                Image.file(
                  File(imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF3F3F5),
                    child: const Icon(Icons.image, color: Color(0xFF9CA3AF)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimeAgo(design.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
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
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Updated ${diff.inDays}d ago';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
