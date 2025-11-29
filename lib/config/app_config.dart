/// 应用配置管理类
class AppConfig {
  // 私有构造函数
  AppConfig._();
  
  /// 当前环境
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  /// 是否为生产环境
  static bool get isProduction => _environment == 'production';
  
  /// 是否为测试环境
  static bool get isStaging => _environment == 'staging';
  
  /// 是否为开发环境
  static bool get isDevelopment => _environment == 'development';
  
  /// API基础URL配置
  static const Map<String, String> _apiBaseUrls = {
    'development': 'http://127.0.0.1:10801/pulse',
    'staging': 'http://test-api.yourcompany.com/pulse',
    'production': 'https://api.yourcompany.com/pulse',
  };
  
  /// 获取当前环境的API基础URL
  static String get apiBaseUrl {
    return _apiBaseUrls[_environment] ?? _apiBaseUrls['development']!;
  }
  
  /// 网络超时配置
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
  
  /// 是否启用日志
  static bool get enableLogging => !isProduction;
  
  /// 应用版本
  static const String appVersion = '1.0.0';
  
  /// 调试信息
  static void printConfig() {
    print('=== App Configuration ===');
    print('Environment: $_environment');
    print('API Base URL: $apiBaseUrl');
    print('Is Production: $isProduction');
    print('Enable Logging: $enableLogging');
    print('========================');
  }
}