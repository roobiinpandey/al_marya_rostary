// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coffee_subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionBeanSelection _$SubscriptionBeanSelectionFromJson(
        Map<String, dynamic> json) =>
    SubscriptionBeanSelection(
      beanId: json['beanId'] as String,
      beanName: json['beanName'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      grindPreference: $enumDecodeNullable(
              _$GrindPreferenceEnumMap, json['grindPreference']) ??
          GrindPreference.wholeBean,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$SubscriptionBeanSelectionToJson(
        SubscriptionBeanSelection instance) =>
    <String, dynamic>{
      'beanId': instance.beanId,
      'beanName': instance.beanName,
      'quantity': instance.quantity,
      'grindPreference': _$GrindPreferenceEnumMap[instance.grindPreference]!,
      'notes': instance.notes,
    };

const _$GrindPreferenceEnumMap = {
  GrindPreference.wholeBean: 'whole_bean',
  GrindPreference.espresso: 'espresso',
  GrindPreference.filter: 'filter',
  GrindPreference.frenchPress: 'french_press',
  GrindPreference.turkish: 'turkish',
};

CoffeeSubscriptionModel _$CoffeeSubscriptionModelFromJson(
        Map<String, dynamic> json) =>
    CoffeeSubscriptionModel(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      tierId: json['tierId'] as String,
      tierName: json['tierName'] as String?,
      tierPrice: (json['tierPrice'] as num).toDouble(),
      beanLimit: (json['beanLimit'] as num).toInt(),
      cadence: $enumDecode(_$SubscriptionCadenceEnumMap, json['cadence']),
      status:
          $enumDecodeNullable(_$SubscriptionStatusEnumMap, json['status']) ??
              SubscriptionStatus.pending,
      upcomingSelection: (json['upcomingSelection'] as List<dynamic>)
          .map((e) =>
              SubscriptionBeanSelection.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentSelection: (json['currentSelection'] as List<dynamic>?)
          ?.map((e) =>
              SubscriptionBeanSelection.fromJson(e as Map<String, dynamic>))
          .toList(),
      subscriptionPrice: (json['subscriptionPrice'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      paymentMethodId: json['paymentMethodId'] as String,
      stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
      deliveryAddress: json['deliveryAddress'] as Map<String, dynamic>,
      nextDeliveryDate: json['nextDeliveryDate'] == null
          ? null
          : DateTime.parse(json['nextDeliveryDate'] as String),
      lastDeliveryDate: json['lastDeliveryDate'] == null
          ? null
          : DateTime.parse(json['lastDeliveryDate'] as String),
      pausedAt: json['pausedAt'] == null
          ? null
          : DateTime.parse(json['pausedAt'] as String),
      pausedUntil: json['pausedUntil'] == null
          ? null
          : DateTime.parse(json['pausedUntil'] as String),
      pauseReason: json['pauseReason'] as String?,
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      cancellationReason: json['cancellationReason'] as String?,
      paymentRetryCount: (json['paymentRetryCount'] as num?)?.toInt() ?? 0,
      lastPaymentAttempt: json['lastPaymentAttempt'] == null
          ? null
          : DateTime.parse(json['lastPaymentAttempt'] as String),
      paymentFailed: json['paymentFailed'] as bool? ?? false,
      isFirstBoxFree: json['isFirstBoxFree'] as bool? ?? true,
      deliveryCount: (json['deliveryCount'] as num?)?.toInt() ?? 0,
      skippedCount: (json['skippedCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CoffeeSubscriptionModelToJson(
        CoffeeSubscriptionModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'userId': instance.userId,
      'tierId': instance.tierId,
      'tierName': instance.tierName,
      'tierPrice': instance.tierPrice,
      'beanLimit': instance.beanLimit,
      'cadence': _$SubscriptionCadenceEnumMap[instance.cadence]!,
      'status': _$SubscriptionStatusEnumMap[instance.status]!,
      'upcomingSelection': instance.upcomingSelection,
      'currentSelection': instance.currentSelection,
      'subscriptionPrice': instance.subscriptionPrice,
      'discount': instance.discount,
      'totalPrice': instance.totalPrice,
      'paymentMethodId': instance.paymentMethodId,
      'stripeSubscriptionId': instance.stripeSubscriptionId,
      'deliveryAddress': instance.deliveryAddress,
      'nextDeliveryDate': instance.nextDeliveryDate?.toIso8601String(),
      'lastDeliveryDate': instance.lastDeliveryDate?.toIso8601String(),
      'pausedAt': instance.pausedAt?.toIso8601String(),
      'pausedUntil': instance.pausedUntil?.toIso8601String(),
      'pauseReason': instance.pauseReason,
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
      'cancellationReason': instance.cancellationReason,
      'paymentRetryCount': instance.paymentRetryCount,
      'lastPaymentAttempt': instance.lastPaymentAttempt?.toIso8601String(),
      'paymentFailed': instance.paymentFailed,
      'isFirstBoxFree': instance.isFirstBoxFree,
      'deliveryCount': instance.deliveryCount,
      'skippedCount': instance.skippedCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$SubscriptionCadenceEnumMap = {
  SubscriptionCadence.weekly: 'weekly',
  SubscriptionCadence.biWeekly: 'bi_weekly',
  SubscriptionCadence.monthly: 'monthly',
};

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.paused: 'paused',
  SubscriptionStatus.cancelled: 'cancelled',
  SubscriptionStatus.pending: 'pending',
  SubscriptionStatus.expired: 'expired',
};
