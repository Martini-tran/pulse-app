import 'package:flutter/cupertino.dart';
import 'package:pulse_app/framework/store/pulse_provider.dart';
import 'package:pulse_app/framework/store/pulse_state.dart';

import '../abstract/pulse_base_view_model.dart';

/**
 * Pulse状态构建器Widget
 */
class PulseBuilder<T extends PulseBaseViewModel> extends StatelessWidget {
  final Widget Function(BuildContext context, PulseState state, T viewModel) builder;
  final T? viewModel;

  const PulseBuilder({
    Key? key,
    required this.builder,
    this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = viewModel ?? PulseProvider.of<T>(context);

    return StreamBuilder<PulseState>(
      stream: vm.stateStream,
      initialData: vm.currentState,
      builder: (context, snapshot) {
        return builder(context, snapshot.data!, vm);
      },
    );
  }
}