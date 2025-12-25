import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String type; // 'lost' or 'found'
  final String location;
  final List<String> images;
  final List<String> imageFileIds;
  final String postedBy;
  final String postedByName;
  final String status; // 'active', 'claimed', 'resolved'
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.location,
    required this.images,
    required this.imageFileIds,
    required this.postedBy,
    required this.postedByName,
    required this.status,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'type': type,
      'location': location,
      'images': images,
      'imageFileIds': imageFileIds,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create from Firestore document
  factory ItemModel.fromMap(String id, Map<String, dynamic> map) {
    return ItemModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      type: map['type'] ?? 'lost',
      location: map['location'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      imageFileIds: List<String>.from(map['imageFileIds'] ?? []),
      postedBy: map['postedBy'] ?? '',
      postedByName: map['postedByName'] ?? 'Anonymous',
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
