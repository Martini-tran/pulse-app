import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/user_api.dart';

class UserStorage {
  static const String _userKey = 'user_info';

  // 内存缓存
  static UserInfoDto? _cachedUser;

  // 获取缓存的用户信息
  static UserInfoDto? get cachedUser => _cachedUser;

  // 应用启动时预加载用户到内存
  static Future<void> initCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_userKey);
    if (jsonStr != null) {
      try {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        _cachedUser = UserInfoDto.fromJson(jsonMap);
      } catch (_) {
        _cachedUser = null;
      }
    }
  }

  // 存储用户信息
  static Future<void> saveUser(UserInfoDto user) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(user.toJson());
    await prefs.setString(_userKey, jsonStr);

    _cachedUser = user;
  }

  // 清除用户信息
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _cachedUser = null;
  }

  // -------------------------------
  // 快捷同步获取方法（直接从内存缓存）
  // -------------------------------
  static int? get userId => _cachedUser?.id;
  static String? get username => _cachedUser?.username;
  static String? get email => _cachedUser?.email;
  static String? get status => _cachedUser?.status;
  static List<String> get roles => _cachedUser?.roles ?? [];
  static List<String> get permissions => _cachedUser?.permissions ?? [];

  static bool hasRole(String role) {
    return roles.contains(role);
  }

  static bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
}
