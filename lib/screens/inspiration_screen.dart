import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/localization/localization_extension.dart';
import '../core/models/specialty_world.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../core/services/paywall_helper.dart';
import '../core/services/world_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import 'style_selection_screen.dart';

class InspirationScreen extends StatefulWidget {
  const InspirationScreen({super.key});
  static const routeName = '/inspiration';

  /// The display categories shown in "All Collections" view.
  /// Each maps to keyword patterns used to filter worlds from the API.
  static const List<String> collectionNames = [
    'Harry Potter',
    'Lord of the Rings',
    'Star Wars',
    'The Matrix',
    'Game of Thrones',
    'Stranger Things',
    'Cyberpunk',
    'Fantasy Worlds',
    'Anime Worlds',
    'Gaming Realms',
    'Luxury Living',
    'Back to the Future',
    'Time Travel',
    'Historical',
    'Design Styles',
    'Modern Architecture',
    'Zodiac & Esoteric',
    'Mythology',
    'Brooklyn Nine-Nine',
    'Parks and Recreation',
    'Sitcoms',
    'Breaking Bad',
    'Ted Lasso',
    'The Sopranos',
    'Yellowstone',
    'Chernobyl',
    'Action Films',
    'Romance Films',
  ];

  @override
  State<InspirationScreen> createState() => _InspirationScreenState();
}

class _InspirationScreenState extends State<InspirationScreen> {
  List<SpecialtyWorld> _worlds = [];
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();
  bool _headerVisible = true;

  static const List<String> _stockRoomImages = [
    'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=1200',
    'https://images.unsplash.com/photo-1600210492493-0946911123ea?w=1200',
    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200',
    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200',
    'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=1200',
    'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=1200',
  ];

  /// Maps display collection names to world-id keyword patterns.
  /// Worlds whose id contains any of these keywords belong to that collection.
  static const Map<String, List<String>> _categoryKeywords = {
    'Harry Potter': ['gryffindor', 'hogwarts', 'slytherin', 'dumbledore', 'potions', 'requirement'],
    'Lord of the Rings': ['lotr-', 'hobbit-hole', 'rivendell', 'minas-tirith', 'mordor', 'rohan', 'lothlorien', 'moria', 'isengard', 'helms-deep', 'fangorn', 'prancing-pony', 'eregion', 'gondor-library', 'green-dragon', 'erebor', 'edoras', 'grey-havens', 'tom-bombadil', 'thranduil', 'dead-marshes'],
    'Star Wars': ['millennium', 'jedi', 'tatooine', 'death-star', 'naboo', 'mos-eisley'],
    'The Matrix': ['matrix', 'construct', 'neb', 'neo-apartment', 'zion', 'club-hel'],
    'Game of Thrones': ['winterfell', 'iron-throne', 'dragonstone', 'castle-black', 'highgarden', 'kings-landing', 'braavos', 'dorne', 'meereen', 'qarth', 'eyrie', 'pyke', 'oldtown', 'casterly', 'white-walker'],
    'Anime Worlds': ['spirited', 'totoro', 'evangelion', 'howl', 'attack-on-titan', 'attack-titan', 'death-note', 'demon-slayer', 'one-piece', 'cowboy-bebop', 'dragon-ball', 'sailor-moon', 'ponyo', 'princess-mononoke', 'naruto', 'hokage'],
    'Gaming Realms': ['minecraft', 'zelda', 'resident-evil', 'elden-ring', 'god-of-war', 'bioshock', 'portal', 'skyrim', 'halo', 'mass-effect', 'assassin', 'animal-crossing', 'hollow-knight', 'pokemon'],
    'Luxury Living': ['dubai', 'monaco', 'santorini', 'bali', 'swiss', 'safari', 'nyc', 'soho', 'moroccan', 'penthouse', 'yacht', 'malibu', 'chalet'],
    'Back to the Future': ['bttf', 'back-to-future', 'delorean', 'hill-valley', 'mcfly', 'clock-tower', 'cafe-80s', 'pleasure-paradise', 'enchantment-sea', 'wild-west-saloon'],
    'Time Travel': ['steampunk', 'retro-50', 'medieval', 'ancient-rome', 'future-2200', 'gatsby', 'roman', 'aztec'],
    'Stranger Things': ['upside-down', 'hawkins', 'starcourt', 'hopper'],
    'Cyberpunk': ['cyberpunk', 'cyber-tokyo', 'blade-runner', 'akira', 'ghost-in-the-shell', 'tron'],
    'Fantasy Worlds': ['hobbit', 'narnia', 'enchanted', 'atlantis', 'rivendell', 'asgard', 'ice-palace', 'crystal-cave', 'cloud-city', 'mushroom', 'fairy', 'dragon', 'mermaid', 'phoenix', 'underwater'],
    'Historical': ['victorian', 'egyptian', 'gatsby', 'roman', 'ottoman', 'aztec', 'chinese-imperial', 'samurai', 'art-nouveau', 'alhambra', 'byzantine', 'tudor', 'baroque', 'colonial', 'petra', 'versailles', 'greek-temple', 'ancient-greek', 'renaissance'],
    'Design Styles': [
      'rustic-farmhouse', 'shabby-chic', 'victorian-parlor', 'georgian-manor',
      'colonial-american', 'craftsman-bungalow', 'tuscan-villa', 'french-provincial',
      'english-cottage', 'country-chic', 'mid-century', 'art-deco', 'art-nouveau',
      'bauhaus', 'brutalist', 'high-tech', 'contemporary-chic', 'urban-loft',
      'transitional', 'organic-modern',
    ],
    'Modern Architecture': [
      'danish-modern', 'swedish-functional', 'norwegian-cabin', 'finnish-sauna',
      'icelandic-lava', 'swiss-alpine', 'german-bauhaus', 'dutch-canal',
      'french-haussmann', 'british-industrial', 'italian-modern-milan',
      'spanish-mediterranean', 'russian-constructivist', 'polish-brutalist',
      'czech-functionalism', 'american-midcentury', 'nyc-modern-loft',
      'california-contemporary', 'brazilian-modernist', 'mexican-modern-barragan',
    ],
    'Zodiac & Esoteric': [
      'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo', 'libra', 'scorpio',
      'sagittarius', 'capricorn', 'aquarius', 'pisces', 'tarot',
    ],
    'Mythology': [
      'olympus', 'asgard', 'valhalla', 'ragnarok', 'zeus', 'odin', 'thor',
      'loki', 'apollo', 'athena', 'elemental', 'chinese-dragon',
      'chinese-phoenix', 'chinese-',
    ],
    'Brooklyn Nine-Nine': [
      'b99-',
    ],
    'Parks and Recreation': [
      'parks-rec',
    ],
    'Sitcoms': [
      'seinfeld', 'the-office-dunder', 'himym', 'bigbang', 'b99-',
      'parks-rec', 'schitts-creek', 'modern-family', 'fresh-prince', 'frasier',
      'friends-apartment',
    ],
    'Breaking Bad': [
      'breaking-bad',
    ],
    'Ted Lasso': [
      'ted-lasso',
    ],
    'The Sopranos': [
      'sopranos-',
    ],
    'Yellowstone': [
      'yellowstone-',
    ],
    'Chernobyl': [
      'chernobyl-',
    ],
    'Action Films': [
      'dark-knight', 'inception', 'madmax', 'gladiator', 'killbill',
    ],
    'Romance Films': [
      'notebook', 'pride-pemberley', 'pride-bennet', 'pride-ballroom',
      'lalaland', 'amelie', 'casablanca',
    ],
    'Mad Max': [
      'madmax-',
    ],
    'Gladiator': [
      'gladiator-',
    ],
    'Kill Bill': [
      'killbill-',
    ],
    'The Notebook': [
      'notebook-',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadWorlds();
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

  Future<void> _createForMe(BuildContext context, SpecialtyWorld world) async {
    HapticService.mediumImpact();
    final canProceed = await ensureTokensOrPaywall(context);
    if (!canProceed || !context.mounted) return;

    final appProvider = context.read<AppProvider>();
    appProvider.setSelectedWorldPrompt(world.prompt, worldName: world.name);

    final stockUrl = _stockRoomImages[Random().nextInt(_stockRoomImages.length)];

    try {
      final resp = await http.get(Uri.parse(stockUrl));
      if (resp.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/stock_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(resp.bodyBytes);
        if (!context.mounted) return;
        await appProvider.setSelectedImage(file);
      }
    } catch (e) {
      debugPrint('Stock image fetch failed: $e');
    }

    if (!context.mounted) return;
    Navigator.pushNamed(context, StyleSelectionScreen.routeName);
  }

  Future<void> _loadWorlds() async {
    try {
      final worlds = await WorldService().getWorlds();
      if (mounted) {
        setState(() {
          _worlds = worlds;
          _loading = false;
        });
      }
    } catch (_) {
      // Use small fallback for offline mode
      if (mounted) {
        setState(() {
          _worlds = _getFallbackWorlds();
          _loading = false;
        });
      }
    }
  }

  List<SpecialtyWorld> _getFilteredWorlds(String category) {
    if (category == 'all') return _worlds;

    final keywords = _categoryKeywords[category] ?? [];
    if (keywords.isEmpty) {
      // Try matching by DB category field
      return _worlds.where((w) => w.category.toLowerCase() == category.toLowerCase()).toList();
    }

    return _worlds.where((w) => keywords.any((kw) => w.id.contains(kw))).toList();
  }

  static List<SpecialtyWorld> _getFallbackWorlds() {
    // Minimal offline fallback -- real data comes from the API
    return [
      SpecialtyWorld(id: 'hobbit-hole', name: 'Hobbit Hole', description: 'Middle Earth Style', category: 'fantasy', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/hobbit-hole.jpg', prompt: 'Transform into a cozy Hobbit hole'),
      SpecialtyWorld(id: 'gryffindor-room', name: 'Gryffindor Room', description: 'Bravery & Gold', category: 'fantasy', imageUrl: 'https://architectural-ai-thumbnails.s3.eu-central-1.amazonaws.com/thumbnails/gryffindor-room.jpg', prompt: 'Transform into Gryffindor common room'),
      SpecialtyWorld(id: 'cyberpunk-2077', name: 'Cyberpunk 2077', description: 'Neon Night City', category: 'futuristic', imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400', prompt: 'Transform into Cyberpunk apartment'),
      SpecialtyWorld(id: 'victorian-1800s', name: '1800s Victorian', description: 'Gothic Elegance', category: 'historical', imageUrl: 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=400', prompt: 'Transform into Victorian parlor'),
      SpecialtyWorld(id: 'japanese-zen', name: 'Japanese Zen', description: 'Temple Peace', category: 'cultural', imageUrl: 'https://images.unsplash.com/photo-1545083036-b175dd155a1d?w=400', prompt: 'Transform into Zen temple'),
      SpecialtyWorld(id: 'mars-colony', name: 'Mars Colony', description: 'Red Planet Base', category: 'futuristic', imageUrl: 'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?w=400', prompt: 'Transform into Mars habitat'),
      SpecialtyWorld(id: 'winterfell-great-hall', name: 'Winterfell Great Hall', description: 'House Stark', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400', prompt: 'Transform into Winterfell Great Hall'),
      SpecialtyWorld(id: 'millennium-falcon', name: 'Millennium Falcon', description: 'Smuggler Ship', category: 'sci-fi', imageUrl: 'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?w=400', prompt: 'Transform into the Millennium Falcon'),
      SpecialtyWorld(id: 'spirited-away-bathhouse', name: 'Spirited Away Bathhouse', description: 'Enchanted Spa', category: 'anime', imageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400', prompt: 'Transform into the Spirited Away bathhouse'),
      SpecialtyWorld(id: 'matrix-construct', name: 'The Construct', description: 'White Loading Room', category: 'sci-fi', imageUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400', prompt: 'Transform into The Matrix Construct'),
    ];
  }

  Future<void> _onWorldTap(BuildContext context, SpecialtyWorld world) async {
    HapticService.mediumImpact();

    final canProceed = await ensureTokensOrPaywall(context);
    if (!canProceed || !context.mounted) return;

    final appProvider = context.read<AppProvider>();
    appProvider.setSelectedWorldPrompt(world.prompt, worldName: world.name);

    if (appProvider.selectedImage == null) {
      _showImagePicker(context, world);
    } else {
      Navigator.pushNamed(context, StyleSelectionScreen.routeName);
    }
  }

  void _showImagePicker(BuildContext context, SpecialtyWorld world) {
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(world.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(context.tr('select_room_photo'), style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.camera_alt,
                    label: context.tr('camera'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picker = ImagePicker();
                      final file = await picker.pickImage(source: ImageSource.camera, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
                      if (file != null && context.mounted) {
                        await context.read<AppProvider>().setSelectedImage(File(file.path));
                        if (!context.mounted) return;
                        Navigator.pushNamed(context, StyleSelectionScreen.routeName);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.photo_library,
                    label: context.tr('gallery'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picker = ImagePicker();
                      final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
                      if (file != null && context.mounted) {
                        await context.read<AppProvider>().setSelectedImage(File(file.path));
                        if (!context.mounted) return;
                        Navigator.pushNamed(context, StyleSelectionScreen.routeName);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final category = args?['category'] ?? 'Fantasy Worlds';
    final isAll = category == 'all';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
        ),
        title: Text(isAll ? context.tr('all_collections') : category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: isAll
                  ? _buildAllCollections(context)
                  : _buildCategoryGrid(context, category),
            ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, String category) {
    final items = _getFilteredWorlds(category);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(context.tr('no_worlds_found'), style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    final featured = items.take(min(6, items.length)).toList();

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            context.tr('inspiration_explore_desc').replaceFirst('%s', category),
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ),
        // Featured horizontal row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade600),
              const SizedBox(width: 6),
              Text(
                context.tr('featured_worlds'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final world = featured[index];
              return SizedBox(
                width: 240,
                child: _InspirationWorldCard(
                  world: world,
                  onTap: () => _onWorldTap(context, world),
                  onCreateForMe: () => _createForMe(context, world),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            context.tr('all_options'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // 2-per-row grid, aligned with the rest of the app.
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final world = items[index];
            return _InspirationWorldCard(
              world: world,
              onTap: () => _onWorldTap(context, world),
              onCreateForMe: () => _createForMe(context, world),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAllCollections(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: InspirationScreen.collectionNames.length,
      itemBuilder: (context, index) {
        final categoryName = InspirationScreen.collectionNames[index];
        final worlds = _getFilteredWorlds(categoryName);
        final previewImage = worlds.isNotEmpty ? worlds.first.imageUrl : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                InspirationScreen.routeName,
                arguments: {'category': categoryName},
              );
            },
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (previewImage.isNotEmpty)
                      SkeletonImage(imageUrl: previewImage, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.black.withValues(alpha: 0.7), Colors.black.withValues(alpha: 0.3)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            categoryName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('worlds_count').replaceFirst('%s', '${worlds.length}'),
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(Icons.chevron_right, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InspirationWorldCard extends StatelessWidget {
  const _InspirationWorldCard({
    required this.world,
    required this.onTap,
    required this.onCreateForMe,
  });

  final SpecialtyWorld world;
  final VoidCallback onTap;
  // Kept for API compatibility with existing callers; no longer rendered.
  final VoidCallback onCreateForMe;

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
              SkeletonImage(imageUrl: world.imageUrl, fit: BoxFit.cover),
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
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.token, size: 12, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.tagBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
