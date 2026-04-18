// lib/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/constants/route_constants.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/todos/todos_add_screen.dart';
import 'features/todos/todos_detail_screen.dart';
import 'features/todos/todos_edit_screen.dart';
import 'features/todos/todos_screen.dart';
import 'providers/auth_provider.dart';
import 'shared/shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter buildRouter(BuildContext context) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.login,
    redirect: (ctx, state) {
      final auth = ctx.read<AuthProvider>();
      final isAuth = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final isOnAuth = loc == RouteConstants.login || loc == RouteConstants.register;

      if (auth.status == AuthStatus.initial) return null;
      if (!isAuth && !isOnAuth) return RouteConstants.login;
      if (isAuth && isOnAuth) return RouteConstants.home;
      return null;
    },
    refreshListenable: context.read<AuthProvider>(),
    routes: [
      // ── Auth routes (tanpa bottom nav) ───────────────
      GoRoute(
        path: RouteConstants.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Halaman detail/form (tanpa bottom nav) ────────
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteConstants.todosAdd,
        builder: (_, __) => const TodosAddScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/todos/:id',
        builder: (_, state) =>
            TodosDetailScreen(todoId: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/todos/:id/edit',
        builder: (_, state) =>
            TodosEditScreen(todoId: state.pathParameters['id']!),
      ),

      // ── Shell (dengan bottom nav) ─────────────────────
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __, navigationShell) =>
            ShellScaffold(child: navigationShell),
        branches: [
          // Tab 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.home,
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          // Tab 1 — Todos
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.todos,
                builder: (_, __) => const TodosScreen(),
              ),
            ],
          ),
          // Tab 2 — Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteConstants.profile,
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}