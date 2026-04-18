// lib/features/todos/todos_detail_screen.dart

import 'dart:io';
import 'dart:typed_data'; // Ditambahkan untuk Uint8List
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart'; // Ditambahkan untuk ApiConstants
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class TodosDetailScreen extends StatefulWidget {
  const TodosDetailScreen({super.key, required this.todoId});

  final String todoId;

  @override
  State<TodosDetailScreen> createState() => _TodosDetailScreenState();
}

class _TodosDetailScreenState extends State<TodosDetailScreen> {
  // Variabel untuk menyimpan gambar sementara secara lokal agar langsung muncul
  Uint8List? _previewImageBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final token = context.read<AuthProvider>().authToken ?? '';
    context.read<TodoProvider>().loadTodoById(
      authToken: token, todoId: widget.todoId,
    );
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1024);
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();

    // Tampilkan gambar secara instan di layar sebelum menunggu server
    setState(() {
      _previewImageBytes = bytes;
    });

    final token    = context.read<AuthProvider>().authToken ?? '';
    final provider = context.read<TodoProvider>();

    final success = await provider.updateCover(
      authToken:     token,
      todoId:        widget.todoId,
      imageFile:     kIsWeb ? null : File(picked.path),
      imageBytes:    bytes,
      imageFilename: picked.name,
    );

    if (!mounted) return;
    if (success) {
      showAppSnackBar(context,
          message: 'Cover berhasil diperbarui.', type: SnackBarType.success);
    } else {
      showAppSnackBar(context,
          message: provider.errorMessage, type: SnackBarType.error);
    }
  }

  Future<void> _confirmDelete(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Hapus Todo'),
        content: const Text('Apakah kamu yakin ingin menghapus todo ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final token = context.read<AuthProvider>().authToken ?? '';
      final success = await context.read<TodoProvider>().removeTodo(
        authToken: token, todoId: widget.todoId,
      );
      if (success && mounted) {
        showAppSnackBar(context,
            message: 'Todo berhasil dihapus.', type: SnackBarType.success);
        context.go(RouteConstants.todos);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();

    if (provider.status == TodoStatus.loading ||
        provider.status == TodoStatus.initial) {
      return const Scaffold(body: LoadingWidget());
    }

    if (provider.status == TodoStatus.error) {
      return Scaffold(
        body: AppErrorWidget(
            message: provider.errorMessage, onRetry: _loadData),
      );
    }

    final todo = provider.selectedTodo;
    if (todo == null) {
      return const Scaffold(
          body: Center(child: Text('Data tidak ditemukan.')));
    }

    return Scaffold(
      appBar: TopAppBarWidget(
        title: todo.title,
        showBackButton: true,
        menuItems: [
          TopAppBarMenuItem(
            text: 'Edit',
            icon: Icons.edit_outlined,
            onTap: () async {
              final edited = await context.push<bool>(
                RouteConstants.todosEdit(todo.id),
              );
              if (edited == true && mounted) _loadData();
            },
          ),
          TopAppBarMenuItem(
            text: 'Hapus',
            icon: Icons.delete_outline,
            isDestructive: true,
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cover ──
            GestureDetector(
              onTap: _pickCover,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Logika Penampilan Gambar:
                      // 1. Jika ada preview lokal, langsung tampilkan
                      if (_previewImageBytes != null)
                        Image.memory(
                          _previewImageBytes!,
                          fit: BoxFit.cover,
                        )
                      // 2. Jika tidak ada preview tapi URL cover tersedia dari server, tampilkan via HTTP
                      else if (todo.urlCover != null)
                        Image.network(
                          // Merakit URL Gambar Ktor dan menambahkan Cache Buster ?v=...
                          '${ApiConstants.baseUrl}/images/todos/${todo.id}?v=${DateTime.now().millisecondsSinceEpoch}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, ___) {
                            print('ERROR RENDER GAMBAR: $error');
                            return const Icon(
                                Icons.image_not_supported_outlined,
                                size: 48);
                          },
                        )
                      // 3. Jika sama sekali tidak ada gambar
                      else
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined,
                                  size: 48),
                              const SizedBox(height: 8),
                              Text('Ketuk untuk menambah cover',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall),
                            ],
                          ),
                        ),
                      // Label Edit Gambar
                      if (_previewImageBytes != null || todo.urlCover != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Ganti',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Status Chip ──
            Chip(
              label: Text(todo.isDone ? 'Selesai' : 'Belum Selesai'),
              avatar: Icon(
                todo.isDone
                    ? Icons.check_circle_rounded
                    : Icons.pending_rounded,
                color: todo.isDone ? Colors.green : Colors.orange,
                size: 18,
              ),
              backgroundColor: todo.isDone
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
            ),
            const SizedBox(height: 16),

            // ── Deskripsi ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deskripsi',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text(todo.description,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}