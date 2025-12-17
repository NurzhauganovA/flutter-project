import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scaffold_with_nav_bar.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
// Импорты новых экранов (создадим их ниже)
import '../features/search/presentation/search_screen.dart';
import '../features/budget/presentation/budget_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorStatsKey = GlobalKey<NavigatorState>(debugLabel: 'shellStats');
final _shellNavigatorSettingsKey = GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isLoginRoute = state.uri.toString() == '/login';
      if (!isAuthenticated) return isLoginRoute ? null : '/login';
      if (isAuthenticated && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorStatsKey,
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // --- Новые роуты ---
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/add-transaction',
        builder: (context, state) {
          // Если передаем параметры (например, тип транзакции)
          final extra = state.extra as Map<String, dynamic>?;
          return AddTransactionScreen(initialType: extra?['type']);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/budgets',
        builder: (context, state) => const BudgetScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
});