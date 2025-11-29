import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

class ToastUtils {
  // 成功提示
  static void success(String message) {
    showToast(
      message,
      backgroundColor: Color(0xFFECFDF5),
      textStyle: TextStyle(
        color: Color(0xFF059669),
        letterSpacing: 1.2,
        fontSize: 14,
      ),
      position: ToastPosition.top,
      duration: Duration(seconds: 2),
    );
  }

  // 错误提示
  static void error(String message) {
    showToast(
      message,
      backgroundColor: Color(0xFFFEF2F2),
      textStyle: TextStyle(
        color: Color(0xFFDC2626),
        letterSpacing: 1.2,
        fontSize: 14,
      ),
      position: ToastPosition.top,
      duration: Duration(seconds: 2),
    );
  }

  // 警告提示
  static void warning(String message) {
    showToast(
      message,
      backgroundColor: Color(0xFFFFFBEB),
      textStyle: TextStyle(
        color: Color(0xFFD97706),
        letterSpacing: 1.2,
        fontSize: 14,
      ),
      position: ToastPosition.top,
      duration: Duration(seconds: 2),
    );
  }
}
