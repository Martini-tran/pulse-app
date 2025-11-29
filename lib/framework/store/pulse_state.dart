import 'package:flutter/material.dart';

import '../../config/pulse_app_config.dart';
import '../../domain/pulse_user.dart';

class PulseState {
  // 用户信息
  final PulseUser? userInfo;

  // 主题数据
  final ThemeData? themeData;

  // 本地化设置
  final Locale? locale;

  // 应用配置
  final PulseAppConfig? appConfig;

  // 加载状态
  final bool isLoading;

  // 错误信息
  final String? errorMessage;

  const PulseState({
    this.userInfo,
    this.themeData,
    this.locale,
    this.appConfig,
    this.isLoading = false,
    this.errorMessage,
  });

  // 创建副本方法
  PulseState copyWith({
    PulseUser? userInfo,
    ThemeData? themeData,
    Locale? locale,
    PulseAppConfig? appConfig,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PulseState(
      userInfo: userInfo ?? this.userInfo,
      themeData: themeData ?? this.themeData,
      locale: locale ?? this.locale,
      appConfig: appConfig ?? this.appConfig,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // 创建空状态
  factory PulseState.empty() {
    return const PulseState();
  }

  // 创建加载状态
  PulseState toLoading() {
    return copyWith(isLoading: true, errorMessage: null);
  }

  // 创建错误状态
  PulseState toError(String message) {
    return copyWith(isLoading: false, errorMessage: message);
  }

  // 创建成功状态
  PulseState toSuccess() {
    return copyWith(isLoading: false, errorMessage: null);
  }
}