// lib/shared/shell_scaffold.dart

import 'package:flutter/material.dart';
import 'widgets/bottom_nav_widget.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const BottomNavWidget(),
    );
  }
}