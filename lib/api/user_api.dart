import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pulse_app/framework/storage/token_storage.dart';

import '../framework/storage/user_storage.dart';
import '../util/request.dart';

/// 登录响应DTO
class LoginResponseDto {
  final String accessToken;
  final String refreshToken;
  final UserInfoDto userInfo;

  LoginResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.userInfo,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      userInfo: UserInfoDto.fromJson(json['user_info']),
    );
  }
}

/// 用户信息DTO
class UserInfoDto {
  final int id;
  final String username;
  final String email;
  final String status;
  final List<String> roles;
  final List<String> permissions;

  UserInfoDto({
    required this.id,
    required this.username,
    required this.email,
    required this.status,
    required this.roles,
    required this.permissions,
  });

  factory UserInfoDto.fromJson(Map<String, dynamic> json) {
    return UserInfoDto(
      id: json['id'] as int? ?? -1, // 或者使用 -1 作为默认值
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'status': status,
      'roles': roles,
      'permissions': permissions,
    };
  }
}

/// 用户相关API服务
class UserApiService {
  static final HttpClient _httpClient = HttpClient.instance;

  /// 用户登录
  static Future<ApiResponse<LoginResponseDto>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.success && response.code == 200 && response.data != null) {
        final loginResponse = LoginResponseDto.fromJson(response.data!);
        // 保存token到本地存储
        await TokenStorage.saveTokens(loginResponse.accessToken, loginResponse.refreshToken);
        // 保存用户信息
        await UserStorage.saveUser(loginResponse.userInfo);
        return ApiResponse.success(loginResponse, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('登录请求异常: $e');
      return ApiResponse<LoginResponseDto>.error('网络异常: $e');
    }
  }

  /// 用户注册
  static Future<ApiResponse<LoginResponseDto>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password
        },
      );

      if (response.success && response.code == 200 && response.data != null) {
        final loginResponse = LoginResponseDto.fromJson(response.data!);
        // 保存token到本地存储
        await TokenStorage.saveTokens(loginResponse.accessToken, loginResponse.refreshToken);
        // 保存用户信息
        await UserStorage.saveUser(loginResponse.userInfo);
        return ApiResponse.success(loginResponse, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('注册请求异常: $e');
      return ApiResponse<LoginResponseDto>.error('网络异常: $e');
    }
  }

  /// 刷新token
  static Future<ApiResponse<LoginResponseDto>> refreshToken() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return ApiResponse<LoginResponseDto>.error('刷新token不存在');
      }

      final response = await _httpClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.success && response.code == 200 && response.data != null) {
        final loginResponse = LoginResponseDto.fromJson(response.data!);

        // 更新token
        await TokenStorage.saveTokens(
            loginResponse.accessToken,
            loginResponse.refreshToken
        );

        return ApiResponse.success(loginResponse, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('刷新token异常: $e');
      return ApiResponse<LoginResponseDto>.error('刷新token失败: $e');
    }
  }

  /// 退出登录
  static Future<ApiResponse<void>> logout() async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/auth/logout',
      );

      // 无论服务端返回什么，都清除本地token
      await TokenStorage.clearTokens();

      if (response.success) {
        return ApiResponse.success(null, message: '退出成功');
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      // 即使网络异常，也要清除本地token
      await TokenStorage.clearTokens();
      print('退出登录异常: $e');
      return ApiResponse<void>.error('退出登录失败: $e');
    }
  }

  /// 检查用户名称是否可用
  static Future<ApiResponse<bool>> checkUser(String username, String email) async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        '/user/checkuser',
        queryParameters: {'username': username, 'email': email},
      );

      if (response.success && response.code == 200) {
        // 根据后端实际返回的数据结构调整
        final isAvailable = response.data?['available'] ?? false;
        return ApiResponse.success(isAvailable, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('检查用户名异常: $e');
      return ApiResponse<bool>.error('检查用户名失败: $e');
    }
  }

  /// 获取当前用户信息
  static Future<ApiResponse<UserInfoDto>> getCurrentUserInfo() async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        '/user/profile',
      );

      if (response.success && response.code == 200 && response.data != null) {
        final userInfo = UserInfoDto.fromJson(response.data!);
        return ApiResponse.success(userInfo, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('获取用户信息异常: $e');
      return ApiResponse<UserInfoDto>.error('获取用户信息失败: $e');
    }
  }

  /// 根据用户ID获取用户信息
  static Future<ApiResponse<UserInfoDto>> getUserInfo(int userId) async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        '/user/$userId',
      );

      if (response.success && response.code == 200 && response.data != null) {
        final userInfo = UserInfoDto.fromJson(response.data!);
        return ApiResponse.success(userInfo, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('获取用户信息异常: $e');
      return ApiResponse<UserInfoDto>.error('获取用户信息失败: $e');
    }
  }

  /// 更新用户信息
  static Future<ApiResponse<UserInfoDto>> updateUserInfo({
    String? username,
    String? email,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (email != null) data['email'] = email;

      final response = await _httpClient.put<Map<String, dynamic>>(
        '/user/profile',
        data: data,
      );

      if (response.success && response.code == 200 && response.data != null) {
        final userInfo = UserInfoDto.fromJson(response.data!);
        return ApiResponse.success(userInfo, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('更新用户信息异常: $e');
      return ApiResponse<UserInfoDto>.error('更新用户信息失败: $e');
    }
  }

  /// 修改密码
  static Future<ApiResponse<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _httpClient.put<Map<String, dynamic>>(
        '/user/password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      if (response.success && response.code == 200) {
        return ApiResponse.success(null, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('修改密码异常: $e');
      return ApiResponse<void>.error('修改密码失败: $e');
    }
  }

  /// 上传头像
  static Future<ApiResponse<String>> uploadAvatar(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'avatar.jpg',
        ),
      });

      final response = await _httpClient.upload<Map<String, dynamic>>(
        '/user/avatar',
        formData,
        onSendProgress: (sent, total) {
          print('上传进度: ${(sent / total * 100).toStringAsFixed(1)}%');
        },
      );

      if (response.success && response.code == 200 && response.data != null) {
        final avatarUrl = response.data!['url'] as String;
        return ApiResponse.success(avatarUrl, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('上传头像异常: $e');
      return ApiResponse<String>.error('上传头像失败: $e');
    }
  }
}