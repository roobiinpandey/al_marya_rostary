// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bean_product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BeanProductModel _$BeanProductModelFromJson(Map<String, dynamic> json) =>
    BeanProductModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      origin: json['origin'] as String,
      roastLevel: $enumDecode(_$RoastLevelEnumMap, json['roastLevel']),
      imageUrl: json['imageUrl'] as String,
      pricePerBag: (json['pricePerBag'] as num).toDouble(),
      bagSizeGrams: (json['bagSizeGrams'] as num?)?.toInt() ?? 250,
      flavorNotes: (json['flavorNotes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      processingMethod: json['processingMethod'] as String? ?? 'washed',
      altitude: (json['altitude'] as num?)?.toInt(),
      variety: json['variety'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isExclusive: json['isExclusive'] as bool? ?? false,
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      inStock: json['inStock'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$BeanProductModelToJson(BeanProductModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'origin': instance.origin,
      'roastLevel': _$RoastLevelEnumMap[instance.roastLevel]!,
      'imageUrl': instance.imageUrl,
      'pricePerBag': instance.pricePerBag,
      'bagSizeGrams': instance.bagSizeGrams,
      'flavorNotes': instance.flavorNotes,
      'processingMethod': instance.processingMethod,
      'altitude': instance.altitude,
      'variety': instance.variety,
      'isActive': instance.isActive,
      'isExclusive': instance.isExclusive,
      'stockQuantity': instance.stockQuantity,
      'inStock': instance.inStock,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$RoastLevelEnumMap = {
  RoastLevel.light: 'light',
  RoastLevel.medium: 'medium',
  RoastLevel.mediumDark: 'medium_dark',
  RoastLevel.dark: 'dark',
};
