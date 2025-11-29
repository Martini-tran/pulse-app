import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:shadcn_ui/shadcn_ui.dart'; // 添加 shadcn_ui 导入

import 'controller/user_pulse_controller.dart';
import 'framework/adapter/device_adapter.dart';
import 'framework/store/pulse_provider.dart';
import 'router/app_router.dart';

/**
 * 应用启动页
 */
class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PulseProvider<UserPulseController>(
      viewModel: UserPulseController(),
      child: OKToast(
        child: ShadApp.router(
          // 使用 ShadApp.router 替代 MaterialApp.router
          title: '轻刻',
          // 配置浅色主题
          theme: ShadThemeData(
            brightness: Brightness.light,
            colorScheme: const ShadSlateColorScheme.light(), // 使用 slate 浅色主题
          ),
          // 配置深色主题
          darkTheme: ShadThemeData(
            brightness: Brightness.dark,
            colorScheme: const ShadSlateColorScheme.dark(), // 使用 slate 深色主题
          ),
          // 主题模式，可以设置为 system 跟随系统
          themeMode: ThemeMode.system,
          builder: (context, child) {
            // 初始化自定义适配器
            DeviceAdapter.init(context);
            ScreenUtil.init(
              context,
              designSize: Size(375, 812), // 设计稿的尺寸（单位 dp）
              minTextAdapt: true, // 是否根据系统字体缩放来缩放文字
              splitScreenMode: true, // 是否支持分屏模式
            );
            return MediaQuery(data: MediaQuery.of(context), child: child!);
          },
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}