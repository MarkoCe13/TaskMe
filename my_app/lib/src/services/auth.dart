import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );

    await _ensureUserDoc(cred.user!); 
    return cred;
  }

  
  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email, password: password,
    );

    await _db.collection('users').doc(cred.user!.uid).set({
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return cred;
  }


  Future<void> _ensureUserDoc(User user) async {
    final doc = _db.collection('users').doc(user.uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await doc.set({
        'email': user.email,
        'displayName': user.displayName,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();
}
