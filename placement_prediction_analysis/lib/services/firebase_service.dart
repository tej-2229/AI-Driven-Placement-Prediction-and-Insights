import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:placement_prediction_analysis/models/test_result.dart';
import 'package:placement_prediction_analysis/models/user_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? UserModel.fromMap(doc.id, doc.data()!) : null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<List<TestResult>> getUserTestResults(String userId) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('testResults')
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs
          .map((doc) => TestResult.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting test results: $e');
      return [];
    }
  }
}


