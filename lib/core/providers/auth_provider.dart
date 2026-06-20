import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:genbarber/core/services/auth_service.dart';
import 'package:genbarber/models/models.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  StreamSubscription? _authStateSubscription;
  String? _errorMessage;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isBarber => _user?.role == UserRole.barber;
  bool get isAuthenticated => _state == AuthState.authenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
      // Ao detectar mudança, indica que está carregando a sessão.
      _setState(AuthState.loading);
      try {
        if (firebaseUser == null) {
          // Usuário deslogado, estado final é não autenticado.
          _user = null;
          _setState(AuthState.unauthenticated);
        } else {
          // Usuário logado, busca dados no Firestore. O timeout ajuda a evitar
          // que o app fique travado indefinidamente sem conexão.
          _user = await _authService.getCurrentUserModel().timeout(const Duration(seconds: 15));
          if (_user != null) {
            _setState(AuthState.authenticated);
          } else {
            // Estado inconsistente: usuário no Auth, mas sem dados no Firestore.
            // Força o logout para o usuário poder tentar novamente.
            await signOut(); // Usa o método signOut do provider para limpar o estado
          }
        }
      } on TimeoutException {
        _errorMessage = 'Verificação da sessão expirou. Verifique sua conexão com a internet.';
        _user = null;
        _setState(AuthState.error);
      } on FirebaseException catch (e) {
        _errorMessage = 'Erro do Firebase ao verificar a sessão (código: ${e.code}).';
        _user = null;
        _setState(AuthState.error);
      } catch (e) {
        _errorMessage = 'Ocorreu um erro inesperado ao verificar a sessão.';
        _user = null;
        _setState(AuthState.error);
      }
    });
  }

  Future<bool> registerWithEmail({
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
    _setState(AuthState.loading);
    try {
      _user = await _authService.registerWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
        shopAddress: shopAddress,
        shopLat: shopLat,
        shopLng: shopLng,
        shopCoverFile: shopCoverFile,
      );
      _setState(AuthState.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      _setState(AuthState.error);
      return false;
    } catch (e) {
      _errorMessage = 'Ocorreu um erro inesperado durante o registro.';
      _setState(AuthState.error);
      return false;
    }
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _setState(AuthState.loading);
    try {
      _user = await _authService.loginWithEmail(
        email: email,
        password: password,
      );
      _setState(AuthState.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      _setState(AuthState.error);
      return false;
    } catch (e) {
      _errorMessage = 'Ocorreu um erro inesperado durante o login.';
      _setState(AuthState.error);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? photoUrl,
  }) async {
    _setState(AuthState.loading);
    try {
      _user = await _authService.updateUserProfile(
        name: name,
        phone: phone,
        photoUrl: photoUrl,
      );
      _setState(AuthState.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      _setState(AuthState.error);
      return false;
    } catch (_) {
      _errorMessage = 'Não foi possível atualizar o perfil. Tente novamente.';
      _setState(AuthState.error);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _setState(AuthState.unauthenticated);
  }

  Future<void> sendPasswordReset(String email) async {
    await _authService.sendPasswordReset(email);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Cancela a assinatura do stream para evitar memory leaks.
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _setState(AuthState s) {
    _state = s;
    notifyListeners();
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':      return 'Usuário não encontrado.';
      case 'wrong-password':      return 'Senha incorreta.';
      case 'invalid-credential':  return 'Email ou senha incorretos.';
      case 'email-already-in-use':return 'Este email já está cadastrado.';
      case 'weak-password':       return 'Senha muito fraca. Use ao menos 6 caracteres.';
      case 'invalid-email':       return 'Email inválido.';
      case 'too-many-requests':   return 'Muitas tentativas. Tente mais tarde.';
      default:                    return 'Erro de autenticação. Tente novamente.';
    }
  }
}
