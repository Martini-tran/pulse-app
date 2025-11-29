import 'package:flutter/material.dart';

import '../../domain/pulse_user.dart';

abstract class PulseAction {
  const PulseAction();
}

// 用户相关动作
class UpdateUserAction extends PulseAction {
  final PulseUser user;
  const UpdateUserAction(this.user);
}

class ClearUserAction extends PulseAction {
  const ClearUserAction();
}

// 主题相关动作
class UpdateThemeAction extends PulseAction {
  final ThemeData themeData;
  const UpdateThemeAction(this.themeData);
}

// 本地化相关动作
class UpdateLocaleAction extends PulseAction {
  final Locale locale;
  const UpdateLocaleAction(this.locale);
}

// 加载状态动作
class SetLoadingAction extends PulseAction {
  final bool isLoading;
  const SetLoadingAction(this.isLoading);
}

// 错误动作
class SetErrorAction extends PulseAction {
  final String message;
  const SetErrorAction(this.message);
}