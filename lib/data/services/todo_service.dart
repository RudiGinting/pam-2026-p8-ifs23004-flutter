// lib/data/services/todo_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/api_response_model.dart';
import '../models/todo_model.dart';
import '../../core/constants/api_constants.dart';

class TodoService {
  TodoService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> _authHeader(String token) => {'Authorization': 'Bearer $token'};
  Map<String, String> _jsonAuthHeader(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ─────────────────────────────────────────────
  // GET /todos/stats
  // Response dari BE: { data: { stats: { total, complete, active } } }
  // ─────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> getStats({
    required String authToken,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.todos}/stats');

    final response = await _client.get(uri, headers: _authHeader(authToken));
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final data = body['data'] as Map<String, dynamic>;
      // Mengambil objek 'stats' dari dalam 'data' agar sesuai dengan home_screen
      final statsData = data['stats'] as Map<String, dynamic>? ?? {};
      return ApiResponse(success: true, message: body['message'] as String, data: statsData);
    }
    return ApiResponse(success: false, message: _parseError(response));
  }

  // ─────────────────────────────────────────────
  // GET /todos?search=&page=&perPage=&filter=
  // ─────────────────────────────────────────────
  Future<ApiResponse<List<TodoModel>>> getTodos({
    required String authToken,
    String search = '',
    int page = 1,
    int perPage = 10,
    bool? isDone,
  }) async {
    // Menyusun query parameters untuk Paginasi dan Filter
    final queryParams = <String, String>{
      'page': page.toString(),
      'perPage': perPage.toString(),
    };

    if (search.isNotEmpty) queryParams['search'] = search;

    // 👇 PERBAIKAN FILTER: Disesuaikan dengan ekspektasi Ktor (complete / active) 👇
    if (isDone == true) {
      queryParams['filter'] = 'complete';
    } else if (isDone == false) {
      queryParams['filter'] = 'active';
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.todos}')
        .replace(queryParameters: queryParams);

    final response = await _client.get(uri, headers: _authHeader(authToken));
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final data = body['data'] as Map<String, dynamic>;
      final list = (data['todos'] as List<dynamic>)
          .map((e) => TodoModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse(success: true, message: body['message'] as String, data: list);
    }
    return ApiResponse(success: false, message: _parseError(response));
  }

  // ─────────────────────────────────────────────
  // POST /todos
  // Body JSON: { title, description }
  // Response: { data: { todoId } }
  // ─────────────────────────────────────────────
  Future<ApiResponse<String>> createTodo({
    required String authToken,
    required String title,
    required String description,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.todos}');
    final response = await _client.post(
      uri,
      headers: _jsonAuthHeader(authToken),
      body: jsonEncode({'title': title, 'description': description}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 || response.statusCode == 201) {
      final todoId = (body['data'] as Map<String, dynamic>)['todoId'] as String;
      return ApiResponse(success: true, message: body['message'] as String, data: todoId);
    }
    return ApiResponse(success: false, message: _parseError(response));
  }

  // ─────────────────────────────────────────────
  // GET /todos/:id
  // ─────────────────────────────────────────────
  Future<ApiResponse<TodoModel>> getTodoById({
    required String authToken,
    required String todoId,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.todoById(todoId)}');
    final response = await _client.get(uri, headers: _authHeader(authToken));
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final todo = TodoModel.fromJson(
        (body['data'] as Map<String, dynamic>)['todo'] as Map<String, dynamic>,
      );
      return ApiResponse(success: true, message: body['message'] as String, data: todo);
    }
    return ApiResponse(success: false, message: _parseError(response));
  }

  // ─────────────────────────────────────────────
  // PUT /todos/:id
  // Body JSON: { title, description, isDone }
  // ─────────────────────────────────────────────
  Future<ApiResponse<void>> updateTodo({
    required String authToken,
    required String todoId,
    required String title,
    required String description,
    required bool isDone,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.todoById(todoId)}');
    final response = await _client.put(
      uri,
      headers: _jsonAuthHeader(authToken),
      body: jsonEncode({'title': title, 'description': description, 'isDone': isDone}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return ApiResponse(success: true, message: body['message'] as String);
    }
    return ApiResponse(success: false, message: _parseError(response));
  }

  // ─────────────────────────────────────────────
  // PUT /todos/:id/cover
  // Multipart form-data, field: file
  // Mendukung Web (Uint8List) dan Mobile (File)
  // ─────────────────────────────────────────────
  Future<ApiResponse<void>> updateTodoCover({
    required String authToken,
    required String todoId,
    File? imageFile,
    Uint8List? imageBytes,
    String imageFilename = 'cover.jpg',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.todoCover(todoId)}');

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
    return ApiResponse(success: false, message: _parseError(response));
  }

  // ─────────────────────────────────────────────
  // DELETE /todos/:id
  // ─────────────────────────────────────────────
  Future<ApiResponse<void>> deleteTodo({
    required String authToken,
    required String todoId,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.todoById(todoId)}');
    final response = await _client.delete(uri, headers: _authHeader(authToken));
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 204) {
      return ApiResponse(success: true, message: body['message'] as String? ?? 'Berhasil.');
    }
    return ApiResponse(success: false, message: _parseError(response));
  }

  String _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message'] as String? ?? 'Gagal. Kode: ${response.statusCode}';
    } catch (_) {
      return 'Gagal. Kode: ${response.statusCode}';
    }
  }

  void dispose() => _client.close();
}