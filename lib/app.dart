
import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'services/settings_service.dart';
import 'services/app_security_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

class AppThemeController {
  AppThemeController._();

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static Future<void> loadTheme() async {
    try {
      final savedTheme =
          await SettingsService.instance.getTheme();

      themeMode.value = _convertTheme(savedTheme);
    } catch (_) {
      themeMode.value = ThemeMode.light;
    }
  }

  static Future<void> updateTheme(String theme) async {
    await SettingsService.instance.saveTheme(theme);
    themeMode.value = _convertTheme(theme);
  }

  static ThemeMode _convertTheme(String theme) {
    switch (theme) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }
}

class BusinessManagerApp extends StatefulWidget {
  const BusinessManagerApp({super.key});

  @override
  State<BusinessManagerApp> createState() =>
      _BusinessManagerAppState();
}

class _BusinessManagerAppState extends State<BusinessManagerApp>
    with WidgetsBindingObserver {
  bool _isLockShowing = false;
  bool _initialCheckCompleted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    AppThemeController.loadTheme();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPinLock();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_initialCheckCompleted) {
        _checkPinLock();
      }
    }
  }

  Future<void> _checkPinLock() async {
    if (_isLockShowing) return;

    _isLockShowing = true;

    try {
      final shouldLock =
          await AppSecurityService.instance.shouldLockApp();

      if (!mounted) return;

      if (shouldLock) {
        final navigator = appNavigatorKey.currentState;

        if (navigator != null) {
          await navigator.pushNamed(AppRoutes.pinLock);
        }
      }
    } catch (_) {
      // Security check errors are not silently treated as PIN success.
    } finally {
      _isLockShowing = false;
      _initialCheckCompleted = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'Business Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentTheme,
          initialRoute: AppRoutes.dashboard,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
