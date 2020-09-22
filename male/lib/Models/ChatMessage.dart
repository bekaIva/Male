import 'package:enum_to_string/enum_to_string.dart';

import 'enums.dart';

class ChatMessage {
  UserType userType;
  String userDisplayName;
  String pair;
  String senderUserId;
  String targetUserId;
  String message;
  dynamic serverTime;
  ChatMessage(
      {this.message,
      this.targetUserId,
      this.senderUserId,
      this.pair,
      this.serverTime,
      this.userType,
      this.userDisplayName});
  Map<String, dynamic> toJson() {
    return {
      'userType': EnumToString.parse(userType),
      'userDisplayName': userDisplayName,
      'pair': pair,
      'senderUserId': senderUserId,
      'targetUserId': targetUserId,
      'message': message,
      'serverTime': serverTime
    };
  }

  ChatMessage.fromJson(Map<String, dynamic> json) {
    userDisplayName = json['userDisplayName'] as String;
    userType =
        EnumToString.fromString<UserType>(UserType.values, json['userType']);
    pair = json['pari'] as String;
    senderUserId = json['senderUserId'] as String;
    targetUserId = json['targetUserId'] as String;
    message = json['message'] as String;
    serverTime = json['serverTime'];
  }
}
