// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_tier_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionTierModel _$SubscriptionTierModelFromJson(
        Map<String, dynamic> json) =>
    SubscriptionTierModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      beanLimit: (json['beanLimit'] as num).toInt(),
      discount: (json['discount'] as num).toDouble(),
      benefits:
          (json['benefits'] as List<dynamic>).map((e) => e as String).toList(),
      isActive: json['isActive'] as bool? ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      weeklyPrice: (json['weeklyPrice'] as num?)?.toDouble(),
      biWeeklyPrice: (json['biWeeklyPrice'] as num?)?.toDouble(),
      monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble(),
      freeShipping: json['freeShipping'] as bool? ?? false,
      prioritySupport: json['prioritySupport'] as bool? ?? false,
      exclusiveBlends: json['exclusiveBlends'] as bool? ?? false,
      maxQuantityPerBean: (json['maxQuantityPerBean'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SubscriptionTierModelToJson(
        SubscriptionTierModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'beanLimit': instance.beanLimit,
      'discount': instance.discount,
      'benefits': instance.benefits,
      'isActive': instance.isActive,
      'displayOrder': instance.displayOrder,
      'weeklyPrice': instance.weeklyPrice,
      'biWeeklyPrice': instance.biWeeklyPrice,
      'monthlyPrice': instance.monthlyPrice,
      'freeShipping': instance.freeShipping,
      'prioritySupport': instance.prioritySupport,
      'exclusiveBlends': instance.exclusiveBlends,
      'maxQuantityPerBean': instance.maxQuantityPerBean,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
