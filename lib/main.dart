import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/user_api.dart';
import 'app.dart';
import 'framework/logger/pulse_logger.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

import 'framework/storage/token_storage.dart';
import 'framework/storage/user_storage.dart';
import 'framework/storage/task_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化日志
  PulseLogger().initialize(LoggerConfig.development());
  WidgetsFlutterBinding.ensureInitialized();
  await TokenStorage.initCache(); // 预加载token到内存
  await UserStorage.initCache(); // 预加载用户信息
  await TaskStorage.initCache(); // 预加载任务数据
  // 初始化网络
  runApp(
    ProviderScope(
      child: PulseApp(),
    ),
  );
}



