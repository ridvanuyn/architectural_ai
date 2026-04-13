import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EngagementNotificationService {
  static final EngagementNotificationService _instance =
      EngagementNotificationService._internal();
  factory EngagementNotificationService() => _instance;
  EngagementNotificationService._internal();

  // Multilingual notification messages (10 messages, sent every 2 days)
  static const Map<String, List<Map<String, String>>> _messages = {
    'en': [
      {
        'title': 'Your room is waiting',
        'body': 'Transform any space with AI in seconds. Try it now!'
      },
      {
        'title': 'New styles just dropped',
        'body': '1000+ design themes available. Find your perfect aesthetic.'
      },
      {
        'title': 'Quick redesign?',
        'body': 'Snap a photo and watch the magic happen. Takes 30 seconds.'
      },
      {
        'title': 'Harry Potter fan?',
        'body': 'Transform your room into Hogwarts. Try our fantasy worlds!'
      },
      {
        'title': 'Your tokens are waiting',
        'body':
            'Use your free tokens before they expire. Create something amazing!'
      },
      {
        'title': 'Before & After magic',
        'body':
            'See the incredible AI transformations our users are creating.'
      },
      {
        'title': 'Weekend project idea',
        'body':
            'Redesign your living room with AI. No furniture moving required!'
      },
      {
        'title': 'Pro tip: Natural light',
        'body':
            'Take photos during golden hour for the best AI redesign results.'
      },
      {
        'title': 'Missing your designs?',
        'body':
            'Come back and create something new. Your creativity is needed!'
      },
      {
        'title': 'Unlock premium quality',
        'body':
            'Upgrade to PRO+ for stunning ultra-HD room transformations.'
      },
    ],
    'tr': [
      {
        'title': 'Odaniz sizi bekliyor',
        'body': 'AI ile herhangi bir alani saniyeler icinde donusturun!'
      },
      {
        'title': 'Yeni stiller geldi',
        'body': '1000+ tasarim temasi mevcut. Mukemmel estetiginizi bulun.'
      },
      {
        'title': 'Hizli yeniden tasarim?',
        'body': 'Bir fotograf cekin ve sihri izleyin. 30 saniye surer.'
      },
      {
        'title': 'Harry Potter hayrani misin?',
        'body':
            'Odanizi Hogwarts\'a donusturun. Fantezi dunyalarimizi deneyin!'
      },
      {
        'title': 'Tokenlariniz bekliyor',
        'body':
            'Ucretsiz tokenlarinizi kullanin. Harika bir sey yaratin!'
      },
      {
        'title': 'Once & Sonra sihri',
        'body':
            'Kullanicilarimizin yarattigi inanilmaz AI donusumlerini gorun.'
      },
      {
        'title': 'Hafta sonu proje fikri',
        'body':
            'Oturma odanizi AI ile yeniden tasarlayin. Mobilya tasimaya gerek yok!'
      },
      {
        'title': 'Pro ipucu: Dogal isik',
        'body': 'En iyi sonuclar icin altin saatte fotograf cekin.'
      },
      {
        'title': 'Tasarimlarinizi ozlediniz mi?',
        'body': 'Geri gelin ve yeni bir sey yaratin!'
      },
      {
        'title': 'Premium kaliteyi acin',
        'body': 'Ultra HD oda donusumleri icin PRO+ surume gecin.'
      },
    ],
    'de': [
      {
        'title': 'Ihr Raum wartet',
        'body': 'Verwandeln Sie jeden Raum mit KI in Sekunden!'
      },
      {
        'title': 'Neue Stile verfuegbar',
        'body':
            '1000+ Designthemen. Finden Sie Ihre perfekte Aesthetik.'
      },
      {
        'title': 'Schnelles Redesign?',
        'body':
            'Foto machen und die Magie beobachten. Dauert 30 Sekunden.'
      },
      {
        'title': 'Harry Potter Fan?',
        'body': 'Verwandeln Sie Ihr Zimmer in Hogwarts!'
      },
      {
        'title': 'Ihre Tokens warten',
        'body':
            'Nutzen Sie Ihre kostenlosen Tokens. Erschaffen Sie etwas Tolles!'
      },
      {
        'title': 'Vorher & Nachher Magie',
        'body': 'Sehen Sie die unglaublichen KI-Transformationen.'
      },
      {
        'title': 'Wochenend-Projektidee',
        'body': 'Gestalten Sie Ihr Wohnzimmer mit KI um!'
      },
      {
        'title': 'Pro-Tipp: Natuerliches Licht',
        'body':
            'Fotografieren Sie zur goldenen Stunde fuer beste Ergebnisse.'
      },
      {
        'title': 'Vermissen Sie Ihre Designs?',
        'body': 'Kommen Sie zurueck und kreieren Sie etwas Neues!'
      },
      {
        'title': 'Premium-Qualitaet freischalten',
        'body': 'Upgraden Sie auf PRO+ fuer Ultra-HD Ergebnisse.'
      },
    ],
    'fr': [
      {
        'title': 'Votre piece vous attend',
        'body':
            'Transformez n\'importe quel espace avec l\'IA en secondes!'
      },
      {
        'title': 'Nouveaux styles disponibles',
        'body':
            '1000+ themes de design. Trouvez votre esthetique parfaite.'
      },
      {
        'title': 'Redesign rapide?',
        'body': 'Prenez une photo et regardez la magie operer.'
      },
      {
        'title': 'Fan de Harry Potter?',
        'body': 'Transformez votre chambre en Poudlard!'
      },
      {
        'title': 'Vos tokens vous attendent',
        'body':
            'Utilisez vos tokens gratuits. Creez quelque chose d\'incroyable!'
      },
      {
        'title': 'Magie Avant & Apres',
        'body': 'Decouvrez les transformations IA incroyables.'
      },
      {
        'title': 'Idee de projet weekend',
        'body': 'Redesignez votre salon avec l\'IA!'
      },
      {
        'title': 'Astuce Pro: Lumiere naturelle',
        'body':
            'Photographiez a l\'heure doree pour les meilleurs resultats.'
      },
      {
        'title': 'Vos designs vous manquent?',
        'body': 'Revenez et creez quelque chose de nouveau!'
      },
      {
        'title': 'Debloquez la qualite premium',
        'body': 'Passez a PRO+ pour des resultats Ultra-HD.'
      },
    ],
  };

  /// Check and show notification if 2+ days since last one
  Future<void> checkAndNotify({
    required String languageCode,
    required bool isSubscriber,
    required int tokenBalance,
  }) async {
    // Subscribers with enough tokens don't get nagged
    if (isSubscriber && tokenBalance >= 5) return;

    final prefs = await SharedPreferences.getInstance();

    // Check if notifications are enabled
    final notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? true;
    if (!notificationsEnabled) return;

    final lastShown = prefs.getString('last_engagement_notification');
    final messageIndex = prefs.getInt('engagement_message_index') ?? 0;

    if (lastShown != null) {
      final lastDate = DateTime.parse(lastShown);
      if (DateTime.now().difference(lastDate).inDays < 2) return;
    }

    final messages = _messages[languageCode] ?? _messages['en']!;
    final message = messages[messageIndex % messages.length];

    // Show notification
    final plugin = FlutterLocalNotificationsPlugin();
    try {
      await plugin.show(
        200,
        message['title'],
        message['body'],
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          android: AndroidNotificationDetails(
            'engagement',
            'Tips & Reminders',
            channelDescription: 'Tips and reminders to use the app',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Failed to show engagement notification: $e');
    }

    // Update state
    await prefs.setString(
        'last_engagement_notification', DateTime.now().toIso8601String());
    await prefs.setInt('engagement_message_index', messageIndex + 1);
  }

  /// Cancel engagement notifications
  Future<void> cancelAll() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.cancel(200);
    } catch (e) {
      debugPrint('Failed to cancel engagement notification: $e');
    }
  }
}
