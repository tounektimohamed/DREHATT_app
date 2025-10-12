import 'package:cloud_firestore/cloud_firestore.dart';

class Claim {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String phone;
  final String email;
  final String imageBase64; // Changé de imageUrl à imageBase64
  final GeoPoint? position;
  final Timestamp timestamp;
  final String status; // Nouveau: statut de la réclamation
  final String category; // Nouveau: catégorie

  Claim({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.phone,
    required this.email,
    required this.imageBase64,
    required this.position,
    required this.timestamp,
    this.status = 'pending',
    this.category = 'general',
  });

  factory Claim.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    GeoPoint? geoPoint = data['position'] as GeoPoint?;
    
    return Claim(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      imageBase64: data['imageBase64'] ?? '', // Changé ici
      position: geoPoint,
      timestamp: data['timestamp'] ?? Timestamp.now(),
      status: data['status'] ?? 'pending',
      category: data['category'] ?? 'general',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'phone': phone,
      'email': email,
      'imageBase64': imageBase64,
      'position': position,
      'timestamp': timestamp,
      'status': status,
      'category': category,
    };
  }
}