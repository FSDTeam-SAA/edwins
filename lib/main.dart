import 'package:flutter/material.dart';
// import 'package:language_app/features/home/home_view.dart';
import 'package:language_app/features/splash/splash.dart';
import 'package:language_app/core/providers/avatar_provider.dart';
import 'package:language_app/app/constants/app_constants.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AvatarProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appTitle,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const SplashScreen());
        // home: const HomeView()); // AvatarDemoPage());
  }
}
