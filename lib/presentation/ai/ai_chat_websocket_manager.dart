import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

// 正确的条件导入方式
import 'package:web_socket_channel/io.dart';

import '../../framework/storage/token_storage.dart';

/// AI聊天WebSocket连接状态
enum AIChatWebSocketStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// AI聊天消息类型
class AIChatMessage {
  final String type;
  final String? messageId;
  final String? content;
  final Map<String, dynamic>? data;
  final int timestamp;
  final String? userId;
  final String? sessionId;
  final Map<String, dynamic>? metadata; // 新增字段

  AIChatMessage({
    required this.type,
    this.messageId,
    this.content,
    this.data,
    required this.timestamp,
    this.userId,
    this.sessionId,
    this.metadata, // 构造函数支持
  });

  factory AIChatMessage.fromJson(Map<String, dynamic> json) {
    return AIChatMessage(
      type: json['type'] ?? '',
      messageId: json['messageId'],
      content: json['content'],
      data: json['data'],
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      userId: json['userId'],
      sessionId: json['sessionId'],
      metadata: json['metadata'], // 反序列化
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'messageId': messageId,
      'content': content,
      'data': data,
      'timestamp': timestamp,
      'userId': userId,
      'sessionId': sessionId,
      'metadata': metadata, // 序列化
    }..removeWhere((key, value) => value == null);
  }
}


/// AI聊天WebSocket管理器
class AIChatWebSocketManager {
  static final AIChatWebSocketManager _instance =
      AIChatWebSocketManager._internal();
  factory AIChatWebSocketManager() => _instance;
  AIChatWebSocketManager._internal();

  // WebSocket相关
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  // 配置参数
  String? _serverUrl;
  Map<String, String>? _headers;
  String? _userId;
  String? _sessionId;
  Duration _heartbeatInterval = const Duration(seconds: 30);
  Duration _reconnectInterval = const Duration(seconds: 5);
  int _maxReconnectAttempts = 5;
  int _reconnectAttempts = 0;
  bool _autoReconnect = true;

  // 状态管理
  AIChatWebSocketStatus _status = AIChatWebSocketStatus.disconnected;
  final StreamController<AIChatWebSocketStatus> _statusController =
      StreamController<AIChatWebSocketStatus>.broadcast();
  final StreamController<AIChatMessage> _messageController =
      StreamController<AIChatMessage>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // 消息队列（离线消息缓存）
  final List<AIChatMessage> _messageQueue = [];
  bool _enableOfflineQueue = true;

  // Getters
  AIChatWebSocketStatus get status => _status;
  Stream<AIChatWebSocketStatus> get statusStream => _statusController.stream;
  Stream<AIChatMessage> get messageStream => _messageController.stream;
  Stream<String> get errorStream => _errorController.stream;
  bool get isConnected => _status == AIChatWebSocketStatus.connected;
  String? get userId => _userId;
  String? get sessionId => _sessionId;

  /// 初始化配置
  void configure({
    required String serverUrl,
    required String userId,
    String? sessionId,
    Map<String, String>? headers,
    Duration? heartbeatInterval,
    Duration? reconnectInterval,
    int? maxReconnectAttempts,
    bool? autoReconnect,
    bool? enableOfflineQueue,
  }) {
    _serverUrl = serverUrl;
    _userId = userId;
    _sessionId = sessionId ?? _generateSessionId();
    _headers = _buildHeaders(headers);

    if (heartbeatInterval != null) _heartbeatInterval = heartbeatInterval;
    if (reconnectInterval != null) _reconnectInterval = reconnectInterval;
    if (maxReconnectAttempts != null)
      _maxReconnectAttempts = maxReconnectAttempts;
    if (autoReconnect != null) _autoReconnect = autoReconnect;
    if (enableOfflineQueue != null) _enableOfflineQueue = enableOfflineQueue;

    debugPrint('AIChatWebSocket配置完成: $_serverUrl');
  }

  /// 构建请求头
  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{
      'User-Agent': 'Flutter-AI-Chat/1.0',
      'X-Client-Type': 'flutter',
      'X-User-ID': _userId ?? '',
      'X-Session-ID': _sessionId ?? '',
      'X-Client-Version': '1.0.0',
    };

    // Web平台特殊处理
    if (kIsWeb) {
      headers['X-Client-Platform'] = 'web';
      // Web平台不能设置某些受限的头部，浏览器会自动处理
      // 如果需要传递协议，使用Sec-WebSocket-Protocol
    } else {
      headers['X-Client-Platform'] = 'mobile';
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// 生成会话ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_userId ?? 'anonymous'}';
  }

  /// 连接WebSocket
  Future<void> connect() async {
    if (_serverUrl == null || _userId == null) {
      _handleError('WebSocket配置不完整，请先调用configure()');
      return;
    }

    if (_status == AIChatWebSocketStatus.connecting ||
        _status == AIChatWebSocketStatus.connected) {
      debugPrint('WebSocket已连接或正在连接中');
      return;
    }

    _updateStatus(AIChatWebSocketStatus.connecting);
    debugPrint('正在连接AI聊天服务器: $_serverUrl');

    try {
      // 根据平台创建不同的WebSocket连接
      if (kIsWeb) {
        // Web平台：使用WebSocketChannel.connect，浏览器会忽略headers
        final token = _headers?['access_token'];
        final query = <String, String>{};
        if (token != null && token.isNotEmpty) {
          query['access_token'] = token;
        }
        final uri = Uri.parse(_serverUrl!).replace(queryParameters: query);
        _channel = WebSocketChannel.connect(uri);
      } else {
        // 移动端和桌面端：使用IOWebSocketChannel.connect
        _channel = IOWebSocketChannel.connect(
          _serverUrl!,
          headers: _headers,
          pingInterval: _heartbeatInterval,
        );
      }

      // 等待连接建立
      await _channel!.ready;

      _updateStatus(AIChatWebSocketStatus.connected);
      _reconnectAttempts = 0;
      debugPrint('AI聊天WebSocket连接成功');

      // 发送连接确认消息
      _sendConnectionMessage();

      // 开始监听消息
      _listenToMessages();

      // 启动心跳（Web平台浏览器会自动处理ping/pong）
      if (!kIsWeb) {
        _startHeartbeat();
      }

      // 发送离线消息队列
      _sendQueuedMessages();
    } catch (e) {
      _handleError('连接失败: $e');
      if (_autoReconnect) {
        _scheduleReconnect();
      }
    }
  }

  /// 发送连接确认消息
  void _sendConnectionMessage() {
    final connectionMessage = AIChatMessage(
      type: 'connection',
      userId: _userId,
      sessionId: _sessionId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: {
        'platform': kIsWeb ? 'web' : 'mobile',
        'clientVersion': '1.0.0',
        'connectTime': DateTime.now().toIso8601String(),
        'userAgent': kIsWeb ? 'Flutter-Web' : 'Flutter-Mobile',
      },
    );

    _sendMessage(connectionMessage, skipQueue: true);
  }

  /// 监听消息
  void _listenToMessages() {
    _channel?.stream.listen(
      (data) {
        try {
          final jsonData = json.decode(data.toString());
          final message = AIChatMessage.fromJson(jsonData);

          debugPrint('收到AI消息类型: ${message.type}');
          _messageController.add(message);
        } catch (e) {
          debugPrint('解析消息失败: $e, 原始数据: $data');
          // 兼容简单文本消息
          final textMessage = AIChatMessage(
            type: 'text',
            content: data.toString(),
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          _messageController.add(textMessage);
        }
      },
      onDone: () {
        debugPrint('WebSocket连接已关闭');
        _updateStatus(AIChatWebSocketStatus.disconnected);
        _stopHeartbeat();
        if (_autoReconnect && _reconnectAttempts < _maxReconnectAttempts) {
          _scheduleReconnect();
        }
      },
      onError: (error) {
        _handleError('WebSocket错误: $error');
        if (_autoReconnect) {
          _scheduleReconnect();
        }
      },
    );
  }

  /// 发送AI聊天消息
  void sendChatMessage({
    required String content,
    String? messageId,
    String messageType = 'chat',
    Map<String, dynamic>? extraData,
  }) {
    final message = AIChatMessage(
      type: messageType,
      messageId: messageId,
      content: content,
      userId: _userId,
      sessionId: _sessionId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: extraData,
    );

    _sendMessage(message);
  }

  /// 发送数据操作消息（配合您的DataOperation）
  void sendDataOperation({
    required String operationType,
    required String action,
    required Map<String, dynamic> operationData,
    String? messageId,
  }) {
    final message = AIChatMessage(
      type: 'data_operation',
      messageId: messageId,
      userId: _userId,
      sessionId: _sessionId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: {
        'operationType': operationType,
        'action': action,
        'operationData': operationData,
      },
    );

    _sendMessage(message);
  }

  /// 发送图片分析消息
  void sendImageAnalysis({
    required String imagePath,
    String? description,
    String? messageId,
  }) {
    final message = AIChatMessage(
      type: 'image_analysis',
      messageId: messageId,
      content: description,
      userId: _userId,
      sessionId: _sessionId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: {'imagePath': imagePath, 'analysisType': 'health'},
    );

    _sendMessage(message);
  }

  /// 发送快捷操作消息
  void sendQuickAction(String actionType) {
    final message = AIChatMessage(
      type: 'quick_action',
      content: actionType,
      userId: _userId,
      sessionId: _sessionId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      data: {'actionType': actionType},
    );

    _sendMessage(message);
  }

  /// 通用消息发送方法
  void _sendMessage(AIChatMessage message, {bool skipQueue = false}) {
    if (!isConnected) {
      if (_enableOfflineQueue && !skipQueue) {
        _messageQueue.add(message);
        debugPrint('连接断开，消息已加入离线队列');
      } else {
        _handleError('WebSocket未连接，无法发送消息');
      }
      return;
    }

    try {
      final messageJson = json.encode(message.toJson());
      _channel?.sink.add(messageJson);
      debugPrint('发送AI消息类型: ${message.type}');
    } catch (e) {
      _handleError('发送消息失败: $e');

      // 发送失败时加入离线队列
      if (_enableOfflineQueue && !skipQueue) {
        _messageQueue.add(message);
      }
    }
  }

  /// 发送离线消息队列
  void _sendQueuedMessages() {
    if (_messageQueue.isEmpty) return;

    debugPrint('发送${_messageQueue.length}条离线消息');
    final messages = List<AIChatMessage>.from(_messageQueue);
    _messageQueue.clear();

    for (final message in messages) {
      _sendMessage(message, skipQueue: true);
      // 避免消息发送过快
      Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// 启动心跳
  void _startHeartbeat() {
    // Web平台浏览器自动处理ping/pong，不需要手动心跳
    if (kIsWeb) {
      debugPrint('Web平台：浏览器自动处理WebSocket心跳');
      return;
    }

    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (isConnected) {
        final heartbeatMessage = AIChatMessage(
          type: 'heartbeat',
          userId: _userId,
          sessionId: _sessionId,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        _sendMessage(heartbeatMessage, skipQueue: true);
      } else {
        _stopHeartbeat();
      }
    });
  }

  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 计划重连
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _handleError('达到最大重连次数($_maxReconnectAttempts)，停止重连');
      return;
    }

    _updateStatus(AIChatWebSocketStatus.reconnecting);
    _reconnectAttempts++;

    final delay = Duration(
      seconds: _reconnectInterval.inSeconds * _reconnectAttempts,
    );
    debugPrint('${delay.inSeconds}秒后进行第$_reconnectAttempts次重连');

    _reconnectTimer = Timer(delay, () async {
      await connect();
    });
  }

  /// 停止重连计时器
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// 断开连接
  void disconnect() {
    debugPrint('主动断开AI聊天WebSocket连接');
    _autoReconnect = false;
    _stopHeartbeat();
    _stopReconnectTimer();

    // 发送断开连接消息
    if (isConnected) {
      final disconnectMessage = AIChatMessage(
        type: 'disconnect',
        userId: _userId,
        sessionId: _sessionId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _sendMessage(disconnectMessage, skipQueue: true);
    }

    _channel?.sink.close();
    _updateStatus(AIChatWebSocketStatus.disconnected);
  }

  /// 重新连接
  Future<void> reconnect() async {
    debugPrint('手动重新连接AI聊天WebSocket');
    disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    _autoReconnect = true;
    _reconnectAttempts = 0;
    await connect();
  }

  /// 更新状态
  void _updateStatus(AIChatWebSocketStatus status) {
    if (_status != status) {
      _status = status;
      _statusController.add(status);
      debugPrint('AI聊天WebSocket状态: $status');
    }
  }

  /// 处理错误
  void _handleError(String error) {
    _updateStatus(AIChatWebSocketStatus.error);
    _errorController.add(error);
    debugPrint('AI聊天WebSocket错误: $error');
  }

  /// 清空离线消息队列
  void clearMessageQueue() {
    _messageQueue.clear();
    debugPrint('已清空离线消息队列');
  }

  /// 获取队列中的消息数量
  int get queuedMessageCount => _messageQueue.length;

  /// 销毁资源
  void dispose() {
    debugPrint('销毁AI聊天WebSocket管理器');
    _autoReconnect = false;
    _stopHeartbeat();
    _stopReconnectTimer();
    _channel?.sink.close();
    _statusController.close();
    _messageController.close();
    _errorController.close();
    _messageQueue.clear();
  }
}

/// AI聊天WebSocket工具类（简化接口）
class AIChatWebSocketUtil {
  static final AIChatWebSocketManager _manager = AIChatWebSocketManager();

  /// 初始化配置
  static void init({
    required String serverUrl,
    required String userId,
    String? sessionId,
    String? authToken,
    Map<String, String>? customHeaders,
    Duration? heartbeatInterval,
    Duration? reconnectInterval,
    int? maxReconnectAttempts,
    bool? autoReconnect,
    bool? enableOfflineQueue,
  }) {
    final headers = <String, String>{};

    // 添加认证头
    headers['access_token'] = TokenStorage.cachedAccessToken ?? '';
    // 添加自定义头
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    _manager.configure(
      serverUrl: serverUrl,
      userId: userId,
      sessionId: sessionId,
      headers: headers,
      heartbeatInterval: heartbeatInterval,
      reconnectInterval: reconnectInterval,
      maxReconnectAttempts: maxReconnectAttempts,
      autoReconnect: autoReconnect,
      enableOfflineQueue: enableOfflineQueue,
    );
  }

  /// 连接
  static Future<void> connect() => _manager.connect();

  /// 断开连接
  static void disconnect() => _manager.disconnect();

  /// 重新连接
  static Future<void> reconnect() => _manager.reconnect();

  /// 发送聊天消息
  static void sendChat(
    String content, {
    String? messageId,
    Map<String, dynamic>? extraData,
  }) {
    _manager.sendChatMessage(
      content: content,
      messageId: messageId,
      extraData: extraData,
    );
  }

  /// 发送数据操作
  static void sendDataOperation({
    required String type,
    required String action,
    required Map<String, dynamic> data,
    String? messageId,
  }) {
    _manager.sendDataOperation(
      operationType: type,
      action: action,
      operationData: data,
      messageId: messageId,
    );
  }

  /// 发送图片分析
  static void sendImageAnalysis(
    String imagePath, {
    String? description,
    String? messageId,
  }) {
    _manager.sendImageAnalysis(
      imagePath: imagePath,
      description: description,
      messageId: messageId,
    );
  }

  /// 发送快捷操作
  static void sendQuickAction(String actionType) {
    _manager.sendQuickAction(actionType);
  }

  /// 流监听
  static Stream<AIChatWebSocketStatus> get statusStream =>
      _manager.statusStream;
  static Stream<AIChatMessage> get messageStream => _manager.messageStream;
  static Stream<String> get errorStream => _manager.errorStream;

  /// 状态获取
  static AIChatWebSocketStatus get status => _manager.status;
  static bool get isConnected => _manager.isConnected;
  static String? get userId => _manager.userId;
  static String? get sessionId => _manager.sessionId;
  static int get queuedMessageCount => _manager.queuedMessageCount;

  /// 工具方法
  static void clearMessageQueue() => _manager.clearMessageQueue();
  static void dispose() => _manager.dispose();
}
