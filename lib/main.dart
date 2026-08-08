import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const VelanApp());
}

class VelanApp extends StatelessWidget {
  const VelanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Responsive text scaling stays within a sane range on all devices.
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedScale = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.2,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScale),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
