// lib/features/todos/todos_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../data/models/todo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Mendeteksi ketika scroll mencapai 200 pixel dari bawah
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final token = context.read<AuthProvider>().authToken;
      final provider = context.read<TodoProvider>();

      // Jika masih ada data dan sedang tidak memuat, fetch data selanjutnya (refresh: false)
      if (token != null && !provider.isLoadingMore && provider.hasMore) {
        provider.fetchTodos(authToken: token);
      }
    }
  }

  void _loadData() {
    final token = context.read<AuthProvider>().authToken;
    // Menggunakan refresh: true untuk mereset paginasi ke halaman 1
    if (token != null) {
      context.read<TodoProvider>().fetchTodos(authToken: token, refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final token = context.read<AuthProvider>().authToken ?? '';

    return Scaffold(
      appBar: TopAppBarWidget(
        title: 'Todo Saya',
        withSearch: true,
        searchHint: 'Cari todo...',
        onSearchChanged: (query) {
          context.read<TodoProvider>().updateSearchQuery(token, query);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context
            .push(RouteConstants.todosAdd)
            .then((_) => _loadData()),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── WIDGET FILTER (SegmentedButton) ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('Semua')),
                ButtonSegment(value: 'pending', label: Text('Pending')),
                ButtonSegment(value: 'done', label: Text('Selesai')),
              ],
              selected: {provider.currentFilter},
              onSelectionChanged: (Set<String> newSelection) {
                provider.setFilter(token, newSelection.first);
              },
            ),
          ),

          // ── LIST DATA TODOS (Paginasi) ────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: _buildBodyContent(context, provider, token),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context, TodoProvider provider, String token) {
    // 1. Tampilkan Loading Penuh (Hanya jika data kosong dan sedang refresh awal)
    if (provider.status == TodoStatus.loading && provider.todos.isEmpty) {
      return const LoadingWidget(message: 'Memuat todo...');
    }

    // 2. Tampilkan Error
    if (provider.status == TodoStatus.error && provider.todos.isEmpty) {
      return AppErrorWidget(message: provider.errorMessage, onRetry: _loadData);
    }

    // 3. Tampilkan Pesan Kosong
    if (provider.todos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(), // Agar tetap bisa di-pull-to-refresh
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Icon(Icons.inbox_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text(
            'Belum ada todo.\nKetuk + untuk menambahkan.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // 4. Tampilkan List Paginasi
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      // Tambah 1 item ekstra di bawah jika masih ada data (untuk indikator loading)
      itemCount: provider.todos.length + (provider.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        // Jika index mencapai panjang list, tampilkan loading spinner di bawah
        if (index == provider.todos.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final todo = provider.todos[index];
        return _TodoCard(
          todo: todo,
          onTap: () => context
              .push(RouteConstants.todosDetail(todo.id))
              .then((_) => _loadData()),
          onToggle: () async {
            final success = await provider.editTodo(
              authToken: token,
              todoId: todo.id,
              title: todo.title,
              description: todo.description,
              isDone: !todo.isDone,
            );
            if (!success && mounted) {
              showAppSnackBar(context,
                  message: provider.errorMessage,
                  type: SnackBarType.error);
            }
          },
        );
      },
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.onTap,
    required this.onToggle,
  });

  final TodoModel todo;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: GestureDetector(
          onTap: onToggle,
          child: Icon(
            todo.isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: todo.isDone ? Colors.green : colorScheme.outline,
            size: 28,
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          todo.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }
}