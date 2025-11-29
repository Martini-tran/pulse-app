import 'package:flutter/cupertino.dart';

import '../abstract/pulse_base_view_model.dart';

/**
 * Pulse状态管理Widget
 */
class PulseProvider<T extends PulseBaseViewModel> extends StatefulWidget {
  final T viewModel;
  final Widget child;

  const PulseProvider({
    Key? key,
    required this.viewModel,
    required this.child,
  }) : super(key: key);

  @override
  State<PulseProvider<T>> createState() => _PulseProviderState<T>();

  // 静态方法获取ViewModel
  static T of<T extends PulseBaseViewModel>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<_InheritedPulseProvider<T>>();
    if (provider == null) {
      throw Exception('PulseProvider<$T> not found in context');
    }
    return provider.viewModel;
  }
}

class _PulseProviderState<T extends PulseBaseViewModel> extends State<PulseProvider<T>> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.onReady();
    });
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedPulseProvider<T>(
      viewModel: widget.viewModel,
      child: widget.child,
    );
  }
}

class _InheritedPulseProvider<T extends PulseBaseViewModel> extends InheritedWidget {
  final T viewModel;

  const _InheritedPulseProvider({
    required this.viewModel,
    required Widget child,
  }) : super(child: child);

  @override
  bool updateShouldNotify(_InheritedPulseProvider<T> oldWidget) {
    return viewModel != oldWidget.viewModel;
  }
}