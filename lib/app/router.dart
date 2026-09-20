import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/discover/presentation/screens/discover_screen.dart';
import '../features/games/twenty_nine/presentation/twenty_nine_game_screen.dart';
import '../features/hangout/presentation/screens/hangout_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/play/presentation/screens/play_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/room/presentation/screens/room_screen.dart';
import '../shared/design_system/tokens/colors.dart';
import '../shared/design_system/tokens/radius.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNav',
);

/// ADDA v2.1 Primary Application Router
/// Employs StatefulShellRoute.indexedStack across four primary branches:
/// 1. HOME (Activity launcher & dashboard)
/// 2. PLAY (Arcade game discovery)
/// 3. HANGOUT (Live spaces & social lobby)
/// 4. CHAT (Messages, rooms & game invites)
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithBottomNav(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: HOME
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Branch 1: PLAY
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/play',
              name: 'play',
              builder: (context, state) => const PlayScreen(),
            ),
          ],
        ),

        // Branch 2: HANGOUT
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/hangout',
              name: 'hangout',
              builder: (context, state) => const HangoutScreen(),
            ),
          ],
        ),

        // Branch 3: CHAT
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              name: 'chat',
              builder: (context, state) => const ChatScreen(),
            ),
          ],
        ),
      ],
    ),

    // Compatibility Routes (Preserved non-destructively for deep links and legacy navigation)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/spaces',
      redirect: (context, state) => '/hangout',
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/discover',
      builder: (context, state) => const DiscoverScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),

    // Active Room Route (Full screen over root navigator)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/space/:id/room',
      builder: (context, state) {
        final spaceId = state.pathParameters['id'] ?? 'space_main';
        final spaceName = (state.extra as String?) ?? 'Adda Space';
        return RoomScreen(spaceId: spaceId, spaceName: spaceName);
      },
    ),

    // Solo Game Route (Independent gameplay without RoomSession)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/play/solo/:gameId',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId'] ?? '';
        switch (gameId) {
          case 'twenty_nine':
            return const TwentyNineGameScreen();
          default:
            return Scaffold(
              appBar: AppBar(title: Text('Unknown Game: $gameId')),
              body: const Center(child: Text('Game not available for solo play')),
            );
        }
      },
    ),
  ],
);

/// 4-Branch Navigation Shell with state preservation
class ScaffoldWithBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNav({super.key, required this.navigationShell});

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AddaColors.surfaceDark : AddaColors.surfaceLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AddaColors.borderDark : AddaColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AddaColors.coral,
            unselectedItemColor: isDark
                ? AddaColors.textMutedDark
                : AddaColors.textMutedLight,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AddaColors.coral.withAlpha(25),
                    borderRadius: AddaRadius.radiusFull,
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    color: AddaColors.coral,
                    size: 20,
                  ),
                ),
                activeIcon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  decoration: const BoxDecoration(
                    gradient: AddaColors.primaryGradient,
                    borderRadius: AddaRadius.radiusFull,
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                label: 'Play',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined),
                activeIcon: Icon(Icons.groups_rounded),
                label: 'Hangout',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                activeIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Chat',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
