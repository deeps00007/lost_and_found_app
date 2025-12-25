import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePicUrl;
  final String? phoneNumber;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePicUrl,
    this.phoneNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePicUrl': profilePicUrl,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePicUrl: map['profilePicUrl'],
      phoneNumber: map['phoneNumber'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
