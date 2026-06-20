import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:genbarber/core/services/firestore_service.dart';
import 'package:genbarber/models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Register ─────────────────────────────────────────────
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
    String? shopAddress,
    double? shopLat,
    double? shopLng,
    File? shopCoverFile,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);

    String? barbershopId;
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'role': role == UserRole.barber ? 'barber' : 'client',
      'isPremium': false,
      'photoUrl': null,
      'barbershopId': null,
    });

    // Se for barbeiro, cria barbearia placeholder
    if (role == UserRole.barber) {
      final shopRef = _db.collection('barbershops').doc();
      barbershopId = shopRef.id;
      final shop = BarbershopModel(
        id: shopRef.id,
        ownerId: cred.user!.uid,
        name: name,
        subtitle: 'Barbearia',
        address: shopAddress ?? '',
        phone: phone,
        lat: shopLat ?? -23.5505,
        lng: shopLng ?? -46.6333,
        hours: {
          'Segunda': '09:00 – 19:00',
          'Terça': '09:00 – 19:00',
          'Quarta': '09:00 – 19:00',
          'Quinta': '09:00 – 19:00',
          'Sexta': '09:00 – 19:00',
          'Sábado': '09:00 – 17:00',
        },
      );
      await shopRef.set(shop.toMap());

      if (shopCoverFile != null) {
        await _firestoreService.uploadBarbershopCover(
            shopRef.id, shopCoverFile);
      }

      await _db.collection('users').doc(cred.user!.uid).update({
        'barbershopId': shopRef.id,
      });
    }

    return UserModel(
      id: cred.user!.uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
      barbershopId: barbershopId,
    );
  }

  // ─── Login ────────────────────────────────────────────────
  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchUser(cred.user!.uid);
  }

  // ─── Fetch user doc ───────────────────────────────────────
  Future<UserModel?> _fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    var user = UserModel.fromMap(uid, doc.data()!);
    if (user.role == UserRole.barber &&
        (user.barbershopId == null || user.barbershopId!.isEmpty)) {
      final ownerShopId = await _firestoreService.getBarbershopIdByOwner(uid);
      if (ownerShopId != null) {
        await _db
            .collection('users')
            .doc(uid)
            .update({'barbershopId': ownerShopId});
        user = UserModel(
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          isPremium: user.isPremium,
          photoUrl: user.photoUrl,
          barbershopId: ownerShopId,
        );
      }
    }

    return user;
  }

  Future<UserModel?> getCurrentUserModel() async {
    if (_auth.currentUser == null) return null;
    return _fetchUser(_auth.currentUser!.uid);
  }

  Future<UserModel?> updateUserProfile({
    required String name,
    required String phone,
    String? photoUrl,
  }) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw FirebaseAuthException(code: 'user-not-found', message: 'Usuário não autenticado.');
    }
    await current.updateDisplayName(name);

    final updateData = {
      'name': name,
      'phone': phone,
    };
    if (photoUrl != null) {
      updateData['photoUrl'] = photoUrl;
    }

    await _db.collection('users').doc(current.uid).update(updateData);
    return _fetchUser(current.uid);
  }

  // ─── Sign Out ─────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Password Reset ───────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
