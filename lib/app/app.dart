import 'package:flutter/material.dart';
import 'package:language_app/app/constants/app_constants.dart';
import 'package:language_app/app/router/app_router.dart';

/// Main app widget with routing configuration
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,

      // Theme configuration
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),

      // Initial route - Splash Screen
      initialRoute: AppRoutes.splash,
      // initialRoute: AppRoutes.home,

      // Route generator with custom transitions
      onGenerateRoute: AppRouter.generateRoute,

      // Fallback for unknown routes
      onUnknownRoute: (settings) {
        return CustomPageRoute(
          page: Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          transitionType: PageTransitionType.fade,
        );
      },
    );
  }
}
