import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdaptiveConfig {
  // 设计稿配置
  static const double designWidth = 375.0;
  static const double designHeight = 812.0;

  // 字体大小配置
  static const Map<String, double> fontSizes = {
    'small': 12.0,
    'normal': 14.0,
    'medium': 16.0,
    'large': 18.0,
    'xlarge': 20.0,
    'xxlarge': 24.0,
  };

  // 间距配置
  static const Map<String, double> spacings = {
    'xs': 4.0,
    'sm': 8.0,
    'md': 16.0,
    'lg': 24.0,
    'xl': 32.0,
    'xxl': 48.0,
  };

  // 圆角配置
  static const Map<String, double> borderRadius = {
    'small': 4.0,
    'medium': 8.0,
    'large': 12.0,
    'xlarge': 16.0,
  };

  // 获取适配后的字体大小
  static double fontSize(String key) {
    return (fontSizes[key] ?? 14.0).sp;
  }

  // 获取适配后的间距
  static double spacing(String key) {
    return (spacings[key] ?? 16.0).w;
  }

  // 获取适配后的圆角
  static double radius(String key) {
    return (borderRadius[key] ?? 8.0).w;
  }
}

