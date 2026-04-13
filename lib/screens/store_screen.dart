import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/localization/localization_extension.dart';
import '../core/models/specialty_world.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
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
  late List<SpecialtyWorld> _worlds;

  @override
  void initState() {
    super.initState();
    debugPrint('StoreScreen initState called');
    // Initialize with default worlds immediately
    _worlds = _defaultWorlds();
    debugPrint('Default worlds loaded: ${_worlds.length}');
    // Then try to fetch from API
    _loadWorldsFromApi();
  }

  Future<void> _loadWorldsFromApi() async {
    try {
      final worlds = await _worldService.getWorlds();
      if (mounted && worlds.isNotEmpty) {
        // FULLY replace defaults with API data (includes S3 image URLs)
        setState(() {
          _worlds = worlds;
        });
      }
    } catch (e) {
      debugPrint('Failed to load worlds from API: $e - using defaults');
      // Keep the default worlds on error
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

  void _onWorldSelected(SpecialtyWorld world) {
    HapticService.mediumImpact();
    final appProvider = context.read<AppProvider>();

    if (!appProvider.hasEnoughTokens) {
      HapticService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough tokens. Buy more to continue.')),
      );
      return;
    }

    // Set the world prompt and go to step wizard to pick photo + options
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
            const Text(
              'Select Your Room Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your room will be transformed into this style',
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
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _pickImageAndCreate(ImageSource.camera, world);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _pickImageAndCreate(ImageSource.gallery, world);
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

  Future<void> _pickImageAndCreate(ImageSource source, SpecialtyWorld world) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final appProvider = context.read<AppProvider>();

        // Set the image and world prompt
        appProvider.setSelectedImage(File(pickedFile.path));
        appProvider.setSelectedWorldPrompt(world.prompt, worldName: world.name);

        HapticService.success();

        // Check tokens
        if (!appProvider.hasEnoughTokens) {
          HapticService.error();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not enough tokens. Buy more to continue.')),
            );
          }
          return;
        }

        // Navigate to step wizard for extra options (tier, custom, etc.)
        if (mounted) {
          Navigator.pushNamed(context, StyleSelectionScreen.routeName);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
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
                    child: const Text('Cancel'),
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
                    child: Text('Unlock for \$${world.price.toStringAsFixed(2)}'),
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
                'Get PRO for unlimited access',
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
    debugPrint('StoreScreen build called, worlds count: ${_worlds.length}');
    final appProvider = context.watch<AppProvider>();
    final isPro = appProvider.isPremium;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Store',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =================== NEED A BOOST ===================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6C63FF), // Vivid purple
                  Color(0xFF3B82F6), // Electric blue
                  Color(0xFF06B6D4), // Cyan accent
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt, color: Colors.yellowAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need a Boost?',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Get tokens to transform any room instantly',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Token pack cards
                _BoostPackCard(
                  tokens: 10,
                  price: '\$9.99',
                  perToken: '\$1.00',
                  label: 'Starter',
                  icon: Icons.flash_on,
                  isBestValue: false,
                  savings: null,
                  onTap: () {
                    HapticService.mediumImpact();
                    // TODO: Trigger purchase
                  },
                ),
                const SizedBox(height: 10),
                _BoostPackCard(
                  tokens: 35,
                  price: '\$24.99',
                  perToken: '\$0.71',
                  label: 'Most Popular',
                  icon: Icons.local_fire_department,
                  isBestValue: true,
                  savings: '29%',
                  onTap: () {
                    HapticService.mediumImpact();
                    // TODO: Trigger purchase
                  },
                ),
                const SizedBox(height: 10),
                _BoostPackCard(
                  tokens: 100,
                  price: '\$59.99',
                  perToken: '\$0.60',
                  label: 'Best Value',
                  icon: Icons.diamond,
                  isBestValue: false,
                  savings: '40%',
                  onTap: () {
                    HapticService.mediumImpact();
                    // TODO: Trigger purchase
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pro Banner
          Container(
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
                      const Text(
                        'Free for PRO members',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Unlock all ${_worlds.length}+ Specialty Worlds',
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
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Text(
                          'Upgrade\nto PRO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
          const SizedBox(height: 28),

          // Specialty Worlds Title
          const Text(
            'Specialty Worlds',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Immersive themes for your next masterpiece.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),

          // Worlds Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _worlds.length,
            itemBuilder: (context, index) {
              final world = _worlds[index];
              return _WorldCard(
                world: world,
                onTap: () => _onWorldSelected(world),
              );
            },
          ),
          const SizedBox(height: 20),
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
                    child: const Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
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
