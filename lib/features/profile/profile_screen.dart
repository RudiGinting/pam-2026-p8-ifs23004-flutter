// lib/features/profile/profile_screen.dart

import 'dart:io';
import 'dart:typed_data'; // Ditambahkan untuk Uint8List
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Update Profile State ────────────
  final _profileFormKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _userCtrl;
  bool _profileLoading = false;

  // State untuk preview gambar instan (Web & Mobile)
  Uint8List? _previewImageBytes;

  // ── Change Password State ───────────
  final _passFormKey = GlobalKey<FormState>();
  final _currPassCtrl  = TextEditingController();
  final _newPassCtrl   = TextEditingController();
  final _confPassCtrl  = TextEditingController();
  bool _passLoading    = false;
  bool _showCurrPass   = false;
  bool _showNewPass    = false;
  bool _showConfPass   = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _userCtrl = TextEditingController(text: user?.username ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _currPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  // ── Foto Profil (Cross-Platform) ─────
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();

    void pickFrom(ImageSource source) async {
      final picked = await picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 512);
      if (picked == null || !mounted) return;

      // Baca sebagai byte (berfungsi di Web, Android, iOS)
      final bytes = await picked.readAsBytes();

      // Tampilkan preview instan menggunakan Image.memory
      setState(() {
        _previewImageBytes = bytes;
      });

      // Lakukan proses upload ke server di latar belakang
      final success = await context.read<AuthProvider>().updatePhoto(
        imageFile:     kIsWeb ? null : File(picked.path),
        imageBytes:    bytes,
        imageFilename: picked.name,
      );

      if (!mounted) return;
      showAppSnackBar(
        context,
        message: success ? 'Foto profil diperbarui.' : context.read<AuthProvider>().errorMessage,
        type: success ? SnackBarType.success : SnackBarType.error,
      );
    }

    if (kIsWeb) {
      // Di web, kamera seringkali butuh izin kompleks, langsung gunakan galeri
      pickFrom(ImageSource.gallery);
      return;
    }

    // Mobile: tampilkan pilihan galeri / kamera
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                pickFrom(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(ctx);
                pickFrom(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Update Profile ──────────────────
  Future<void> _submitProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _profileLoading = true);

    final success = await context.read<AuthProvider>().updateProfile(
      name:     _nameCtrl.text.trim(),
      username: _userCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _profileLoading = false);

    showAppSnackBar(
      context,
      message: success
          ? 'Profil berhasil diperbarui.'
          : context.read<AuthProvider>().errorMessage,
      type: success ? SnackBarType.success : SnackBarType.error,
    );
  }

  // ── Change Password ─────────────────
  Future<void> _submitPassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _passLoading = true);

    final success = await context.read<AuthProvider>().updatePassword(
      currentPassword: _currPassCtrl.text.trim(),
      newPassword:     _newPassCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _passLoading = false);

    showAppSnackBar(
      context,
      message: success
          ? 'Kata sandi berhasil diubah.'
          : context.read<AuthProvider>().errorMessage,
      type: success ? SnackBarType.success : SnackBarType.error,
    );

    if (success) {
      _currPassCtrl.clear();
      _newPassCtrl.clear();
      _confPassCtrl.clear();
    }
  }

  // ── Logout ─────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go(RouteConstants.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<AuthProvider>();
    final user        = provider.user;
    final colorScheme = Theme.of(context).colorScheme;

    if (provider.status == AuthStatus.loading && user == null) {
      return const Scaffold(body: LoadingWidget());
    }

    return Scaffold(
      appBar: TopAppBarWidget(
        title: 'Profil Saya',
        showBackButton: true,
        menuItems: [
          TopAppBarMenuItem(
            text: 'Keluar',
            icon: Icons.logout,
            isDestructive: true,
            onTap: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar Section ──
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: colorScheme.primaryContainer,
                        // Gunakan preview lokal jika ada, jika tidak gunakan URL, jika tidak null
                        backgroundImage: _previewImageBytes != null
                            ? MemoryImage(_previewImageBytes!) as ImageProvider
                            : (user?.urlPhoto != null ? NetworkImage(user!.urlPhoto!) : null),
                        // Tampilkan inisial jika tidak ada gambar sama sekali
                        child: (_previewImageBytes == null && user?.urlPhoto == null)
                            ? Text(
                          (user?.name.isNotEmpty == true)
                              ? user!.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              fontSize: 36,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: colorScheme.surface, width: 2),
                          ),
                          child: Icon(Icons.camera_alt,
                              size: 16, color: colorScheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('@${user?.username ?? ''}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Edit Profil ──
          _SectionCard(
            title: 'Edit Profil',
            icon: Icons.person_outline,
            child: Form(
              key: _profileFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Username tidak boleh kosong.' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _profileLoading ? null : _submitProfile,
                      icon: _profileLoading
                          ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save_outlined),
                      label: Text(_profileLoading ? 'Menyimpan...' : 'Simpan Profil'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Ganti Kata Sandi ──
          _SectionCard(
            title: 'Ganti Kata Sandi',
            icon: Icons.lock_outline,
            child: Form(
              key: _passFormKey,
              child: Column(
                children: [
                  _PasswordField(
                    controller: _currPassCtrl,
                    label: 'Kata Sandi Saat Ini',
                    show: _showCurrPass,
                    onToggle: () =>
                        setState(() => _showCurrPass = !_showCurrPass),
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Kata sandi saat ini diperlukan.' : null,
                  ),
                  const SizedBox(height: 16),
                  _PasswordField(
                    controller: _newPassCtrl,
                    label: 'Kata Sandi Baru',
                    show: _showNewPass,
                    onToggle: () =>
                        setState(() => _showNewPass = !_showNewPass),
                    validator: (v) =>
                    (v == null || v.trim().length < 6)
                        ? 'Minimal 6 karakter.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _PasswordField(
                    controller: _confPassCtrl,
                    label: 'Konfirmasi Kata Sandi Baru',
                    show: _showConfPass,
                    onToggle: () =>
                        setState(() => _showConfPass = !_showConfPass),
                    validator: (v) =>
                    v != _newPassCtrl.text ? 'Kata sandi tidak cocok.' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _passLoading ? null : _submitPassword,
                      icon: _passLoading
                          ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.key),
                      label: Text(_passLoading ? 'Mengubah...' : 'Ganti Kata Sandi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Helper Widgets ──────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !show,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
              show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}