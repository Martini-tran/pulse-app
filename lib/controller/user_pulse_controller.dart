import 'package:flutter/material.dart';

import '../domain/pulse_user.dart';
import '../framework/abstract/pulse_base_view_model.dart';
import '../framework/store/pulse_action.dart';
import '../service/user_service.dart';

class UserPulseController extends PulseBaseViewModel {
  // 用户服务
  final UserService _userService = UserService();

  @override
  void onInit() {
    super.onInit();
    loadUserInfo();
  }

  // 加载用户信息
  Future<void> loadUserInfo() async {
    await pulseCall(() async {
      final user = await _userService.getCurrentUser();
      dispatch(UpdateUserAction(user));
    }, errorMessage: '加载用户信息失败');
  }

  // 更新用户信息
  Future<void> updateUserInfo(PulseUser user) async {
    await pulseCall(() async {
      final updatedUser = await _userService.updateUser(user);
      dispatch(UpdateUserAction(updatedUser));
    }, errorMessage: '更新用户信息失败');
  }

  // 登出
  Future<void> logout() async {
    await pulseCall(() async {
      await _userService.logout();
      dispatch(const ClearUserAction());
    }, errorMessage: '登出失败');
  }

  // 切换主题
  void changeTheme(ThemeData theme) {
    dispatch(UpdateThemeAction(theme));
  }

  // 切换语言
  void changeLocale(Locale locale) {
    dispatch(UpdateLocaleAction(locale));
  }
}