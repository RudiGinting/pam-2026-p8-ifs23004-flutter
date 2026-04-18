// lib/data/services/todo_repository.dart

import 'dart:io';
import 'dart:typed_data';
import '../models/api_response_model.dart';
import '../models/todo_model.dart';
import 'todo_service.dart';

class TodoRepository {
  TodoRepository({TodoService? service})
      : _service = service ?? TodoService();

  final TodoService _service;

  // ─────────────────────────────────────────────
  // Tambahan Fungsi Get Stats
  // ─────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> getStats({
    required String authToken,
  }) async {
    try {
      return await _service.getStats(authToken: authToken);
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Update Fungsi Get Todos (Paginasi & Filter)
  // ─────────────────────────────────────────────
  Future<ApiResponse<List<TodoModel>>> getTodos({
    required String authToken,
    String search = '',
    int page = 1,
    int perPage = 10,
    bool? isDone,
  }) async {
    try {
      return await _service.getTodos(
        authToken: authToken,
        search: search,
        page: page,
        perPage: perPage,
        isDone: isDone,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  Future<ApiResponse<String>> createTodo({
    required String authToken,
    required String title,
    required String description,
  }) async {
    try {
      return await _service.createTodo(
        authToken: authToken, title: title, description: description,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  Future<ApiResponse<TodoModel>> getTodoById({
    required String authToken,
    required String todoId,
  }) async {
    try {
      return await _service.getTodoById(authToken: authToken, todoId: todoId);
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  Future<ApiResponse<void>> updateTodo({
    required String authToken,
    required String todoId,
    required String title,
    required String description,
    required bool isDone,
  }) async {
    try {
      return await _service.updateTodo(
        authToken: authToken,
        todoId: todoId,
        title: title,
        description: description,
        isDone: isDone,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  Future<ApiResponse<void>> updateTodoCover({
    required String authToken,
    required String todoId,
    File? imageFile,
    Uint8List? imageBytes,
    String imageFilename = 'cover.jpg',
  }) async {
    try {
      return await _service.updateTodoCover(
        authToken: authToken,
        todoId: todoId,
        imageFile: imageFile,
        imageBytes: imageBytes,
        imageFilename: imageFilename,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }

  Future<ApiResponse<void>> deleteTodo({
    required String authToken,
    required String todoId,
  }) async {
    try {
      return await _service.deleteTodo(authToken: authToken, todoId: todoId);
    } catch (e) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan jaringan: $e');
    }
  }
}