import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../domain/pulse_user.dart';
import '../store/pulse_action.dart';
import '../store/pulse_reducer.dart';
import '../store/pulse_state.dart';

/**
 * Pulse基础ViewModel - 类似GSYBaseViewModel
 */
abstract class PulseBaseViewModel extends ChangeNotifier {


  // 状态流控制器
  final StreamController<PulseState> _stateController =
      StreamController<PulseState>.broadcast();

  // 当前状态
  PulseState _currentState = PulseState.empty();

  // 获取状态流
  Stream<PulseState> get stateStream => _stateController.stream;

  // 获取当前状态
  PulseState get currentState => _currentState;

  // 用户信息
  PulseUser? get userInfo => _currentState.userInfo;

  // 是否加载中
  bool get isLoading => _currentState.isLoading;

  // 错误信息
  String? get errorMessage => _currentState.errorMessage;

  // 分发动作
  void dispatch(PulseAction action) {
    final newState = PulseReducer.reduce(_currentState, action);
    _updateState(newState);
  }

  // 更新状态
  void _updateState(PulseState newState) {
    _currentState = newState;
    _stateController.add(newState);
    notifyListeners();
  }

  // 设置加载状态
  void setLoading(bool loading) {
    dispatch(SetLoadingAction(loading));
  }

  // 设置错误状态
  void setError(String message) {
    dispatch(SetErrorAction(message));
  }

  // 清除错误
  void clearError() {
    if (_currentState.errorMessage != null) {
      _updateState(_currentState.copyWith(errorMessage: null));
    }
  }

  // 异步操作包装器
  Future<T?> pulseCall<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) setLoading(true);
      final result = await operation();
      if (showLoading) setLoading(false);
      clearError();
      return result;
    } catch (e) {
      setError(errorMessage ?? e.toString());
      return null;
    }
  }

  // 生命周期方法
  void onInit() {}

  void onReady() {}

  void onClose() {}

  @override
  void dispose() {
    _stateController.close();
    onClose();
    super.dispose();
  }
}
