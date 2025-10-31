class BrewingMethod {
  final String id;
  final BilingualText name;
  final BilingualText description;
  final BilingualText instructions;
  final List<BrewingEquipment> equipment;
  final BrewingParameters parameters;
  final String difficulty;
  final int totalTime;
  final int servings;
  final List<String> categories;
  final List<String> tags;
  final bool isActive;
  final int displayOrder;
  final bool isPopular;
  final String? image;
  final String? icon;
  final String color;
  final List<BrewingTip> tips;
  final List<BrewingVariation> variations;
  final BrewingAnalytics analytics;
  final BrewingSeo seo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BrewingMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.equipment,
    required this.parameters,
    required this.difficulty,
    required this.totalTime,
    required this.servings,
    required this.categories,
    required this.tags,
    required this.isActive,
    required this.displayOrder,
    required this.isPopular,
    this.image,
    this.icon,
    required this.color,
    required this.tips,
    required this.variations,
    required this.analytics,
    required this.seo,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedTotalTime {
    if (totalTime < 60) {
      return '${totalTime}min';
    } else {
      final hours = totalTime ~/ 60;
      final minutes = totalTime % 60;
      return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
    }
  }

  String get difficultyIcon {
    switch (difficulty) {
      case 'Beginner':
        return '⭐';
      case 'Intermediate':
        return '⭐⭐';
      case 'Advanced':
        return '⭐⭐⭐';
      case 'Expert':
        return '⭐⭐⭐⭐';
      default:
        return '⭐';
    }
  }

  factory BrewingMethod.fromJson(Map<String, dynamic> json) {
    return BrewingMethod(
      id: json['_id'] ?? '',
      name: BilingualText.fromJson(json['name'] ?? {}),
      description: BilingualText.fromJson(json['description'] ?? {}),
      instructions: BilingualText.fromJson(json['instructions'] ?? {}),
      equipment:
          (json['equipment'] as List<dynamic>?)
              ?.map((e) => BrewingEquipment.fromJson(e))
              .toList() ??
          [],
      parameters: BrewingParameters.fromJson(json['parameters'] ?? {}),
      difficulty: json['difficulty'] ?? 'Beginner',
      totalTime: (json['totalTime'] as num?)?.toInt() ?? 0,
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      isActive: json['isActive'] ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      isPopular: json['isPopular'] ?? false,
      image: json['image'],
      icon: json['icon'],
      color: json['color'] ?? '#A89A6A',
      tips:
          (json['tips'] as List<dynamic>?)
              ?.map((e) => BrewingTip.fromJson(e))
              .toList() ??
          [],
      variations:
          (json['variations'] as List<dynamic>?)
              ?.map((e) => BrewingVariation.fromJson(e))
              .toList() ??
          [],
      analytics: BrewingAnalytics.fromJson(json['analytics'] ?? {}),
      seo: BrewingSeo.fromJson(json['seo'] ?? {}),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name.toJson(),
      'description': description.toJson(),
      'instructions': instructions.toJson(),
      'equipment': equipment.map((e) => e.toJson()).toList(),
      'parameters': parameters.toJson(),
      'difficulty': difficulty,
      'totalTime': totalTime,
      'servings': servings,
      'categories': categories,
      'tags': tags,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'isPopular': isPopular,
      'image': image,
      'icon': icon,
      'color': color,
      'tips': tips.map((e) => e.toJson()).toList(),
      'variations': variations.map((e) => e.toJson()).toList(),
      'analytics': analytics.toJson(),
      'seo': seo.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class BilingualText {
  final String en;
  final String ar;

  const BilingualText({required this.en, required this.ar});

  factory BilingualText.fromJson(Map<String, dynamic> json) {
    return BilingualText(en: json['en'] ?? '', ar: json['ar'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'en': en, 'ar': ar};
  }
}

class BrewingEquipment {
  final BilingualText name;
  final bool required;
  final BilingualText? description;

  const BrewingEquipment({
    required this.name,
    required this.required,
    this.description,
  });

  factory BrewingEquipment.fromJson(Map<String, dynamic> json) {
    return BrewingEquipment(
      name: BilingualText.fromJson(json['name'] ?? {}),
      required: json['required'] ?? true,
      description: json['description'] != null
          ? BilingualText.fromJson(json['description'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.toJson(),
      'required': required,
      'description': description?.toJson(),
    };
  }
}

class BrewingParameters {
  final String grindSize;
  final String coffeeToWaterRatio;
  final WaterTemperature waterTemperature;
  final BrewTime brewTime;

  const BrewingParameters({
    required this.grindSize,
    required this.coffeeToWaterRatio,
    required this.waterTemperature,
    required this.brewTime,
  });

  factory BrewingParameters.fromJson(Map<String, dynamic> json) {
    return BrewingParameters(
      grindSize: json['grindSize'] ?? '',
      coffeeToWaterRatio: json['coffeeToWaterRatio'] ?? '',
      waterTemperature: WaterTemperature.fromJson(
        json['waterTemperature'] ?? {},
      ),
      brewTime: BrewTime.fromJson(json['brewTime'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grindSize': grindSize,
      'coffeeToWaterRatio': coffeeToWaterRatio,
      'waterTemperature': waterTemperature.toJson(),
      'brewTime': brewTime.toJson(),
    };
  }
}

class WaterTemperature {
  final int? celsius;
  final int? fahrenheit;

  const WaterTemperature({this.celsius, this.fahrenheit});

  factory WaterTemperature.fromJson(Map<String, dynamic> json) {
    return WaterTemperature(
      celsius: json['celsius'] != null
          ? (json['celsius'] as num).toInt()
          : null,
      fahrenheit: json['fahrenheit'] != null
          ? (json['fahrenheit'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'celsius': celsius, 'fahrenheit': fahrenheit};
  }
}

class BrewTime {
  final int? minutes;
  final BilingualText? description;

  const BrewTime({this.minutes, this.description});

  factory BrewTime.fromJson(Map<String, dynamic> json) {
    return BrewTime(
      minutes: json['minutes'] != null
          ? (json['minutes'] as num).toInt()
          : null,
      description: json['description'] != null
          ? BilingualText.fromJson(json['description'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'minutes': minutes, 'description': description?.toJson()};
  }
}

class BrewingTip {
  final BilingualText tip;
  final String importance;

  const BrewingTip({required this.tip, required this.importance});

  factory BrewingTip.fromJson(Map<String, dynamic> json) {
    return BrewingTip(
      tip: BilingualText.fromJson(json['tip'] ?? {}),
      importance: json['importance'] ?? 'Medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {'tip': tip.toJson(), 'importance': importance};
  }
}

class BrewingVariation {
  final BilingualText name;
  final BilingualText description;
  final List<String> modifications;

  const BrewingVariation({
    required this.name,
    required this.description,
    required this.modifications,
  });

  factory BrewingVariation.fromJson(Map<String, dynamic> json) {
    return BrewingVariation(
      name: BilingualText.fromJson(json['name'] ?? {}),
      description: BilingualText.fromJson(json['description'] ?? {}),
      modifications:
          (json['modifications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.toJson(),
      'description': description.toJson(),
      'modifications': modifications,
    };
  }
}

class BrewingAnalytics {
  final int viewCount;
  final int likeCount;
  final int shareCount;
  final double avgRating;
  final int totalRatings;

  const BrewingAnalytics({
    required this.viewCount,
    required this.likeCount,
    required this.shareCount,
    required this.avgRating,
    required this.totalRatings,
  });

  factory BrewingAnalytics.fromJson(Map<String, dynamic> json) {
    return BrewingAnalytics(
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'viewCount': viewCount,
      'likeCount': likeCount,
      'shareCount': shareCount,
      'avgRating': avgRating,
      'totalRatings': totalRatings,
    };
  }
}

class BrewingSeo {
  final BilingualText? metaTitle;
  final BilingualText? metaDescription;
  final String? slug;
  final List<String> keywords;

  const BrewingSeo({
    this.metaTitle,
    this.metaDescription,
    this.slug,
    required this.keywords,
  });

  factory BrewingSeo.fromJson(Map<String, dynamic> json) {
    return BrewingSeo(
      metaTitle: json['metaTitle'] != null
          ? BilingualText.fromJson(json['metaTitle'])
          : null,
      metaDescription: json['metaDescription'] != null
          ? BilingualText.fromJson(json['metaDescription'])
          : null,
      slug: json['slug'],
      keywords:
          (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metaTitle': metaTitle?.toJson(),
      'metaDescription': metaDescription?.toJson(),
      'slug': slug,
      'keywords': keywords,
    };
  }
}
