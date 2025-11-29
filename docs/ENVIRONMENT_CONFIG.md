# 环境配置说明

## 概述

本项目使用环境变量来管理不同环境的配置，包括API地址、超时设置等。

## 配置文件结构

```
lib/config/
├── app_config.dart          # 主配置管理类
└── environment_config.dart  # 环境配置示例
```

## 使用方法

### 1. 开发环境（默认）
```bash
flutter run
# 或
flutter run --dart-define=ENVIRONMENT=development
```

### 2. 测试环境
```bash
flutter run --dart-define=ENVIRONMENT=staging
```

### 3. 生产环境
```bash
flutter run --dart-define=ENVIRONMENT=production
```

### 4. 构建生产版本
```bash
# Android
flutter build apk --dart-define=ENVIRONMENT=production

# iOS
flutter build ios --dart-define=ENVIRONMENT=production

# Web
flutter build web --dart-define=ENVIRONMENT=production
```

## 配置项说明

| 环境 | API地址 | 日志 | 超时时间 |
|------|---------|------|----------|
| development | http://127.0.0.1:10801/pulse | 启用 | 15秒 |
| staging | http://test-api.yourcompany.com/pulse | 启用 | 30秒 |
| production | https://api.yourcompany.com/pulse | 禁用 | 30秒 |

## 自定义配置

### 修改API地址

编辑 `lib/config/app_config.dart` 文件中的 `_apiBaseUrls` 映射：

```dart
static const Map<String, String> _apiBaseUrls = {
  'development': 'http://127.0.0.1:10801/pulse',
  'staging': 'http://your-staging-api.com/pulse',
  'production': 'https://your-production-api.com/pulse',
};
```

### 添加新的配置项

在 `AppConfig` 类中添加新的静态属性：

```dart
static const String appName = String.fromEnvironment(
  'APP_NAME',
  defaultValue: 'Pulse App',
);
```

## CI/CD 集成

### GitHub Actions 示例

```yaml
- name: Build APK
  run: flutter build apk --dart-define=ENVIRONMENT=production
```

### 环境变量文件

可以创建 `.env` 文件来管理环境变量（不要提交到版本控制）：

```bash
# .env.development
ENVIRONMENT=development
API_BASE_URL=http://127.0.0.1:10801/pulse

# .env.production
ENVIRONMENT=production
API_BASE_URL=https://api.yourcompany.com/pulse
```

## 安全注意事项

1. **不要在代码中硬编码敏感信息**（如API密钥、密码等）
2. **生产环境配置应该通过CI/CD系统注入**
3. **确保生产环境禁用调试日志**
4. **使用HTTPS协议进行生产环境通信**

## 故障排除

### 常见问题

1. **配置未生效**
   - 检查环境变量是否正确设置
   - 重新启动应用

2. **网络请求失败**
   - 检查API地址是否正确
   - 确认网络连接正常
   - 查看控制台日志

3. **构建失败**
   - 确保所有必需的环境变量都已设置
   - 检查配置文件语法是否正确