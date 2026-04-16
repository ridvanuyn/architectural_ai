import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../core/localization/localization_extension.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import 'before_after_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const routeName = '/history';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _headerVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final dir = _scrollController.position.userScrollDirection;
    if (dir == ScrollDirection.reverse && _headerVisible) {
      setState(() => _headerVisible = false);
    } else if (dir == ScrollDirection.forward && !_headerVisible) {
      setState(() => _headerVisible = true);
    }
  }

  /// Returns all designs held by the provider. Server-side scoping already
  /// limits results to the authenticated user (see backend `/api/designs`
  /// which filters by `req.user.id`), so we don't need to re-filter here.
  /// Local/simulated designs fall through unchanged.
  List filterDesignsForCurrentUser(AppProvider appProvider) {
    return appProvider.designs;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final designs = filterDesignsForCurrentUser(appProvider);
        final isLoggedIn = appProvider.user != null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _headerVisible
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      context.tr('history'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  secondChild: const SizedBox(height: 0, width: double.infinity),
                ),
                Expanded(
                  child: designs.isEmpty
                      ? _EmptyState(isLoggedIn: isLoggedIn)
                      : _buildMasonryGrid(context, appProvider, designs),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMasonryGrid(BuildContext context, AppProvider appProvider, List designs) {
    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];

    for (int i = 0; i < designs.length; i++) {
      final design = designs[i];
      final height = i % 3 == 0 ? 200.0 : i % 3 == 1 ? 160.0 : 180.0;
      final card = _HistoryMasonryCard(
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

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: leftColumn)),
          const SizedBox(width: 12),
          Expanded(child: Column(children: rightColumn)),
        ],
      ),
    );
  }

}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.isLoggedIn = false});
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('no_designs'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLoggedIn
                  ? context.tr('start_creating')
                  : context.tr('start_first_design'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryMasonryCard extends StatelessWidget {
  const _HistoryMasonryCard({
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
