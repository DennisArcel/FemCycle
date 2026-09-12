import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the CLI-generated options,
  // but only if it hasn't already been initialized natively
  // (google-services.json on Android auto-registers a default app).
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Set up timezone data fresh on every app start, so zonedSchedule() always
  // uses the device's current timezone — not a value cached from whenever
  // the user last logged in.
  await NotificationService.initializeTimeZoneData();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const FemCycleApp(),
    ),
  );
}

class FemCycleApp extends StatelessWidget {
  const FemCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'FemCycle',
      debugShowCheckedModeBanner: false,
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}