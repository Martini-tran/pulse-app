class PulseUser {
  /**
   * 用户ID
   */
  final String? id;

  /**
   * 名称
   */
  final String? name;

  /**
   * 邮箱
   */
  final String? email;

  /**
   * avatar
   */
  final String? avatar;

  /**
   * extra
   */
  final Map<String, dynamic>? extra;

  const PulseUser({
    this.id,
    this.name,
    this.email,
    this.avatar,
    this.extra,
  });

  factory PulseUser.empty() {
    return const PulseUser();
  }

  PulseUser copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    Map<String, dynamic>? extra,
  }) {
    return PulseUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'extra': extra,
    };
  }

  factory PulseUser.fromJson(Map<String, dynamic> json) {
    return PulseUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
      extra: json['extra'],
    );
  }
}