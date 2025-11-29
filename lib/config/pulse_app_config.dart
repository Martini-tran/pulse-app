class PulseAppConfig {
  /**
   * appName
   */
  final String appName;

  /**
   * 版本
   */
  final String version;

  /**
   * 是否为debug
   */
  final bool debugMode;

  /**
   * 其他的一些配置
   */
  final Map<String, dynamic> settings;


  const PulseAppConfig({
    required this.appName,
    required this.version,
    this.debugMode = false,
    this.settings = const {},
  });

  
  PulseAppConfig copyWith({
    String? appName,
    String? version,
    bool? debugMode,
    Map<String, dynamic>? settings,
  }) {
    return PulseAppConfig(
      appName: appName ?? this.appName,
      version: version ?? this.version,
      debugMode: debugMode ?? this.debugMode,
      settings: settings ?? this.settings,
    );
  }
}
