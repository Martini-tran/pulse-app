import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../api/user_api.dart';
import '../../../controller/user_pulse_controller.dart';
import '../../../framework/logger/pulse_logger.dart';
import '../../../framework/store/pulse_provider.dart';
import '../../../util/request.dart';
import '../../../util/toast_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final logger = PulseLogger();

  final _formKey = GlobalKey<FormState>();

  /**
   * 用户名称
   */
  final _usernameController = TextEditingController();

  /**
   * 密码
   */
  final _passwordController = TextEditingController();

  /**
   * 用户协议
   */
  bool _agreeToTerms = false;

  /**
   * 密码图标开关
   */
  bool _isPasswordVisible = false;

  /**
   * 登录按钮遮罩
   */
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: PulseProvider<UserPulseController>(
        viewModel: UserPulseController(),
        child: Container(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 768.w;
                final isDesktop = constraints.maxWidth > 1024.w;
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 100.w : (isTablet ? 60.w : 24.w),
                      vertical: 20.h,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 480.w : double.infinity,
                          ),
                          child: Card(
                            elevation: 20,
                            shadowColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.r),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isDark
                                      ? [
                                    const Color(0xFF1e1e2e).withOpacity(0.95),
                                    const Color(0xFF2a2a3e).withOpacity(0.95),
                                  ]
                                      : [
                                    Colors.white.withOpacity(0.95),
                                    Colors.white.withOpacity(0.9),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(32.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildHeader(),
                                    SizedBox(height: 40.h),
                                    _buildForm(),
                                    SizedBox(height: 24.h),
                                    _buildLoginButton(),
                                    SizedBox(height: 16.h),
                                    _buildForgotPassword(),
                                    SizedBox(height: 24.h),
                                    _buildToggleMode(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(height: 20.h),
        AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              '欢迎来到轻刻',
              textStyle: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
              speed: const Duration(milliseconds: 100),
            ),
          ],
          isRepeatingAnimation: false,
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  // 用户名校验
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return '用户名不能为空';
    }
    return null;
  }

  // 密码校验
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '密码不能为空';
    }
    return null;
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Username Field
          ShadInputFormField(
            controller: _usernameController,
            placeholder: Text('请输入用户名|邮箱'),
            keyboardType: TextInputType.emailAddress,
            leading: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.verified_user_outlined),
            ),
            validator: _validateUsername,
          ),
          SizedBox(height: 16.h),
          // Password Field
          ShadInputFormField(
            controller: _passwordController,
            placeholder: Text('请输入密码'),
            obscureText: !_isPasswordVisible,
            leading: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.lock_outlined),
            ),
            trailing: SizedBox(
              height: 20, // 限制高度
              child: IconButton(
                constraints: BoxConstraints(maxHeight: 20), // 关键代码
                padding: EdgeInsets.zero,
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  size: 18, // 减小图标尺寸
                  color: Theme.of(context).hintColor,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            validator: _validatePassword,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return ShadButton(
      onPressed: _isLoading ? null : _handleLogin,
      size: ShadButtonSize.lg,
      child: _isLoading
          ? SpinKitWave(color: Colors.white, size: 20.sp)
          : Text(
        '登 录',
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // Handle forgot password
        },
        child: Text(
          '忘记密码?',
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF667eea),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }


  Widget _buildToggleMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "还没有账号?",
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              logger.info("跳转到注册页面");
              context.go("/register");
            });
          },
          child: Text(
             '立即注册',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF667eea),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _handleLogin() async {
    // context.go("/home");
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      logger.info("开始登录请求");
      ApiResponse<LoginResponseDto> apiResponse = await UserApiService.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      logger.info("登录请求完成");

      if (apiResponse.success && apiResponse.code == 200 && apiResponse.data != null) {
        final userInfo = apiResponse.data!.userInfo;

        // 根据用户状态进行不同跳转
        switch (userInfo.status) {
          case '1000':
            logger.info("用户状态: ${userInfo.status}, 跳转到引导页");
            // ToastUtils.success('登录成功，欢迎新用户！');
            context.go("/guide_1");
            break;
          case '2000':
            logger.info("用户状态: ${userInfo.status}, 跳转到主页");
            // ToastUtils.success('登录成功');
            context.go("/home");
            break;
          default:
            logger.warn("未知用户状态: ${userInfo.status}");
            ToastUtils.warning('用户状态异常，请联系客服');
            break;
        }
      } else {
        ToastUtils.warning(apiResponse.message);
      }
    } catch (e) {
      logger.error("登录异常: $e");
      ToastUtils.error('登录失败');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}