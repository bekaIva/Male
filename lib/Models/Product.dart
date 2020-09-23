import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:male/Localizations/app_localizations.dart';

import 'FirestoreImage.dart';

class Product {
  double get totalProductPrice =>
      (this.basePrice ?? 0) +
      (selectableAddons?.where((element) => element.isSelected)?.fold<double>(
              0.0,
              (previousValue, element) =>
                  previousValue + (element?.price ?? 0.0)) ??
          0) +
      (checkableAddons?.where((element) => element.isSelected)?.fold(
              0,
              (previousValue, element) =>
                  previousValue + (element?.price ?? 0)) ??
          0);
  String documentId;
  String productDocumentId;
  Map<String, String> localizedName;
  Map<String, String> localizedDescription;
  List<AddonDescription> addonDescriptions;
  List<PaidAddon> selectableAddons;
  List<PaidAddon> checkableAddons;
  List<FirestoreImage> images;
  int quantityInSupply;
  double basePrice;
  int order;
  int quantity;
  Product(
      {this.localizedDescription,
      this.localizedName,
      this.addonDescriptions,
      this.selectableAddons,
      this.checkableAddons,
      this.images,
      this.order});
  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'documentId': documentId,
      'productDocumentId': productDocumentId,
      'localizedName': localizedName,
      'localizedDescription': localizedDescription,
      'addonDescriptions': addonDescriptions?.map((e) => e.toJson())?.toList(),
      'selectableAddons': selectableAddons?.map((e) => e.toJson())?.toList(),
      'checkableAddons': checkableAddons?.map((e) => e.toJson())?.toList(),
      'images': images?.map((e) => e.toJson())?.toList(),
      'quantityInSupply': quantityInSupply,
      'basePrice': basePrice,
      'quantity': quantity
    };
  }

  Map<String, dynamic> toCheckoutJson(BuildContext context) {
    return {
      'Quantity': quantity,
      'Price': totalProductPrice ?? 0,
      'Name':
          localizedName[AppLocalizations.of(context).locale.languageCode] ?? '',
      'Description':
          '${nullSafeMapValue(localizedDescription, AppLocalizations.of(context).locale.languageCode) ?? ''} ${nullSafeMapValue(selectableAddons?.firstWhere((element) => element.isSelected, orElse: () => null)?.localizedName, AppLocalizations.of(context).locale.languageCode) ?? ''} ${(checkableAddons?.where((element) => element.isSelected)?.fold('', (previousValue, element) => previousValue + nullSafeMapValue(element?.localizedName, AppLocalizations.of(context).locale.languageCode)) ?? '')}',
    };
  }

  V nullSafeMapValue<K, V>(Map<K, V> map, K key) {
    if (map?.containsKey(key) ?? false) return map[key];
    return null;
  }

  Product.fromJson(Map<String, dynamic> json) {
    order = (json['order'] as num)?.toInt();
    productDocumentId = json['productDocumentId'] as String;
    quantityInSupply = (json['quantityInSupply'] as num)?.toInt();
    basePrice = (json['basePrice'] as num)?.toDouble();
    quantity = (json['quantity'] as num)?.toInt();
    documentId = json['documentId'] as String;
    localizedName = Map<String, String>.from(json['localizedName'] ?? {});
    localizedDescription =
        Map<String, String>.from(json['localizedDescription']);
    addonDescriptions = (json['addonDescriptions'] as List<dynamic>)
        ?.map((e) => AddonDescription.fromJson(e))
        ?.toList();

    selectableAddons = (json['selectableAddons'] as List<dynamic>)
        ?.map((e) => PaidAddon.fromJson(e))
        ?.toList();

    checkableAddons = (json['checkableAddons'] as List<dynamic>)
        ?.map((e) => PaidAddon.fromJson(e))
        ?.toList();

    images = (json['images'] as List<dynamic>)
        ?.map((e) => FirestoreImage.fromJson(e))
        ?.toList();
  }
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Product &&
            runtimeType == other.runtimeType &&
            productDocumentId == other.productDocumentId &&
            ListEquality().equals(selectableAddons, other.selectableAddons) &&
            ListEquality().equals(checkableAddons, other.checkableAddons);
  }

  @override
  int get hashCode =>
      selectableAddons.hashCode ^
      checkableAddons.hashCode ^
      productDocumentId.hashCode;
}

class AddonDescription {
  Map<String, String> localizedAddonDescriptionName;
  Map<String, String> localizedAddonDescription;
  AddonDescription(
      {this.localizedAddonDescription, this.localizedAddonDescriptionName});
  Map<String, dynamic> toJson() {
    return {
      'localizedAddonDescriptionName': localizedAddonDescriptionName,
      'localizedAddonDescription': localizedAddonDescription,
    };
  }

  AddonDescription.fromJson(Map<String, dynamic> json) {
    localizedAddonDescriptionName =
        Map<String, String>.from(json['localizedAddonDescriptionName'] ?? {});
    localizedAddonDescription =
        Map<String, String>.from(json['localizedAddonDescription'] ?? {});
  }
}

class PaidAddon {
  PaidAddon({this.isSelected, this.price, this.localizedName});
  bool isSelected;
  Map<String, String> localizedName;
  double price;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaidAddon &&
            runtimeType == other.runtimeType &&
            isSelected == other.isSelected &&
            price == other.price &&
            MapEquality().equals(localizedName, other.localizedName);
  }

  @override
  int get hashCode =>
      isSelected.hashCode ^ price.hashCode ^ localizedName.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'isSelected': isSelected,
      'localizedName': localizedName,
      'price': price,
    };
  }

  PaidAddon.fromJson(Map<String, dynamic> json) {
    isSelected = json['isSelected'] as bool;
    localizedName = Map<String, String>.from(json['localizedName']);
    price = (json['price'] as num)?.toDouble();
  }
}
