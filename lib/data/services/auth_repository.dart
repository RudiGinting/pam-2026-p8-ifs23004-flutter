// lib/data/services/auth_repository.dart

import 'dart:io';
import 'dart:typed_data';
import '../models/api_response_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class AuthRepository {
  AuthRepository({AuthService? service})
      : _service = service ?? AuthService();

  final AuthService _service;

  Future<ApiResponse<String>> register({
    required String name,
    required String username,
    required String password,
  }) async {
    try {
      return await _service.register(name: name, username: username, password: password);
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  Future<ApiResponse<Map<String, String>>> login({
    required String username,
    required String password,
  }) async {
    try {
      return await _service.login(username: username, password: password);
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  Future<ApiResponse<void>> logout({required String authToken}) async {
    try {
      return await _service.logout(authToken: authToken);
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  Future<ApiResponse<Map<String, String>>> refreshToken({
    required String authToken,
    required String refreshToken,
  }) async {
    try {
      return await _service.refreshToken(authToken: authToken, refreshToken: refreshToken);
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  Future<ApiResponse<UserModel>> getMe({required String authToken}) async {
    try {
      return await _service.getMe(authToken: authToken);
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  Future<ApiResponse<void>> updateMe({
    required String authToken,
    required String name,
    required String username,
  }) async {
    try {
      return await _service.updateMe(authToken: authToken, name: name, username: username);
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  Future<ApiResponse<void>> updatePassword({
    required String authToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      return await _service.updatePassword(
        authToken: authToken,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  Future<ApiResponse<void>> updatePhoto({
    required String authToken,
    File? imageFile,
    Uint8List? imageBytes,
    String imageFilename = 'photo.jpg',
  }) async {
    try {
      return await _service.updatePhoto(
        authToken: authToken,
        imageFile: imageFile,
        imageBytes: imageBytes,
        imageFilename: imageFilename,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }
}