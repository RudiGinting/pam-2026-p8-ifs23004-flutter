// lib/shared/widgets/bottom_nav_widget.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_constants.dart';

class BottomNavWidget extends StatelessWidget {
  const BottomNavWidget({super.key});

  static const _items = [
    _NavItem(RouteConstants.home,    'Home',   Icons.home_outlined,    Icons.home_rounded),
    _NavItem(RouteConstants.todos,   'Todos',  Icons.task_outlined,    Icons.task_rounded),
    _NavItem(RouteConstants.profile, 'Profil', Icons.person_outlined,  Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    // Hitung index aktif berdasarkan rute saat ini
    int selectedIndex = 0;
    for (int i = 0; i < _items.length; i++) {
      if (location.startsWith(_items[i].route)) {
        selectedIndex = i;
        break;
      }
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        if (index != selectedIndex) {
          context.go(_items[index].route);
        }
      },
      destinations: _items.map((item) {
        final _ = _items.indexOf(item) == selectedIndex;
        return NavigationDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.activeIcon),
          label: item.label,
        );
      }).toList(),
    );
  }
}

class _NavItem {
  const _NavItem(this.route, this.label, this.icon, this.activeIcon);

  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}