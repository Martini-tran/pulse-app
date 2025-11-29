adb connect 192.168.31.222:5555


# 设置中国源
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
set PUB_HOSTED_URL=https://pub.flutter-io.cn

$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"

# 完整修复步骤

更新 build.gradle.kts（使用上面提供的配置）
清理项目：

bashflutter clean
cd android
./gradlew clean

重新构建：

bashflutter pub get
flutter build apk --debug
⚠️ 如果仍有问题
如果升级到 API 35 后还有其他问题，可以尝试：

检查 Flutter 插件兼容性：

bashflutter pub deps

更新 Flutter 和 Dart：

bashflutter upgrade