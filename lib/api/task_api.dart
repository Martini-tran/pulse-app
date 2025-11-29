import 'dart:convert';
import '../framework/storage/token_storage.dart';
import '../util/request.dart';
import '../models/task_item.dart';

/// 任务完成记录DTO
class TaskCompletionDto {
  final String taskId;
  final String title;
  final bool isCompleted;
  final DateTime completedAt;

  TaskCompletionDto({
    required this.taskId,
    required this.title,
    required this.isCompleted,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'title': title,
      'is_completed': isCompleted,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  factory TaskCompletionDto.fromJson(Map<String, dynamic> json) {
    return TaskCompletionDto(
      taskId: json['task_id'] as String,
      title: json['title'] as String,
      isCompleted: json['is_completed'] as bool,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }
}

/// 任务相关API服务
class TaskApiService {
  static final HttpClient _httpClient = HttpClient.instance;

  /// 同步任务完成状态到后端
  static Future<ApiResponse<bool>> syncTaskCompletion(TaskCompletionDto taskCompletion) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/task/completion',
        data: taskCompletion.toJson(),
      );

      if (response.success && response.code == 200) {
        return ApiResponse.success(true, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('同步任务完成状态失败: $e');
      return ApiResponse<bool>.error('同步失败: $e');
    }
  }

  /// 批量同步多个任务完成状态
  static Future<ApiResponse<bool>> syncMultipleTaskCompletions(List<TaskCompletionDto> taskCompletions) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        '/task/completion/batch',
        data: taskCompletions.map((task) => task.toJson()).toList(),
      );

      if (response.success && response.code == 200) {
        return ApiResponse.success(true, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('批量同步任务完成状态失败: $e');
      return ApiResponse<bool>.error('批量同步失败: $e');
    }
  }

  /// 获取用户的任务完成历史
  static Future<ApiResponse<List<TaskCompletionDto>>> getTaskCompletionHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().substring(0, 10);
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().substring(0, 10);
      }

      final response = await _httpClient.get<List<dynamic>>(
        '/task/completion/history',
        queryParameters: queryParams,
      );

      if (response.success && response.code == 200 && response.data != null) {
        final taskCompletions = response.data!
            .map((json) => TaskCompletionDto.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(taskCompletions, message: response.message);
      }

      return ApiResponse.error(response.message, code: response.code);
    } catch (e) {
      print('获取任务完成历史失败: $e');
      return ApiResponse<List<TaskCompletionDto>>.error('获取历史失败: $e');
    }
  }

  /// 获取今日任务完成状态
  static Future<ApiResponse<List<TaskCompletionDto>>> getTodayTaskCompletions() async {
    final today = DateTime.now();
    return getTaskCompletionHistory(startDate: today, endDate: today);
  }
}
