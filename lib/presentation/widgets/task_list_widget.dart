import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/task_item.dart';
import '../../framework/storage/task_storage.dart';
import '../../api/task_api.dart';

import '../../../framework/adapter/adaptive_extension.dart';

/// 任务列表组件
class TaskListWidget extends StatefulWidget {
  final bool isDark;
  final Function(String taskId, bool isCompleted)? onTaskToggle;

  const TaskListWidget({
    super.key,
    required this.isDark,
    this.onTaskToggle,
  });

  @override
  State<TaskListWidget> createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget> {
  List<TaskItem> _tasks = [];
  Set<String> _completedToday = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 确保默认任务已初始化
      await TaskStorage.initDefaultTasksIfEmpty();
      
      // 尝试从后端同步任务完成状态
      await TaskStorage.syncCompletionsFromBackend().catchError((error) {
        print('后端同步失败，使用本地数据: $error');
      });
      
      // 加载任务和完成状态
      _tasks = TaskStorage.cachedTasks;
      _completedToday = TaskStorage.completedTasksToday;
    } catch (e) {
      print('加载任务失败: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleTask(String taskId) async {
    final currentTask = _tasks.firstWhere((task) => task.id == taskId);
    final newCompletedState = !_completedToday.contains(taskId);

    setState(() {
      if (newCompletedState) {
        _completedToday.add(taskId);
      } else {
        _completedToday.remove(taskId);
      }
    });

    try {
      // 保存到本地存储
      await TaskStorage.markTaskCompleted(taskId, newCompletedState);

      // 尝试同步到后端
      final taskCompletion = TaskCompletionDto(
        taskId: taskId,
        title: currentTask.title,
        isCompleted: newCompletedState,
        completedAt: DateTime.now(),
      );

      // 异步同步，不阻塞UI
      TaskApiService.syncTaskCompletion(taskCompletion).then((response) {
        if (!response.success) {
          print('同步任务状态失败: ${response.message}');
          // 这里可以添加重试逻辑或者显示错误提示
        }
      }).catchError((error) {
        print('同步任务状态异常: $error');
      });

      // 调用回调函数
      widget.onTaskToggle?.call(taskId, newCompletedState);

    } catch (e) {
      // 如果保存失败，恢复UI状态
      setState(() {
        if (newCompletedState) {
          _completedToday.remove(taskId);
        } else {
          _completedToday.add(taskId);
        }
      });
      print('切换任务状态失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDark 
            ? [const Color(0xFF1F1F1F), const Color(0xFF2A2A2A)]
            : [Colors.white, const Color(0xFFFAFBFF)],
        ),
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: widget.isDark 
              ? Colors.black.withOpacity(0.3)
              : const Color(0xFF667EEA).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.w),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题区域
              Row(
                children: [
                  Icon(
                    Icons.checklist_outlined,
                    color: const Color(0xFF4CAF50),
                    size: 16.w,
                  ),
                  Gap(6.w),
                  AutoSizeText(
                    "今日任务",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                  ),
                  const Spacer(),
                  // 完成进度
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.w),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: AutoSizeText(
                      "${_completedToday.length}/${_tasks.length}",
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4CAF50),
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              Gap(12.h),
              // 任务列表
              ...List.generate(_tasks.length, (index) {
                final task = _tasks[index];
                final isCompleted = _completedToday.contains(task.id);
                return _buildTaskItem(task, isCompleted, index);
              }),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTaskItem(TaskItem task, bool isCompleted, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: index < _tasks.length - 1 ? 8.h : 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.w),
          onTap: () => _toggleTask(task.id),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isCompleted 
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.w),
              border: Border.all(
                color: isCompleted 
                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // 复选框
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF4CAF50) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4.w),
                    border: Border.all(
                      color: isCompleted 
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14.w,
                        )
                      : null,
                ),
                Gap(12.w),
                // 任务内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        task.title,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isCompleted 
                              ? Colors.grey[600]
                              : (widget.isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF2D3748)),
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        minFontSize: 10,
                      ),
                      Gap(2.h),
                      AutoSizeText(
                        task.subtitle,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isCompleted 
                              ? Colors.grey[500]
                              : Colors.grey[600],
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        minFontSize: 8,
                      ),
                    ],
                  ),
                ),
                // 完成状态指示器
                if (isCompleted)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: AutoSizeText(
                      "已完成",
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index))
     .fadeIn(duration: 300.ms)
     .slideX(begin: -0.2, end: 0);
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDark 
            ? [const Color(0xFF1F1F1F), const Color(0xFF2A2A2A)]
            : [Colors.white, const Color(0xFFFAFBFF)],
        ),
        borderRadius: BorderRadius.circular(16.w),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF667EEA),
                ),
              ),
            ),
            Gap(8.h),
            AutoSizeText(
              "加载任务中...",
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
