import 'package:cloud_firestore/cloud_firestore.dart';

/// 10. DeviceToken
class DeviceToken {
  final String id;
  final DocumentReference userRef;
  final String deviceToken;
  final String platform;
  final DateTime createdAt;

  DeviceToken({
    required this.id,
    required this.userRef,
    required this.deviceToken,
    required this.platform,
    required this.createdAt,
  });

  factory DeviceToken.fromMap(String id, Map<String, dynamic> data) => DeviceToken(
        id: id,
        userRef: data['userRef'],
        deviceToken: data['deviceToken'],
        platform: data['platform'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'userRef': userRef,
        'deviceToken': deviceToken,
        'platform': platform,
        'createdAt': createdAt,
      };
}
