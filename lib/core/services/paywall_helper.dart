import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'haptic_service.dart';
import 'revenue_cat_service.dart';

/// Gate any token-spending action behind a balance check.
/// If the user has fewer than [requiredTokens], present the RevenueCat paywall
/// and re-check after they return.
///
/// Returns true if the caller should proceed with the action.
Future<bool> ensureTokensOrPaywall(
  BuildContext context, {
  int requiredTokens = 1,
}) async {
  final provider = context.read<AppProvider>();
  if (provider.tokenBalance >= requiredTokens) return true;

  HapticService.error();
  if (!context.mounted) return false;

  final purchased = await RevenueCatService().presentPaywall(
    context,
    appProvider: provider,
  );
  if (!purchased) return false;

  return provider.tokenBalance >= requiredTokens;
}
