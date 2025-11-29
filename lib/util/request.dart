import 'dart:async';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:pulse_app/framework/storage/token_storage.dart';
import 'package:pulse_app/config/app_config.dart';

// 移除 dart:io 导入
// import 'dart:io'; // 这个在Web端不可用

// 添加平台检测
import 'package:flutter/foundation.dart' show kIsWeb;

import '../framework/logger/pulse_logger.dart';

/// 网络请求状态枚举
enum NetworkStatus { success, error, timeout, cancel, noNetwork }

/// 统一响应结果封装
class ApiResponse<T> {
  final bool success;
  final int code;
  final String message;
  final T? data;
  final NetworkStatus status;
  final Map<String, List<String>>? headers;

  ApiResponse({
    required this.success,
    required this.code,
    required this.message,
    this.data,
    required this.status,
    this.headers,
  });

  factory ApiResponse.success(
    T data, {
    String message = 'success',
    Map<String, List<String>>? headers,
  }) {
    return ApiResponse(
      success: true,
      code: 200,
      message: message,
      data: data,
      status: NetworkStatus.success,
      headers: headers,
    );
  }

  factory ApiResponse.error(
    String message, {
    int code = -1,
    Map<String, List<String>>? headers,
  }) {
    return ApiResponse(
      success: false,
      code: code,
      message: message,
      status: NetworkStatus.error,
      headers: headers,
    );
  }

  /// 获取指定header的值
  String? getHeader(String key) {
    final values = headers?[key.toLowerCase()];
    return values?.isNotEmpty == true ? values!.first : null;
  }

  /// 获取指定header的所有值
  List<String>? getHeaders(String key) {
    return headers?[key.toLowerCase()];
  }

  /// 检查是否包含指定header
  bool hasHeader(String key) {
    return headers?.containsKey(key.toLowerCase()) == true;
  }

  /// 获取Content-Type
  String? get contentType => getHeader('content-type');

  /// 获取Content-Length
  int? get contentLength {
    final length = getHeader('content-length');
    return length != null ? int.tryParse(length) : null;
  }

  /// 获取ETag
  String? get etag => getHeader('etag');

  /// 获取Last-Modified
  String? get lastModified => getHeader('last-modified');

  /// 获取access_token token（从响应头中）
  String? get authorization => getHeader('access_token');

  /// 获取Set-Cookie
  List<String>? get setCookie => getHeaders('set-cookie');
}

/// 企业级HTTP客户端工具类
class HttpClient {
  static HttpClient? _instance;
  late Dio _dio;

  // 私有构造函数
  HttpClient._internal() {
    _dio = Dio();
    _initConfig();
    _initInterceptors();
  }

  // 单例模式
  static HttpClient get instance {
    return _instance ??= HttpClient._internal();
  }

  /// 初始化基础配置
  void _initConfig() {
    _dio.options = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
    );
    
    // 打印配置信息（仅在非生产环境）
    if (AppConfig.enableLogging) {
      AppConfig.printConfig();
    }
  }



  /// 初始化拦截器
  void _initInterceptors() {
    // 请求拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 添加token
          final token = _getAuthToken();
          if (token.isNotEmpty) {
            options.headers['access_token'] = '$token';
          }

          // 添加设备信息 - Web端兼容处理
          options.headers['User-Agent'] = _getUserAgent();
          options.headers['Device-ID'] = _getDeviceId();

          handler.next(options);
        },
        onResponse: (response, handler) {
          // 统一处理响应
          _handleResponse(response);
          handler.next(response);
        },
        onError: (error, handler) {
          // 统一处理错误
          _handleError(error);
          handler.next(error);
        },
      ),
    );

    // 日志拦截器（仅在debug模式下启用）
    if (AppConfig.enableLogging) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    // 放在 HttpClient 类里
    Future<void>? _refreshingFuture;

    /// Token过期重试拦截器（刷新去重 + 走 onRequest 重新注入新 token）
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (error, handler) async {
          // 非 401 直接透传
          if (error.response?.statusCode != 401) {
            handler.next(error);
            return;
          }

          final original = error.requestOptions;

          try {
            // 如果当前没有在刷新，发起一次刷新；有的话，直接等它完成
            _refreshingFuture ??= _refreshToken()
                .then((ok) {
                  if (!ok) throw Exception('refresh token failed');
                })
                .whenComplete(() {
                  // 刷新结束后无论成功失败都清空句柄
                  _refreshingFuture = null;
                });

            // 等待刷新结果
            await _refreshingFuture;

            // 刷新成功：重发原请求 —— 用 request 保证会走 onRequest 拦截器
            final response = await _dio.request(
              original.path,
              data: original.data,
              queryParameters: original.queryParameters,
              options: Options(
                method: original.method,
                // 移除旧的 access_token 头，让 onRequest 注入最新的
                headers: Map<String, dynamic>.from(original.headers)
                  ..remove('access_token')
                  ..remove('Authorization'),
                responseType: original.responseType,
                contentType: original.contentType,
                followRedirects: original.followRedirects,
                receiveDataWhenStatusError: original.receiveDataWhenStatusError,
                extra: original.extra,
              ),
              cancelToken: original.cancelToken,
              onSendProgress: original.onSendProgress,
              onReceiveProgress: original.onReceiveProgress,
            );

            handler.resolve(response);
          } catch (e) {
            // 刷新失败或重试失败：把原错误抛回去（或在此返回统一未登录错误）
            handler.next(error);
          }
        },
      ),
    );
  }

  /// 获取认证token
  String _getAuthToken() {
    return TokenStorage.cachedAccessToken ?? '';
  }

  /// 获取用户代理信息 - Web端兼容处理
  String _getUserAgent() {
    if (kIsWeb) {
      // Web端使用浏览器信息
      return 'MyApp/1.0.0 (Web)';
    } else {
      // 移动端需要动态导入dart:io
      try {
        // 使用条件导入或者返回默认值
        return 'MyApp/1.0.0 (Mobile)';
      } catch (e) {
        return 'MyApp/1.0.0 (Unknown)';
      }
    }
  }

  /// 获取设备ID - Web端兼容处理
  String _getDeviceId() {
    if (kIsWeb) {
      // Web端可以使用sessionStorage或localStorage生成设备ID
      return _generateWebDeviceId();
    } else {
      // 移动端获取设备唯一标识
      return 'mobile_device_id_here';
    }
  }

  /// Web端生成设备ID
  String _generateWebDeviceId() {
    // 可以结合浏览器指纹、时间戳等生成唯一ID
    // 这里简化处理，实际项目中可以使用更复杂的算法
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString();
    return 'web_device_$random';
  }

  /// 处理响应
  void _handleResponse(Response response) {
    // 可以在这里做统一的响应处理
    // 比如埋点、日志记录等
  }

  /// 处理错误
  void _handleError(DioException error) {
    // 统一错误处理
    // 比如错误上报、用户提示等
    if (kIsWeb) {
      // Web端错误处理
      print('Web Network Error: ${error.message}');
    } else {
      // 移动端错误处理
      print('Mobile Network Error: ${error.message}');
    }
  }

  bool _isRefreshing = false;
  List<Completer<bool>> _refreshQueue = [];

  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      final completer = Completer<bool>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) {
        await TokenStorage.clearTokens();
        return false;
      }

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'access_token': null}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await TokenStorage.saveTokens(
          data['access_token'],
          data['refresh_token'] ?? refreshToken, // 如果服务端不返回新refresh_token则保持原有
        );

        // 通知队列中的请求
        _refreshQueue.forEach((completer) => completer.complete(true));
        _refreshQueue.clear();

        return true;
      }

      await TokenStorage.clearTokens();
      return false;
    } catch (e) {
      await TokenStorage.clearTokens();
      _refreshQueue.forEach((completer) => completer.complete(false));
      _refreshQueue.clear();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// GET请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleSuccessResponse<T>(response);
    } catch (e) {
      return _handleErrorResponse<T>(e);
    }
  }

  /// POST请求
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleSuccessResponse<T>(response);
    } catch (e) {
      return _handleErrorResponse<T>(e);
    }
  }

  /// PUT请求
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleSuccessResponse<T>(response);
    } catch (e) {
      return _handleErrorResponse<T>(e);
    }
  }

  /// DELETE请求
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleSuccessResponse<T>(response);
    } catch (e) {
      return _handleErrorResponse<T>(e);
    }
  }

  /// 上传文件 - Web端兼容处理
  Future<ApiResponse<T>> upload<T>(
    String path,
    FormData formData, {
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      return _handleSuccessResponse<T>(response);
    } catch (e) {
      return _handleErrorResponse<T>(e);
    }
  }

  /// 下载文件 - Web端需要特殊处理
  Future<ApiResponse<String>> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      if (kIsWeb) {
        // Web端下载处理
        return _downloadForWeb(
          urlPath,
          savePath,
          onReceiveProgress,
          cancelToken,
        );
      } else {
        // 移动端下载处理
        final response = await _dio.download(
          urlPath,
          savePath,
          onReceiveProgress: onReceiveProgress,
          cancelToken: cancelToken,
        );
        return ApiResponse.success(
          savePath,
          message: '下载成功',
          headers: response.headers.map,
        );
      }
    } catch (e) {
      return _handleErrorResponse<String>(e);
    }
  }

  /// Web端下载文件处理
  Future<ApiResponse<String>> _downloadForWeb(
    String urlPath,
    String savePath,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  ) async {
    try {
      // Web端下载文件，获取二进制数据
      final response = await _dio.get(
        urlPath,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );

      // 在Web端，通常是触发浏览器下载
      // 这里返回成功状态，实际的文件下载由浏览器处理
      return ApiResponse.success(
        'Web下载已触发',
        message: 'Web端下载成功',
        headers: response.headers.map,
      );
    } catch (e) {
      return _handleErrorResponse<String>(e);
    }
  }

  /// 处理成功响应（改进版本）
  ApiResponse<T> _handleSuccessResponse<T>(Response response) {
    try {
      final data = response.data;
      final headers = response.headers.map;

      // 添加调试日志
      print('原始响应数据: $data');
      print('响应状态码: ${response.statusCode}');
      print('响应类型: ${data.runtimeType}');

      // 处理null或空数据
      if (data == null) {
        return ApiResponse.error(
          '响应数据为空',
          code: response.statusCode as int,
          headers: headers,
        );
      }

      // 根据后端API设计调整
      if (data is Map<String, dynamic>) {
        final code = data['code'] ?? response.statusCode;
        final message = data['message'] ?? 'success';
        final result = data['data']; // 这里可能是null

        print('解析后 - code: $code, message: $message, result: $result');

        if (code == 200) {
          // 处理result为null的情况
          if (result == null) {
            // 根据业务需要决定是否允许null数据
            return ApiResponse(
              data: null, // 或者 result as T?
              success: true,
              code: code,
              message: message,
              status: NetworkStatus.success,
              headers: headers,
            );
          }

          return ApiResponse(
            data: result as T, // 确保类型转换正确
            success: true,
            code: code,
            message: message,
            status: NetworkStatus.success,
            headers: headers,
          );
        } else {
          return ApiResponse.error(message, code: code, headers: headers);
        }
      }

      // 直接返回原始数据
      return ApiResponse.success(data as T, headers: headers);
    } catch (e, stackTrace) {
      print('处理响应时发生错误: $e');
      print('堆栈跟踪: $stackTrace');
      return ApiResponse.error('响应处理失败: $e', code: response.statusCode as int);
    }
  }

  /// 处理错误响应
  ApiResponse<T> _handleErrorResponse<T>(dynamic error) {
    Map<String, List<String>>? headers;

    if (error is DioException) {
      headers = error.response?.headers.map;

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiResponse(
            success: false,
            code: -1,
            message: '请求超时，请检查网络连接',
            status: NetworkStatus.timeout,
            headers: headers,
          );
        case DioExceptionType.cancel:
          return ApiResponse(
            success: false,
            code: -1,
            message: '请求已取消',
            status: NetworkStatus.cancel,
            headers: headers,
          );
        case DioExceptionType.connectionError:
          return ApiResponse(
            success: false,
            code: -1,
            message: kIsWeb ? 'Web网络连接失败，请检查CORS设置' : '网络连接失败，请检查网络设置',
            status: NetworkStatus.noNetwork,
            headers: headers,
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? -1;
          String message = '服务器错误($statusCode)';

          // 根据状态码提供更友好的错误信息
          switch (statusCode) {
            case 400:
              message = '请求参数错误';
              break;
            case 401:
              message = '未授权，请重新登录';
              break;
            case 403:
              message = '禁止访问';
              break;
            case 404:
              message = '请求的资源不存在';
              break;
            case 500:
              message = '服务器内部错误';
              break;
            case 502:
              message = '网关错误';
              break;
            case 503:
              message = '服务不可用';
              break;
          }

          return ApiResponse(
            success: false,
            code: statusCode,
            message: message,
            status: NetworkStatus.error,
            headers: headers,
          );
        default:
          return ApiResponse(
            success: false,
            code: -1,
            message: error.message ?? '未知错误',
            status: NetworkStatus.error,
            headers: headers,
          );
      }
    }

    return ApiResponse(
      success: false,
      code: -1,
      message: error.toString(),
      status: NetworkStatus.error,
    );
  }

  /// 设置基础URL
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  /// 设置超时时间
  void setTimeout({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    if (connectTimeout != null) {
      _dio.options.connectTimeout = connectTimeout;
    }
    if (receiveTimeout != null) {
      _dio.options.receiveTimeout = receiveTimeout;
    }
    if (sendTimeout != null) {
      _dio.options.sendTimeout = sendTimeout;
    }
  }

  /// 添加请求头
  void addHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  /// 移除请求头
  void removeHeader(String key) {
    _dio.options.headers.remove(key);
  }

  /// 清除请求头
  void clearHeaders() {
    _dio.options.headers.clear();
  }
}
