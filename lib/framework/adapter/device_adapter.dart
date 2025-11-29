import 'package:flutter/cupertino.dart';

import 'device_type.dart';

/**
 * 设备适配器
 */
class DeviceAdapter {

  /**
   *
   */
  static late MediaQueryData _mediaQuery;

  /**
   * 宽
   */
  static late double _designWidth;

  /**
   * 高
   */
  static late double _designHeight;

  // 初始化适配器
  static void init(
    BuildContext context, {
    double designWidth = 375.0,
    double designHeight = 812.0,
  }) {
    _mediaQuery = MediaQuery.of(context);
    _designWidth = designWidth;
    _designHeight = designHeight;
  }

  // 设备类型判断
  static PhoneDeviceType get phoneDeviceType {
    final screenWidth = _mediaQuery.size.width;
    final screenHeight = _mediaQuery.size.height;
    final shortestSide = _mediaQuery.size.shortestSide;

    if (shortestSide >= 600) {
      return PhoneDeviceType.tablet;
    } else if (shortestSide >= 414) {
      return PhoneDeviceType.largePhone;
    } else if (shortestSide <= 320) {
      return PhoneDeviceType.smallPhone;
    }
    return PhoneDeviceType.normalPhone;
  }

  // 是否为刘海屏
  static bool get hasNotch => _mediaQuery.padding.top > 24;

  // 状态栏高度
  static double get statusBarHeight => _mediaQuery.padding.top;

  // 底部安全区域高度
  static double get bottomSafeHeight => _mediaQuery.padding.bottom;

  // 屏幕宽度
  static double get screenWidth => _mediaQuery.size.width;

  // 屏幕高度
  static double get screenHeight => _mediaQuery.size.height;

  // 像素密度
  static double get pixelRatio => _mediaQuery.devicePixelRatio;


  static double get designWidth => _designWidth;

  static double get designHeight => _designHeight;

}
