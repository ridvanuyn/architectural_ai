import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/localization/localization_extension.dart';
import '../core/models/style.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../core/services/paywall_helper.dart';
import '../core/services/world_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import 'before_after_screen.dart';
import 'history_screen.dart';
import 'home_shell.dart';
import 'inspiration_screen.dart';
import 'processing_screen.dart';
import 'style_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_CategoryItem> _categories = [
    _CategoryItem(name: 'Harry Potter', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/dark-academia.jpg', icon: Icons.auto_fix_high),
    _CategoryItem(name: 'Lord of the Rings', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/lotr-rivendell.jpg', icon: Icons.landscape),
    _CategoryItem(name: 'Star Wars', imageUrl: 'https://images.unsplash.com/photo-1547700055-b61cacebece9?w=400', icon: Icons.rocket_launch),
    _CategoryItem(name: 'The Matrix', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/cyberpunk-loft.jpg', icon: Icons.code),
    _CategoryItem(name: 'Game of Thrones', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/gothic-romantic.jpg', icon: Icons.shield),
    _CategoryItem(name: 'Anime Worlds', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/cottagecore-cozy.jpg', icon: Icons.animation),
    _CategoryItem(name: 'Gaming Realms', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/cyberpunk-loft.jpg', icon: Icons.sports_esports),
    _CategoryItem(name: 'Sitcoms', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/friends-apartment.jpg', icon: Icons.tv),
    _CategoryItem(name: 'Back to the Future', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/bttf-delorean-workshop.jpg', icon: Icons.access_time),
    _CategoryItem(name: 'Luxury Living', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/baroque-opulent.jpg', icon: Icons.diamond),
    _CategoryItem(name: 'Time Travel', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/art-deco-glamour.jpg', icon: Icons.history_edu),
  ];

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    HapticService.lightImpact();

    if (!context.mounted) return;
    final canProceed = await ensureTokensOrPaywall(context);
    if (!canProceed || !context.mounted) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null && context.mounted) {
      final appProvider = context.read<AppProvider>();
      await appProvider.setSelectedImage(File(pickedFile.path));
      if (!context.mounted) return;

      HapticService.mediumImpact();

      Navigator.pushNamed(context, StyleSelectionScreen.routeName);
    }
  }

  static const List<_QuickToolItem> _quickTools = [
    _QuickToolItem(id: 'tool-clean-room', name: 'Clean Room', icon: Icons.cleaning_services_outlined),
    _QuickToolItem(id: 'tool-delete-clutter', name: 'Remove 3 Items', icon: Icons.delete_sweep_outlined),
    _QuickToolItem(id: 'tool-light-room', name: 'Light Room', icon: Icons.light_mode_outlined),
    _QuickToolItem(id: 'tool-sunset-room', name: 'Sunset Glow', icon: Icons.wb_twilight_outlined),
    _QuickToolItem(id: 'tool-add-plants', name: 'Add Plants', icon: Icons.local_florist_outlined),
    _QuickToolItem(id: 'tool-cozy-mode', name: 'Cozy Mode', icon: Icons.fireplace_outlined),
    _QuickToolItem(id: 'tool-night-mode', name: 'Night Mode', icon: Icons.nightlight_outlined),
    _QuickToolItem(id: 'tool-expand-room', name: 'Expand Room', icon: Icons.open_in_full),
  ];

  void _quickToolTap(BuildContext context, String worldId) {
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
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _pickAndProcess(context, ImageSource.camera, worldId);
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
                    Text(context.tr('camera'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _pickAndProcess(context, ImageSource.gallery, worldId);
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
                    Text(context.tr('gallery'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
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

  Future<void> _pickAndProcess(BuildContext context, ImageSource source, String worldId) async {
    final canProceed = await ensureTokensOrPaywall(context);
    if (!canProceed || !context.mounted) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
    if (file == null || !context.mounted) return;

    final appProvider = context.read<AppProvider>();
    await appProvider.setSelectedImage(File(file.path));
    if (!context.mounted) return;

    try {
      final world = await WorldService().getWorld(worldId);
      appProvider.setSelectedStyle(null);
      appProvider.setSelectedWorldPrompt(world.prompt, worldName: world.name);
      appProvider.setTier('pro');
    } catch (_) {
      if (context.mounted) Navigator.pushNamed(context, StyleSelectionScreen.routeName);
      return;
    }

    if (!context.mounted) return;
    HapticService.success();
    Navigator.pushNamed(context, ProcessingScreen.routeName);
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
                    Text(context.tr('camera'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
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
                    Text(context.tr('gallery'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
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
                // App bar: "Architectural AI" left + token pill + avatar right
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TokenBadge(balance: appProvider.displayedTokenBalance),
                        const SizedBox(width: 10),
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
                  ],
                ),
                const SizedBox(height: 20),
                // Hero Card — always visible, taps open image picker
                GestureDetector(
                  onTap: () => _showImageSourceSheet(context),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: const DecorationImage(
                        image: NetworkImage('https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/scandinavian-hygge.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Redesign your\nspace instantly',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4400B6), Color(0xFF5D21DF)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Start Creating',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Quick Tools Row
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickTools.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final tool = _quickTools[index];
                      return GestureDetector(
                        onTap: () => _quickToolTap(context, tool.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F3F8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE8E6F0), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tool.icon, size: 16, color: const Color(0xFF5D21DF)),
                              const SizedBox(width: 6),
                              Text(
                                tool.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1C1D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Recent Projects
                if (appProvider.designs.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('home_recent_projects'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1C1D),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticService.lightImpact();
                          final shell = HomeShell.of(context);
                          if (shell != null) {
                            shell.setTab(1);
                          } else {
                            Navigator.pushNamed(
                              context,
                              HistoryScreen.routeName,
                            );
                          }
                        },
                        child: Text(
                          context.tr('view_all'),
                          style: const TextStyle(
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
                // Cinematic Bundles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cinematic Bundles',
                      style: const TextStyle(
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
                      child: Text(
                        context.tr('view_all'),
                        style: const TextStyle(
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
                // Latest Designs
                const SizedBox(height: 28),
                _SectionHeader(title: context.tr('latest_designs')),
                const SizedBox(height: 12),
                _LatestDesignsRow(appProvider: appProvider),
                // Most Used Styles
                const SizedBox(height: 28),
                _SectionHeader(title: context.tr('most_used_styles')),
                const SizedBox(height: 12),
                _MostUsedStylesRow(appProvider: appProvider),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1C1D),
      ),
    );
  }
}

class _LatestDesignsRow extends StatelessWidget {
  const _LatestDesignsRow({required this.appProvider});
  final AppProvider appProvider;

  @override
  Widget build(BuildContext context) {
    final designs = appProvider.designs.take(10).toList();
    if (designs.isEmpty) {
      return SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => SkeletonLoader(
            width: 160,
            height: 120,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: designs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final design = designs[index];
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
    );
  }
}

class _MostUsedStylesRow extends StatelessWidget {
  const _MostUsedStylesRow({required this.appProvider});
  final AppProvider appProvider;

  @override
  Widget build(BuildContext context) {
    // Source of truth is `appProvider.styles` — the backend already returns
    // these sorted by global usageCount (Redis-cached), so we don't need to
    // re-count the user's own design history.
    final ranked = appProvider.styles
        .where((s) => s.imageUrl.isNotEmpty)
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    final top = ranked.take(6).toList();

    if (top.isEmpty) {
      return SizedBox(
        height: 130,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => SkeletonLoader(
            width: 110,
            height: 130,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: top.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final style = top[index];
          return _MostUsedStyleCard(
            item: _MostUsedItem(style: style, count: style.usageCount),
            onTap: () {
              HapticService.lightImpact();
              appProvider.setSelectedStyle(style);
              appProvider.clearWorldPrompt();
              Navigator.pushNamed(context, StyleSelectionScreen.routeName);
            },
          );
        },
      ),
    );
  }
}

class _MostUsedItem {
  _MostUsedItem({required this.style, required this.count});
  final DesignStyle style;
  final int count;
}

class _MostUsedStyleCard extends StatelessWidget {
  const _MostUsedStyleCard({required this.item, required this.onTap});
  final _MostUsedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.style.imageUrl.isNotEmpty)
                SkeletonImage(imageUrl: item.style.imageUrl, fit: BoxFit.cover)
              else
                Container(color: const Color(0xFFE5E7EB)),
              Container(
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
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '×${item.count}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  item.style.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _TokenBadge extends StatelessWidget {
  const _TokenBadge({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF5D21DF);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticService.lightImpact();
          ensureTokensOrPaywall(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, size: 18, color: accent),
              const SizedBox(width: 4),
              Text(
                '$balance',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
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
                          context.tr('home_tap_explore'),
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
                        design.styleName ?? context.tr('design_fallback_name'),
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
                          design.styleName ?? context.tr('design_fallback_name'),
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


class _QuickToolItem {
  const _QuickToolItem({
    required this.id,
    required this.name,
    required this.icon,
  });
  final String id;
  final String name;
  final IconData icon;
}
