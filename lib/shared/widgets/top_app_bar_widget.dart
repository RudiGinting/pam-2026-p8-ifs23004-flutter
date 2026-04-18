// lib/shared/widgets/top_app_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class TopAppBarMenuItem {
  const TopAppBarMenuItem({
    required this.text,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;
}

class TopAppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  const TopAppBarWidget({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.menuItems = const [],
    this.showThemeToggle = true,
    // Search
    this.withSearch = false,
    this.onSearchChanged,
    this.searchHint = 'Cari...',
  });

  final String title;
  final bool showBackButton;
  final List<TopAppBarMenuItem> menuItems;
  final bool showThemeToggle;
  // Search
  final bool withSearch;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<TopAppBarWidget> createState() => _TopAppBarWidgetState();
}

class _TopAppBarWidgetState extends State<TopAppBarWidget> {
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _closeSearch() {
    setState(() => _isSearching = false);
    _searchCtrl.clear();
    widget.onSearchChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    // ── Mode Pencarian ──────────────────────────────
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _closeSearch,
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.searchHint,
            border: InputBorder.none,
          ),
          onChanged: widget.onSearchChanged,
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchCtrl.clear();
                widget.onSearchChanged?.call('');
                setState(() {});
              },
            ),
        ],
      );
    }

    // ── Mode Normal ─────────────────────────────────
    return AppBar(
      title: Text(widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: false,
      automaticallyImplyLeading: widget.showBackButton,
      actions: [
        // Tombol Search
        if (widget.withSearch)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Cari',
            onPressed: () => setState(() => _isSearching = true),
          ),

        // Tombol Light/Dark Toggle
        if (widget.showThemeToggle)
          IconButton(
            icon: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => themeProvider.toggleTheme(),
          ),

        // Menu Tambahan (titik tiga)
        if (widget.menuItems.isNotEmpty)
          PopupMenuButton<int>(
            onSelected: (i) => widget.menuItems[i].onTap(),
            itemBuilder: (_) => List.generate(
              widget.menuItems.length,
                  (i) => PopupMenuItem<int>(
                value: i,
                child: Row(
                  children: [
                    Icon(
                      widget.menuItems[i].icon,
                      size: 20,
                      color: widget.menuItems[i].isDestructive
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.menuItems[i].text,
                      style: TextStyle(
                        color: widget.menuItems[i].isDestructive
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
