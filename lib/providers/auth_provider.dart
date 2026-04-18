// lib/providers/auth_provider.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  // ── State ────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _authToken;
  String? _refreshToken;
  String _errorMessage = '';

  // ── Getters ──────────────────────────────────
  AuthStatus get status        => _status;
  UserModel? get user          => _user;
  String? get authToken        => _authToken;
  bool get isAuthenticated     => _authToken != null && _status == AuthStatus.authenticated;
  String get errorMessage      => _errorMessage;

  // ── Init: cek token tersimpan ─────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken    = prefs.getString('authToken');
    _refreshToken = prefs.getString('refreshToken');

    if (_authToken != null) {
      await loadProfile();
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // ── Register ─────────────────────────────────
  Future<bool> register({
    required String name,
    required String username,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);
    final result = await _repository.register(
      name: name, username: username, password: password,
    );
    if (result.success) {
      _setStatus(AuthStatus.unauthenticated);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(AuthStatus.error);
    return false;
  }

  // ── Login ────────────────────────────────────
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);
    final result = await _repository.login(username: username, password: password);
    if (result.success && result.data != null) {
      await _saveTokens(
        authToken:    result.data!['authToken']!,
        refreshToken: result.data!['refreshToken']!,
      );
      await loadProfile();
      return true;
    }
    _errorMessage = result.message;
    _setStatus(AuthStatus.error);
    return false;
  }

  // ── Logout ───────────────────────────────────
  Future<void> logout() async {
    if (_authToken != null) {
      await _repository.logout(authToken: _authToken!);
    }
    await _clearTokens();
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ── Load Profile ─────────────────────────────
  Future<void> loadProfile() async {
    if (_authToken == null) return;
    _setStatus(AuthStatus.loading);
    final result = await _repository.getMe(authToken: _authToken!);
    if (result.success && result.data != null) {
      _user = result.data;
      _setStatus(AuthStatus.authenticated);
    } else {
      // Token tidak valid, coba refresh
      final refreshed = await _tryRefreshToken();
      if (!refreshed) {
        await _clearTokens();
        _setStatus(AuthStatus.unauthenticated);
      }
    }
  }

  // ── Update Profile ────────────────────────────
  Future<bool> updateProfile({
    required String name,
    required String username,
  }) async {
    if (_authToken == null) return false;
    _setStatus(AuthStatus.loading);
    final result = await _repository.updateMe(
      authToken: _authToken!, name: name, username: username,
    );
    if (result.success) {
      await loadProfile();
      return true;
    }
    _errorMessage = result.message;
    _setStatus(AuthStatus.authenticated);
    return false;
  }

  // ── Update Password ───────────────────────────
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_authToken == null) return false;
    _setStatus(AuthStatus.loading);
    final result = await _repository.updatePassword(
      authToken: _authToken!,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (result.success) {
      _setStatus(AuthStatus.authenticated);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(AuthStatus.authenticated);
    return false;
  }

  // ── Update Photo ──────────────────────────────
  // Mendukung Web (imageBytes) dan Mobile (imageFile)
  Future<bool> updatePhoto({
    File? imageFile,
    Uint8List? imageBytes,
    String imageFilename = 'photo.jpg',
  }) async {
    if (_authToken == null) return false;
    _setStatus(AuthStatus.loading);
    final result = await _repository.updatePhoto(
      authToken: _authToken!,
      imageFile: imageFile,
      imageBytes: imageBytes,
      imageFilename: imageFilename,
    );
    if (result.success) {
      await loadProfile();
      return true;
    }
    _errorMessage = result.message;
    _setStatus(AuthStatus.authenticated);
    return false;
  }

  // ── Refresh Token ─────────────────────────────
  Future<bool> _tryRefreshToken() async {
    if (_authToken == null || _refreshToken == null) return false;
    final result = await _repository.refreshToken(
      authToken: _authToken!,
      refreshToken: _refreshToken!,
    );
    if (result.success && result.data != null) {
      await _saveTokens(
        authToken:    result.data!['authToken']!,
        refreshToken: result.data!['refreshToken']!,
      );
      final profileResult = await _repository.getMe(authToken: _authToken!);
      if (profileResult.success && profileResult.data != null) {
        _user = profileResult.data;
        return true;
      }
    }
    return false;
  }

  // ── Helpers ───────────────────────────────────
  Future<void> _saveTokens({
    required String authToken,
    required String refreshToken,
  }) async {
    _authToken    = authToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', authToken);
    await prefs.setString('refreshToken', refreshToken);
  }

  Future<void> _clearTokens() async {
    _authToken    = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('refreshToken');
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}