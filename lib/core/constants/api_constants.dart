
// lib/core/constants/api_constants.dart

class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      'https://pam-2026-p5-ifs23004-be.rudijonathan.fun:8080';

  // ── Auth ──────────────────────────────────
  static const String authRegister = '/auth/register';
  static const String authLogin    = '/auth/login';
  static const String authLogout   = '/auth/logout';
  static const String authRefresh  = '/auth/refresh-token';

  // ── Users ─────────────────────────────────
  static const String usersMe         = '/users/me';
  static const String usersMePassword = '/users/me/password';
  static const String usersMePhoto    = '/users/me/photo';

  // ── Todos ─────────────────────────────────
  static const String todos = '/todos';
  static String todoById(String id) => '/todos/$id';
  static String todoCover(String id) => '/todos/$id/cover';
}