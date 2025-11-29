import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 页面导入
import '../presentation/pages/guide/guide_1.dart';
import '../presentation/pages/home/home.dart';
import '../presentation/pages/login/login.dart';
import '../presentation/pages/register/register.dart';
import '../presentation/pages/splash/splash.dart';
import '../presentation/pages/diet/diet_page.dart';
import '../presentation/pages/meal/meal_detail_page.dart';
import '../presentation/pages/profile/profile_page.dart';
import '../presentation/pages/sport_page.dart';
import '../presentation/pages/customize/customize_page.dart';

// 路由名称常量
class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String guide1 = '/guide_1';
  static const String guide2 = '/guide_2';
  static const String diet = '/diet';
  static const String profile = '/profile';
  static const String sport = '/sport';
  static const String customize = '/customize';
  static const String mealDetail = '/meal';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String achievements = '/achievements';
  static const String statistics = '/statistics';
}

// 自定义页面转场动画
class CustomPageTransition extends CustomTransitionPage<void> {
  const CustomPageTransition({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionsBuilder: _transitionsBuilder,
          transitionDuration: const Duration(milliseconds: 300),
        );

  static Widget _transitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
      ),
      child: child,
    );
  }
}

// 错误页面
class ErrorPage extends StatelessWidget {
  final String error;
  
  const ErrorPage({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('页面错误'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '页面加载失败',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}

// 路由守卫 - 检查用户是否已登录
bool _isUserLoggedIn() {
  // 这里应该检查用户的登录状态
  // 可以从SharedPreferences、Hive或其他存储中获取
  return true; // 临时返回true，实际应用中需要实现真实的登录检查
}

// 主路由配置
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  errorBuilder: (context, state) => ErrorPage(error: state.error.toString()),
  redirect: (context, state) {
    final isLoggedIn = _isUserLoggedIn();
    final isGoingToLogin = state.matchedLocation == AppRoutes.login;
    final isGoingToRegister = state.matchedLocation == AppRoutes.register;
    final isGoingToSplash = state.matchedLocation == AppRoutes.splash;
    final isGoingToGuide = state.matchedLocation.startsWith('/guide');

    // 如果用户未登录且不是去登录、注册、启动页或引导页，则重定向到登录页
    if (!isLoggedIn && 
        !isGoingToLogin && 
        !isGoingToRegister && 
        !isGoingToSplash && 
        !isGoingToGuide) {
      return AppRoutes.login;
    }

    return null; // 不需要重定向
  },
  routes: [
    // 启动页
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => CustomPageTransition(
        child: SplashPage(),
      ),
    ),
    
    // 主页
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) => CustomPageTransition(
        child: HomePage(),
      ),
    ),
    
    // 登录页
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) => CustomPageTransition(
        child: LoginPage(),
      ),
    ),
    
    // 注册页
    GoRoute(
      path: AppRoutes.register,
      pageBuilder: (context, state) => CustomPageTransition(
        child: RegisterPage(),
      ),
    ),
    
    // 引导页1
    GoRoute(
      path: AppRoutes.guide1,
      pageBuilder: (context, state) => CustomPageTransition(
        child: GuidePage_1(),
      ),
    ),
    // 饮食页面
    GoRoute(
      path: AppRoutes.diet,
      pageBuilder: (context, state) => CustomPageTransition(
        child: const DietPage(),
      ),
    ),
    
    // 个人资料页面
    GoRoute(
      path: AppRoutes.profile,
      pageBuilder: (context, state) => CustomPageTransition(
        child: const ProfilePage(),
      ),
    ),
    
    // 运动页面
    GoRoute(
      path: AppRoutes.sport,
      pageBuilder: (context, state) => CustomPageTransition(
        child: const SportPage(),
      ),
    ),
    
    // 定制页面
    GoRoute(
      path: AppRoutes.customize,
      pageBuilder: (context, state) => CustomPageTransition(
        child: const CustomizePage(),
      ),
    ),
    
    // 餐食详情页面（带参数）
    GoRoute(
      path: '${AppRoutes.mealDetail}/:mealType/:mealId',
      pageBuilder: (context, state) {
        final mealType = state.pathParameters['mealType']!;
        final mealId = state.pathParameters['mealId']!;
        return CustomPageTransition(
          child: MealDetailPage(mealType: mealType, mealId: mealId),
        );
      },
    ),
    
    // 设置页面（新增）
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (context, state) => CustomPageTransition(
        child: const SettingsPage(),
      ),
    ),
    
    // 通知页面（新增）
    GoRoute(
      path: AppRoutes.notifications,
      pageBuilder: (context, state) => CustomPageTransition(
        child: const NotificationsPage(),
      ),
    ),
    
    // 成就页面（新增）
    GoRoute(
      path: AppRoutes.achievements,
      pageBuilder: (context, state) => CustomPageTransition(
        child: const AchievementsPage(),
      ),
    ),
    
    // 统计页面（新增）
    GoRoute(
      path: AppRoutes.statistics,
      pageBuilder: (context, state) => CustomPageTransition(
        child: const StatisticsPage(),
      ),
    ),
  ],
);

// 路由扩展方法
extension AppRouterExtension on GoRouter {
  /// 安全导航到指定路由
  void safeGo(BuildContext context, String location) {
    try {
      go(location);
    } catch (e) {
      // 如果导航失败，显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导航失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// 安全推送到指定路由
  void safePush(BuildContext context, String location) {
    try {
      push(location);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导航失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// 临时页面组件（需要在实际项目中创建对应的页面文件）
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: const Center(child: Text('设置页面')),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知')),
      body: const Center(child: Text('通知页面')),
    );
  }
}

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('成就')),
      body: const Center(child: Text('成就页面')),
    );
  }
}

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: const Center(child: Text('统计页面')),
    );
  }
}