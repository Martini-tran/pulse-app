import 'device_adapter.dart';
import 'device_type.dart';

extension AdaptiveExtension on num {
  // 宽度适配
  double get w {
    final screenWidth = DeviceAdapter.screenWidth;
    final designWidth = DeviceAdapter.designWidth;
    return this * screenWidth / designWidth;
  }

  // 高度适配
  double get h {
    final screenHeight = DeviceAdapter.screenHeight;
    final designHeight = DeviceAdapter.designHeight;
    return this * screenHeight / designHeight;
  }

  // 字体适配
  double get sp {
    final adapted = w;
    final deviceType = DeviceAdapter.phoneDeviceType;

    // 根据设备类型调整字体大小
    switch (deviceType) {
      case PhoneDeviceType.smallPhone:
        return (adapted * 0.9).clamp(10.0, 30.0);
      case PhoneDeviceType.largePhone:
        return (adapted * 1.05).clamp(12.0, 35.0);
      case PhoneDeviceType.tablet:
        return (adapted * 1.2).clamp(14.0, 40.0);
      case PhoneDeviceType.normalPhone:
      default:
        return adapted.clamp(11.0, 32.0);
    }
  }

  // 响应式适配
  double get responsive {
    final deviceType = DeviceAdapter.phoneDeviceType;
    switch (deviceType) {
      case PhoneDeviceType.tablet:
        return this * 1.5;
      case PhoneDeviceType.largePhone:
        return this * 1.2;
      case PhoneDeviceType.smallPhone:
        return this * 0.9;
      default:
        return this.toDouble();
    }
  }
}
