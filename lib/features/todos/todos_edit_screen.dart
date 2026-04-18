// lib/features/todos/todos_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class TodosEditScreen extends StatefulWidget {
  const TodosEditScreen({super.key, required this.todoId});

  final String todoId;

  @override
  State<TodosEditScreen> createState() => _TodosEditScreenState();
}

class _TodosEditScreenState extends State<TodosEditScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _isDone        = false;
  bool _isLoading     = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().authToken ?? '';
      context.read<TodoProvider>().loadTodoById(
        authToken: token, todoId: widget.todoId,
      );
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _populateForm() {
    if (_isInitialized) return;
    final todo = context.read<TodoProvider>().selectedTodo;
    if (todo == null) return;
    _titleCtrl.text = todo.title;
    _descCtrl.text  = todo.description;
    _isDone         = todo.isDone;
    _isInitialized  = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final token   = context.read<AuthProvider>().authToken ?? '';
    final success = await context.read<TodoProvider>().editTodo(
      authToken:   token,
      todoId:      widget.todoId,
      title:       _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      isDone:      _isDone,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      showAppSnackBar(context,
          message: 'Todo berhasil diperbarui.', type: SnackBarType.success);
      Navigator.of(context).pop(true);
    } else {
      showAppSnackBar(context,
          message: context.read<TodoProvider>().errorMessage,
          type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();

    if (provider.selectedTodo != null) _populateForm();

    return Scaffold(
      appBar: const TopAppBarWidget(title: 'Edit Todo', showBackButton: true),
      body: provider.selectedTodo == null
          ? const LoadingWidget(message: 'Memuat data...')
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul Todo',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul tidak boleh kosong.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Deskripsi tidak boleh kosong.'
                    : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Tandai sebagai selesai'),
                subtitle: Text(_isDone ? 'Sudah selesai' : 'Belum selesai'),
                value: _isDone,
                onChanged: (v) => setState(() => _isDone = v),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_isLoading ? 'Menyimpan...' : 'Simpan'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}