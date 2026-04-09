import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Extension for easy access to translations
extension LocalizationExtension on BuildContext {
  /// Get the AppLocalizations instance
  AppLocalizations get l10n => AppLocalizations.of(this);
  
  /// Translate a key
  String tr(String key) => AppLocalizations.of(this).translate(key);
}

