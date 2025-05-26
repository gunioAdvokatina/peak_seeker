import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peak_seeker/models/trail.dart';

class TrailService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<Trail>> getTrails() async {
    final snapshot = await _firestore.collection('trails').get();
    return snapshot.docs.map((doc) => Trail.fromMap(doc.id, doc.data())).toList();
  }
}
