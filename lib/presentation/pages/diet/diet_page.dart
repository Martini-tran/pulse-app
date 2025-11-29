import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:getwidget/getwidget.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../framework/adapter/adaptive_extension.dart';
import '../chat/ai_chat_page.dart';

// 数据模型
class DietRecord {
  final String date;
  final String breakfast;
  final String lunch;
  final String dinner;
  final double weight;

  const DietRecord({
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.weight,
  });
}

class DietPage extends ConsumerStatefulWidget {
  const DietPage({super.key});

  @override
  ConsumerState<DietPage> createState() => _DietPageState();
}

class _DietPageState extends ConsumerState<DietPage>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 模拟饮食数据
  final List<DietRecord> _dietRecords = [
    DietRecord(
      date: "2025-08-26",
      breakfast: "鸡蛋+胡萝卜包子",
      lunch: "米饭+炒菜",
      dinner: "荞麦面+麻辣拌",
      weight: 105.0,
    ),
    DietRecord(
      date: "2025-08-25",
      breakfast: "燕麦粥+水果",
      lunch: "鸡胸肉沙拉",
      dinner: "蒸蛋羹+青菜",
      weight: 104.5,
    ),
    DietRecord(
      date: "2025-08-24",
      breakfast: "全麦面包+牛奶",
      lunch: "瘦肉粥+小菜",
      dinner: "清蒸鱼+蔬菜",
      weight: 104.8,
    ),
    DietRecord(
      date: "2025-08-23",
      breakfast: "豆浆+包子",
      lunch: "番茄鸡蛋面",
      dinner: "紫薯+酸奶",
      weight: 105.2,
    ),
    DietRecord(
      date: "2025-08-22",
      breakfast: "小米粥+咸菜",
      lunch: "炒河粉",
      dinner: "蔬菜汤+馒头",
      weight: 105.5,
    ),
    DietRecord(
      date: "2025-08-21",
      breakfast: "鸡蛋饼+豆浆",
      lunch: "盖浇饭",
      dinner: "水果沙拉",
      weight: 105.8,
    ),
    DietRecord(
      date: "2025-08-20",
      breakfast: "酸奶+坚果",
      lunch: "蒸蛋+米饭",
      dinner: "荞麦面+洋葱炒鸡胸肉",
      weight: 104.0,
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

  DietRecord? _getDietRecordForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      return _dietRecords.firstWhere((record) => record.date == dateStr);
    } catch (e) {
      return null;
    }
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
                  _buildQuickDateNav(isDark),
                  Gap(16.h),
                  _buildBreakfastCard(isDark),
                  Gap(12.h),
                  _buildLunchCard(isDark),
                  Gap(12.h),
                  _buildDinnerCard(isDark),
                  Gap(12.h),
                  _buildSnackCard(isDark),
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
                  Icons.restaurant,
                  color: isDark ? Colors.amber[300] : Colors.orange[600],
                  size: 14.w,
                ),
                Gap(4.w),
                AutoSizeText(
                  "饮食管理",
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
              "智能饮食计划",
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
            Gap(2.h),
            AutoSizeText(
              "AI定制 · 营养均衡 · 健康减脂",
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
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
          child:
              Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4ECDC4), Color(0xFF67E6DC)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ECDC4).withOpacity(0.3),
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
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .shimmer(duration: 2000.ms)
                  .then()
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.05, 1.05),
                  ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
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
                    colors: [Color(0xFF4ECDC4), Color(0xFF67E6DC)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 12.w,
                ),
              ),
              Gap(8.w),
              AutoSizeText(
                "AI饮食建议",
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
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
                    color: const Color(0xFF4ECDC4),
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
              color: const Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.w),
            ),
            child: AutoSizeText(
              "根据您的减脂目标，建议增加蛋白质摄入，减少碳水化合物。可以通过AI聊天调整个人饮食计划，获得更精准的营养搭配建议。",
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
          final isSelected =
              DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate);
          final isToday =
              DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child:
                Container(
                      width: 44.w,
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4ECDC4)
                            : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                        borderRadius: BorderRadius.circular(12.w),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: const Color(0xFF4ECDC4),
                                width: 1,
                              )
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
                                  : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
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
                    )
                    .animate(target: isSelected ? 1 : 0)
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.1, 1.1),
                    ),
          );
        },
      ),
    );
  }

  Widget _buildBreakfastCard(bool isDark) {
    final dietRecord = _getDietRecordForDate(_selectedDate);
    return _buildMealCard(
      "早餐",
      dietRecord?.breakfast ?? "暂无记录",
      Icons.wb_sunny,
      const Color(0xFFFFE66D),
      isDark,
      "早餐制作方法：\n1. 准备新鲜鸡蛋2个\n2. 热锅下油，煎至两面金黄\n3. 蒸包子5-8分钟\n4. 搭配温开水或豆浆",
    );
  }

  Widget _buildLunchCard(bool isDark) {
    final dietRecord = _getDietRecordForDate(_selectedDate);
    return _buildMealCard(
      "午餐",
      dietRecord?.lunch ?? "暂无记录",
      Icons.wb_sunny_outlined,
      const Color(0xFF4ECDC4),
      isDark,
      "午餐制作方法：\n1. 米饭蒸煮20分钟\n2. 热锅爆炒时令蔬菜\n3. 加入适量调料\n4. 营养搭配均衡",
    );
  }

  Widget _buildDinnerCard(bool isDark) {
    final dietRecord = _getDietRecordForDate(_selectedDate);
    return _buildMealCard(
      "晚餐",
      dietRecord?.dinner ?? "暂无记录",
      Icons.nightlight_round,
      const Color(0xFF667EEA),
      isDark,
      "晚餐制作方法：\n1. 荞麦面煮制8-10分钟\n2. 准备麻辣拌菜\n3. 调制酱料\n4. 拌匀即可享用",
    );
  }

  Widget _buildSnackCard(bool isDark) {
    return _buildMealCard(
      "其他",
      "坚果+酸奶",
      Icons.local_cafe,
      const Color(0xFFFF6B6B),
      isDark,
      "加餐制作方法：\n1. 选择无糖酸奶\n2. 搭配混合坚果\n3. 控制分量适中\n4. 两餐之间食用",
    );
  }

  Widget _buildMealCard(
    String mealType,
    String mealContent,
    IconData icon,
    Color color,
    bool isDark,
    String recipe,
  ) {
    return GFCard(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
      content: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
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
                  mealType,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                ),
                Gap(4.h),
                AutoSizeText(
                  mealContent,
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
            onTap: () => _showRecipeDialog(mealType, recipe),
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.w),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(Icons.menu_book, color: color, size: 16.w),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecipeDialog(String mealType, String recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$mealType制作方法'),
        content: Text(recipe),
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
            _buildNavItem(Icons.home_rounded, "首页", false, isDark, () {
              context.push('/home');
            }),
            _buildNavItem(Icons.restaurant_menu, "饮食", true, isDark, () {}),
            _buildNavItem(
              Icons.tune,
              "定制",
              false,
              isDark,
              () => context.push('/customize'),
            ),
            _buildNavItem(Icons.directions_run, "运动", false, isDark, () {
              context.push('/sport');
            }),
            _buildNavItem(Icons.person, "我的", false, isDark, () {
              context.push('/profile');
            }),
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
            color: isSelected ? const Color(0xFF4ECDC4) : Colors.grey[500],
            size: 20.w,
          ),
          Gap(2.h),
          AutoSizeText(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: isSelected ? const Color(0xFF4ECDC4) : Colors.grey[500],
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
