import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/localization/localization_extension.dart';
import '../core/models/specialty_world.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../core/services/paywall_helper.dart';
import '../core/services/world_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import 'processing_screen.dart';
import 'style_selection_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  static const routeName = '/store';

  /// Public accessor for default worlds list (used by other screens)
  static List<SpecialtyWorld> getDefaultWorlds() => _StoreScreenState._defaultWorlds();

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final WorldService _worldService = WorldService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<SpecialtyWorld> _worlds = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _autoRetryScheduled = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String _searchQuery = '';
  bool _headerVisible = true;
  // Debounce timer for search
  DateTime? _lastSearchTime;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadWorlds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }

    final dir = _scrollController.position.userScrollDirection;
    if (dir == ScrollDirection.reverse && _headerVisible) {
      setState(() => _headerVisible = false);
    } else if (dir == ScrollDirection.forward && !_headerVisible) {
      setState(() => _headerVisible = true);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    _lastSearchTime = DateTime.now();
    final capturedTime = _lastSearchTime;
    // Debounce: 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_lastSearchTime == capturedTime && mounted) {
        if (query != _searchQuery) {
          _searchQuery = query;
          _currentPage = 1;
          _loadWorlds();
        }
      }
    });
  }

  Future<void> _loadWorlds() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final result = await _worldService.searchWorlds(
        query: _searchQuery,
        page: 1,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _worlds = result['worlds'] as List<SpecialtyWorld>;
          _currentPage = result['page'] as int;
          _totalPages = result['totalPages'] as int;
          _isLoading = false;
          _hasError = false;
          _autoRetryScheduled = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load worlds: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = _worlds.isEmpty;
        });
        if (_hasError && !_autoRetryScheduled) {
          _autoRetryScheduled = true;
          Timer(const Duration(seconds: 2), () {
            if (mounted && _hasError) _loadWorlds();
          });
        }
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await _worldService.searchWorlds(
        query: _searchQuery,
        page: _currentPage + 1,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _worlds.addAll(result['worlds'] as List<SpecialtyWorld>);
          _currentPage = result['page'] as int;
          _totalPages = result['totalPages'] as int;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  static List<SpecialtyWorld> _defaultWorlds() {
    // Small offline fallback — the real 200+ worlds come from the API
    return [
      SpecialtyWorld(
        id: 'hobbit-hole',
        name: 'Hobbit Hole',
        description: 'Middle Earth Style',
        category: 'fantasy',
        imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/hobbit-hole.jpg',
        prompt: 'Transform into a cozy Hobbit hole',
      ),
      SpecialtyWorld(
        id: 'gryffindor-room',
        name: 'Gryffindor Room',
        description: 'Bravery & Gold',
        category: 'fantasy',
        imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/gryffindor-room.jpg',
        prompt: 'Transform into Gryffindor common room',
      ),
      SpecialtyWorld(
        id: 'cyberpunk-2077',
        name: 'Cyberpunk 2077',
        description: 'Neon Night City',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400',
        prompt: 'Transform into Cyberpunk apartment',
      ),
      SpecialtyWorld(
        id: 'victorian-1800s',
        name: '1800s Victorian',
        description: 'Gothic Elegance',
        category: 'historical',
        imageUrl: 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=400',
        prompt: 'Transform into Victorian parlor',
      ),
      SpecialtyWorld(
        id: 'japanese-zen',
        name: 'Japanese Zen',
        description: 'Temple Peace',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1545083036-b175dd155a1d?w=400',
        prompt: 'Transform into Zen temple',
      ),
      SpecialtyWorld(
        id: 'mars-colony',
        name: 'Mars Colony',
        description: 'Red Planet Base',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?w=400',
        prompt: 'Transform into Mars habitat',
      ),
    ];
  }

  final ImagePicker _picker = ImagePicker();
  SpecialtyWorld? _selectedWorld;

  Future<void> _onWorldSelected(SpecialtyWorld world) async {
    HapticService.mediumImpact();
    final appProvider = context.read<AppProvider>();

    final canProceed = await ensureTokensOrPaywall(context);
    if (!canProceed || !mounted) return;

    appProvider.setSelectedWorldPrompt(world.prompt, worldName: world.name);
    _showImageSourceDialog(world);
  }

  void _showImageSourceDialog(SpecialtyWorld world) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // World preview
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: world.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => SkeletonLoader(width: 60, height: 60, borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        world.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        world.description.isNotEmpty ? world.description : world.category,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('select_room_photo_title'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('transform_subtitle'),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.camera_alt,
                    label: context.tr('camera'),
                    onTap: () async {
                      final appProvider = context.read<AppProvider>();
                      Navigator.pop(ctx);
                      await _pickImageAndCreate(ImageSource.camera, world, appProvider);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.photo_library,
                    label: context.tr('gallery'),
                    onTap: () async {
                      final appProvider = context.read<AppProvider>();
                      Navigator.pop(ctx);
                      await _pickImageAndCreate(ImageSource.gallery, world, appProvider);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageAndCreate(ImageSource source, SpecialtyWorld world, AppProvider appProvider) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        // Re-check tokens after the async picker (paywall may be needed).
        final canProceed = await ensureTokensOrPaywall(context);
        if (!canProceed || !mounted) return;

        await appProvider.setSelectedImage(File(pickedFile.path));
        if (!mounted) return;
        appProvider.setSelectedWorldPrompt(world.prompt, worldName: world.name);

        HapticService.success();
        if (mounted) {
          Navigator.pushNamed(context, StyleSelectionScreen.routeName);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('pick_image_failed')}: $e')),
        );
      }
    }
  }

  void _showPurchaseDialog(SpecialtyWorld world) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: world.imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (_, __) => SkeletonLoader(width: 120, height: 120, borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              world.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              world.description.isNotEmpty ? world.description : world.category,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      HapticService.success();
                      // After unlock, show image picker
                      _showImageSourceDialog(world);
                    },
                    child: Text(
                      context.tr('unlock_for').replaceFirst(
                        '%s',
                        '\$${world.price.toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to Pro subscription
              },
              child: Text(
                context.tr('get_pro_cta'),
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_headerVisible ? kToolbarHeight : 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _headerVisible ? kToolbarHeight : 0,
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              context.tr('store'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.tr('search_worlds_hint'),
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20, color: Color(0xFF9CA3AF)),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _currentPage = 1;
                            _loadWorlds();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                  ),
                ),
              ),
            ),
          ),

          // Pro Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Color(0xFF1A1A1A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('free_for_pro'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            context.tr('unlock_all_worlds'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // TODO: Navigate to Pro subscription
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Text(
                              context.tr('upgrade_to_pro'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('specialty_worlds'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('specialty_worlds_desc'),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading / Error / Empty / Grid
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasError && _worlds.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 56, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('failed_to_load'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('tap_retry'),
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticService.lightImpact();
                          _autoRetryScheduled = false;
                          _loadWorlds();
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(context.tr('retry')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_worlds.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('no_worlds_search'),
                      style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final world = _worlds[index];
                    return _WorldCard(
                      world: world,
                      onTap: () => _onWorldSelected(world),
                    );
                  },
                  childCount: _worlds.length,
                ),
              ),
            ),

          // Loading more indicator
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.world,
    required this.onTap,
  });

  final SpecialtyWorld world;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              CachedNetworkImage(
                imageUrl: world.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => SkeletonLoader(
                  borderRadius: BorderRadius.circular(16),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.cardBackground,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
              // Gradient Overlay
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
              // NEW badge
              if (world.isNew)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(context.tr('new_badge'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                  ),
                ),
              // Token cost badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.token, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      const Text(
                        '1',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Text Content
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      world.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      world.description.isNotEmpty ? world.description : world.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoostPackCard extends StatelessWidget {
  const _BoostPackCard({
    required this.tokens,
    required this.price,
    required this.perToken,
    required this.label,
    required this.icon,
    required this.isBestValue,
    required this.savings,
    required this.onTap,
  });

  final int tokens;
  final String price;
  final String perToken;
  final String label;
  final IconData icon;
  final bool isBestValue;
  final String? savings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isBestValue
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: isBestValue
              ? Border.all(color: Colors.yellowAccent, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isBestValue
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isBestValue ? const Color(0xFF6C63FF) : Colors.yellowAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '$tokens Tokens',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isBestValue ? const Color(0xFF1A1A2E) : Colors.white,
                        ),
                      ),
                      if (savings != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isBestValue
                                ? const Color(0xFF10B981)
                                : const Color(0xFF10B981).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SAVE $savings',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$label  ·  $perToken/token',
                    style: TextStyle(
                      fontSize: 11,
                      color: isBestValue
                          ? const Color(0xFF6B7280)
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Price button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isBestValue
                    ? const Color(0xFF6C63FF)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isBestValue
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                price,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isBestValue ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
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
      onTap: () {
        HapticService.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.tagBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
