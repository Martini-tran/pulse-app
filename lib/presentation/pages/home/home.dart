import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../framework/adapter/adaptive_extension.dart';
import '../../widgets/task_list_widget.dart';
import '../chat/ai_chat_page.dart';

// 新增的第三方组件

import '../../../framework/logger/pulse_logger.dart';
import '../../../framework/adapter/device_adapter.dart';
import '../../../framework/storage/user_storage.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  final logger = PulseLogger();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeviceAdapter.init(context);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark

          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(12.h),
                  _buildCompactHeader(isDark),
                  Gap(16.h),
                  _buildAIInsightCard(isDark),
                  Gap(16.h),
                  TaskListWidget(isDark: isDark),
                  Gap(80.h),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildCompactBottomNav(isDark),
    );
  }

  Widget _buildCompactHeader(bool isDark) {
    return Row(

      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getGreetingIcon(),
                  color: isDark ? Colors.amber[300] : Colors.orange[600],
                  size: 14.w,
                ),
                Gap(4.w),
                AutoSizeText(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
            Gap(2.h),
            AutoSizeText(
              UserStorage.username ?? "未登录",
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
            Gap(2.h),
            AutoSizeText(
              "目标：减脂 · 智能饮食 + 训练计划",
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              maxLines: 1,
              minFontSize: 9,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAIInsightCard(bool isDark) {

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF1F1F1F), const Color(0xFF2A2A2A)]
            : [Colors.white, const Color(0xFFFAFBFF)],
        ),
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : const Color(0xFF667EEA).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.w),
        child: Stack(
          children: [
            // 背景装饰图案
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF667EEA).withOpacity(0.1),
                      const Color(0xFF667EEA).withOpacity(0.03),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头部区域
                  Row(
                    children: [
                      // 左侧图标容器
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: Colors.grey[200], // 浅灰背景
                          borderRadius: BorderRadius.circular(8.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.psychology_outlined,
                          color: Colors.black87, // 深色图标
                          size: 18.w,
                        ),
                      ),

                      Gap(12.w),

                      // 中间文字（字体缩小）
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              "AI健康顾问",
                              style: TextStyle(
                                fontSize: 14.sp, // 从 16.sp 改成 14.sp
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      // 右侧按钮（整体更小）
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h), // 缩小 padding
                        decoration: BoxDecoration(
                          color: Colors.grey[200], // 用浅灰背景，简约风格
                          borderRadius: BorderRadius.circular(16.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AIChatPage()),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                color: const Color(0xFF667EEA), // 蓝紫色点缀
                                size: 12.w,
                              ),
                              Gap(3.w),
                              AutoSizeText(
                                "咨询",
                                style: TextStyle(
                                  color: const Color(0xFF667EEA), // 和图标统一
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  Gap(16.h),
                  // 今日建议区域
                  Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: const Color(0xFFFF9800),
                              size: 16.w,
                            ),
                            Gap(6.w),
                            AutoSizeText(
                              "今日建议",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                        Gap(8.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRecommendationChip(
                                "🥚 增加蛋白质",
                                "每餐+20g",
                                const Color(0xFF4CAF50),
                                isDark,
                              ),
                            ),
                            Gap(8.w),
                            Expanded(
                              child: _buildRecommendationChip(
                                "💧 多喝水",
                                "目标2.5L",
                                const Color(0xFF2196F3),
                                isDark,
                              ),
                            ),
                          ],
                        ),
                        Gap(8.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRecommendationChip(
                                "🚶‍♂️ 饭后散步",
                                "15-20分钟",
                                const Color(0xFFFF9800),
                                isDark,
                              ),
                            ),
                            Gap(8.w),
                            Expanded(
                              child: _buildRecommendationChip(
                                "😴 早点休息",
                                "23:00前",
                                const Color(0xFF9C27B0),
                                isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Gap(12.h),
                  // 主要分析内容
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF667EEA).withOpacity(0.08),
                          const Color(0xFF764BA2).withOpacity(0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.w),
                      border: Border.all(
                        color: const Color(0xFF667EEA).withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: const Color(0xFF4CAF50),
                              size: 16.w,
                            ),
                            Gap(6.w),
                            AutoSizeText(
                              "减脂进展良好",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4CAF50),
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                        Gap(8.h),
                        AutoSizeText(
                          "恭喜！第3天开始掉秤，从105kg→104kg！前两天是身体适应期，现在正式进入减脂通道。您的饮食控制很棒，建议继续保持当前结构。",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF2D3748),
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 4,
                          minFontSize: 10,
                        ),
                      ],
                    ),
                  ),
                  Gap(12.h),
                ],
              ),
            ),

          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildRecommendationChip(String title, String subtitle, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.w),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF2D3748),
            ),
            maxLines: 1,
            minFontSize: 9,
          ),
          Gap(2.h),
          AutoSizeText(
            subtitle,
            style: TextStyle(
              fontSize: 9.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            minFontSize: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBottomNav(bool isDark) {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, "首页", true, isDark, () {}),
            _buildNavItem(
              Icons.restaurant_menu,
              "饮食",
              false,
              isDark,
              () => context.push('/diet'),
            ),
            _buildNavItem(Icons.tune, "定制", false, isDark, () => context.push('/customize')),
            _buildNavItem(Icons.directions_run, "运动", false, isDark, () {context.push('/sport');}),
            _buildNavItem(Icons.person, "我的", false, isDark, () {context.push('/profile');}),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isSelected,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF667EEA) : Colors.grey[500],
            size: 20.w,
          ),
          Gap(2.h),
          AutoSizeText(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: isSelected ? const Color(0xFF667EEA) : Colors.grey[500],
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '早上好';
    if (hour >= 12 && hour < 18) return '下午好';
    if (hour >= 18 && hour < 22) return '晚上好';
    return '夜深了';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return Icons.wb_sunny_outlined;
    if (hour >= 12 && hour < 18) return Icons.wb_sunny;
    if (hour >= 18 && hour < 22) return Icons.nights_stay_outlined;
    return Icons.bedtime_outlined;
  }
}
