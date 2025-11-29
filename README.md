# Pulse App (轻刻)

一款基于 Flutter 开发的健康与生活管理应用，帮助用户追踪饮食、运动、任务和营养，并提供 AI 智能助手功能。

## 功能特性

### 核心功能
- **饮食追踪** - 记录每日三餐，追踪卡路里和营养摄入
- **运动管理** - 记录运动数据，监测健康指标
- **任务管理** - 创建和管理日常任务，追踪完成情况
- **AI 助手** - 基于 WebSocket 的实时 AI 聊天，提供健康指导
- **用户档案** - 个人信息管理、成就系统、数据统计

### 技术亮点
- 响应式设计，支持多种屏幕尺寸
- 深色/浅色主题切换
- 本地数据持久化
- 安全的 Token 管理

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.x / Dart ^3.8.1 |
| 状态管理 | Riverpod / Redux |
| 路由 | Go Router |
| 网络请求 | Dio |
| 本地存储 | Hive / Shared Preferences / Secure Storage |
| UI 组件 | Shadcn UI / ForUI / GetWidget |
| 图表 | FL Chart / Syncfusion Charts |
| 动画 | Lottie / Flutter Animate |

## 项目结构

```
lib/
├── api/                 # API 服务层
├── config/              # 配置管理
├── controller/          # 业务逻辑控制器
├── domain/              # 领域模型
├── framework/           # 核心框架
│   ├── adapter/         # 设备适配
│   ├── logger/          # 日志系统
│   ├── storage/         # 数据持久化
│   └── store/           # 状态管理
├── models/              # 数据模型
├── presentation/        # UI 层
│   ├── ai/              # AI 聊天功能
│   ├── pages/           # 页面
│   └── widgets/         # 可复用组件
├── router/              # 路由配置
├── service/             # 服务层
├── util/                # 工具类
├── app.dart             # 根组件
└── main.dart            # 入口文件
```

## 快速开始

### 环境要求

- Flutter SDK >= 3.8.0
- Dart SDK >= 3.8.1
- Android Studio / VS Code
- Android SDK (Android 开发)
- Xcode (iOS 开发，仅限 macOS)

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd pulse-app
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   # 开发环境
   flutter run

   # 指定环境运行
   flutter run --dart-define=ENVIRONMENT=development
   ```

### 中国用户配置镜像源

```bash
# Windows CMD
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
set PUB_HOSTED_URL=https://pub.flutter-io.cn

# Windows PowerShell
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"

# macOS / Linux
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PUB_HOSTED_URL=https://pub.flutter-io.cn
```

## 构建发布

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release --dart-define=ENVIRONMENT=production

# App Bundle (推荐用于 Google Play)
flutter build appbundle --release --dart-define=ENVIRONMENT=production
```

### iOS

```bash
flutter build ios --release --dart-define=ENVIRONMENT=production
```

### 清理项目

```bash
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
```

## 环境配置

应用支持三种运行环境：

| 环境 | API 地址 | 日志 | 超时时间 |
|------|---------|------|---------|
| Development | http://127.0.0.1:10801/pulse | 开启 | 15s |
| Staging | http://test-api.yourcompany.com/pulse | 开启 | 30s |
| Production | https://api.yourcompany.com/pulse | 关闭 | 30s |

详细配置说明请参考 [docs/ENVIRONMENT_CONFIG.md](docs/ENVIRONMENT_CONFIG.md)

## 常用命令

```bash
# 检查依赖
flutter pub deps

# 代码分析
dart analyze

# 更新 Flutter
flutter upgrade

# 生成图标
flutter pub run flutter_launcher_icons

# 生成启动页
flutter pub run flutter_native_splash:create
```

## 项目信息

- **版本**: 1.0.0+1
- **Dart SDK**: ^3.8.1
- **支持平台**: Android, iOS

## 相关项目

- **后端服务**: [https://github.com/Martini-tran/pulse.git](https://github.com/Martini-tran/pulse.git)

## 社区交流

- **QQ 群**: 923901004

## 许可证

[MIT License](LICENSE)
