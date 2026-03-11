import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DonorDiscountStateStore {
  static const String _storageKey = 'donor_discount_state_by_product';

  static Future<void> setDonorDiscountState(
    String productId,
    bool isActive,
  ) async {
    final trimmedProductId = productId.trim();
    if (trimmedProductId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final currentStates = _readStates(prefs);
    currentStates[trimmedProductId] = isActive;
    await prefs.setString(_storageKey, jsonEncode(currentStates));
  }

  static Future<bool?> getDonorDiscountState(String productId) async {
    final trimmedProductId = productId.trim();
    if (trimmedProductId.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final currentStates = _readStates(prefs);
    return currentStates[trimmedProductId];
  }

  static Map<String, bool> _readStates(SharedPreferences prefs) {
    final rawJson = prefs.getString(_storageKey);
    if (rawJson == null || rawJson.isEmpty) return {};

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return {};

      final result = <String, bool>{};
      decoded.forEach((key, value) {
        if (key is String && value is bool) {
          result[key] = value;
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }
}
