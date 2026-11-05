
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';

class BusinessManagerApp extends StatelessWidget {
  const BusinessManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Business Manager',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      themeMode: ThemeMode.light,

      initialRoute: AppRoutes.dashboard,

      routes: AppRoutes.routes,
    );
  }
}
