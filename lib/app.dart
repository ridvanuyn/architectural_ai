import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/providers/app_provider.dart';
import 'screens/before_after_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_shell.dart';
import 'screens/inspiration_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/result_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/style_selection_screen.dart';
import 'screens/store_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

class ArchitecturalAIApp extends StatelessWidget {
  const ArchitecturalAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: 'Architectural AI',
            theme: AppTheme.light(),
            debugShowCheckedModeBanner: false,
            
            // Localization
            locale: appProvider.locale,
            supportedLocales: SupportedLanguage.locales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            
            initialRoute: SplashScreen.routeName,
            routes: {
              SplashScreen.routeName: (context) => const SplashScreen(),
              OnboardingScreen.routeName: (context) => const OnboardingScreen(),
              HomeShell.routeName: (context) => const HomeShell(),
              StyleSelectionScreen.routeName: (context) =>
                  const StyleSelectionScreen(),
              ProcessingScreen.routeName: (context) => const ProcessingScreen(),
              BeforeAfterScreen.routeName: (context) => const BeforeAfterScreen(),
              ResultDetailScreen.routeName: (context) => const ResultDetailScreen(),
              HistoryScreen.routeName: (context) => const HistoryScreen(),
              StoreScreen.routeName: (context) => const StoreScreen(),
              SettingsScreen.routeName: (context) => const SettingsScreen(),
              InspirationScreen.routeName: (context) => const InspirationScreen(),
            },
          );
        },
      ),
    );
  }
}
