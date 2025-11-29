import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../framework/adapter/adaptive_extension.dart';
import '../../../domain/meal.dart';
import '../../../api/diet_api.dart';

// 餐食详情状态管理
final mealDetailProvider =
    StateNotifierProvider.family<MealDetailNotifier, MealDetailState, String>((
      ref,
      mealId,
    ) {
      return MealDetailNotifier(mealId);
    });

class MealDetailState {
  final Meal? meal;
  final bool isLoading;
  final String? error;

  const MealDetailState({this.meal, this.isLoading = false, this.error});

  MealDetailState copyWith({Meal? meal, bool? isLoading, String? error}) {
    return MealDetailState(
      meal: meal ?? this.meal,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MealDetailNotifier extends StateNotifier<MealDetailState> {
  final String mealId;

  MealDetailNotifier(this.mealId) : super(const MealDetailState()) {
    loadMealDetail();
  }

  Future<void> loadMealDetail() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await DietApiService.getDietRecordByDate(mealId);
      if (response.success && response.data != null) {
        // 这里需要根据实际的Meal模型来转换数据
        // 暂时注释掉，因为需要了解Meal模型的结构
        // final meal = Meal.fromDietRecord(response.data!);
        // state = state.copyWith(meal: meal, isLoading: false);
        state = state.copyWith(isLoading: false);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

class MealDetailPage extends ConsumerWidget {
  final String mealType;
  final String mealId;

  const MealDetailPage({
    super.key,
    required this.mealType,
    required this.mealId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealDetailState = ref.watch(mealDetailProvider(mealId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, mealDetailState.meal, isDark),
          if (mealDetailState.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (mealDetailState.error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.w,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      '加载失败',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(mealDetailProvider(mealId).notifier)
                            .loadMealDetail();
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            )
          else if (mealDetailState.meal != null)
            SliverPadding(
              padding: EdgeInsets.all(16.w),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildNutritionInfo(mealDetailState.meal!, isDark),
                  SizedBox(height: 20.h),
                  _buildIngredientsSection(mealDetailState.meal!, isDark),
                  SizedBox(height: 20.h),
                  _buildCookingMethodSection(mealDetailState.meal!, isDark),
                  SizedBox(height: 20.h),
                  _buildCookingInfoSection(mealDetailState.meal!, isDark),
                  SizedBox(height: 100.h), // 底部间距
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Meal? meal, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200.h,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20.w),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: meal != null
            ? Text(
                meal.name,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getMealTypeColor(mealType),
                _getMealTypeColor(mealType).withOpacity(0.8),
              ],
            ),
          ),
          child: meal != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getMealTypeIcon(meal.type),
                        size: 48.w,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20.w),
                        ),
                        child: Text(
                          meal.type,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildNutritionInfo(Meal meal, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10.w,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '营养信息',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: Text(
                  '${meal.calories} kcal',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: const Color(0xFF4ECDC4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutritionItem(
                '蛋白质',
                '${meal.protein}g',
                const Color(0xFFFF6B6B),
                isDark,
              ),
              _buildNutritionItem(
                '碳水',
                '${meal.carbs}g',
                const Color(0xFF4ECDC4),
                isDark,
              ),
              _buildNutritionItem(
                '脂肪',
                '${meal.fat}g',
                const Color(0xFFFFE66D),
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(
    String name,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          width: 60.w,
          height: 60.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30.w),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          name,
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(Meal meal, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10.w,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: const Color(0xFF4ECDC4),
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                '所需食材',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...meal.ingredients
              .map(
                (ingredient) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ECDC4),
                          borderRadius: BorderRadius.circular(3.w),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        ingredient,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildCookingMethodSection(Meal meal, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10.w,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                color: const Color(0xFFFFE66D),
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                '制作方法',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            meal.cookingMethod,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookingInfoSection(Meal meal, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 10.w,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            Icons.access_time,
            '制作时间',
            '${meal.cookingTime} 分钟',
            const Color(0xFF4ECDC4),
            isDark,
          ),
          Container(
            width: 1.w,
            height: 40.h,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          _buildInfoItem(
            Icons.star_outline,
            '难度等级',
            meal.difficulty,
            const Color(0xFFFFE66D),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.w),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getMealTypeColor(String type) {
    switch (type) {
      case '早餐':
        return const Color(0xFFFFE66D);
      case '午餐':
        return const Color(0xFF4ECDC4);
      case '晚餐':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF4ECDC4);
    }
  }

  IconData _getMealTypeIcon(String type) {
    switch (type) {
      case '早餐':
        return Icons.wb_sunny;
      case '午餐':
        return Icons.wb_sunny_outlined;
      case '晚餐':
        return Icons.nights_stay;
      default:
        return Icons.restaurant;
    }
  }
}
