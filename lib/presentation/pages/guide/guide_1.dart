import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:oktoast/oktoast.dart';

/// 引导页 - AI减肥助手用户信息收集页面
class GuidePage_1 extends StatefulWidget {
  const GuidePage_1({Key? key}) : super(key: key);

  @override
  State<GuidePage_1> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage_1> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormBuilderState>();
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  double _progress = 0.0;
  int _currentStep = 0;
  final int _totalSteps = 6;

  // 表单数据
  DateTime? _birthDate;
  String? _gender;
  double? _height;
  double? _currentWeight;
  double? _targetWeight;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    int filledFields = 0;

    if (_birthDate != null) filledFields++;
    if (_gender != null) filledFields++;
    if (_height != null) filledFields++;
    if (_currentWeight != null) filledFields++;
    if (_targetWeight != null) filledFields++;

    double newProgress = filledFields / _totalSteps;
    if (newProgress != _progress) {
      setState(() {
        _progress = newProgress;
        _currentStep = filledFields;
      });
      _progressController.animateTo(_progress);
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  double _calculateBMI(double weight, double height) {
    final heightInM = height / 100;
    return weight / (heightInM * heightInM);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 24) return '正常';
    if (bmi < 28) return '超重';
    return '肥胖';
  }

  void _onSubmit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;

      // 计算额外信息
      final age = _calculateAge(_birthDate!);
      final currentBMI = _calculateBMI(_currentWeight!, _height!);
      final targetBMI = _calculateBMI(_targetWeight!, _height!);

      // 显示结果
      _showResultDialog(age, currentBMI, targetBMI);

      // 这里可以保存数据到本地或发送到服务器
      // await _saveUserData(formData);
    } else {
      showToast('请完整填写所有信息', position: ToastPosition.center);
    }
  }

  void _showResultDialog(int age, double currentBMI, double targetBMI) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gap(16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('年龄', '$age岁'),
                  _buildInfoRow('性别', _gender == 'male' ? '男性' : '女性'),
                  _buildInfoRow('身高', '${_height!.toInt()}cm'),
                  _buildInfoRow(
                    '当前体重',
                    '${_currentWeight}kg (BMI: ${currentBMI.toStringAsFixed(1)}) - ${_getBMICategory(currentBMI)}',
                  ),
                  _buildInfoRow(
                    '目标体重',
                    '${_targetWeight}kg (BMI: ${targetBMI.toStringAsFixed(1)}) - ${_getBMICategory(targetBMI)}',
                  ),
                ],
              ),
            ),
            Gap(24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 跳转到主页面

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: Text(
                  '开始我的减肥计划 🚀',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF718096),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildForm()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Gap(16.h),

          AutoSizeText(
            '告诉我们一些关于你的信息\n我们将为你制定个性化的减肥计划',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF718096),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ).animate(delay: 400.ms).fadeIn(duration: 600.ms).slideY(begin: 0.3),

          Gap(20.h),

          // 进度条
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '完成进度',
              style: TextStyle(
                color: const Color(0xFF718096),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$_currentStep/$_totalSteps',
              style: TextStyle(
                color: const Color(0xFF2D3748),
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Gap(8.h),
        Container(
          width: double.infinity,
          height: 5.h,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(3.r),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA),
                    borderRadius: BorderRadius.circular(3.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: FormBuilder(
        key: _formKey,
        child:         SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              // 表单字段
              _buildBirthDateField(),
              Gap(16.h),
              _buildGenderField(),
              Gap(16.h),
              _buildHeightField(),
              Gap(16.h),
              _buildWeightFields(),
              Gap(24.h),
              _buildSubmitButton(),
              Gap(20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBirthDateField() {
    return _buildAnimatedFormField(
      delay: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('出生日期'),
          Gap(6.h),
          FormBuilderDateTimePicker(
            name: 'birthdate',
            inputType: InputType.date,
            format: DateFormat('yyyy年MM月dd日'),
            decoration: _buildInputDecoration('请选择您的出生日期'),
            validator: FormBuilderValidators.required(errorText: '请选择出生日期'),
            onChanged: (value) {
              setState(() {
                _birthDate = value;
              });
              _updateProgress();
            },
            firstDate: DateTime(1920),
            lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
            locale: const Locale('zh', 'CN'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderField() {
    return _buildAnimatedFormField(
      delay: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('性别'),
          Gap(6.h),
          Row(
            children: [
              Expanded(child: _buildGenderOption('male', '👨 男性')),
              Gap(12.w),
              Expanded(child: _buildGenderOption('female', '👩 女性')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = value;
        });
        _updateProgress();
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? const Color(0xFF667EEA)
                : const Color(0xFFE2E8F0),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12.r),
          color: isSelected ? const Color(0xFF667EEA) : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF2D3748),
            ),
          ),
        ),
      ),
    ).animate(target: isSelected ? 1 : 0);
  }

  Widget _buildHeightField() {
    return _buildAnimatedFormField(
      delay: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('身高'),
          Gap(6.h),
          FormBuilderTextField(
            name: 'height',
            decoration: _buildInputDecoration('请输入您的身高').copyWith(
              suffixText: 'cm',
              suffixStyle: TextStyle(
                color: const Color(0xFF718096),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: '请输入身高'),
              FormBuilderValidators.numeric(errorText: '请输入有效数字'),
              FormBuilderValidators.min(100, errorText: '身高不能少于100cm'),
              FormBuilderValidators.max(250, errorText: '身高不能超过250cm'),
            ]),
            onChanged: (value) {
              if (value != null && value.isNotEmpty) {
                _height = double.tryParse(value);
              } else {
                _height = null;
              }
              _updateProgress();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeightFields() {
    return _buildAnimatedFormField(
      delay: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('体重信息'),
          Gap(6.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前体重',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF718096),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Gap(3.h),
                    FormBuilderTextField(
                      name: 'currentWeight',
                      decoration: _buildInputDecoration('当前体重').copyWith(
                        suffixText: 'kg',
                        suffixStyle: TextStyle(
                          color: const Color(0xFF718096),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '请输入当前体重'),
                        FormBuilderValidators.numeric(errorText: '请输入有效数字'),
                        FormBuilderValidators.min(30, errorText: '体重不能少于30kg'),
                        FormBuilderValidators.max(
                          300,
                          errorText: '体重不能超过300kg',
                        ),
                      ]),
                      onChanged: (value) {
                        if (value != null && value.isNotEmpty) {
                          _currentWeight = double.tryParse(value);
                        } else {
                          _currentWeight = null;
                        }
                        _updateProgress();
                      },
                    ),
                  ],
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '目标体重',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF718096),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Gap(3.h),
                    FormBuilderTextField(
                      name: 'targetWeight',
                      decoration: _buildInputDecoration('目标体重').copyWith(
                        suffixText: 'kg',
                        suffixStyle: TextStyle(
                          color: const Color(0xFF718096),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '请输入目标体重'),
                        FormBuilderValidators.numeric(errorText: '请输入有效数字'),
                        FormBuilderValidators.min(30, errorText: '体重不能少于30kg'),
                        FormBuilderValidators.max(
                          300,
                          errorText: '体重不能超过300kg',
                        ),
                      ]),
                      onChanged: (value) {
                        if (value != null && value.isNotEmpty) {
                          _targetWeight = double.tryParse(value);
                        } else {
                          _targetWeight = null;
                        }
                        _updateProgress();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return _buildAnimatedFormField(
      delay: 500,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _onSubmit,
          style:
              ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ).copyWith(
                elevation: MaterialStateProperty.resolveWith<double>((states) {
                  if (states.contains(MaterialState.pressed)) return 0;
                  return 8;
                }),
                backgroundColor: MaterialStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (states.contains(MaterialState.pressed)) {
                    return const Color(0xFF5A67D8);
                  }
                  return const Color(0xFF667EEA);
                }),
              ),
          child: Text(
            '开始我的减肥之旅 🚀',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFormField({required int delay, required Widget child}) {
    return child
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuart);
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF2D3748),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: const Color(0xFFA0AEC0), fontSize: 14.sp),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    );
  }
}
