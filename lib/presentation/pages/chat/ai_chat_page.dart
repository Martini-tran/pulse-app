import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../framework/logger/pulse_logger.dart';
import '../../../framework/storage/user_storage.dart';
import '../../ai/ai_chat_websocket_manager.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({Key? key}) : super(key: key);

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

// 数据操作类型
class DataOperation {
  final String type; // 'weight', 'blood_pressure', 'exercise', etc.
  final String action; // 'add', 'update', 'delete', 'query'
  final Map<String, dynamic> data;
  final String displayText;
  final bool isExecuted;

  DataOperation({
    required this.type,
    required this.action,
    required this.data,
    required this.displayText,
    this.isExecuted = false,
  });

  DataOperation copyWith({bool? isExecuted}) {
    return DataOperation(
      type: type,
      action: action,
      data: data,
      displayText: displayText,
      isExecuted: isExecuted ?? this.isExecuted,
    );
  }
}

class _AIChatPageState extends State<AIChatPage> {
  final logger = PulseLogger();

  List<types.Message> _messages = [];
  late final types.User _user;
  final _assistant = const types.User(
    id: 'ai-assistant',
    firstName: '助',
    lastName: '',
    imageUrl: null,
  );

  // 添加WebSocket相关的状态管理
  late StreamSubscription<AIChatWebSocketStatus> _statusSubscription;
  late StreamSubscription<AIChatMessage> _messageSubscription;
  late StreamSubscription<String> _errorSubscription;

  bool _showFloatingTags = false; // 新增：控制悬浮标签显示
  final Map<String, DataOperation> _pendingOperations = {};

  bool _aiIsTyping = false;
  Timer? _typingTimeout;

  @override
  void initState() {
    super.initState();
    _initializeUser(); // 初始化用户信息
    _initializeWebSocket(); // 初始化WebSocket
  }

  @override
  void dispose() {
    // 取消WebSocket订阅
    _statusSubscription.cancel();
    _messageSubscription.cancel();
    _errorSubscription.cancel();

    // 断开WebSocket连接
    AIChatWebSocketUtil.disconnect();
    super.dispose();
  }

  void _initializeUser() {
    // 从UserStorage获取用户ID，如果没有则使用默认值
    final userId =
        UserStorage.userId?.toString() ??
        'user_${DateTime.now().millisecondsSinceEpoch}';
    _user = types.User(id: userId);
  }

  void _loadMessages() {
    const String welcomeText = "嗨～我是你的 AI 健康小帮手 👋 输入『帮助』即可查看所有功能哦～";

    // 添加欢迎消息
    final welcomeMessage = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: welcomeText,
      metadata: {
        "quickActions": [
          {"label": "今日总结", "payload": "今日总结"},
          {"label": "查看统计", "payload": "查看统计"},
        ],
      },
    );
    setState(() {
      _messages = [welcomeMessage];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
      appBar: _buildCompactAppBar(isDark),
      body: Column(
        children: [
          // 聊天界面
          Expanded(
            child: Stack(
              children: [
                Chat(
                  messages: _messages,
                  onSendPressed: _handleSendPressed,
                  onAttachmentPressed: _handleAttachmentPressed,
                  user: _user,
                  theme: _buildChatTheme(isDark),
                  inputOptions: InputOptions(
                    inputClearMode: InputClearMode.always,
                    keyboardType: TextInputType.multiline,
                    sendButtonVisibilityMode: SendButtonVisibilityMode.always,
                  ),
                  l10n: const ChatL10nZhCN(
                    inputPlaceholder: '请输入',
                    emptyChatPlaceholder: '开始对话吧',
                    attachmentButtonAccessibilityLabel: '发送媒体',
                    sendButtonAccessibilityLabel: '发送',
                    and: '和',
                    isTyping: '正在输入',
                    others: '其他',
                  ),
                  showUserAvatars: true,
                  showUserNames: false,
                  bubbleBuilder: _buildCustomBubble,
                ),

                // 悬浮标签菜单
                if (_showFloatingTags) _buildFloatingTagsMenu(isDark),

                // 👇 新增：AI 正在输入指示器
                if (_aiIsTyping) _buildTypingIndicator(isDark),
              ],
            ),
          ),

          // 数据操作确认面板
          if (_pendingOperations.isNotEmpty) _buildOperationPanel(isDark),
        ],
      ),
    );
  }

  /// 在AppBar中添加连接状态指示器
  PreferredSizeWidget _buildCompactAppBar(bool isDark) {
    return AppBar(
      toolbarHeight: 50.h,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: _getConnectionColor(),
              shape: BoxShape.circle,
            ),
            child: Icon(_getConnectionIcon(), color: Colors.white, size: 12.w),
          ),
          Gap(6.w),
          AutoSizeText(
            "健身助手",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
            maxLines: 1,
          ),
          // 添加连接状态文本
          if (!AIChatWebSocketUtil.isConnected) ...[
            Gap(4.w),
            AutoSizeText(
              "(离线)",
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.3, end: 0),
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      elevation: 0,
      shadowColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, size: 18.w),
        onPressed: () => Navigator.pop(context),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
      actions: [
        // 添加连接/断开按钮
        IconButton(
          icon: Icon(
            AIChatWebSocketUtil.isConnected ? Icons.link : Icons.link_off,
            size: 18.w,
          ),
          onPressed: _toggleConnection,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: Icon(
            _showFloatingTags ? Icons.label : Icons.label_outline,
            size: 18.w,
          ),
          onPressed: () {
            setState(() {
              _showFloatingTags = !_showFloatingTags;
            });
          },
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: Icon(Icons.refresh, size: 18.w),
          onPressed: _clearChat,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        Gap(4.w),
      ],
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Positioned(
      left: 12.w,
      right: 12.w,
      bottom: 60.h, // 刚好在输入框上面
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 助手头像圆点
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 14,
              color: Colors.white,
            ),
          ),

          SizedBox(width: 8.w),

          // 气泡 + 动画省电样式
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF0F0F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _typingDot(isDark).animate(onPlay: (c) => c.repeat()).scale(),
                SizedBox(width: 4.w),
                _typingDot(
                  isDark,
                ).animate(delay: 150.ms, onPlay: (c) => c.repeat()).scale(),
                SizedBox(width: 4.w),
                _typingDot(
                  isDark,
                ).animate(delay: 300.ms, onPlay: (c) => c.repeat()).scale(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingDot(bool isDark) {
    return Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFB8BCC8) : const Color(0xFF667EEA),
            shape: BoxShape.circle,
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
        )
        .then(delay: 100.ms)
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(0.8, 0.8),
          duration: 600.ms,
        );
  }

  // 悬浮标签菜单
  Widget _buildFloatingTagsMenu(bool isDark) {
    return Positioned(
      bottom: 80.h, // 在输入框上方
      left: 12.w,
      right: 12.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1A1A).withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏和关闭按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AutoSizeText(
                  "快捷操作",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _showFloatingTags = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(12.w),
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      Icons.close,
                      size: 16.w,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            Gap(8.h),
            // 标签按钮
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                _buildFloatingTagButton(
                  "🍎 饮食生成",
                  () => _quickRecordDiet(),
                  isDark,
                ),
                _buildFloatingTagButton(
                  "📈 查看统计",
                  () => _quickViewStats(),
                  isDark,
                ),
                _buildFloatingTagButton(
                  "📅 今日总结",
                  () => _quickDailySummary(),
                  isDark,
                ),
              ],
            ),
          ],
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 300.ms).fadeIn(),
    );
  }

  // 悬浮标签按钮
  Widget _buildFloatingTagButton(
    String text,
    VoidCallback onPressed,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        onPressed();
        // 点击后可以选择是否隐藏菜单
        setState(() {
          _showFloatingTags = false;
        });
      },
      borderRadius: BorderRadius.circular(20.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFF667EEA).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.w),
          border: Border.all(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: AutoSizeText(
          text,
          style: TextStyle(
            fontSize: 11.sp,
            color: const Color(0xFF667EEA),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _buildReplyTags(types.TextMessage msg) {
    // 1) 优先：后端或上游在 message.metadata.quickActions 下发的标签
    final metaTags = (msg.metadata?['quickActions'] as List?)
        ?.map((e) {
          final m = e as Map;
          return {
            "label": (m["label"] as String?) ?? "操作",
            "payload": (m["payload"] as String?) ?? "",
          };
        })
        .where((m) => (m["label"]?.isNotEmpty ?? false))
        .toList();

    if (metaTags != null && metaTags.isNotEmpty) return metaTags;

    // 2) 兜底默认标签：也可按消息内容/场景做更智能的推荐
    return const [];
  }

  // 自定义气泡构建器 - 支持Markdown渲染
  Widget _buildCustomBubble(
    Widget child, {
    required types.Message message,
    required bool nextMessageInGroup,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // AI助手消息 - 现代化样式
    if (message is types.TextMessage && message.author.id == _assistant.id) {
      final replyTags = _buildReplyTags(message);

      return Container(
        margin: EdgeInsets.only(
          left: 12.w,
          right: 50.w, // 右侧留更多空间，更自然
          top: nextMessageInGroup ? 2.h : 8.h,
          bottom: 2.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主消息气泡
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                  bottomLeft: nextMessageInGroup
                      ? Radius.circular(6.r)
                      : Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    offset: Offset(0, 2.h),
                    blurRadius: 8.r,
                  ),
                ],
                border: isDark
                    ? null
                    : Border.all(color: const Color(0xFFF0F0F0), width: 1),
              ),
              child: MarkdownBody(
                data: message.text,
                styleSheet: _buildMarkdownStyle(isDark),
                selectable: true,
                onTapLink: (text, href, title) {
                  if (href != null) {
                    _showSnackBar('链接: $href');
                  }
                },
              ),
            ),

            // 快速回复标签 - 紧贴气泡下方
            if (replyTags.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.only(left: 4.w),
                child: Wrap(
                  spacing: 4.w,
                  runSpacing: 3.h,
                  children: replyTags
                      .map((tag) => _buildQuickReplyChip(tag, isDark))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 用户消息保持原来的样式
    if (message is types.TextMessage && message.author.id == _user.id) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF667EEA), // 保持你原来的用户消息背景色
          borderRadius: BorderRadius.circular(12.w),
        ),
        child: child,
      );
    }

    // 其他消息类型保持默认
    return child;
  }

  // 快速回复标签组件
  Widget _buildQuickReplyChip(Map<String, String> tag, bool isDark) {
    final label = tag["label"]!;
    final payload = tag["payload"] ?? "";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendQuickPayload(payload),
        borderRadius: BorderRadius.circular(12.r),
        splashColor: const Color(0xFF667EEA).withOpacity(0.1),
        highlightColor: const Color(0xFF667EEA).withOpacity(0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDark ? const Color(0xFF404040) : const Color(0xFFE9ECEF),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFB8BCC8)
                      : const Color(0xFF6C757D),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Markdown样式配置
  MarkdownStyleSheet _buildMarkdownStyle(bool isDark) {
    return MarkdownStyleSheet(
      p: TextStyle(
        color: isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A),
        fontSize: 14.sp,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      h1: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      h2: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 19.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      h3: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      strong: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w700,
      ),
      em: TextStyle(
        color: isDark ? const Color(0xFFB8BCC8) : const Color(0xFF6C757D),
        fontStyle: FontStyle.italic,
      ),
      code: TextStyle(
        backgroundColor: isDark
            ? const Color(0xFF2D2D2D)
            : const Color(0xFFF1F3F4),
        color: const Color(0xFF667EEA),
        fontSize: 13.sp,
        fontFamily: 'SF Mono',
        fontWeight: FontWeight.w500,
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? const Color(0xFF404040) : const Color(0xFFE9ECEF),
          width: 1,
        ),
      ),
      codeblockPadding: EdgeInsets.all(14.w),
      blockquote: TextStyle(
        color: isDark ? const Color(0xFFB8BCC8) : const Color(0xFF6C757D),
        fontSize: 14.sp,
        fontStyle: FontStyle.italic,
        height: 1.4,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: const Color(0xFF667EEA), width: 3.w),
        ),
      ),
      blockquotePadding: EdgeInsets.only(left: 14.w, top: 2.h, bottom: 2.h),
      listBullet: TextStyle(
        color: const Color(0xFF667EEA),
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
      ),
      a: TextStyle(
        color: const Color(0xFF667EEA),
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // 优化的快速回复发送方法
  void _sendQuickPayload(String text) {
    if (text.trim().isEmpty) return;

    // 添加触觉反馈
    HapticFeedback.lightImpact();

    final userMsg = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: text,
    );

    _addMessage(userMsg);
    _sendToAIWebSocket(text, userMsg.id);
  }

  // 构建聊天主题
  DefaultChatTheme _buildChatTheme(bool isDark) {
    return DefaultChatTheme(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
      primaryColor: const Color(0xFF667EEA),
      secondaryColor: isDark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFFF0F0F0),
      inputBackgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      inputTextColor: isDark ? Colors.white : Colors.black87,
      inputBorderRadius: BorderRadius.circular(20.w),
      messageBorderRadius: 12.w,
      userAvatarNameColors: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
      receivedMessageBodyTextStyle: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 14.sp,
        height: 1.3,
      ),
      sentMessageBodyTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14.sp,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
      inputTextStyle: TextStyle(
        fontSize: 14.sp,
        color: isDark ? Colors.white : Colors.black87,
      ),
      inputPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      messageInsetsHorizontal: 12.w,
      messageInsetsVertical: 8.h,
    );
  }

  // 数据操作确认面板
  Widget _buildOperationPanel(bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "待确认操作",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Gap(8.h),
          ..._pendingOperations.entries.map((entry) {
            final operation = entry.value;
            final messageId = entry.key;
            return _buildOperationCard(operation, isDark, messageId);
          }).toList(),
        ],
      ),
    );
  }

  // 数据操作确认卡片
  Widget _buildOperationCard(
    DataOperation operation,
    bool isDark,
    String messageId,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: operation.isExecuted
            ? (isDark ? Colors.green[800]!.withOpacity(0.3) : Colors.green[50])
            : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F4FF)),
        border: Border.all(
          color: operation.isExecuted
              ? Colors.green[300]!
              : const Color(0xFF667EEA).withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                operation.isExecuted ? Icons.check_circle : Icons.data_usage,
                size: 16.w,
                color: operation.isExecuted
                    ? Colors.green[600]
                    : const Color(0xFF667EEA),
              ),
              Gap(8.w),
              Expanded(
                child: Text(
                  operation.displayText,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          if (!operation.isExecuted) ...[
            Gap(12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _cancelOperation(messageId),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                  ),
                  child: Text(
                    "取消",
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ),
                Gap(8.w),
                ElevatedButton(
                  onPressed: () => _executeOperation(operation, messageId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 6.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.w),
                    ),
                  ),
                  child: Text("确认执行", style: TextStyle(fontSize: 12.sp)),
                ),
              ],
            ),
          ] else ...[
            Gap(8.h),
            Text(
              "✅ 操作已完成",
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 修改原有的发送消息方法，使用WebSocket
  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);

    // 使用WebSocket发送消息而不是HTTP
    _sendToAIWebSocket(message.text, textMessage.id);
  }

  /// 通过WebSocket发送消息给AI
  void _sendToAIWebSocket(String text, String messageId) {
    if (!AIChatWebSocketUtil.isConnected) {
      _showSnackBar('AI助手未连接，消息将在连接后发送');
    }

    AIChatWebSocketUtil.sendChat(
      text,
      messageId: messageId,
      extraData: {
        'timestamp': DateTime.now().toIso8601String(),
        'language': 'zh_CN',
        'chatType': 'health_assistant',
      },
    );
  }

  // 处理附件 - 直接选择图片
  void _handleAttachmentPressed() {
    _handleImageSelection();
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);

      // 使用WebSocket发送图片分析请求
      AIChatWebSocketUtil.sendImageAnalysis(
        result.path,
        description: '请分析这张图片',
        messageId: message.id,
      );
    }
  }

  void _handleFileSelection() async {
    // 这里可以添加文件选择逻辑
    _showSnackBar("文件选择功能开发中");
  }

  void _quickViewStats() {
    AIChatWebSocketUtil.sendQuickAction('view_stats');
  }

  void _quickDailySummary() {
    AIChatWebSocketUtil.sendQuickAction('daily_summary');
  }

  void _quickRecordDiet() {
    AIChatWebSocketUtil.sendQuickAction('record_diet');
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  /// 修改清空聊天方法，同时清空离线队列
  void _clearChat() {
    setState(() {
      _messages.clear();
      _pendingOperations.clear();
    });

    // 清空WebSocket离线消息队列
    AIChatWebSocketUtil.clearMessageQueue();

    _loadMessages();
    _showSnackBar("对话已清空");
  }

  void _addAIResponse(String response, [DataOperation? operation]) {
    final messageId = const Uuid().v4();
    final message = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: messageId,
      text: response,
    );

    if (operation != null) {
      _pendingOperations[messageId] = operation;
    }

    _addMessage(message);
  }

  void _addAImetaDataResponse(
    String response,
    Map<String, dynamic>? metadata, [
    DataOperation? operation,
  ]) {
    final messageId = const Uuid().v4();
    final message = types.TextMessage(
      author: _assistant,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: messageId,
      text: response,
      metadata: metadata,
    );

    if (operation != null) {
      _pendingOperations[messageId] = operation;
    }

    _addMessage(message);
  }

  // 执行数据操作
  void _executeOperation(DataOperation operation, String messageId) async {
    _showSnackBar("正在执行操作...");

    // 通过WebSocket发送数据操作请求
    AIChatWebSocketUtil.sendDataOperation(
      type: operation.type,
      action: operation.action,
      data: operation.data,
      messageId: messageId,
    );

    // 标记为正在处理
    setState(() {
      _pendingOperations[messageId] = operation.copyWith(isExecuted: false);
    });
  }

  // 取消数据操作
  void _cancelOperation(String messageId) {
    setState(() {
      _pendingOperations.remove(messageId);
    });
    _addAIResponse("好的，已取消该操作。还有其他需要帮助的吗？");
  }

  // 调用数据API（模拟）
  Future<bool> _callDataAPI(DataOperation operation) async {
    // 模拟API调用
    return true;
  }

  String _getBloodPressureAdvice(Map<String, dynamic> data) {
    final systolic = data['systolic'] as int;
    final diastolic = data['diastolic'] as int;

    if (systolic < 120 && diastolic < 80) {
      return "血压正常，继续保持健康的生活方式。";
    } else if (systolic >= 140 || diastolic >= 90) {
      return "血压偏高，建议咨询医生并注意饮食清淡、适量运动。";
    } else {
      return "血压略高，建议保持健康饮食和规律运动。";
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return; // 1) 页面已卸载直接返回

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return; // 2) 没有可用的 messenger 就不弹

    // 3) 避免堆叠，先收起当前的
    messenger.hideCurrentSnackBar();

    // 4) 给浮动 Snackbar 预留边距，避免被键盘/底部面板挡住
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade400
            : const Color(0xFF667EEA),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(left: 16, right: 16, bottom: 16 + bottomInset),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 初始化WebSocket连接
  void _initializeWebSocket() {
    try {
      AIChatWebSocketUtil.init(
        // serverUrl: 'ws://192.168.31.6:10801/pulse/ws/chat', // 🔧 修改为您的服务器地址
        serverUrl: 'ws://127.0.0.1:10801/pulse/ws/chat',
        // serverUrl: 'ws://140.143.22.164:10801/pulse/ws/chat',
        // 🔧 修改为您的服务器地址
        // userId: "3", // 使用现有的用户ID
        userId: _user.id,
        // 使用现有的用户ID
        sessionId: 'health_chat_${DateTime.now().millisecondsSinceEpoch}',
        heartbeatInterval: const Duration(seconds: 30),
        reconnectInterval: const Duration(seconds: 3),
        maxReconnectAttempts: 10,
        autoReconnect: true,
        enableOfflineQueue: true,
      );
      // 监听WebSocket状态变化
      _statusSubscription = AIChatWebSocketUtil.statusStream.listen((status) {
        _handleWebSocketStatusChange(status);
      });

      // 监听WebSocket消息
      _messageSubscription = AIChatWebSocketUtil.messageStream.listen((
        message,
      ) {
        _handleWebSocketMessage(message);
      });

      // 监听WebSocket错误
      _errorSubscription = AIChatWebSocketUtil.errorStream.listen((error) {
        _handleWebSocketError(error);
      });

      // 连接WebSocket
      _connectWebSocket();
      _loadMessages();
    } catch (e, stack) {
      print("❌ Error: $e");
      print("📌 Stacktrace: $stack");
      logger.error("连接失败", e);
      logger.error("连接失败" + UserStorage.userId.toString());
    }
  }

  /// 连接WebSocket
  Future<void> _connectWebSocket() async {
    try {
      await AIChatWebSocketUtil.connect();
    } catch (e) {
      debugPrint('WebSocket连接失败: $e');
    }
  }

  /// 处理WebSocket状态变化
  void _handleWebSocketStatusChange(AIChatWebSocketStatus status) {
    switch (status) {
      case AIChatWebSocketStatus.connected:
        _showSnackBar('✅ AI助手已连接');
        // 可以更新UI显示连接状态
        break;
      case AIChatWebSocketStatus.disconnected:
        _showSnackBar('❌ AI助手连接断开');
        break;
      case AIChatWebSocketStatus.reconnecting:
        _showSnackBar('🔄 正在重连AI助手...');
        break;
      case AIChatWebSocketStatus.error:
        _showSnackBar('⚠️ AI助手连接错误', isError: true);
        break;
      case AIChatWebSocketStatus.connecting:
        _showSnackBar('🔗 正在连接AI助手...');
        break;
    }
  }

  void _handleWebSocketMessage(AIChatMessage wsMessage) {
    switch (wsMessage.type) {
      case 'text':
      case 'chat':
        // 普通聊天消息
        _addAImetaDataResponse(wsMessage.content ?? '', wsMessage.metadata);
        break;

      case 'data_operation_response':
        // 数据操作响应
        _handleDataOperationResponse(wsMessage);
        break;

      case 'image_analysis_response':
        // 图片分析响应
        _handleImageAnalysisResponse(wsMessage);
        break;
      case 'typing':
        // AI正在输入（可选实现）
        _handleTypingIndicator(wsMessage);
        break;

      default:
        debugPrint('未知消息类型: ${wsMessage.type}');
    }
  }

  /// 处理WebSocket错误
  void _handleWebSocketError(String error) {
    _showSnackBar('WebSocket错误: $error', isError: true);
  }

  /// 处理数据操作响应
  void _handleDataOperationResponse(AIChatMessage wsMessage) {
    final success = wsMessage.data?['success'] ?? false;
    if (success) {
      _showSnackBar("✅ 数据记录成功！");
      // 添加AI成功响应
      final successMessage = wsMessage.data?['message'];
      _addAIResponse(successMessage);
    } else {
      _showSnackBar("❌ 操作失败，请重试", isError: true);
      // 添加AI错误响应
      final errorMessage = wsMessage.data?['error'] ?? "操作执行失败，请稍后重试。";
      _addAIResponse(errorMessage);
    }
  }

  /// 处理图片分析响应
  void _handleImageAnalysisResponse(AIChatMessage wsMessage) {
    final analysis = wsMessage.content ?? '图片分析完成';
    _addAIResponse(analysis);

    // 如果有结构化数据，可以进一步处理
    if (wsMessage.data != null) {
      final analysisData = wsMessage.data!;

      // 检查是否有可执行的数据操作
      if (analysisData['suggestedOperations'] != null) {
        final operations = analysisData['suggestedOperations'] as List;
        for (final opData in operations) {
          final operation = DataOperation(
            type: opData['type'],
            action: opData['action'],
            data: opData['data'],
            displayText: opData['displayText'],
          );

          final operationMessageId = const Uuid().v4();
          _pendingOperations[operationMessageId] = operation;
        }

        if (operations.isNotEmpty) {
          setState(() {}); // 刷新UI显示待执行操作
        }
      }
    }
  }

  /// 处理打字指示器
  void _handleTypingIndicator(AIChatMessage wsMessage) {
    final isTyping = wsMessage.data?['isTyping'] ?? false;

    // 清理上次的超时
    _typingTimeout?.cancel();

    setState(() {
      _aiIsTyping = isTyping;
    });

    // 安全兜底：若 5 秒内没收到“停止打字”，自动收起提示
    if (isTyping) {
      _typingTimeout = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _aiIsTyping = false);
        }
      });
    }
  }

  /// 处理统计数据响应
  void _handleStatsResponse(Map<String, dynamic>? data) {
    if (data != null) {
      final stats = data['stats'] as Map<String, dynamic>?;
      if (stats != null) {
        String statsText = "📊 您的健康数据统计：\n\n";

        if (stats['weight'] != null) {
          final weightData = stats['weight'];
          statsText += "⚖️ 体重：${weightData['current']}kg\n";
          statsText += "   趋势：${weightData['trend']}\n\n";
        }

        if (stats['bloodPressure'] != null) {
          final bpData = stats['bloodPressure'];
          statsText +=
              "🩸 血压：${bpData['systolic']}/${bpData['diastolic']}mmHg\n";
          statsText += "   状态：${bpData['status']}\n\n";
        }

        if (stats['exercise'] != null) {
          final exerciseData = stats['exercise'];
          statsText += "🏃‍♂️ 运动：本周${exerciseData['weeklyTotal']}分钟\n";
          statsText += "   目标完成度：${exerciseData['goalProgress']}%\n";
        }

        _addAIResponse(statsText);
      }
    }
  }

  /// 处理每日总结响应
  void _handleDailySummaryResponse(Map<String, dynamic>? data) {
    if (data != null) {
      final summary = data['summary'] as String?;
      if (summary != null) {
        _addAIResponse(summary);
      }

      // 如果有建议，也添加到响应中
      final suggestions = data['suggestions'] as List?;
      if (suggestions != null && suggestions.isNotEmpty) {
        String suggestionText = "\n💡 今日建议：\n";
        for (int i = 0; i < suggestions.length; i++) {
          suggestionText += "• ${suggestions[i]}\n";
        }
        _addAIResponse(suggestionText);
      }
    }
  }

  /// 获取连接状态颜色
  Color _getConnectionColor() {
    switch (AIChatWebSocketUtil.status) {
      case AIChatWebSocketStatus.connected:
        return const Color(0xFF4CAF50); // 绿色
      case AIChatWebSocketStatus.connecting:
      case AIChatWebSocketStatus.reconnecting:
        return const Color(0xFFFFA726); // 橙色
      case AIChatWebSocketStatus.error:
        return const Color(0xFFF44336); // 红色
      case AIChatWebSocketStatus.disconnected:
      default:
        return const Color(0xFF9E9E9E); // 灰色
    }
  }

  /// 获取连接状态图标
  IconData _getConnectionIcon() {
    switch (AIChatWebSocketUtil.status) {
      case AIChatWebSocketStatus.connected:
        return Icons.smart_toy_outlined;
      case AIChatWebSocketStatus.connecting:
      case AIChatWebSocketStatus.reconnecting:
        return Icons.sync;
      case AIChatWebSocketStatus.error:
        return Icons.error_outline;
      case AIChatWebSocketStatus.disconnected:
      default:
        return Icons.smart_toy_outlined;
    }
  }

  // 切换连接状态
  void _toggleConnection() async {
    if (AIChatWebSocketUtil.isConnected) {
      AIChatWebSocketUtil.disconnect();
      _showSnackBar("已断开AI助手连接");
    } else {
      await _connectWebSocket();
    }
  }

  /// 添加一个方法来显示WebSocket调试信息（可选）
  void _showWebSocketDebugInfo() {
    final status = AIChatWebSocketUtil.status;
    final queueCount = AIChatWebSocketUtil.queuedMessageCount;
    final userId = AIChatWebSocketUtil.userId;
    final sessionId = AIChatWebSocketUtil.sessionId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WebSocket 调试信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('状态: $status'),
            Text('用户ID: $userId'),
            Text('会话ID: $sessionId'),
            Text('离线队列: $queueCount 条消息'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

// 中文本地化
class ChatL10nZhCN extends ChatL10n {
  const ChatL10nZhCN({
    String attachmentButtonAccessibilityLabel = '发送媒体',
    String emptyChatPlaceholder = '暂无消息',
    String fileButtonAccessibilityLabel = '文件',
    String inputPlaceholder = '输入消息...',
    String sendButtonAccessibilityLabel = '发送',
    String unreadMessagesLabel = '未读消息',
    String and = '和',
    String isTyping = '正在输入',
    String others = '其他',
  }) : super(
         attachmentButtonAccessibilityLabel: attachmentButtonAccessibilityLabel,
         emptyChatPlaceholder: emptyChatPlaceholder,
         fileButtonAccessibilityLabel: fileButtonAccessibilityLabel,
         inputPlaceholder: inputPlaceholder,
         sendButtonAccessibilityLabel: sendButtonAccessibilityLabel,
         unreadMessagesLabel: unreadMessagesLabel,
         and: and,
         isTyping: isTyping,
         others: others,
       );
}
