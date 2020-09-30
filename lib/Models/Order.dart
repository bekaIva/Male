import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:male/Models/Address.dart';
import 'package:male/Models/Product.dart';
import 'package:male/Models/enums.dart';

class Order {
  String orderMessage;
  Map<DeliveryStatus, DeliveryStatusStep> deliveryStatusSteps;
  String TransactionID;
  String Hash;
  int orderId;
  String documentId;
  String uid;
  List<Product> products;
  PaymentMethods paymentMethod;
  PaymentStatus paymentStatus;
  double deliveryFee;
  UserAddress deliveryAddress;
  bool isSeen;
  dynamic serverTime;
  Order(
      {this.paymentMethod,
      this.orderMessage,
      this.deliveryStatusSteps,
      this.orderId,
      this.paymentStatus = PaymentStatus.NotPaid,
      this.documentId,
      this.isSeen,
      this.serverTime,
      this.uid,
      this.products,
      this.deliveryAddress,
      this.deliveryFee,
      this.Hash,
      this.TransactionID});
  Order.fromJson(Map<String, dynamic> json) {
    orderMessage = json['orderMessage'] as String;
    TransactionID = json['TransactionID'] as String;
    Hash = json['Hash'] as String;
    deliveryStatusSteps = (json['deliveryStatusSteps'] as Map<String, dynamic>)
        ?.map((key, value) => MapEntry(
            EnumToString.fromString(DeliveryStatus.values, key),
            DeliveryStatusStep.fromJson(value)));
    orderId = json['orderId'] as int;
    paymentStatus = EnumToString.fromString(
        PaymentStatus.values, (json['paymentStatus'] as String) ?? 'UNKNOWN');
    isSeen = json['isSeen'] as bool;
    serverTime = json['serverTime'];
    uid = json['uid'] as String;
    products = (json['products'] as List<dynamic>)
        ?.map((e) => Product.fromJson(e))
        ?.toList();
    paymentMethod = EnumToString.fromString(
        PaymentMethods.values, json['paymentMethod'] as String);
    deliveryFee = (json['deliveryFee'] as num)?.toDouble();
    deliveryAddress = UserAddress.fromJson(json['deliveryAddress']);
  }
  Map<String, dynamic> toJson() {
    return {
      'orderMessage': orderMessage,
      'TransactionID': TransactionID,
      'Hash': Hash,
      'deliveryStatusSteps': deliveryStatusSteps.map(
          (key, value) => MapEntry(EnumToString.parse(key), value.toJson())),
      'orderId': orderId,
      'paymentStatus': EnumToString.parse(paymentStatus),
      'isSeen': isSeen,
      'serverTime': serverTime,
      'uid': uid,
      'products': products?.map((e) => e.toJson())?.toList(),
      'paymentMethod': EnumToString.parse(paymentMethod),
      'deliveryFee': deliveryFee,
      'deliveryAddress': deliveryAddress?.toJson(),
    };
  }

  Map<String, dynamic> toCheckoutJson(BuildContext context) {
    return {
      'documentId': documentId,
      'TransactionID': TransactionID,
      'Hash': Hash,
      'uid': uid,
      'OrderId': orderId,
      'OrderedProducts':
          products?.map((e) => e.toCheckoutJson(context))?.toList(),
      'DeliveryFee': deliveryFee,
    };
  }
}

class DeliveryStatusStep {
  StepState stepState;
  bool isActive;
  dynamic creationTimestamp;
  dynamic completionTimestamp;
  DeliveryStatusStep(
      {this.creationTimestamp,
      this.completionTimestamp,
      this.isActive,
      this.stepState});
  DeliveryStatusStep.fromJson(Map<String, dynamic> json) {
    stepState =
        EnumToString.fromString(StepState.values, json['stepState'] as String);
    isActive = json['isActive'] as bool;
    creationTimestamp = json['creationTimestamp'];
    completionTimestamp = json['completionTimestamp'];
  }
  Map<String, dynamic> toJson() {
    return {
      'stepState': EnumToString.parse(stepState),
      'isActive': isActive,
      'creationTimestamp': creationTimestamp,
      'completionTimestamp': completionTimestamp
    };
  }
}
