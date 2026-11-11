import 'package:ecoenzyme/features/auth/presentation/screens/login.dart';
import 'package:ecoenzyme/features/auth/presentation/screens/otp.dart';
import 'package:ecoenzyme/features/auth/presentation/screens/register.dart';
import 'package:ecoenzyme/features/ecoai/presentation/home.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const home = '/home';
}

GoRouter createAppRouter({bool Function()? isAuthenticated}) {
  final hasAuthenticatedUser =
      isAuthenticated ??
      () => Supabase.instance.client.auth.currentUser != null;

  return GoRouter(
    initialLocation: AppRoutes.login,
    onException: (_, _, router) => router.go(AppRoutes.login),
    redirect: (BuildContext _, GoRouterState state) {
      final isPublicRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.otp;

      if (!hasAuthenticatedUser() && !isPublicRoute) {
        return AppRoutes.login;
      }

      if (hasAuthenticatedUser() &&
          (state.matchedLocation == AppRoutes.login ||
              state.matchedLocation == AppRoutes.register)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (_, _) =>
            hasAuthenticatedUser() ? AppRoutes.home : AppRoutes.login,
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (_, _) => const Home(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (_, state) {
          final email = state.uri.queryParameters['email']!;

          return OtpScreen(email: email);
        },
      ),
    ],
  );
}

final appRouter = createAppRouter();
