import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:getwidget/getwidget.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../framework/adapter/adaptive_extension.dart';

// 定制计划数据模型
class CustomPlan {
  final String id;
  final String title;
  final String description;
  final String category;
  final int duration; // 天数
  final String difficulty;
  final List<String> features;
  final String imageUrl;
  final bool isRecommended;
  final bool isPopular;

  const CustomPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.difficulty,
    required this.features,
    required this.imageUrl,
    this.isRecommended = false,
    this.isPopular = false,
  });
}

// 定制目标数据模型
class CustomGoal {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final bool isSelected;

  const CustomGoal({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    this.isSelected = false,
  });
}

class CustomizePage extends ConsumerStatefulWidget {
  const CustomizePage({super.key});

  @override
  ConsumerState<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends ConsumerState<CustomizePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedCategory = "全部";
  List<String> _selectedGoals = [];

  final List<String> _categories = ["全部", "减脂", "增肌", "塑形", "健康"];

  final List<CustomGoal> _goals = [
    CustomGoal(
      id: "weight_loss",
      title: "减脂瘦身",
      icon: Icons.trending_down,
      color: const Color(0xFFFF6B6B),
      description: "科学减脂，健康瘦身",
    ),
    CustomGoal(
      id: "muscle_gain",
      title: "增肌塑形",
      icon: Icons.fitness_center,
      color: const Color(0xFF4ECDC4),
      description: "增强肌肉，完美体型",
    ),
    CustomGoal(
      id: "health",
      title: "健康管理",
      icon: Icons.favorite,
      color: const Color(0xFFFFE66D),
      description: "全面健康，活力满满",
    ),
    CustomGoal(
      id: "endurance",
      title: "耐力提升",
      icon: Icons.directions_run,
      color: const Color(0xFF667EEA),
      description: "提升体能，增强耐力",
    ),
  ];

  final List<CustomPlan> _plans = [
    CustomPlan(
      id: "fat_burn_30",
      title: "30天燃脂计划",
      description: "科学饮食搭配高效运动，30天见证蜕变",
      category: "减脂",
      duration: 30,
      difficulty: "中等",
      features: ["个性化饮食", "HIIT训练", "进度跟踪", "专业指导"],
      imageUrl: "",
      isRecommended: true,
    ),
    CustomPlan(
      id: "muscle_build_60",
      title: "60天增肌塑形",
      description: "系统性力量训练，打造完美肌肉线条",
      category: "增肌",
      duration: 60,
      difficulty: "困难",
      features: ["力量训练", "营养补充", "恢复指导", "形体雕塑"],
      imageUrl: "",
      isPopular: true,
    ),
    CustomPlan(
      id: "health_90",
      title: "90天健康管理",
      description: "全方位健康管理，养成良好生活习惯",
      category: "健康",
      duration: 90,
      difficulty: "简单",
      features: ["健康监测", "习惯养成", "营养均衡", "心理健康"],
      imageUrl: "",
    ),
    CustomPlan(
      id: "shape_45",
      title: "45天完美塑形",
      description: "针对性塑形训练，雕塑理想身材",
      category: "塑形",
      duration: 45,
      difficulty: "中等",
      features: ["局部塑形", "柔韧训练", "体态矫正", "线条雕塑"],
      imageUrl: "",
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

  List<CustomPlan> get _filteredPlans {
    if (_selectedCategory == "全部") {
      return _plans;
    }
    return _plans.where((plan) => plan.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
            size: 20.w,
          ),
          onPressed: () => context.pop(),
        ),
        title: AutoSizeText(
          "个性定制",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
          maxLines: 1,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: isDark ? Colors.white : Colors.black,
              size: 20.w,
            ),
            onPressed: () => _showHelpDialog(context, isDark),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Gap(8.h),
                _buildWelcomeCard(isDark),
                Gap(20.h),
                _buildGoalSelection(isDark),
                Gap(20.h),
                _buildCategoryFilter(isDark),
                Gap(16.h),
                _buildPlansList(isDark),
                Gap(80.h), // 底部空间
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(bool isDark) {
    return GFCard(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.w)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18.w,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      "专属定制计划",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                    Gap(4.h),
                    AutoSizeText(
                      "基于您的目标和身体状况，为您量身打造",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(12.w),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 16.w,
                ),
                Gap(8.w),
                Expanded(
                  child: AutoSizeText(
                    "AI智能分析，精准匹配最适合您的计划",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildGoalSelection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          "选择您的目标",
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _goals.map((goal) {
            final isSelected = _selectedGoals.contains(goal.id);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedGoals.remove(goal.id);
                  } else {
                    _selectedGoals.add(goal.id);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? goal.color.withOpacity(0.2)
                      : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                  borderRadius: BorderRadius.circular(20.w),
                  border: Border.all(
                    color: isSelected ? goal.color : Colors.grey.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      goal.icon,
                      color: isSelected ? goal.color : Colors.grey[600],
                      size: 16.w,
                    ),
                    Gap(6.w),
                    AutoSizeText(
                      goal.title,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isSelected ? goal.color : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ).animate().scale(delay: (300 + _goals.indexOf(goal) * 100).ms);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          "计划分类",
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
        ),
        Gap(12.h),
        SizedBox(
          height: 40.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF667EEA)
                        : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF667EEA) : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: AutoSizeText(
                      category,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ).animate(target: isSelected ? 1 : 0).scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.05, 1.05),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlansList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(
              "推荐计划",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
            TextButton(
              onPressed: () {
                // 查看更多计划
              },
              child: AutoSizeText(
                "查看全部",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF667EEA),
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
        Gap(12.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredPlans.length,
          itemBuilder: (context, index) {
            final plan = _filteredPlans[index];
            return _buildPlanCard(plan, isDark, index);
          },
        ),
      ],
    );
  }

  Widget _buildPlanCard(CustomPlan plan, bool isDark, int index) {
    return GestureDetector(
      onTap: () => _showPlanDetail(plan, isDark),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        child: GFCard(
          padding: EdgeInsets.all(16.w),
          margin: EdgeInsets.zero,
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.w)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (plan.isRecommended) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B6B),
                                  borderRadius: BorderRadius.circular(8.w),
                                ),
                                child: AutoSizeText(
                                  "推荐",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                              Gap(6.w),
                            ],
                            if (plan.isPopular) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4ECDC4),
                                  borderRadius: BorderRadius.circular(8.w),
                                ),
                                child: AutoSizeText(
                                  "热门",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                              Gap(6.w),
                            ],
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF667EEA).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8.w),
                              ),
                              child: AutoSizeText(
                                plan.category,
                                style: TextStyle(
                                  color: const Color(0xFF667EEA),
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        Gap(8.h),
                        AutoSizeText(
                          plan.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                        Gap(4.h),
                        AutoSizeText(
                          plan.description,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  Gap(12.w),
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 24.w,
                    ),
                  ),
                ],
              ),
              Gap(12.h),
              Row(
                children: [
                  _buildPlanInfo(Icons.schedule, "${plan.duration}天", isDark),
                  Gap(16.w),
                  _buildPlanInfo(Icons.trending_up, plan.difficulty, isDark),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA),
                      borderRadius: BorderRadius.circular(16.w),
                    ),
                    child: AutoSizeText(
                      "开始计划",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (400 + index * 100).ms).slideX(begin: 0.2, end: 0),
    );
  }

  Widget _buildPlanInfo(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 14.w,
        ),
        Gap(4.w),
        AutoSizeText(
          text,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey[600],
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  void _showPlanDetail(CustomPlan plan, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
        ),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      plan.title,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                    Gap(8.h),
                    AutoSizeText(
                      plan.description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 3,
                    ),
                    Gap(20.h),
                    AutoSizeText(
                      "计划特色",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                    Gap(12.h),
                    ...plan.features.map((feature) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: const Color(0xFF4ECDC4),
                            size: 16.w,
                          ),
                          Gap(8.w),
                          AutoSizeText(
                            feature,
                            style: TextStyle(fontSize: 14.sp),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    )).toList(),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _startCustomPlan(plan);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.w),
                          ),
                        ),
                        child: AutoSizeText(
                          "开始${plan.title}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: AutoSizeText(
          "定制帮助",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutoSizeText(
              "1. 选择您的健身目标\n2. 浏览推荐的定制计划\n3. 查看计划详情和特色\n4. 开始您的专属计划",
              style: TextStyle(fontSize: 14.sp),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AutoSizeText(
              "知道了",
              style: TextStyle(
                color: const Color(0xFF667EEA),
                fontSize: 14.sp,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _startCustomPlan(CustomPlan plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AutoSizeText(
          "已开始${plan.title}！",
          style: TextStyle(fontSize: 14.sp),
          maxLines: 1,
        ),
        backgroundColor: const Color(0xFF4ECDC4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}