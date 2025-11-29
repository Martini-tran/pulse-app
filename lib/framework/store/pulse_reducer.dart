import 'package:pulse_app/framework/store/pulse_action.dart';
import 'package:pulse_app/framework/store/pulse_state.dart';

import '../../domain/pulse_user.dart';

/**
 * Pulse Reducer - 状态更新逻辑
 */
class PulseReducer {
  static PulseState reduce(PulseState state, PulseAction action) {
    switch (action.runtimeType) {
      case UpdateUserAction:
        final userAction = action as UpdateUserAction;
        return state.copyWith(userInfo: userAction.user);

      case ClearUserAction:
        return state.copyWith(userInfo: PulseUser.empty());

      case UpdateThemeAction:
        final themeAction = action as UpdateThemeAction;
        return state.copyWith(themeData: themeAction.themeData);

      case UpdateLocaleAction:
        final localeAction = action as UpdateLocaleAction;
        return state.copyWith(locale: localeAction.locale);

      case SetLoadingAction:
        final loadingAction = action as SetLoadingAction;
        return state.copyWith(isLoading: loadingAction.isLoading);

      case SetErrorAction:
        final errorAction = action as SetErrorAction;
        return state.toError(errorAction.message);

      default:
        return state;
    }
  }
}