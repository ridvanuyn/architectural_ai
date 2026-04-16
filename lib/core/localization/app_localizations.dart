import 'package:flutter/material.dart';

import 'languages/en.dart';
import 'languages/es.dart';
import 'languages/pt.dart';
import 'languages/tr.dart';
import 'languages/zh.dart';
import 'languages/hi.dart';
import 'languages/ar.dart';
import 'languages/fr.dart';
import 'languages/de.dart';
import 'languages/it.dart';
import 'languages/ja.dart';
import 'languages/ko.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  late Map<String, String> _localizedStrings;
  
  Future<bool> load() async {
    _localizedStrings = _getTranslations(locale.languageCode);
    return true;
  }
  
  Map<String, String> _getTranslations(String languageCode) {
    switch (languageCode) {
      case 'en':
        return enTranslations;
      case 'es':
        return esTranslations;
      case 'pt':
        return ptTranslations;
      case 'tr':
        return trTranslations;
      case 'zh':
        return zhTranslations;
      case 'hi':
        return hiTranslations;
      case 'ar':
        return arTranslations;
      case 'fr':
        return frTranslations;
      case 'de':
        return deTranslations;
      case 'it':
        return itTranslations;
      case 'ja':
        return jaTranslations;
      case 'ko':
        return koTranslations;
      default:
        return enTranslations;
    }
  }
  
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
  
  // Shorthand
  String get(String key) => translate(key);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return SupportedLanguage.codes.contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class SupportedLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRTL;
  
  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.isRTL = false,
  });
  
  Locale get locale => Locale(code);
  
  static const List<SupportedLanguage> all = [
    SupportedLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    SupportedLanguage(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    SupportedLanguage(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flag: '🇧🇷',
    ),
    SupportedLanguage(
      code: 'tr',
      name: 'Turkish',
      nativeName: 'Türkçe',
      flag: '🇹🇷',
    ),
    SupportedLanguage(
      code: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
    ),
    SupportedLanguage(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
    ),
    SupportedLanguage(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      isRTL: true,
    ),
    SupportedLanguage(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),
    SupportedLanguage(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
    ),
    SupportedLanguage(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
    ),
    SupportedLanguage(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
    ),
    SupportedLanguage(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
    ),
  ];
  
  static List<String> get codes => all.map((l) => l.code).toList();
  
  static List<Locale> get locales => all.map((l) => l.locale).toList();
  
  static SupportedLanguage fromCode(String code) {
    return all.firstWhere(
      (l) => l.code == code,
      orElse: () => all.first,
    );
  }
}

