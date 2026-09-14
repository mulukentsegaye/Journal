import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/services/settings_service.dart';
import 'core/services/security_service.dart';
import 'features/auth/widgets/auth_gate.dart';
import 'features/auth/widgets/lock_screen.dart';
import 'features/today/pages/today_page.dart';
import 'features/journal/pages/journal_page.dart';
import 'shared/widgets/bottom_nav_bar.dart';
import 'shared/widgets/profile_drawer.dart';

/// Clean scroll behavior that prevents exaggerated overscroll bounce and supports all input devices.
class MindfulScrollBehavior extends MaterialScrollBehavior {
  const MindfulScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

/// Root widget that configures MaterialApp with theme and App Lock security.
class DailyReflectionApp extends StatefulWidget {
  const DailyReflectionApp({super.key});

  @override
  State<DailyReflectionApp> createState() => _DailyReflectionAppState();
}

class _DailyReflectionAppState extends State<DailyReflectionApp>
    with WidgetsBindingObserver {
  final _securityService = SecurityService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _securityService.handleAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _securityService.handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService(), _securityService]),
      builder: (context, _) {
        return MaterialApp(
          title: 'Daily Reflection',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: SettingsService().themeMode,
          scrollBehavior: const MindfulScrollBehavior(),
          builder: (context, child) {
            return Stack(
              children: [
                ?child,
                if (_securityService.isLocked) const LockScreen(),
              ],
            );
          },
          navigatorObservers: [SentryNavigatorObserver()],
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Top-level shell that manages the bottom navigation
/// and swaps between feature pages.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  /// Static helper to open the right-side profile drawer from anywhere in the app
  static void openDrawer() {
    scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, _) {
        final currentTheme = SettingsService().themeMode;
        // Direction: positive = moving right (Journal), negative = moving left (Today)
        final goingForward = _currentIndex > _previousIndex;

        final pages = <Widget>[
          TodayPage(key: ValueKey('today_$currentTheme')),
          JournalPage(key: ValueKey('journal_$currentTheme')),
        ];

        return Scaffold(
          key: AppShell.scaffoldKey,
          endDrawer: const ProfileDrawer(),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            transitionBuilder: (child, animation) {
              // Determine if this child is the incoming or outgoing widget
              final isIncoming = animation.status == AnimationStatus.forward;
              final slideBegin = isIncoming
                  ? Offset(goingForward ? 0.06 : -0.06, 0.0)
                  : Offset(goingForward ? -0.06 : 0.06, 0.0);

              return SlideTransition(
                position: Tween<Offset>(
                  begin: slideBegin,
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey('tab_${_currentIndex}_$currentTheme'),
              child: pages[_currentIndex],
            ),
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        );
      },
    );
  }
}
