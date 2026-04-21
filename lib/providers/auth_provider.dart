import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  User? get user => _user;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  bool get isAuthenticated => _user != null;

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    try {
      String email = identifier;
      
      if (RegExp(r'^[0-9]+$').hasMatch(identifier) && identifier.length >= 10) {
        final query = await _db
            .collection('users')
            .where('phone', isEqualTo: identifier)
            .limit(1)
            .get();
        
        if (query.docs.isEmpty) {
          throw Exception('No user found with this mobile number.');
        }
        email = query.docs.first.get('email');
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (_user == null) return null;
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(_user!.uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({String? name, String? email, String? phone}) async {
    if (_user == null) return;
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (email != null) {
        await _user!.verifyBeforeUpdateEmail(email);
        updates['email'] = email;
      }
      if (phone != null) updates['phone'] = phone;

      if (updates.isNotEmpty) {
        await _db.collection('users').doc(_user!.uid).update(updates);
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    if (_user == null || _user!.email == null) return;
    try {
      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      await _user!.reauthenticateWithCredential(credential);
      // Update password
      await _user!.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    if (_user == null) return;
    try {
      String uid = _user!.uid;
      await _db.collection('users').doc(uid).delete();
      await _user!.delete();
      _user = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
