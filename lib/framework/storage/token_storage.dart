import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _refreshToken = 'refresh_token';

  // 添加内存缓存
  static String? _cachedAccessToken;
  static String? _cachedRefreshToken;

  // 获取缓存的access token（同步）
  static String? get cachedAccessToken => _cachedAccessToken;

  // 应用启动时预加载token到内存
  static Future<void> initCache() async {
    _cachedAccessToken = await getToken();
    _cachedRefreshToken = await getRefreshToken();
  }

  // 存储双token
  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshToken, refreshToken);

    // 更新内存缓存
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
  }

  // 清除所有token
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshToken);

    // 清除内存缓存
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
  }

  // 原有方法保持兼容
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _cachedAccessToken = token;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshToken);
  }
}