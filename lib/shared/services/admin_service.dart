import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is admin
  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['role'] == 'admin' || doc.data()?['isAdmin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Get current user's role
  static Future<String> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'guest';

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['role'] ?? 'user';
    } catch (e) {
      print('Error getting user role: $e');
      return 'user';
    }
  }

  // Make user admin (only callable by existing admin)
  static Future<bool> makeAdmin(String userId) async {
    if (!await isAdmin()) {
      throw Exception('Only admins can make other users admin');
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'role': 'admin',
        'isAdmin': true,
        'adminSince': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error making user admin: $e');
      return false;
    }
  }

  // Remove admin role
  static Future<bool> removeAdmin(String userId) async {
    if (!await isAdmin()) {
      throw Exception('Only admins can remove admin role');
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'role': 'user',
        'isAdmin': false,
        'adminSince': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      print('Error removing admin role: $e');
      return false;
    }
  }

  // Get all admins
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('Error getting admins: $e');
      return [];
    }
  }

  // Log admin action
  static Future<void> logAction(String action, Map<String, dynamic> details) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('admin_logs').add({
        'adminId': user.uid,
        'adminEmail': user.email,
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging admin action: $e');
    }
  }

  // Get admin statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final usersCount = await _firestore.collection('users').count().get();
      final reviewsCount = await _firestore.collection('reviews').count().get();
      final reportsCount = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      // Get today's new users
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final todayUsersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .count()
          .get();

      return {
        'totalUsers': usersCount.count ?? 0,
        'totalReviews': reviewsCount.count ?? 0,
        'pendingReports': reportsCount.count ?? 0,
        'todayNewUsers': todayUsersSnapshot.count ?? 0,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'totalUsers': 0,
        'totalReviews': 0,
        'pendingReports': 0,
        'todayNewUsers': 0,
      };
    }
  }
}
