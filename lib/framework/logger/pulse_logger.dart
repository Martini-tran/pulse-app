import 'dart:io';

import 'package:logger/logger.dart';

// 日志配置类
class LoggerConfig {
  final Level level;
  final bool enabled;
  final bool enableColors;
  final bool enableEmojis;
  final int methodCount;
  final int errorMethodCount;
  final int lineLength;
  final bool enableFileOutput;
  final String? logFilePath;

  const LoggerConfig({
    this.level = Level.debug,
    this.enabled = true,
    this.enableColors = true,
    this.enableEmojis = true,
    this.methodCount = 2,
    this.errorMethodCount = 5,
    this.lineLength = 120,
    this.enableFileOutput = false,
    this.logFilePath,
  });

  // 从环境变量或配置文件创建配置
  factory LoggerConfig.fromEnvironment() {
    // 可以从环境变量读取配置
    const String envLevel = String.fromEnvironment('LOG_LEVEL', defaultValue: 'debug');
    const bool envEnabled = bool.fromEnvironment('LOG_ENABLED', defaultValue: true);

    Level level;
    switch (envLevel.toLowerCase()) {
      case 'trace':
        level = Level.trace;
        break;
      case 'debug':
        level = Level.debug;
        break;
      case 'info':
        level = Level.info;
        break;
      case 'warning':
        level = Level.warning;
        break;
      case 'error':
        level = Level.error;
        break;
      case 'fatal':
        level = Level.fatal;
        break;
      case 'off':
        level = Level.off;
        break;
      default:
        level = Level.debug;
    }

    return LoggerConfig(
      level: level,
      enabled: envEnabled,
      enableColors: const bool.fromEnvironment('LOG_COLORS', defaultValue: true),
      enableEmojis: const bool.fromEnvironment('LOG_EMOJIS', defaultValue: true),
      enableFileOutput: const bool.fromEnvironment('LOG_FILE_OUTPUT', defaultValue: false),
    );
  }

  // 开发环境配置
  factory LoggerConfig.development() {
    return const LoggerConfig(
      level: Level.debug,
      enabled: true,
      enableColors: true,
      enableEmojis: true,
      methodCount: 2,
      errorMethodCount: 5,
    );
  }

  // 生产环境配置
  factory LoggerConfig.production() {
    return const LoggerConfig(
      level: Level.warning,
      enabled: true,
      enableColors: false,
      enableEmojis: false,
      methodCount: 0,
      errorMethodCount: 3,
      enableFileOutput: true,
    );
  }

  // 测试环境配置
  factory LoggerConfig.test() {
    return const LoggerConfig(
      level: Level.off,
      enabled: false,
    );
  }
}

class PulseLogger {
  static final PulseLogger _instance = PulseLogger._internal();
  factory PulseLogger() => _instance;
  PulseLogger._internal();

  Logger? _logger;
  LoggerConfig? _config;

  // 初始化日志器
  void initialize(LoggerConfig config) {
    _config = config;

    if (!config.enabled) {
      _logger = null;
      return;
    }

    // 创建输出列表
    List<LogOutput> outputs = [ConsoleOutput()];

    // 如果启用文件输出
    if (config.enableFileOutput) {
      outputs.add(FileOutput(file: File(config.logFilePath ?? 'logs/app.log')));
    }

    _logger = Logger(
      level: config.level,
      printer: PrettyPrinter(
        methodCount: config.methodCount,
        errorMethodCount: config.errorMethodCount,
        lineLength: config.lineLength,
        colors: config.enableColors,
        printEmojis: config.enableEmojis,
      ),
      output: MultiOutput(outputs),
    );
  }

  // 检查日志级别是否启用
  bool _isLevelEnabled(Level level) {
    if (_logger == null || _config == null || !_config!.enabled) {
      return false;
    }
    return level.index >= _config!.level.index;
  }

  // 对外暴露的日志方法
  void trace(dynamic message) {
    if (_isLevelEnabled(Level.trace)) {
      _logger?.t(message);
    }
  }

  void debug(dynamic message) {
    if (_isLevelEnabled(Level.debug)) {
      _logger?.d(message);
    }
  }

  void info(dynamic message) {
    if (_isLevelEnabled(Level.info)) {
      _logger?.i(message);
    }
  }

  void warn(dynamic message) {
    if (_isLevelEnabled(Level.warning)) {
      _logger?.w(message);
    }
  }

  void error(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (_isLevelEnabled(Level.error)) {
      _logger?.e(message, error: error, stackTrace: stackTrace);
    }
  }

  void fatal(dynamic message, [Object? error, StackTrace? stackTrace]) {
    if (_isLevelEnabled(Level.fatal)) {
      _logger?.f(message, error: error, stackTrace: stackTrace);
    }
  }

  // 动态修改日志级别
  void setLevel(Level level) {
    if (_config != null) {
      _config = LoggerConfig(
        level: level,
        enabled: _config!.enabled,
        enableColors: _config!.enableColors,
        enableEmojis: _config!.enableEmojis,
        methodCount: _config!.methodCount,
        errorMethodCount: _config!.errorMethodCount,
        lineLength: _config!.lineLength,
        enableFileOutput: _config!.enableFileOutput,
        logFilePath: _config!.logFilePath,
      );
      initialize(_config!);
    }
  }

  // 启用/禁用日志
  void setEnabled(bool enabled) {
    if (_config != null) {
      _config = LoggerConfig(
        level: _config!.level,
        enabled: enabled,
        enableColors: _config!.enableColors,
        enableEmojis: _config!.enableEmojis,
        methodCount: _config!.methodCount,
        errorMethodCount: _config!.errorMethodCount,
        lineLength: _config!.lineLength,
        enableFileOutput: _config!.enableFileOutput,
        logFilePath: _config!.logFilePath,
      );
      initialize(_config!);
    }
  }

  // 获取当前配置
  LoggerConfig? get config => _config;
}

// void main() {
//   // 方式1: 使用预定义配置
//   PulseLogger().initialize(LoggerConfig.development());
//
//   // 方式2: 使用环境变量配置
//   // PulseLogger().initialize(LoggerConfig.fromEnvironment());
//
//   // 方式3: 自定义配置
//   // PulseLogger().initialize(LoggerConfig(
//   //   level: Level.info,
//   //   enabled: true,
//   //   enableFileOutput: true,
//   //   logFilePath: 'logs/my_app.log',
//   // ));
//
//   // 使用日志
//   final logger = PulseLogger();
//   logger.debug('这是调试信息');
//   logger.info('这是信息日志');
//   logger.warn('这是警告信息');
//   logger.error('这是错误信息');
//
//   // 动态修改配置
//   logger.setLevel(Level.warning); // 只显示警告及以上级别
//   logger.setEnabled(false); // 禁用所有日志
// }