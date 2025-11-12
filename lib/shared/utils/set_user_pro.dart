import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

/// Utility function to set the current user as Pro for testing purposes
/// Call this from anywhere in your app: await setUserAsPro();
Future<void> setUserAsPro() async {
  final currentUser = FirebaseService.auth.currentUser;
  
  if (currentUser == null) {
    print('❌ No user is currently logged in');
    return;
  }
  
  try {
    await FirebaseService.firestore
        .collection('users')
        .doc(currentUser.uid)
        .update({
      'isPro': true,
      'proSince': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ User ${currentUser.uid} is now PRO!');
    print('📧 Email: ${currentUser.email}');
  } catch (e) {
    print('❌ Error setting user as Pro: $e');
  }
}

/// Utility function to remove Pro status (for testing)
Future<void> removeProStatus() async {
  final currentUser = FirebaseService.auth.currentUser;
  
  if (currentUser == null) {
    print('❌ No user is currently logged in');
    return;
  }
  
  try {
    await FirebaseService.firestore
        .collection('users')
        .doc(currentUser.uid)
        .update({
      'isPro': false,
      'proSince': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Pro status removed from user ${currentUser.uid}');
  } catch (e) {
    print('❌ Error removing Pro status: $e');
  }
}
