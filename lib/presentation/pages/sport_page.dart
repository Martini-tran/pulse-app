import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:getwidget/getwidget.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../framework/adapter/adaptive_extension.dart';
import 'chat/ai_chat_page.dart';

// 运动数据模型
class SportRecord {
  final String date;
  final String cardio;
  final String strength;
  final String flexibility;
  final int duration; // 分钟
  final int calories; // 卡路里

  const SportRecord({
    required this.date,
    required this.cardio,
    required this.strength,
    required this.flexibility,
    required this.duration,
    required this.calories,
  });
}

class SportPage extends ConsumerStatefulWidget {
  const SportPage({super.key});

  @override
  ConsumerState<SportPage> createState() => _SportPageState();
}

class _SportPageState extends ConsumerState<SportPage> 
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 模拟运动数据
  final List<SportRecord> _sportRecords = [
    SportRecord(
      date: "2025-08-26",
      cardio: "跑步30分钟",
      strength: "哑铃训练",
      flexibility: "瑜伽拉伸",
      duration: 60,
      calories: 350,
    ),
    SportRecord(
      date: "2025-08-25",
      cardio: "游泳45分钟",
      strength: "俯卧撑×30",
      flexibility: "腿部拉伸",
      duration: 75,
      calories: 420,
    ),
    SportRecord(
      date: "2025-08-24",
      cardio: "骑行40分钟",
      strength: "深蹲×50",
      flexibility: "全身拉伸",
      duration: 65,
      calories: 380,
    ),
    SportRecord(
      date: "2025-08-23",
      cardio: "快走25分钟",
      strength: "平板支撑",
      flexibility: "颈肩放松",
      duration: 45,
      calories: 280,
    ),
    SportRecord(
      date: "2025-08-22",
      cardio: "跳绳20分钟",
      strength: "卷腹×40",
      flexibility: "腰部拉伸",
      duration: 50,
      calories: 320,
    ),
    SportRecord(
      date: "2025-08-21",
      cardio: "椭圆机35分钟",
      strength: "引体向上",
      flexibility: "背部拉伸",
      duration: 55,
      calories: 340,
    ),
    SportRecord(
      date: "2025-08-20",
      cardio: "爬楼梯15分钟",
      strength: "臀桥×25",
      flexibility: "臀部拉伸",
      duration: 40,
      calories: 250,
    ),
  ];

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
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  SportRecord? _getSportRecordForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      return _sportRecords.firstWhere((record) => record.date == dateStr);
    } catch (e) {
      return null;
    }
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
                  _buildCompactHeader(isDark),
                  Gap(16.h),
                  _buildAIInsightCard(isDark),
                  Gap(16.h),
                  _buildQuickDateNav(isDark),
                  Gap(16.h),
                  _buildCardioCard(isDark),
                  Gap(12.h),
                  _buildStrengthCard(isDark),
                  Gap(12.h),
                  _buildFlexibilityCard(isDark),
                  Gap(12.h),
                  _buildStatsCard(isDark),
                  Gap(80.h), // 底部导航栏空间
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
                  Icons.fitness_center,
                  color: isDark ? Colors.orange[300] : Colors.deepOrange[600],
                  size: 14.w,
                ),
                Gap(4.w),
                AutoSizeText(
                  "运动管理",
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
              "智能运动计划",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
            Gap(2.h),
            AutoSizeText(
              "AI定制 · 科学训练 · 高效燃脂",
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              minFontSize: 9,
            ),
          ],
        ),
        // AI快捷入口
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIChatPage()),
          ),
          child: Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 24.w,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .shimmer(duration: 2000.ms)
              .then()
              .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05)),
        ),
      ],
    );
  }

  Widget _buildAIInsightCard(bool isDark) {
    return GFCard(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.w),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 12.w),
              ),
              Gap(8.w),
              AutoSizeText(
                "AI运动建议",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AIChatPage()),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B),
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                  child: AutoSizeText(
                    "调整",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          Gap(8.h),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.w),
            ),
            child: AutoSizeText(
              "根据您的健身目标，建议增加有氧运动强度，配合力量训练。可以通过AI聊天调整个人运动计划，获得更科学的训练安排。",
              style: TextStyle(
                fontSize: 11.sp,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.3,
              ),
              maxLines: 3,
              minFontSize: 9,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickDateNav(bool isDark) {
    return Container(
      height: 60.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: 6 - index));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate);
          final isToday = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 44.w,
              margin: EdgeInsets.only(right: 8.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFF6B6B)
                    : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                borderRadius: BorderRadius.circular(12.w),
                border: isToday && !isSelected
                    ? Border.all(color: const Color(0xFFFF6B6B), width: 1)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AutoSizeText(
                    DateFormat('E', 'zh_CN').format(date),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    maxLines: 1,
                  ),
                  Gap(2.h),
                  AutoSizeText(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black),
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ).animate(target: isSelected ? 1 : 0)
                .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1)),
          );
        },
      ),
    );
  }

  Widget _buildCardioCard(bool isDark) {
    final sportRecord = _getSportRecordForDate(_selectedDate);
    return _buildSportCard(
      "有氧运动", 
      sportRecord?.cardio ?? "暂无记录", 
      Icons.directions_run, 
      const Color(0xFF4ECDC4), 
      isDark,
      "有氧运动指导： 1. 热身5-10分钟2. 保持适中强度3. 心率控制在目标区间4. 运动后拉伸放松"
    );
  }

  Widget _buildStrengthCard(bool isDark) {
    final sportRecord = _getSportRecordForDate(_selectedDate);
    return _buildSportCard(
      "力量训练", 
      sportRecord?.strength ?? "暂无记录", 
      Icons.fitness_center, 
      const Color(0xFF667EEA), 
      isDark,
      "力量训练指导：1. 选择合适重量2. 动作标准规范3. 控制训练节奏4. 组间适当休息"
    );
  }

  Widget _buildFlexibilityCard(bool isDark) {
    final sportRecord = _getSportRecordForDate(_selectedDate);
    return _buildSportCard(
      "柔韧拉伸", 
      sportRecord?.flexibility ?? "暂无记录", 
      Icons.self_improvement, 
      const Color(0xFFFFE66D), 
      isDark,
      "拉伸训练指导：1. 运动后进行拉伸2. 每个动作保持15-30秒3. 呼吸保持自然4. 避免过度拉伸"
    );
  }

  Widget _buildStatsCard(bool isDark) {
    final sportRecord = _getSportRecordForDate(_selectedDate);
    return GFCard(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.w),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.analytics, color: Colors.white, size: 12.w),
              ),
              Gap(8.w),
              AutoSizeText(
                "运动数据",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
            ],
          ),
          Gap(12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "运动时长",
                  "${sportRecord?.duration ?? 0}分钟",
                  Icons.timer,
                  const Color(0xFF4ECDC4),
                  isDark,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: _buildStatItem(
                  "消耗卡路里",
                  "${sportRecord?.calories ?? 0}千卡",
                  Icons.local_fire_department,
                  const Color(0xFFFF6B6B),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.w),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.w),
          Gap(4.h),
          AutoSizeText(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 1,
          ),
          Gap(2.h),
          AutoSizeText(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSportCard(String sportType, String sportContent, IconData icon, Color color, bool isDark, String guide) {
    return GFCard(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.w),
      ),
      content: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(10.w),
            ),
            child: Icon(icon, color: Colors.white, size: 20.w),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  sportType,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                ),
                Gap(4.h),
                AutoSizeText(
                  sportContent,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showGuideDialog(sportType, guide),
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.w),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.help_outline,
                color: color,
                size: 16.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGuideDialog(String sportType, String guide) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$sportType指导'),
        content: Text(guide),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
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
            _buildNavItem(Icons.home_rounded, "首页", false, isDark, () {context.push('/home');}),
            _buildNavItem(
              Icons.restaurant_menu,
              "饮食",
              false,
              isDark,
                  () => context.push('/diet'),
            ),
            _buildNavItem(Icons.tune, "定制", false, isDark, () => context.push('/customize')),
            _buildNavItem(Icons.directions_run, "运动", true, isDark, () {}),
            _buildNavItem(Icons.person, "我的", false, isDark, () {context.push('/profile');}),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey[500],
            size: 20.w,
          ),
          Gap(2.h),
          AutoSizeText(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey[500],
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}