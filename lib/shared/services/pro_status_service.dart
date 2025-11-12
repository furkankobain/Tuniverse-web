import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache for pro status
  static bool? _cachedProStatus;
  static String? _cachedUserId;
  
  /// Check if current user is a pro member (PRO_MONTHLY, PRO_ANNUAL or active TRIAL)
  static Future<bool> isProUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    
    // Return cached value if user hasn't changed
    if (_cachedUserId == currentUser.uid && _cachedProStatus != null) {
      return _cachedProStatus!;
    }
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data();
      final subscription = data?['subscription'] as String? ?? 'free';
      final isPro = data?['isPro'] as bool? ?? false; // Backward compatibility
      
      // Check subscription types
      bool hasPro = isPro || 
                    subscription == 'pro_monthly' || 
                    subscription == 'pro_annual';
      
      // Check trial status
      if (subscription == 'pro_trial') {
        final trialEndsAt = (data?['trialEndsAt'] as Timestamp?)?.toDate();
        if (trialEndsAt != null && DateTime.now().isBefore(trialEndsAt)) {
          hasPro = true;
        }
      }
      
      // Cache the result
      _cachedUserId = currentUser.uid;
      _cachedProStatus = hasPro;
      
      return hasPro;
    } catch (e) {
      print('Error checking pro status: $e');
      return false;
    }
  }
  
  /// Set pro status for current user
  static Future<bool> setProStatus(bool isPro) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'isPro': isPro,
        'proSince': isPro ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Clear cache
      _cachedProStatus = null;
      _cachedUserId = null;
      
      return true;
    } catch (e) {
      print('Error setting pro status: $e');
      return false;
    }
  }
  
  /// Clear cache (useful after logout)
  static void clearCache() {
    _cachedProStatus = null;
    _cachedUserId = null;
  }
  
  /// Stream of pro status changes
  static Stream<bool> proStatusStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(false);
    }
    
    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      final data = snapshot.data();
      
      final subscription = data?['subscription'] as String? ?? 'free';
      final isPro = data?['isPro'] as bool? ?? false; // Backward compatibility
      
      // Check subscription types
      bool hasPro = isPro || 
                    subscription == 'pro_monthly' || 
                    subscription == 'pro_annual';
      
      // Check trial status
      if (subscription == 'pro_trial') {
        final trialEndsAt = (data?['trialEndsAt'] as Timestamp?)?.toDate();
        if (trialEndsAt != null && DateTime.now().isBefore(trialEndsAt)) {
          hasPro = true;
        }
      }
      
      return hasPro;
    });
  }
  
  /// Check if user has ad-free access (PRO or AD_FREE subscription, or active trial)
  static Future<bool> isAdFree() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data();
      final subscription = data?['subscription'] as String? ?? 'free';
      
      // Check if user has pro or ad-free subscription
      if (subscription == 'pro_monthly' || subscription == 'pro_annual' || subscription == 'ad_free') {
        return true;
      }
      
      // Check trial status
      if (subscription == 'pro_trial') {
        final trialEndsAt = (data?['trialEndsAt'] as Timestamp?)?.toDate();
        if (trialEndsAt != null && DateTime.now().isBefore(trialEndsAt)) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking ad-free status: $e');
      return false;
    }
  }
  
  /// Get pro features list
  static List<String> getProFeatures() {
    return [
      '🎎 Add photos to your reviews',
      '✍️ Rich text formatting (bold, italic, colors)',
      '✨ Animated profile frame',
      'ᴜ PRO badge on your profile',
      '🚫 Ad-free experience',
      '🌯 Exclusive features access',
      '🌟 Early access to new features',
      '💫 Premium themes',
    ];
  }
}
