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
        setState(() {
          _worlds = worlds;
        });
      }
    } catch (e) {
      debugPrint('Failed to load worlds from API: $e - using defaults');
      // Keep the default worlds, no need to do anything
    }
  }

  static List<SpecialtyWorld> _defaultWorlds() {
    return [
      SpecialtyWorld(
        id: 'hobbit-hole',
        name: 'Hobbit Hole',
        description: 'Middle Earth Style',
        category: 'fantasy',
        imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400',
        prompt: 'Transform into a cozy Hobbit hole from Middle Earth',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'gryffindor-room',
        name: 'Gryffindor Room',
        description: 'Bravery & Gold',
        category: 'fantasy',
        imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400',
        prompt: 'Transform into a Gryffindor common room from Hogwarts',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'slytherin-dungeon',
        name: 'Slytherin Dungeon',
        description: 'Ambition & Green',
        category: 'fantasy',
        imageUrl: 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=400',
        prompt: 'Transform into a Slytherin dungeon common room',
      ),
      SpecialtyWorld(
        id: 'hollywood-glamour',
        name: 'Hollywood Glamour',
        description: 'Golden Age Luxury',
        category: 'cinematic',
        imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=400',
        prompt: 'Transform into 1940s Hollywood glamour style',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'cyberpunk-2077',
        name: 'Cyberpunk 2077',
        description: 'Neon Night City',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400',
        prompt: 'Transform into Cyberpunk 2077 Night City apartment',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'victorian-1800s',
        name: '1800s Victorian',
        description: 'Gothic Elegance',
        category: 'historical',
        imageUrl: 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=400',
        prompt: 'Transform into Victorian era parlor from the 1800s',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'stone-age',
        name: '8000 BC Stone Age',
        description: 'Primitive Living',
        category: 'historical',
        imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
        prompt: 'Transform into Stone Age dwelling',
      ),
      SpecialtyWorld(
        id: 'prehistoric-cave',
        name: 'Prehistoric Cave',
        description: 'Natural Shelter',
        category: 'nature',
        imageUrl: 'https://images.unsplash.com/photo-1504893524553-b855bce32c67?w=400',
        prompt: 'Transform into prehistoric cave dwelling',
      ),
      SpecialtyWorld(
        id: 'post-apocalyptic',
        name: 'Post-Apocalyptic',
        description: 'Bunker Survival',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1534854638093-bada1813ca19?w=400',
        prompt: 'Transform into post-apocalyptic bunker hideout',
      ),
      SpecialtyWorld(
        id: 'underwater-atlantis',
        name: 'Underwater Atlantis',
        description: 'Deep Sea Kingdom',
        category: 'nature',
        imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400',
        prompt: 'Transform into underwater Atlantean palace',
      ),
      SpecialtyWorld(
        id: 'mars-colony',
        name: 'Mars Colony',
        description: 'Red Planet Base',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?w=400',
        prompt: 'Transform into Mars colony habitat module',
      ),
      SpecialtyWorld(
        id: 'egyptian-palace',
        name: 'Egyptian Palace',
        description: "Pharaoh's Court",
        category: 'historical',
        imageUrl: 'https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=400',
        prompt: 'Transform into Ancient Egyptian palace',
      ),
      SpecialtyWorld(
        id: 'medieval-castle',
        name: 'Medieval Castle',
        description: 'Stone Fortress',
        category: 'historical',
        imageUrl: 'https://images.unsplash.com/photo-1533154683836-84ea7a0bc310?w=400',
        prompt: 'Transform into medieval castle chamber',
      ),
      SpecialtyWorld(
        id: 'japanese-zen',
        name: 'Japanese Zen',
        description: 'Temple Peace',
        category: 'nature',
        imageUrl: 'https://images.unsplash.com/photo-1600210492493-0946911123ea?w=400',
        prompt: 'Transform into Japanese Zen temple space',
      ),
      SpecialtyWorld(
        id: 'cyber-tokyo',
        name: 'Cyber-Tokyo',
        description: 'Neon Metropolis',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400',
        prompt: 'Transform into futuristic Tokyo apartment',
      ),
      SpecialtyWorld(
        id: 'nordic-hall',
        name: 'Nordic Hall',
        description: 'Viking Longhouse',
        category: 'nature',
        imageUrl: 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=400',
        prompt: 'Transform into Viking longhouse great hall',
      ),
      SpecialtyWorld(
        id: 'mayan-temple',
        name: 'Mayan Temple',
        description: 'Jungle Ruins',
        category: 'historical',
        imageUrl: 'https://images.unsplash.com/photo-1518638150340-f706e86654de?w=400',
        prompt: 'Transform into Mayan temple chamber',
      ),
      SpecialtyWorld(
        id: 'futuristic-ship',
        name: 'Futuristic Ship',
        description: 'Sci-Fi Interior',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1534996858221-380b92700493?w=400',
        prompt: 'Transform into futuristic spaceship interior',
      ),
      SpecialtyWorld(
        id: 'tsunami-shelter',
        name: 'Tsunami Shelter',
        description: 'Disaster Proof',
        category: 'luxury',
        imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
        prompt: 'Transform into high-tech tsunami shelter',
      ),
      SpecialtyWorld(
        id: 'belle-epoque',
        name: 'Belle Époque',
        description: 'Parisian Charm',
        category: 'luxury',
        imageUrl: 'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=400',
        prompt: 'Transform into Belle Époque Parisian salon',
      ),
      // ============ 20 NEW WORLDS ============
      SpecialtyWorld(
        id: 'winterfell-great-hall',
        name: 'Winterfell Great Hall',
        description: 'House Stark Castle',
        category: 'fantasy',
        imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        prompt: 'Transform into the Great Hall of Winterfell from Game of Thrones',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'iron-throne-room',
        name: 'Iron Throne Room',
        description: 'Kings Landing Palace',
        category: 'fantasy',
        imageUrl: 'https://images.unsplash.com/photo-1551524559-8af4e6624178?w=400',
        prompt: 'Transform into the Iron Throne room of Kings Landing',
      ),
      SpecialtyWorld(
        id: 'upside-down',
        name: 'The Upside Down',
        description: 'Stranger Things Dimension',
        category: 'fantasy',
        imageUrl: 'https://images.unsplash.com/photo-1509248961895-b23aad4f24b4?w=400',
        prompt: 'Transform into The Upside Down from Stranger Things',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'hawkins-80s-basement',
        name: 'Hawkins 80s Basement',
        description: 'Retro Gaming Den',
        category: 'cinematic',
        imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400',
        prompt: 'Transform into 1980s Hawkins basement from Stranger Things',
      ),
      SpecialtyWorld(
        id: 'pandora-hometree',
        name: 'Pandora Hometree',
        description: "Avatar Na'vi Dwelling",
        category: 'nature',
        imageUrl: 'https://images.unsplash.com/photo-1518173946687-a4c036bc3e69?w=400',
        prompt: "Transform into a Na'vi Hometree dwelling from Avatar",
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'matrix-construct',
        name: 'Matrix Construct',
        description: 'White Loading Room',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=400',
        prompt: 'Transform into The Matrix construct loading program',
      ),
      SpecialtyWorld(
        id: 'nebuchadnezzar-ship',
        name: 'Nebuchadnezzar Ship',
        description: 'Matrix Hovercraft',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400',
        prompt: 'Transform into the Nebuchadnezzar hovercraft from The Matrix',
      ),
      SpecialtyWorld(
        id: 'millennium-falcon',
        name: 'Millennium Falcon',
        description: 'Star Wars Smuggler Ship',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?w=400',
        prompt: 'Transform into the Millennium Falcon interior from Star Wars',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'jedi-temple',
        name: 'Jedi Temple',
        description: 'Force Meditation Chamber',
        category: 'fantasy',
        imageUrl: 'https://images.unsplash.com/photo-1507692049790-de58290a4334?w=400',
        prompt: 'Transform into a Jedi Temple meditation chamber from Star Wars',
      ),
      SpecialtyWorld(
        id: 'blade-runner-2049',
        name: 'Blade Runner 2049',
        description: 'Neo-Noir Future',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=400',
        prompt: 'Transform into a Blade Runner 2049 apartment',
      ),
      SpecialtyWorld(
        id: 'narnia-wardrobe',
        name: 'Narnia Beyond Wardrobe',
        description: 'Magical Winter Forest',
        category: 'fantasy',
        imageUrl: 'https://images.unsplash.com/photo-1418985991508-e47386d96a71?w=400',
        prompt: 'Transform into Narnia just beyond the wardrobe',
      ),
      SpecialtyWorld(
        id: 'gatsby-mansion',
        name: 'Gatsby Mansion',
        description: 'Roaring 1920s Party',
        category: 'historical',
        imageUrl: 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=400',
        prompt: 'Transform into The Great Gatsby mansion party room',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'roman-villa',
        name: 'Roman Villa',
        description: 'Ancient Empire Luxury',
        category: 'historical',
        imageUrl: 'https://images.unsplash.com/photo-1553877522-43269d4ea984?w=400',
        prompt: 'Transform into an Ancient Roman villa',
      ),
      SpecialtyWorld(
        id: 'ottoman-harem',
        name: 'Ottoman Palace',
        description: 'Topkapı Elegance',
        category: 'historical',
        imageUrl: 'https://images.unsplash.com/photo-1596484552834-6a58f850e0a1?w=400',
        prompt: 'Transform into an Ottoman palace chamber from Topkapı',
      ),
      SpecialtyWorld(
        id: 'renaissance-studio',
        name: 'Renaissance Studio',
        description: 'Da Vinci Workshop',
        category: 'historical',
        imageUrl: 'https://images.unsplash.com/photo-1577720580479-7d839d829c73?w=400',
        prompt: "Transform into a Renaissance artist studio like Leonardo da Vinci's workshop",
      ),
      SpecialtyWorld(
        id: 'tron-grid',
        name: 'Tron Grid',
        description: 'Digital Light World',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1558591710-4b4a1ae0f04d?w=400',
        prompt: 'Transform into Tron digital grid world',
      ),
      SpecialtyWorld(
        id: 'interstellar-endurance',
        name: 'Endurance Station',
        description: 'Interstellar Spacecraft',
        category: 'futuristic',
        imageUrl: 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=400',
        prompt: 'Transform into the Endurance spacecraft from Interstellar',
      ),
      SpecialtyWorld(
        id: 'enchanted-forest-cabin',
        name: 'Enchanted Forest',
        description: 'Fairy Tale Cottage',
        category: 'nature',
        imageUrl: 'https://images.unsplash.com/photo-1476231682828-37e571bc172f?w=400',
        prompt: 'Transform into an enchanted forest fairy tale cottage',
      ),
      SpecialtyWorld(
        id: 'dubai-penthouse',
        name: 'Dubai Sky Penthouse',
        description: 'Ultra Luxury Living',
        category: 'luxury',
        imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=400',
        prompt: 'Transform into an ultra-luxury Dubai penthouse',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'wes-anderson-hotel',
        name: 'Grand Budapest Hotel',
        description: 'Wes Anderson Aesthetic',
        category: 'cinematic',
        imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400',
        prompt: 'Transform into a Wes Anderson film set, Grand Budapest Hotel style',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'titanic-first-class',
        name: 'Titanic First Class',
        description: '1912 Ocean Liner',
        category: 'cinematic',
        imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400',
        prompt: 'Transform into a Titanic first-class suite',
      ),
      // ============ ANIMATED SERIES ============
      SpecialtyWorld(
        id: 'simpsons-living-room',
        name: 'Simpsons Living Room',
        description: 'Springfield Home',
        category: 'animated',
        imageUrl: 'https://images.unsplash.com/photo-1585412727339-54e4bae3bbf9?w=400',
        prompt: 'Transform into The Simpsons living room from Springfield',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'family-guy-house',
        name: 'Griffin Family Room',
        description: 'Quahog Residence',
        category: 'animated',
        imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400',
        prompt: 'Transform into the Griffin family living room from Family Guy',
      ),
      SpecialtyWorld(
        id: 'rick-morty-garage',
        name: "Rick's Garage Lab",
        description: 'Mad Scientist Workshop',
        category: 'animated',
        imageUrl: 'https://images.unsplash.com/photo-1581093458791-9f3c3900df4b?w=400',
        prompt: 'Transform into Rick Sanchez garage laboratory from Rick and Morty',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'death-note-room',
        name: 'Light Yagami Room',
        description: 'Death Note Anime',
        category: 'animated',
        imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400',
        prompt: 'Transform into Light Yagami bedroom from Death Note anime',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'spirited-away-bathhouse',
        name: 'Spirited Away Bathhouse',
        description: 'Studio Ghibli Magic',
        category: 'animated',
        imageUrl: 'https://images.unsplash.com/photo-1528164344705-47542687000d?w=400',
        prompt: 'Transform into the bathhouse from Spirited Away by Studio Ghibli',
      ),
      SpecialtyWorld(
        id: 'attack-titan-headquarters',
        name: 'Survey Corps HQ',
        description: 'Attack on Titan',
        category: 'animated',
        imageUrl: 'https://images.unsplash.com/photo-1533154683836-84ea7a0bc310?w=400',
        prompt: 'Transform into Survey Corps headquarters from Attack on Titan',
      ),
      SpecialtyWorld(
        id: 'demon-slayer-dojo',
        name: 'Demon Slayer Dojo',
        description: 'Kimetsu no Yaiba',
        category: 'animated',
        imageUrl: 'https://images.unsplash.com/photo-1600210492493-0946911123ea?w=400',
        prompt: 'Transform into a Demon Slayer Corps training dojo',
      ),
      SpecialtyWorld(
        id: 'south-park-room',
        name: 'South Park Bedroom',
        description: 'Colorado Kids',
        category: 'animated',
        imageUrl: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400',
        prompt: 'Transform into a South Park kids bedroom',
      ),
      SpecialtyWorld(
        id: 'adventure-time-treehouse',
        name: 'Finn & Jake Treehouse',
        description: 'Land of Ooo',
        category: 'animated',
        imageUrl: 'https://images.unsplash.com/photo-1520637836993-a071674a97c4?w=400',
        prompt: 'Transform into Finn and Jake treehouse from Adventure Time',
      ),
      // ============ COUNTRY STYLES ============
      SpecialtyWorld(
        id: 'korean-hanok',
        name: 'Korean Hanok House',
        description: 'Traditional Seoul Style',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1590912710484-739e9ad9c7d3?w=400',
        prompt: 'Transform into a traditional Korean Hanok house',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'korean-modern-kdrama',
        name: 'K-Drama Penthouse',
        description: 'Seoul Luxury Style',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=400',
        prompt: 'Transform into a modern Korean drama penthouse',
      ),
      SpecialtyWorld(
        id: 'turkish-modern',
        name: 'Istanbul Chic',
        description: 'Modern Turkish Style',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400',
        prompt: 'Transform into modern Turkish Istanbul style',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'turkish-konak',
        name: 'Anatolian Konak',
        description: 'Ottoman Mansion',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1596484552834-6a58f850e0a1?w=400',
        prompt: 'Transform into a traditional Turkish konak mansion',
      ),
      SpecialtyWorld(
        id: 'italian-tuscan',
        name: 'Tuscan Villa',
        description: 'Italian Countryside',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=400',
        prompt: 'Transform into an Italian Tuscan villa',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'italian-milan-modern',
        name: 'Milan Design District',
        description: 'Contemporary Italian',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=400',
        prompt: 'Transform into a Milan design district apartment',
      ),
      SpecialtyWorld(
        id: 'greek-santorini',
        name: 'Santorini Blue',
        description: 'Greek Island Style',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=400',
        prompt: 'Transform into a Santorini Greek island home',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'greek-classical',
        name: 'Classical Athens',
        description: 'Ancient Greek Temple',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1555993539-1732b0258235?w=400',
        prompt: 'Transform into an Ancient Greek classical interior',
      ),
      SpecialtyWorld(
        id: 'french-parisian',
        name: 'Parisian Apartment',
        description: 'Haussmann Elegance',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=400',
        prompt: 'Transform into a classic Parisian Haussmann apartment',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'french-provence',
        name: 'Provence Farmhouse',
        description: 'French Country Style',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=400',
        prompt: 'Transform into a French Provence farmhouse',
      ),
      SpecialtyWorld(
        id: 'spanish-andalusian',
        name: 'Andalusian Riad',
        description: 'Moorish Spanish Style',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=400',
        prompt: 'Transform into a Spanish Andalusian interior',
      ),
      SpecialtyWorld(
        id: 'moroccan-riad',
        name: 'Marrakech Riad',
        description: 'Moroccan Palace',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1548624313-0396c75e4b1a?w=400',
        prompt: 'Transform into a Moroccan riad in Marrakech',
      ),
      SpecialtyWorld(
        id: 'indian-mughal',
        name: 'Mughal Palace',
        description: 'Royal Indian Style',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=400',
        prompt: 'Transform into a Mughal palace chamber',
      ),
      SpecialtyWorld(
        id: 'scandinavian-hygge',
        name: 'Nordic Hygge',
        description: 'Cozy Scandinavian',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=400',
        prompt: 'Transform into a Scandinavian hygge living space',
      ),
      SpecialtyWorld(
        id: 'mexican-hacienda',
        name: 'Mexican Hacienda',
        description: 'Vibrant Latin Style',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400',
        prompt: 'Transform into a Mexican hacienda',
      ),
      SpecialtyWorld(
        id: 'brazilian-tropical',
        name: 'Rio Tropical Modern',
        description: 'Brazilian Beach Style',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400',
        prompt: 'Transform into a Brazilian tropical modern home',
      ),
      SpecialtyWorld(
        id: 'chinese-traditional',
        name: 'Ming Dynasty Chamber',
        description: 'Imperial Chinese',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=400',
        prompt: 'Transform into a Ming Dynasty Chinese chamber',
      ),
      SpecialtyWorld(
        id: 'russian-imperial',
        name: 'St. Petersburg Palace',
        description: 'Tsarist Russian Style',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=400',
        prompt: 'Transform into a Russian Imperial palace chamber',
      ),
      SpecialtyWorld(
        id: 'balinese-resort',
        name: 'Bali Paradise Villa',
        description: 'Indonesian Tropical',
        category: 'cultural',
        imageUrl: 'https://images.unsplash.com/photo-1540541338287-41700207dee6?w=400',
        prompt: 'Transform into a Balinese villa resort',
      ),
      // ============ MORE TV SERIES ============
      SpecialtyWorld(
        id: 'breaking-bad-lab',
        name: 'Heisenberg Lab',
        description: 'Breaking Bad Meth Lab',
        category: 'cinematic',
        imageUrl: 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=400',
        prompt: 'Transform into Walter White meth lab from Breaking Bad',
      ),
      SpecialtyWorld(
        id: 'peaky-blinders-office',
        name: 'Shelby Company Office',
        description: 'Peaky Blinders',
        category: 'cinematic',
        imageUrl: 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=400',
        prompt: 'Transform into Thomas Shelby office from Peaky Blinders',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'money-heist-hideout',
        name: 'La Casa de Papel',
        description: 'Money Heist Hideout',
        category: 'cinematic',
        imageUrl: 'https://images.unsplash.com/photo-1541123603104-512919d6a96c?w=400',
        prompt: 'Transform into the Professor hideout from Money Heist',
      ),
      SpecialtyWorld(
        id: 'squid-game-dorm',
        name: 'Squid Game Dorm',
        description: 'Korean Survival Game',
        category: 'cinematic',
        imageUrl: 'https://images.unsplash.com/photo-1541123603104-512919d6a96c?w=400',
        prompt: 'Transform into Squid Game player dormitory',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'the-crown-palace',
        name: 'Buckingham Palace',
        description: 'The Crown Royal Style',
        category: 'luxury',
        imageUrl: 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=400',
        prompt: 'Transform into a Buckingham Palace state room from The Crown',
      ),
      SpecialtyWorld(
        id: 'bridgerton-regency',
        name: 'Bridgerton Drawing Room',
        description: 'Regency Era Romance',
        category: 'historical',
        imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400',
        prompt: 'Transform into a Bridgerton Regency era drawing room',
        isFeatured: true,
      ),
      SpecialtyWorld(
        id: 'friends-apartment',
        name: "Monica's Apartment",
        description: 'Central Perk NYC',
        category: 'cinematic',
        imageUrl: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400',
        prompt: 'Transform into Monica Geller apartment from Friends',
      ),
      SpecialtyWorld(
        id: 'succession-penthouse',
        name: 'Roy Family Penthouse',
        description: 'Succession Billionaire',
        category: 'luxury',
        imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=400',
        prompt: 'Transform into the Roy family penthouse from Succession',
      ),
      SpecialtyWorld(
        id: 'narcos-mansion',
        name: 'Escobar Hacienda',
        description: 'Narcos Drug Lord Style',
        category: 'cinematic',
        imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400',
        prompt: 'Transform into Pablo Escobar Hacienda from Narcos',
      ),
      SpecialtyWorld(
        id: 'sherlock-baker-street',
        name: '221B Baker Street',
        description: 'BBC Sherlock',
        category: 'cinematic',
        imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400',
        prompt: 'Transform into 221B Baker Street from BBC Sherlock',
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
                        world.description,
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
              world.description,
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
                      world.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
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
