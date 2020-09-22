import 'package:cloud_firestore/cloud_firestore.dart';

class Coordinates {
  double latitude;
  double longitude;

  Coordinates({this.longitude, this.latitude});

  Coordinates.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'] as double;
    longitude = json['longitude'] as double;
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class UserAddress {
  DocumentReference referance;
  bool isPrimary;
  String uid;
  String name;
  String addressName;
  Coordinates coordinates;
  String address;
  String mobileNumber;
  UserAddress(
      {this.address,
      this.name,
      this.addressName,
      this.uid,
      this.isPrimary,
      this.coordinates,
      this.mobileNumber});
  UserAddress.fromDocument(DocumentSnapshot doc) {
    var json = doc.data();
    referance = doc.reference;
    name = json['name'] as String;
    addressName = json['addressName'] as String;
    isPrimary = json['isPrimary'] as bool;
    uid = json['uid'] as String;
    coordinates = Coordinates.fromJson(json['coordinates']);
    address = json['address'] as String;
    mobileNumber = json['mobileNumber'] as String;
  }
  UserAddress.fromJson(Map<String, dynamic> json) {
    name = json['name'] as String;
    addressName = json['addressName'] as String;
    isPrimary = json['isPrimary'] as bool;
    uid = json['uid'] as String;
    coordinates = Coordinates.fromJson(json['coordinates']);
    address = json['address'] as String;
    mobileNumber = json['mobileNumber'] as String;
  }
  Map<String, dynamic> toJson() {
    return {
      'addressName': addressName,
      'isPrimary': isPrimary,
      'uid': uid,
      'name': name,
      'coordinates': coordinates.toJson(),
      'address': address,
      'mobileNumber': mobileNumber,
    };
  }
}
