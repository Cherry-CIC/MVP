import 'dart:async';
import 'dart:convert';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/services/error_string.dart';
import 'package:cherry_mvp/core/utils/result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsernameService {
  static const _usernameCacheByUidKey = 'username_cache_by_uid';
  static const Duration _readTimeout = Duration(seconds: 6);
  static const Duration _writeTimeout = Duration(seconds: 8);

  static Future<String?> getUsername(String uid) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();

    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreConstants.pathUserCollection)
          .doc(trimmedUid)
          .get()
          .timeout(_readTimeout);

      final data = doc.data();
      final username = (data?[FirestoreConstants.username] as String?)?.trim();

      if (username != null && username.isNotEmpty) {
        await _cacheUsernameForUid(prefs, trimmedUid, username);
        return username;
      }
    } catch (_) {
      // Fall back to local cache if Firestore read fails.
    }

    final cached = _readCachedUsernames(prefs)[trimmedUid]?.trim();
    if (cached == null || cached.isEmpty) return null;
    return cached;
  }

  static Future<Result<bool>> isUsernameTaken(
    String username, {
    String? excludeUid,
  }) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) {
      return Result.failure('Username is required.');
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection(FirestoreConstants.pathUserCollection)
          .where(FirestoreConstants.username, isEqualTo: trimmedUsername)
          .limit(5)
          .get()
          .timeout(_readTimeout);

      final isTaken = query.docs.any((doc) => doc.id != excludeUid);
      return Result.success(isTaken);
    } on TimeoutException {
      return Result.failure(ErrorStrings.timeoutError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<void>> saveUsername(String uid, String username) async {
    final trimmedUid = uid.trim();
    final trimmedUsername = username.trim();

    if (trimmedUid.isEmpty) {
      return Result.failure('User id is required.');
    }
    if (trimmedUsername.isEmpty) {
      return Result.failure('Username is required.');
    }

    try {
      await FirebaseFirestore.instance
          .collection(FirestoreConstants.pathUserCollection)
          .doc(trimmedUid)
          .set({
            FirestoreConstants.username: trimmedUsername,
          }, SetOptions(merge: true))
          .timeout(_writeTimeout);

      final prefs = await SharedPreferences.getInstance();
      await _cacheUsernameForUid(prefs, trimmedUid, trimmedUsername);
      await prefs.setString(FirestoreConstants.username, trimmedUsername);
      return Result.success(null);
    } on TimeoutException {
      return Result.failure(ErrorStrings.timeoutError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Map<String, String> _readCachedUsernames(SharedPreferences prefs) {
    final raw = prefs.getString(_usernameCacheByUidKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};

      final result = <String, String>{};
      decoded.forEach((key, value) {
        if (key is String && value is String) {
          result[key] = value;
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _cacheUsernameForUid(
    SharedPreferences prefs,
    String uid,
    String username,
  ) async {
    final cache = _readCachedUsernames(prefs);
    cache[uid] = username;
    await prefs.setString(_usernameCacheByUidKey, jsonEncode(cache));
  }
}
