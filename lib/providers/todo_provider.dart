// lib/providers/todo_provider.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart'; // Ditambahkan untuk menghapus cache gambar
import '../data/models/todo_model.dart';
import '../data/services/todo_repository.dart';

enum TodoStatus { initial, loading, success, error }

class TodoProvider extends ChangeNotifier {
  TodoProvider({TodoRepository? repository})
      : _repository = repository ?? TodoRepository();

  final TodoRepository _repository;

  // ── State ────────────────────────────────────
  TodoStatus _status = TodoStatus.initial;
  List<TodoModel> _todos = [];
  TodoModel? _selectedTodo;
  String _errorMessage = '';
  String _searchQuery = '';

  // State Paginasi
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // State Filter ('all', 'done', 'pending')
  String _currentFilter = 'all';

  // State Statistik
  Map<String, dynamic>? _stats;

  // ── Getters ──────────────────────────────────
  TodoStatus get status       => _status;
  TodoModel? get selectedTodo => _selectedTodo;
  String get errorMessage     => _errorMessage;
  List<TodoModel> get todos   => List.unmodifiable(_todos);

  // Getters Paginasi & Filter
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  String get currentFilter => _currentFilter;

  // Getters Statistik
  Map<String, dynamic>? get stats => _stats;

  // ── Load Stats ──────────────────────────────
  Future<void> loadStats({required String authToken}) async {
    final result = await _repository.getStats(authToken: authToken);
    if (result.success && result.data != null) {
      _stats = result.data;
      notifyListeners();
    }
  }

  // ── Fetch Todos (Paginasi & Filter) ─────────
  Future<void> fetchTodos({
    required String authToken,
    bool refresh = false
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _todos.clear();
      _setStatus(TodoStatus.loading);
    } else {
      if (!_hasMore || _isLoadingMore) return;
      _isLoadingMore = true;
      notifyListeners(); // Tampilkan indikator loading di bawah
    }

    // Konversi filter teks ke boolean untuk diteruskan ke Service
    bool? isDoneParam;
    if (_currentFilter == 'done') isDoneParam = true;
    if (_currentFilter == 'pending') isDoneParam = false;

    final result = await _repository.getTodos(
      authToken: authToken,
      search: _searchQuery,
      page: _currentPage,
      perPage: 10,
      isDone: isDoneParam,
    );

    if (result.success && result.data != null) {
      final fetchedTodos = result.data!;

      // Jika data yang dikembalikan kurang dari perPage (10), berarti data habis
      if (fetchedTodos.isEmpty || fetchedTodos.length < 10) {
        _hasMore = false;
      }

      if (refresh) {
        _todos = fetchedTodos;
      } else {
        _todos.addAll(fetchedTodos);
      }

      _currentPage++;
      _setStatus(TodoStatus.success);
    } else {
      _errorMessage = result.message;
      _setStatus(TodoStatus.error);
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  // ── Load Single Todo ──────────────────────────
  Future<void> loadTodoById({
    required String authToken,
    required String todoId,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.getTodoById(
        authToken: authToken, todoId: todoId);
    if (result.success && result.data != null) {
      _selectedTodo = result.data;
      _setStatus(TodoStatus.success);
    } else {
      _errorMessage = result.message;
      _setStatus(TodoStatus.error);
    }
  }

  // ── Create Todo ───────────────────────────────
  Future<bool> addTodo({
    required String authToken,
    required String title,
    required String description,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.createTodo(
      authToken:   authToken,
      title:       title,
      description: description,
    );
    if (result.success) {
      // Refresh list dan stats setelah menambah
      await fetchTodos(authToken: authToken, refresh: true);
      await loadStats(authToken: authToken);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  // ── Update Todo ───────────────────────────────
  Future<bool> editTodo({
    required String authToken,
    required String todoId,
    required String title,
    required String description,
    required bool isDone,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.updateTodo(
      authToken:   authToken,
      todoId:      todoId,
      title:       title,
      description: description,
      isDone:      isDone,
    );
    if (result.success) {
      // Refresh list, detail, dan stats
      await Future.wait([
        loadTodoById(authToken: authToken, todoId: todoId),
        fetchTodos(authToken: authToken, refresh: true),
        loadStats(authToken: authToken),
      ]);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  // ── Update Cover ──────────────────────────────
  Future<bool> updateCover({
    required String authToken,
    required String todoId,
    File? imageFile,
    Uint8List? imageBytes,
    String imageFilename = 'cover.jpg',
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.updateTodoCover(
      authToken:     authToken,
      todoId:        todoId,
      imageFile:     imageFile,
      imageBytes:    imageBytes,
      imageFilename: imageFilename,
    );

    if (result.success) {
      // 👇 MEMBERSIHKAN CACHE GAMBAR AGAR GAMBAR BARU MUNCUL 👇
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      await Future.wait([
        loadTodoById(authToken: authToken, todoId: todoId),
        fetchTodos(authToken: authToken, refresh: true),
      ]);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  // ── Delete Todo ───────────────────────────────
  Future<bool> removeTodo({
    required String authToken,
    required String todoId,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.deleteTodo(
        authToken: authToken, todoId: todoId);
    if (result.success) {
      // Refresh list dan stats setelah menghapus
      await fetchTodos(authToken: authToken, refresh: true);
      await loadStats(authToken: authToken);
      _selectedTodo = null;
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  // ── Set Filter ────────────────────────────────
  void setFilter(String authToken, String filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    fetchTodos(authToken: authToken, refresh: true);
  }

  // ── Search ────────────────────────────────────
  void updateSearchQuery(String authToken, String query) {
    _searchQuery = query;
    fetchTodos(authToken: authToken, refresh: true);
  }

  void clearSelectedTodo() {
    _selectedTodo = null;
    notifyListeners();
  }

  void _setStatus(TodoStatus status) {
    _status = status;
    notifyListeners();
  }
}