import 'package:cloud_firestore/cloud_firestore.dart';

class Trail {
  final String id;
  final String name;
  final String location;
  final double length;
  final String difficulty;
  final String? description;
  final GeoPoint? startPoint;

  Trail({
    required this.id,
    required this.name,
    required this.location,
    required this.length,
    required this.difficulty,
    this.description,
    this.startPoint,
  });

  factory Trail.fromMap(String id, Map<String, dynamic> data) {
    return Trail(
      id: id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      length: (data['length'] ?? 0).toDouble(),
      difficulty: data['difficulty'] ?? '',
      description: data['description'] as String?,
      startPoint: data['startPoint'] as GeoPoint?,
    );
  }
}
