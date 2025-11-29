// splash_page.dart
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../framework/storage/token_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double _progress = 0.0;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    if (_hasLoaded) return;
    _hasLoaded = true;

    // 模拟初始化进度到50%
    for (int i = 0; i <= 50; i++) {
      setState(() => _progress = i / 100.0);
      await Future.delayed(Duration(milliseconds: 20));
    }

    // 获取token
    String token = (await TokenStorage.getRefreshToken()) ?? '';

    // token获取完成，进度到100%
    for (int i = 51; i <= 100; i++) {
      setState(() => _progress = i / 100.0);
      await Future.delayed(Duration(milliseconds: 10));
    }

    // 延迟一点时间让用户看到100%
    await Future.delayed(Duration(milliseconds: 500));

    if (mounted) {
      if (token.isEmpty) {
        context.go('/login'); // 未登录跳转登录页
      } else {
        // context.go('/home'); // 已登录跳转主页
        context.go('/login'); // 已登录跳转主页
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 0.7.sw, // sw = screen width
          child : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    '轻刻',
                    textStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    speed: Duration(milliseconds: 30),
                  ),
                  TypewriterAnimatedText(
                    '减重有AI，身轻有爱',
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    speed: Duration(milliseconds: 120),
                  ),
                ],
                totalRepeatCount: 1, // 重复次数，设为无限可以用 repeatForever: true
                pause: Duration(milliseconds: 100),
                displayFullTextOnTap: true,
                stopPauseOnTap: true,
                isRepeatingAnimation: false,
              ),
              SizedBox(height: 10),
              FProgress(
                value: _progress, // 绑定进度值
                semanticsLabel: 'Loading',
              ),
            ],
          )
        ),
      ),
    );
  }
}
