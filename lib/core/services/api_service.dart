import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// CREATE or UPDATE document
  Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).doc(docId).set(
          data,
          SetOptions(merge: true),
        );
  }

  /// READ single document
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String collection,
    required String docId,
  }) async {
    return await _firestore.collection(collection).doc(docId).get();
  }

  /// DELETE document
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  /// LISTEN to collection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String collection,
    Query<Map<String, dynamic>> Function(
      Query<Map<String, dynamic>> query,
    )? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query =
        _firestore.collection(collection);

    if (queryBuilder != null) {
      query = queryBuilder(query);
    }

    return query.snapshots();
  }

  /// ADD document with auto ID
  Future<DocumentReference<Map<String, dynamic>>> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    return await _firestore.collection(collection).add(data);
  }
}
