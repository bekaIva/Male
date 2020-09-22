import 'package:male/Models/Product.dart';

class CartItem {
  String documentId;
  String userId;
  Product product;
  CartItem({this.product, this.userId});
  Map<String, dynamic> toJson() {
    return {'userId': userId, 'product': product.toJson()};
  }

  CartItem.fromJson(Map<String, dynamic> json) {
    userId = json['userId'] as String;
    product = Product.fromJson(json['product']);
  }
}
