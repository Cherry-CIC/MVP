import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/services/error_string.dart';
import 'package:cherry_mvp/core/utils/result.dart';

// TODO maybe turn this into a user service, and have username retrieval and caching as part of it.
// TODO as we need to get other details like user photo etc for other parts of the app.
class UsernameService {
  static const _usernameCacheByUidKey = 'username_cache_by_uid';
  static const Duration _readTimeout = Duration(seconds: 15);
  static const Duration _writeTimeout = Duration(seconds: 15);

  static Future<Result<String?>> resolveUsername(
    String uid, {
    FirebaseFirestore? firestore,
    SharedPreferences? preferences,
    Duration readTimeout = _readTimeout,
  }) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) {
      return Result.failure('User id is required.');
    }

    final prefs = preferences ?? await SharedPreferences.getInstance();
    final cached = _getCachedUsername(prefs, trimmedUid);
    if (cached != null && cached.isNotEmpty) {
      return Result.success(cached);
    }

    try {
      final db = firestore ?? FirebaseFirestore.instance;
      final doc = await db
          .collection(FirestoreConstants.pathUserCollection)
          .doc(trimmedUid)
          .get()
          .timeout(readTimeout);

      final data = doc.data();
      final username = (data?[FirestoreConstants.username] as String?)?.trim();

      if (username != null && username.isNotEmpty) {
        await cacheUsernameForUid(prefs, trimmedUid, username);
        return Result.success(username);
      }

      // Document exists (or does not), but has no username set yet.
      return Result.success(null);
    } on TimeoutException {
      final fallback = _getCachedUsername(prefs, trimmedUid);
      if (fallback != null && fallback.isNotEmpty) {
        return Result.success(fallback);
      }
      return Result.failure(ErrorStrings.timeoutError);
    } catch (e) {
      final fallback = _getCachedUsername(prefs, trimmedUid);
      if (fallback != null && fallback.isNotEmpty) {
        return Result.success(fallback);
      }
      return Result.failure(e.toString());
    }
  }

  static Future<String?> getUsername(String uid) async {
    final result = await resolveUsername(uid);
    return result.value;
  }

  static Future<Result<bool>> isUsernameTaken(
    String username, {
    String? excludeUid,
    FirebaseFirestore? firestore,
    Duration readTimeout = _readTimeout,
  }) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) {
      return Result.failure('Username is required.');
    }

    try {
      final db = firestore ?? FirebaseFirestore.instance;
      final query = await db
          .collection(FirestoreConstants.pathUserCollection)
          .where(FirestoreConstants.username, isEqualTo: trimmedUsername)
          .limit(5)
          .get()
          .timeout(readTimeout);

      final isTaken = query.docs.any((doc) => doc.id != excludeUid);
      return Result.success(isTaken);
    } on TimeoutException {
      return Result.failure(ErrorStrings.timeoutError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static Future<Result<void>> saveUsername(
    String uid,
    String username, {
    FirebaseFirestore? firestore,
    SharedPreferences? preferences,
    Duration writeTimeout = _writeTimeout,
  }) async {
    final trimmedUid = uid.trim();
    final trimmedUsername = username.trim();

    if (trimmedUid.isEmpty) {
      return Result.failure('User id is required.');
    }
    if (trimmedUsername.isEmpty) {
      return Result.failure('Username is required.');
    }

    try {
      final db = firestore ?? FirebaseFirestore.instance;
      await db
          .collection(FirestoreConstants.pathUserCollection)
          .doc(trimmedUid)
          .set({
            FirestoreConstants.username: trimmedUsername,
          }, SetOptions(merge: true))
          .timeout(writeTimeout);

      final prefs = preferences ?? await SharedPreferences.getInstance();
      await cacheUsernameForUid(prefs, trimmedUid, trimmedUsername);
      return Result.success(null);
    } on TimeoutException {
      return Result.failure(ErrorStrings.timeoutError);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  static String? _getCachedUsername(SharedPreferences prefs, String uid) {
    final cachedFromMap = _readCachedUsernames(prefs)[uid]?.trim();
    if (cachedFromMap != null && cachedFromMap.isNotEmpty) {
      return cachedFromMap;
    }

    final storedUid = prefs.getString(FirestoreConstants.id)?.trim();
    if (storedUid == uid) {
      final fallback = prefs.getString(FirestoreConstants.username)?.trim();
      if (fallback != null && fallback.isNotEmpty) {
        return fallback;
      }
    }
    return null;
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

  static Future<void> cacheUsernameForUid(
    SharedPreferences prefs,
    String uid,
    String username,
  ) async {
    final trimmedUid = uid.trim();
    final trimmedUsername = username.trim();
    if (trimmedUid.isEmpty || trimmedUsername.isEmpty) return;

    final cache = _readCachedUsernames(prefs);
    cache[trimmedUid] = trimmedUsername;
    await prefs.setString(_usernameCacheByUidKey, jsonEncode(cache));
    await prefs.setString(FirestoreConstants.username, trimmedUsername);
    await prefs.setString(FirestoreConstants.id, trimmedUid);
  }
}
