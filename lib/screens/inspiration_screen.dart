import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/models/specialty_world.dart';
import '../core/providers/app_provider.dart';
import '../core/services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_loader.dart';
import 'style_selection_screen.dart';

class InspirationScreen extends StatelessWidget {
  const InspirationScreen({super.key});
  static const routeName = '/inspiration';

  static final Map<String, List<SpecialtyWorld>> _collections = {
    'Harry Potter': [
      SpecialtyWorld(id: 'gryffindor-room', name: 'Gryffindor Common Room', description: 'Bravery & Gold', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400', prompt: 'Transform into a Gryffindor common room from Hogwarts with warm red and gold colors, fireplace, and magical portraits'),
      SpecialtyWorld(id: 'slytherin-dungeon', name: 'Slytherin Dungeon', description: 'Ambition & Green', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=400', prompt: 'Transform into a Slytherin dungeon common room with green lighting and stone walls'),
      SpecialtyWorld(id: 'hogwarts-library', name: 'Hogwarts Library', description: 'Ancient Knowledge', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?w=400', prompt: 'Transform into the Hogwarts library with floating candles and ancient books'),
      SpecialtyWorld(id: 'room-of-requirement', name: 'Room of Requirement', description: 'Whatever You Need', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400', prompt: 'Transform into the Room of Requirement from Harry Potter'),
    ],
    'Star Wars': [
      SpecialtyWorld(id: 'millennium-falcon', name: 'Millennium Falcon', description: 'Smuggler Ship', category: 'sci-fi', imageUrl: 'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?w=400', prompt: 'Transform into the Millennium Falcon cockpit and lounge from Star Wars'),
      SpecialtyWorld(id: 'jedi-temple', name: 'Jedi Temple', description: 'Force Meditation', category: 'sci-fi', imageUrl: 'https://images.unsplash.com/photo-1507692049790-de58290a4334?w=400', prompt: 'Transform into a Jedi Temple meditation chamber'),
      SpecialtyWorld(id: 'tatooine-home', name: 'Tatooine Homestead', description: 'Desert Dwelling', category: 'sci-fi', imageUrl: 'https://images.unsplash.com/photo-1509316785289-025f5b846b35?w=400', prompt: 'Transform into a Tatooine moisture farm homestead from Star Wars'),
      SpecialtyWorld(id: 'death-star', name: 'Death Star Interior', description: 'Imperial Station', category: 'sci-fi', imageUrl: 'https://images.unsplash.com/photo-1534996858221-380b92700493?w=400', prompt: 'Transform into the Death Star interior command room'),
    ],
    'The Matrix': [
      SpecialtyWorld(id: 'matrix-construct', name: 'The Construct', description: 'White Loading Room', category: 'sci-fi', imageUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400', prompt: 'Transform into The Matrix construct white loading program'),
      SpecialtyWorld(id: 'neb-ship', name: 'Nebuchadnezzar', description: 'Hovercraft Interior', category: 'sci-fi', imageUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400', prompt: 'Transform into the Nebuchadnezzar hovercraft from The Matrix'),
      SpecialtyWorld(id: 'matrix-club', name: 'Club Hel', description: 'Merovingian Club', category: 'sci-fi', imageUrl: 'https://images.unsplash.com/photo-1566737236500-c8ac43014a67?w=400', prompt: 'Transform into Club Hel from The Matrix with neon and leather'),
    ],
    'Game of Thrones': [
      SpecialtyWorld(id: 'winterfell', name: 'Winterfell Great Hall', description: 'House Stark', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400', prompt: 'Transform into the Great Hall of Winterfell from Game of Thrones'),
      SpecialtyWorld(id: 'iron-throne', name: 'Iron Throne Room', description: 'Kings Landing', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1551524559-8af4e6624178?w=400', prompt: 'Transform into the Iron Throne room'),
      SpecialtyWorld(id: 'dragonstone', name: 'Dragonstone Castle', description: 'Targaryen Seat', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1533154683836-84ea7a0bc310?w=400', prompt: 'Transform into Dragonstone castle throne room'),
    ],
    'Stranger Things': [
      SpecialtyWorld(id: 'upside-down', name: 'The Upside Down', description: 'Dark Dimension', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1509248961895-b23aad4f24b4?w=400', prompt: 'Transform into The Upside Down from Stranger Things'),
      SpecialtyWorld(id: 'hawkins-80s', name: "Hawkins '80s Basement", description: 'Retro Gaming Den', category: 'retro', imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400', prompt: 'Transform into 1980s Hawkins basement from Stranger Things with arcade games'),
      SpecialtyWorld(id: 'starcourt-mall', name: 'Starcourt Mall', description: '80s Shopping Center', category: 'retro', imageUrl: 'https://images.unsplash.com/photo-1519567241046-7f570f88e07a?w=400', prompt: 'Transform into Starcourt Mall from Stranger Things with 80s neon'),
    ],
    'Cyberpunk': [
      SpecialtyWorld(id: 'cyberpunk-2077', name: 'Night City Apartment', description: 'Neon Future', category: 'futuristic', imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400', prompt: 'Transform into Cyberpunk 2077 Night City apartment with neon lights'),
      SpecialtyWorld(id: 'cyber-tokyo', name: 'Cyber-Tokyo', description: 'Neon Metropolis', category: 'futuristic', imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400', prompt: 'Transform into futuristic Tokyo apartment with holographic displays'),
      SpecialtyWorld(id: 'blade-runner', name: 'Blade Runner 2049', description: 'Neo-Noir', category: 'futuristic', imageUrl: 'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=400', prompt: 'Transform into a Blade Runner 2049 apartment'),
    ],
    'Fantasy Worlds': [
      SpecialtyWorld(id: 'hobbit-hole', name: 'Hobbit Hole', description: 'Middle Earth', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400', prompt: 'Transform into a cozy Hobbit hole from Middle Earth'),
      SpecialtyWorld(id: 'narnia', name: 'Narnia Beyond Wardrobe', description: 'Magical Kingdom', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1418985991508-e47386d96a71?w=400', prompt: 'Transform into Narnia beyond the wardrobe'),
      SpecialtyWorld(id: 'enchanted-forest', name: 'Enchanted Forest', description: 'Magical Nature', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=400', prompt: 'Transform into an enchanted forest cabin'),
      SpecialtyWorld(id: 'underwater-atlantis', name: 'Underwater Atlantis', description: 'Deep Sea Kingdom', category: 'fantasy', imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400', prompt: 'Transform into underwater Atlantean palace'),
    ],
    'Historical': [
      SpecialtyWorld(id: 'victorian-1800s', name: '1800s Victorian', description: 'Gothic Elegance', category: 'historical', imageUrl: 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=400', prompt: 'Transform into Victorian era parlor from the 1800s'),
      SpecialtyWorld(id: 'egyptian-palace', name: 'Egyptian Palace', description: "Pharaoh's Court", category: 'historical', imageUrl: 'https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=400', prompt: 'Transform into Ancient Egyptian palace'),
      SpecialtyWorld(id: 'gatsby-mansion', name: 'Gatsby Mansion', description: 'Roaring 1920s', category: 'historical', imageUrl: 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=400', prompt: 'Transform into The Great Gatsby mansion'),
      SpecialtyWorld(id: 'roman-villa', name: 'Roman Villa', description: 'Ancient Empire', category: 'historical', imageUrl: 'https://images.unsplash.com/photo-1553877522-43269d4ea984?w=400', prompt: 'Transform into an Ancient Roman villa'),
      SpecialtyWorld(id: 'ottoman-palace', name: 'Ottoman Palace', description: 'Topkapi Elegance', category: 'historical', imageUrl: 'https://images.unsplash.com/photo-1596484552834-6a58f850e0a1?w=400', prompt: 'Transform into an Ottoman palace chamber'),
    ],
  };

  void _onWorldTap(BuildContext context, SpecialtyWorld world) {
    HapticService.mediumImpact();
    final appProvider = context.read<AppProvider>();
    appProvider.setSelectedWorldPrompt(world.prompt, worldName: world.name);

    // If no photo selected, show picker first then go to wizard
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
            Text('Select a room photo to transform', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picker = ImagePicker();
                      final file = await picker.pickImage(source: ImageSource.camera, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
                      if (file != null && context.mounted) {
                        context.read<AppProvider>().setSelectedImage(File(file.path));
                        Navigator.pushNamed(context, StyleSelectionScreen.routeName);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picker = ImagePicker();
                      final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
                      if (file != null && context.mounted) {
                        context.read<AppProvider>().setSelectedImage(File(file.path));
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
    final items = _collections[category] ?? _collections['Fantasy Worlds']!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
        ),
        title: Text(category, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Explore $category themed rooms. Tap to transform your space.',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final world = items[index];
                    return GestureDetector(
                      onTap: () => _onWorldTap(context, world),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
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
                                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                                    stops: const [0.4, 1.0],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 10, right: 10, bottom: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(world.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text(world.description, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
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
              ),
            ),
          ],
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
