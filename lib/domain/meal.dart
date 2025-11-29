class Meal {
  final String id;
  final String name;
  final String type; // 早餐、午餐、晚餐
  final int calories;
  final int protein; // 蛋白质(g)
  final int carbs; // 碳水化合物(g)
  final int fat; // 脂肪(g)
  final String description;
  final List<String> ingredients; // 食材列表
  final String cookingMethod; // 制作方法
  final int cookingTime; // 制作时间(分钟)
  final String difficulty; // 难度等级

  const Meal({
    required this.id,
    required this.name,
    required this.type,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.description,
    required this.ingredients,
    required this.cookingMethod,
    required this.cookingTime,
    required this.difficulty,
  });

  // 从JSON创建Meal对象
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      calories: json['calories'] as int,
      protein: json['protein'] as int,
      carbs: json['carbs'] as int,
      fat: json['fat'] as int,
      description: json['description'] as String,
      ingredients: List<String>.from(json['ingredients'] as List),
      cookingMethod: json['cookingMethod'] as String,
      cookingTime: json['cookingTime'] as int,
      difficulty: json['difficulty'] as String,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'description': description,
      'ingredients': ingredients,
      'cookingMethod': cookingMethod,
      'cookingTime': cookingTime,
      'difficulty': difficulty,
    };
  }

  // 复制并修改部分属性
  Meal copyWith({
    String? id,
    String? name,
    String? type,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    String? description,
    List<String>? ingredients,
    String? cookingMethod,
    int? cookingTime,
    String? difficulty,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      cookingMethod: cookingMethod ?? this.cookingMethod,
      cookingTime: cookingTime ?? this.cookingTime,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  @override
  String toString() {
    return 'Meal(id: $id, name: $name, type: $type, calories: $calories)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Meal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// 营养成分数据模型
class NutritionData {
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
  final int sugar;
  final int sodium;

  const NutritionData({
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
  });

  factory NutritionData.fromJson(Map<String, dynamic> json) {
    return NutritionData(
      protein: json['protein'] as int,
      carbs: json['carbs'] as int,
      fat: json['fat'] as int,
      fiber: json['fiber'] as int? ?? 0,
      sugar: json['sugar'] as int? ?? 0,
      sodium: json['sodium'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
    };
  }
}

// 食材数据模型
class Ingredient {
  final String name;
  final double amount;
  final String unit;
  final int calories;
  final NutritionData nutrition;

  const Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    required this.calories,
    required this.nutrition,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      calories: json['calories'] as int,
      nutrition: NutritionData.fromJson(json['nutrition'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'calories': calories,
      'nutrition': nutrition.toJson(),
    };
  }
}