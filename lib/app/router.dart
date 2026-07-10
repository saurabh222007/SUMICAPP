import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/library/presentation/screens/library_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/player/presentation/screens/player_screen.dart';
import '../features/lyrics/presentation/screens/lyrics_screen.dart';
import '../features/playlist/presentation/screens/playlist_detail_screen.dart';
import '../shared/widgets/mini_player.dart';

// Key for GoRouter navigation state
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// List of Route Paths for the SUMIC application.
abstract class AppRoutePaths {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String home = '/home';
  static const String search = '/search';
  static const String player = '/player';
  static const String library = '/library';
  static const String playlist = '/playlist/:id';
  static const String lyrics = '/lyrics';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// List of Route Names for the SUMIC application.
abstract class AppRouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';

  static const String home = 'home';
  static const String search = 'search';
  static const String player = 'player';
  static const String library = 'library';
  static const String playlist = 'playlist';
  static const String lyrics = 'lyrics';
  static const String profile = 'profile';
  static const String settings = 'settings';
}

/// Central GoRouter configuration.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutePaths.home, // Standard landing page
  debugLogDiagnostics: true,
  
  // Dynamic Authentication Guards (Redirect logic)
  redirect: (BuildContext context, GoRouterState state) async {
    const secureStorage = SecureStorageService();
    final String? token = await secureStorage.read(SecureStorageKeys.accessToken);
    final bool isLoggedIn = token != null && token.isNotEmpty;

    final String location = state.matchedLocation;
    final bool isAuthRoute = location == AppRoutePaths.login ||
        location == AppRoutePaths.register ||
        location == AppRoutePaths.forgotPassword;

    // Redirect to login if user is not logged in
    if (!isLoggedIn && !isAuthRoute && location != AppRoutePaths.splash) {
      return AppRoutePaths.login;
    }

    // Redirect to home if user is logged in but hits auth pages
    if (isLoggedIn && isAuthRoute) {
      return AppRoutePaths.home;
    }

    return null;
  },

  routes: <RouteBase>[
    // --- AUTHENTICATION ROUTES ---
    GoRoute(
      path: AppRoutePaths.login,
      name: AppRouteNames.login,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutePaths.register,
      name: AppRouteNames.register,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutePaths.forgotPassword,
      name: AppRouteNames.forgotPassword,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // --- NON-TAB DETAILED ROUTES ---
    GoRoute(
      path: AppRoutePaths.player,
      name: AppRouteNames.player,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const PlayerScreen(),
    ),
    GoRoute(
      path: AppRoutePaths.playlist,
      name: AppRouteNames.playlist,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'unknown';
        return PlaylistDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: AppRoutePaths.lyrics,
      name: AppRouteNames.lyrics,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const LyricsScreen(),
    ),
    GoRoute(
      path: AppRoutePaths.settings,
      name: AppRouteNames.settings,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),

    // --- BOTTOM NAVIGATION SHELL ROUTE ---
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) {
        return _AppNavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutePaths.home,
          name: AppRouteNames.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.search,
          name: AppRouteNames.search,
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.library,
          name: AppRouteNames.library,
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.profile,
          name: AppRouteNames.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

/// Persistent Layout shell containing the bottom navigation bar and global Mini Player.
class _AppNavigationShell extends StatelessWidget {
  final Widget child;

  const _AppNavigationShell({required this.child});

  @override
  Widget build(BuildContext context) {
    // Calculates currently selected tab index based on the URI
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith(AppRoutePaths.search)) currentIndex = 1;
    if (location.startsWith(AppRoutePaths.library)) currentIndex = 2;
    if (location.startsWith(AppRoutePaths.profile)) currentIndex = 3;

    return Scaffold(
      body: Stack(
        children: [
          child,
          // Floating Mini Player overlay positioned above the Bottom Navigation Bar
          const Positioned(
            bottom: 12.0,
            left: 0,
            right: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: const Color(0xFF0D0D12),
        indicatorColor: const Color(0xFF6750A4).withOpacity(0.3),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.goNamed(AppRouteNames.home);
              break;
            case 1:
              context.goNamed(AppRouteNames.search);
              break;
            case 2:
              context.goNamed(AppRouteNames.library);
              break;
            case 3:
              context.goNamed(AppRouteNames.profile);
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search, color: Colors.white70),
            selectedIcon: Icon(Icons.search, color: Colors.white),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.library_music, color: Colors.white),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.white70),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

