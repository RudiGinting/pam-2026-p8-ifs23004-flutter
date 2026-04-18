// lib/data/services/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/api_response_model.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';

class AuthService {
  AuthService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  // ─────────────────────────────────────────────
  // POST /auth/register
  // Body JSON: { name, username, password }
  // Response: { data: { userId } }
  // ─────────────────────────────────────────────
  Future<ApiResponse<String>> register({
    required String name,
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authRegister}');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'username': username, 'password': password}),
    );

    // 👇 👇 👇 TAMBAHKAN BARIS INI UNTUK DEBUGGING 👇 👇 👇
    print('--- DEBUGGING REGISTER ---');
    print('URL Tujuan: $uri');
    print('Status Code: ${response.statusCode}');
    print('Response Body (Isi dari server): \n${response.body}');
    print('--------------------------');
    // 👆 👆 👆 ===================================== 👆 👆 👆

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      final userId = (body['data'] as Map<String, dynamic>)['userId'] as String;
      return ApiResponse(success: true, message: body['message'] as String, data: userId);
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal mendaftar.');
  }

  // ─────────────────────────────────────────────
  // POST /auth/login
  // Body JSON: { username, password }
  // Response: { data: { authToken, refreshToken } }
  // ─────────────────────────────────────────────
  Future<ApiResponse<Map<String, String>>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authLogin}');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final data = body['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        message: body['message'] as String,
        data: {
          'authToken':    data['authToken']    as String,
          'refreshToken': data['refreshToken'] as String,
        },
      );
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal login.');
  }

  // ─────────────────────────────────────────────
  // POST /auth/logout
  // Body JSON: { authToken }
  // ─────────────────────────────────────────────
  Future<ApiResponse<void>> logout({required String authToken}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authLogout}');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'authToken': authToken}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return ApiResponse(success: true, message: body['message'] as String);
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal logout.');
  }

  // ─────────────────────────────────────────────
  // POST /auth/refresh-token
  // Body JSON: { authToken, refreshToken }
  // Response: { data: { authToken, refreshToken } }
  // ─────────────────────────────────────────────
  Future<ApiResponse<Map<String, String>>> refreshToken({
    required String authToken,
    required String refreshToken,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authRefresh}');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'authToken': authToken, 'refreshToken': refreshToken}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final data = body['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        message: body['message'] as String,
        data: {
          'authToken':    data['authToken']    as String,
          'refreshToken': data['refreshToken'] as String,
        },
      );
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Token tidak valid.');
  }

  // ─────────────────────────────────────────────
  // GET /users/me
  // Header: Authorization: Bearer <token>
  // ─────────────────────────────────────────────
  Future<ApiResponse<UserModel>> getMe({required String authToken}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersMe}');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $authToken'},
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final user = UserModel.fromJson(
        (body['data'] as Map<String, dynamic>)['user'] as Map<String, dynamic>,
      );
      return ApiResponse(success: true, message: body['message'] as String, data: user);
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal memuat profil.');
  }

  // ─────────────────────────────────────────────
  // PUT /users/me
  // Header: Authorization: Bearer <token>
  // Body JSON: { name, username }
  // ─────────────────────────────────────────────
  Future<ApiResponse<void>> updateMe({
    required String authToken,
    required String name,
    required String username,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersMe}');
    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'name': name, 'username': username}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return ApiResponse(success: true, message: body['message'] as String);
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal memperbarui profil.');
  }

  // ─────────────────────────────────────────────
  // PUT /users/me/password
  // Body JSON: { password, newPassword }
  // ─────────────────────────────────────────────
  Future<ApiResponse<void>> updatePassword({
    required String authToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersMePassword}');
    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'password': currentPassword, 'newPassword': newPassword}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return ApiResponse(success: true, message: body['message'] as String);
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal memperbarui kata sandi.');
  }

  // ─────────────────────────────────────────────
  // PUT /users/me/photo
  // Multipart form-data, field: file
  // Mendukung Web (Uint8List) dan Mobile (File)
  // ─────────────────────────────────────────────
  Future<ApiResponse<void>> updatePhoto({
    required String authToken,
    File? imageFile,            // Mobile (Android/iOS)
    Uint8List? imageBytes,      // Web
    String imageFilename = 'photo.jpg',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersMePhoto}');

    final request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $authToken';

    if (kIsWeb && imageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'file', imageBytes, filename: imageFilename,
      ));
    } else if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return ApiResponse(success: true, message: body['message'] as String);
    }
    return ApiResponse(success: false, message: body['message'] as String? ?? 'Gagal memperbarui foto.');
  }


  void dispose() => _client.close();
}