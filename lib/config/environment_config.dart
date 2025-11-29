/// 环境配置示例
/// 
/// 使用方法：
/// 1. 开发环境：flutter run
/// 2. 测试环境：flutter run --dart-define=ENVIRONMENT=staging
/// 3. 生产环境：flutter run --dart-define=ENVIRONMENT=production
/// 
/// 或者在 build 时指定：
/// flutter build apk --dart-define=ENVIRONMENT=production

class EnvironmentConfig {
  /// 开发环境配置
  static const Map<String, dynamic> development = {
    'api_base_url': 'http://127.0.0.1:10801/pulse',
    'enable_logging': true,
    'debug_mode': true,
    'api_timeout': 15,
  };

  /// 测试环境配置
  static const Map<String, dynamic> staging = {
    'api_base_url': 'http://test-api.yourcompany.com/pulse',
    'enable_logging': true,
    'debug_mode': true,
    'api_timeout': 30,
  };

  /// 生产环境配置
  static const Map<String, dynamic> production = {
    // 'api_base_url': 'https://140.143.22.164/pulse',
    'api_base_url': 'http://127.0.0.1:10801/pulse',
    'enable_logging': false,
    'debug_mode': false,
    'api_timeout': 30,
  };

  /// 获取当前环境配置
  static Map<String, dynamic> get current {
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    
    switch (environment) {
      case 'staging':
        return staging;
      case 'production':
        return production;
      default:
        return development;
    }
  }
}