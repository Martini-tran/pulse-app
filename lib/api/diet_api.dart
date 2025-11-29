import '../util/request.dart';

/// 饮食记录DTO
class DietRecordDto {
  final String date;
  final String breakfast;
  final String lunch;
  final String dinner;
  final double weight;
  final String? notes;
  final int? calories;

  DietRecordDto({
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.weight,
    this.notes,
    this.calories,
  });

  factory DietRecordDto.fromJson(Map<String, dynamic> json) {
    return DietRecordDto(
      date: json['date'] as String? ?? '',
      breakfast: json['breakfast'] as String? ?? '',
      lunch: json['lunch'] as String? ?? '',
      dinner: json['dinner'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      calories: json['calories'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
      'weight': weight,
      if (notes != null) 'notes': notes,
      if (calories != null) 'calories': calories,
    };
  }
}



/// 饮食记录相关API服务
class DietApiService {
  static final HttpClient _httpClient = HttpClient.instance;

  /// 获取饮食记录列表
  static Future<ApiResponse<dynamic>> getDietRecords() async {
    try {

      final response = await _httpClient.get<List<dynamic>>(
        '/diet/records'
      );
      if (response.success && response.code == 200 && response.data != null) {
        return response;
      }


      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('获取饮食记录异常: $e');
      return ApiResponse.error("获取饮食记录异常");
    }
  }

  /// 根据日期获取饮食记录
  static Future<ApiResponse<DietRecordDto>> getDietRecordByDate(
    String date,
  ) async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        '/diet/records/$date',
      );

      if (response.success && response.code == 200 && response.data != null) {
        final dietRecord = DietRecordDto.fromJson(response.data!);
        return ApiResponse.success(dietRecord, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('获取饮食记录异常: $e');
      return ApiResponse<DietRecordDto>.error('获取饮食记录失败: $e');
    }
  }

  /// 创建饮食记录
  static Future<ApiResponse<DietRecordDto>> createDietRecord({
    required String date,
    required String breakfast,
    required String lunch,
    required String dinner,
    required double weight,
    String? notes,
    int? calories,
  }) async {
    try {
      final data = {
        'date': date,
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'weight': weight,
        if (notes != null) 'notes': notes,
        if (calories != null) 'calories': calories,
      };

      final response = await _httpClient.post<Map<String, dynamic>>(
        '/diet/records',
        data: data,
      );

      if (response.success &&
          (response.code == 200 || response.code == 201) &&
          response.data != null) {
        final dietRecord = DietRecordDto.fromJson(response.data!);
        return ApiResponse.success(dietRecord, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('创建饮食记录异常: $e');
      return ApiResponse<DietRecordDto>.error('创建饮食记录失败: $e');
    }
  }

  /// 更新饮食记录
  static Future<ApiResponse<DietRecordDto>> updateDietRecord({
    required String date,
    String? breakfast,
    String? lunch,
    String? dinner,
    double? weight,
    String? notes,
    int? calories,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (breakfast != null) data['breakfast'] = breakfast;
      if (lunch != null) data['lunch'] = lunch;
      if (dinner != null) data['dinner'] = dinner;
      if (weight != null) data['weight'] = weight;
      if (notes != null) data['notes'] = notes;
      if (calories != null) data['calories'] = calories;

      final response = await _httpClient.put<Map<String, dynamic>>(
        '/diet/records/$date',
        data: data,
      );

      if (response.success && response.code == 200 && response.data != null) {
        final dietRecord = DietRecordDto.fromJson(response.data!);
        return ApiResponse.success(dietRecord, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('更新饮食记录异常: $e');
      return ApiResponse<DietRecordDto>.error('更新饮食记录失败: $e');
    }
  }

  /// 删除饮食记录
  static Future<ApiResponse<void>> deleteDietRecord(String date) async {
    try {
      final response = await _httpClient.delete<Map<String, dynamic>>(
        '/diet/records/$date',
      );

      if (response.success && response.code == 200) {
        return ApiResponse.success(null, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('删除饮食记录异常: $e');
      return ApiResponse<void>.error('删除饮食记录失败: $e');
    }
  }

  /// 获取饮食统计数据
  static Future<ApiResponse<Map<String, dynamic>>> getDietStatistics({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _httpClient.get<Map<String, dynamic>>(
        '/diet/statistics',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.success && response.code == 200 && response.data != null) {
        return ApiResponse.success(response.data!, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('获取饮食统计异常: $e');
      return ApiResponse<Map<String, dynamic>>.error('获取饮食统计失败: $e');
    }
  }
}
