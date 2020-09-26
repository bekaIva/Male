import 'FirestoreImage.dart';

class Category {
  String documentId;
  int order;
  Map<String, String> localizedName = {};
  FirestoreImage image;
  Map<String, dynamic> toJson() => {
        'order': order,
        'localizedName': localizedName,
        'image': image?.toJson(),
      };
  Category({this.image, this.localizedName, this.order});
  Category.fromJson(Map<String, dynamic> json, {this.documentId}) {
    order = (json['order'] as num)?.toInt();
    localizedName = Map<String, String>.from(json['localizedName']);
    image = FirestoreImage.fromJson(json['image']);
  }
}
