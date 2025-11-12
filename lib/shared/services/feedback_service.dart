import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/result.dart';

class FeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit feedback
  static Future<Result<void>> submitFeedback({
    required String type,
    required String message,
    String? email,
    int? rating,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      
      final feedbackData = {
        'type': type, // 'bug', 'feature', 'general', 'rating'
        'message': message,
        'email': email ?? user?.email,
        'userId': user?.uid,
        'rating': rating,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // 'pending', 'reviewed', 'resolved', 'rejected'
        'version': '1.0.0', // App version
        'platform': 'mobile', // Platform info
      };

      await _firestore.collection('feedback').add(feedbackData);
      
      return Result.success(null);
    } catch (e) {
      return Result.failure('Feedback gönderilemedi: ${e.toString()}');
    }
  }

  // Submit bug report
  static Future<Result<void>> submitBugReport({
    required String description,
    required String steps,
    String? email,
    Map<String, dynamic>? deviceInfo,
  }) async {
    return submitFeedback(
      type: 'bug',
      message: description,
      email: email,
      metadata: {
        'steps': steps,
        'deviceInfo': deviceInfo ?? {},
      },
    );
  }

  // Submit feature request
  static Future<Result<void>> submitFeatureRequest({
    required String title,
    required String description,
    String? email,
    String? priority,
  }) async {
    return submitFeedback(
      type: 'feature',
      message: '$title\n\n$description',
      email: email,
      metadata: {
        'priority': priority ?? 'medium',
      },
    );
  }

  // Submit general feedback
  static Future<Result<void>> submitGeneralFeedback({
    required String message,
    String? email,
    int? rating,
  }) async {
    return submitFeedback(
      type: 'general',
      message: message,
      email: email,
      rating: rating,
    );
  }

  // Submit app rating
  static Future<Result<void>> submitAppRating({
    required int rating,
    String? comment,
    String? email,
  }) async {
    return submitFeedback(
      type: 'rating',
      message: comment ?? '',
      email: email,
      rating: rating,
      metadata: {
        'ratingCategory': 'app',
      },
    );
  }

  // Get user's feedback history
  static Future<Result<List<Map<String, dynamic>>>> getUserFeedback() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure('Kullanıcı giriş yapmamış');
      }

      final query = await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      final feedbackList = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      return Result.success(feedbackList);
    } catch (e) {
      return Result.failure('Feedback geçmişi alınamadı: ${e.toString()}');
    }
  }

  // Check if user has rated the app
  static Future<bool> hasUserRatedApp() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final query = await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'rating')
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
