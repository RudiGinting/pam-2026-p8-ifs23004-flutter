// lib/features/todos/todos_add_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class TodosAddScreen extends StatefulWidget {
  const TodosAddScreen({super.key});

  @override
  State<TodosAddScreen> createState() => _TodosAddScreenState();
}

class _TodosAddScreenState extends State<TodosAddScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _isLoading  = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final token   = context.read<AuthProvider>().authToken ?? '';
    final success = await context.read<TodoProvider>().addTodo(
      authToken:   token,
      title:       _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      showAppSnackBar(context,
          message: 'Todo berhasil ditambahkan.', type: SnackBarType.success);
      Navigator.of(context).pop(true);
    } else {
      showAppSnackBar(context,
          message: context.read<TodoProvider>().errorMessage,
          type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopAppBarWidget(title: 'Tambah Todo', showBackButton: true),
      body: SingleChildScrollView(
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
                textInputAction: TextInputAction.next,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Judul tidak boleh kosong.' : null,
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
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Deskripsi tidak boleh kosong.' : null,
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