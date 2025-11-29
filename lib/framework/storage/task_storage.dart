import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/task_item.dart';
import '../../api/task_api.dart';

/// 任务本地存储管理器
class TaskStorage {
  static const String _tasksKey = 'daily_tasks';
  static const String _completedTasksKey = 'completed_tasks_today';

  // 内存缓存
  static List<TaskItem>? _cachedTasks;
  static Set<String>? _cachedCompletedToday;

  /// 获取缓存的任务列表
  static List<TaskItem> get cachedTasks => _cachedTasks ?? [];

  /// 获取今日已完成任务ID集合
  static Set<String> get completedTasksToday => _cachedCompletedToday ?? {};

  /// 初始化缓存
  static Future<void> initCache() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载任务列表
    final tasksJson = prefs.getString(_tasksKey);
    if (tasksJson != null) {
      try {
        final tasksList = jsonDecode(tasksJson) as List;
        _cachedTasks = tasksList.map((json) => TaskItem.fromJson(json)).toList();
      } catch (_) {
        _cachedTasks = [];
      }
    } else {
      _cachedTasks = [];
    }

    // 加载今日完成任务
    final completedJson = prefs.getString(_completedTasksKey);
    if (completedJson != null) {
      try {
        final completedData = jsonDecode(completedJson) as Map<String, dynamic>;
        final today = DateTime.now().toIso8601String().substring(0, 10);
        if (completedData['date'] == today) {
          _cachedCompletedToday = Set<String>.from(completedData['tasks']);
        } else {
          _cachedCompletedToday = <String>{};
        }
      } catch (_) {
        _cachedCompletedToday = <String>{};
      }
    } else {
      _cachedCompletedToday = <String>{};
    }
  }

  /// 保存任务列表
  static Future<void> saveTasks(List<TaskItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_tasksKey, tasksJson);
    _cachedTasks = tasks;
  }

  /// 标记任务完成状态
  static Future<void> markTaskCompleted(String taskId, bool isCompleted) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // 更新今日完成任务集合
    final completedToday = Set<String>.from(_cachedCompletedToday ?? {});
    if (isCompleted) {
      completedToday.add(taskId);
    } else {
      completedToday.remove(taskId);
    }

    // 保存到本地存储
    final completedData = {
      'date': today,
      'tasks': completedToday.toList(),
    };
    await prefs.setString(_completedTasksKey, jsonEncode(completedData));
    _cachedCompletedToday = completedToday;

    // 更新任务列表中的完成状态
    if (_cachedTasks != null) {
      final updatedTasks = _cachedTasks!.map((task) {
        if (task.id == taskId) {
          return task.copyWith(
            isCompleted: isCompleted,
            completedAt: isCompleted ? DateTime.now() : null,
          );
        }
        return task;
      }).toList();
      await saveTasks(updatedTasks);
    }
  }

  /// 获取默认的每日建议任务
  static List<TaskItem> getDefaultDailyTasks() {
    final now = DateTime.now();
    return [
      TaskItem(
        id: 'protein_task',
        title: '🥚 增加蛋白质',
        subtitle: '每餐+20g',
        createdAt: now,
      ),
      TaskItem(
        id: 'water_task',
        title: '💧 多喝水',
        subtitle: '目标2.5L',
        createdAt: now,
      ),
      TaskItem(
        id: 'walk_task',
        title: '🚶‍♂️ 饭后散步',
        subtitle: '15-20分钟',
        createdAt: now,
      ),
      TaskItem(
        id: 'sleep_task',
        title: '😴 早点休息',
        subtitle: '23:00前',
        createdAt: now,
      ),
    ];
  }

  /// 初始化默认任务（如果没有任务）
  static Future<void> initDefaultTasksIfEmpty() async {
    if (_cachedTasks == null || _cachedTasks!.isEmpty) {
      final defaultTasks = getDefaultDailyTasks();
      await saveTasks(defaultTasks);
    }
  }

  /// 同步今日完成的任务到后端
  static Future<bool> syncTodayCompletionsToBackend() async {
    try {
      if (_cachedTasks == null || _cachedCompletedToday == null) {
        return false;
      }

      final completedTasks = _cachedTasks!
          .where((task) => _cachedCompletedToday!.contains(task.id))
          .toList();

      if (completedTasks.isEmpty) {
        return true; // 没有需要同步的任务
      }

      final taskCompletions = completedTasks.map((task) => TaskCompletionDto(
        taskId: task.id,
        title: task.title,
        isCompleted: true,
        completedAt: task.completedAt ?? DateTime.now(),
      )).toList();

      final response = await TaskApiService.syncMultipleTaskCompletions(taskCompletions);
      return response.success;
    } catch (e) {
      print('同步今日任务完成状态失败: $e');
      return false;
    }
  }

  /// 从后端获取并更新今日任务完成状态
  static Future<bool> syncCompletionsFromBackend() async {
    try {
      final response = await TaskApiService.getTodayTaskCompletions();
      if (response.success && response.data != null) {
        final completedTaskIds = response.data!
            .where((completion) => completion.isCompleted)
            .map((completion) => completion.taskId)
            .toSet();

        // 更新本地缓存
        _cachedCompletedToday = completedTaskIds;

        // 保存到本地存储
        final prefs = await SharedPreferences.getInstance();
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final completedData = {
          'date': today,
          'tasks': completedTaskIds.toList(),
        };
        await prefs.setString(_completedTasksKey, jsonEncode(completedData));

        return true;
      }
      return false;
    } catch (e) {
      print('从后端同步任务完成状态失败: $e');
      return false;
    }
  }

  /// 双向同步：先从后端获取，再推送本地更改
  static Future<bool> bidirectionalSync() async {
    try {
      // 1. 先从后端获取最新状态
      final syncFromBackend = await syncCompletionsFromBackend();
      
      // 2. 再推送本地的更改到后端
      final syncToBackend = await syncTodayCompletionsToBackend();
      
      return syncFromBackend && syncToBackend;
    } catch (e) {
      print('双向同步失败: $e');
      return false;
    }
  }

  /// 清除所有任务数据
  static Future<void> clearAllTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
    await prefs.remove(_completedTasksKey);
    _cachedTasks = [];
    _cachedCompletedToday = <String>{};
  }
}
