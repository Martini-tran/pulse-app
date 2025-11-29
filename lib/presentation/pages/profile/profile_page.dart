import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:gap/gap.dart';
import 'package:getwidget/getwidget.dart';
import '../../../framework/adapter/device_adapter.dart';
import '../../../framework/adapter/adaptive_extension.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
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
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
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
                  _buildHeader(isDark),
                  Gap(16.h),
                  _buildProfileCard(isDark),
                  Gap(12.h),
                  _buildStatsRow(isDark),
                  Gap(12.h),
                  _buildMenuSection(isDark),
                  Gap(12.h),
                  _buildSettingsSection(isDark),
                  Gap(80.h), // 底部导航栏空间
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(8.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black87,
              size: 14.w,
            ),
          ),
        ),
        Gap(12.w),
        AutoSizeText(
          "个人资料",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildProfileCard(bool isDark) {
    return GFCard(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
      content: Column(
        children: [
          // 头像部分
          Stack(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  size: 28.w,
                  color: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 8.w,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Gap(12.h),
          AutoSizeText(
            "Jaael",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
          ),
          Gap(4.h),
          AutoSizeText(
            "健康生活，从今天开始",
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
            maxLines: 1,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "连续打卡",
            "7",
            "天",
            Icons.calendar_today,
            const Color(0xFF4ECDC4),
            isDark,
          ),
        ),
        Gap(8.w),
        Expanded(
          child: _buildStatCard(
            "目标达成",
            "85",
            "%",
            Icons.trending_up,
            const Color(0xFFFF6B6B),
            isDark,
          ),
        ),
        Gap(8.w),
        Expanded(
          child: _buildStatCard(
            "总积分",
            "1,240",
            "分",
            Icons.stars,
            const Color(0xFFFFE66D),
            isDark,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.4, end: 0);
  }

  Widget _buildStatCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(8.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16.w),
          Gap(4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AutoSizeText(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                minFontSize: 10,
              ),
              AutoSizeText(
                unit,
                style: TextStyle(
                  fontSize: 9.sp,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
              ),
            ],
          ),
          Gap(2.h),
          AutoSizeText(
            title,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.grey[600],
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          "个人信息",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
          maxLines: 1,
        ),
        Gap(8.h),
        _buildMenuItem(
          "用户名",
          "Jaael",
          Icons.person_outline,
          const Color(0xFF667EEA),
          isDark,
          () {},
        ),
        Gap(8.h),
        _buildMenuItem(
          "邮箱",
          "jaael@example.com",
          Icons.email_outlined,
          const Color(0xFF4ECDC4),
          isDark,
          () {},
        ),
        Gap(8.h),
        _buildMenuItem(
          "手机号",
          "138****8888",
          Icons.phone_outlined,
          const Color(0xFFFF6B6B),
          isDark,
          () {},
        ),
        Gap(8.h),
        _buildMenuItem(
          "生日",
          "1990-01-01",
          Icons.cake_outlined,
          const Color(0xFFFFE66D),
          isDark,
          () {},
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0);
  }

  Widget _buildSettingsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          "设置",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
          maxLines: 1,
        ),
        Gap(8.h),
        _buildMenuItem(
          "通知设置",
          "已开启",
          Icons.notifications_outlined,
          const Color(0xFF667EEA),
          isDark,
          () {},
        ),
        Gap(8.h),
        _buildMenuItem(
          "隐私设置",
          "",
          Icons.privacy_tip_outlined,
          const Color(0xFF4ECDC4),
          isDark,
          () {},
        ),
        Gap(8.h),
        _buildMenuItem(
          "关于我们",
          "",
          Icons.info_outline,
          const Color(0xFFFF6B6B),
          isDark,
          () {},
        ),
        Gap(8.h),
        _buildMenuItem(
          "退出登录",
          "",
          Icons.logout_outlined,
          const Color(0xFFFF6B6B),
          isDark,
          () {},
          isDestructive: true,
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.6, end: 0);
  }

  Widget _buildMenuItem(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    bool isDark,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(8.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Icon(
                icon,
                color: isDestructive ? const Color(0xFFFF6B6B) : iconColor,
                size: 16.w,
              ),
            ),
            Gap(8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    title,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? const Color(0xFFFF6B6B)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                    maxLines: 1,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    Gap(2.h),
                    AutoSizeText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 12.w,
            ),
          ],
        ),
      ),
    ).animate().scale(
      delay: Duration(milliseconds: 100),
      duration: Duration(milliseconds: 200),
    );
  }
}