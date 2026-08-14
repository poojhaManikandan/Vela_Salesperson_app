import 'package:flutter/material.dart';
import 'data/bill_store.dart';
import 'data/theme_controller.dart';
import 'screens/splash_screen.dart';
import 'services/translation_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationService.init();
  await BillStore.load();
  await ThemeController.init();
  runApp(const VelanApp());
}

class VelanApp extends StatelessWidget {
  const VelanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TranslationService.isTamil,
      builder: (context, isTamil, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: ThemeController.instance,
          builder: (context, dark, _) => MaterialApp(
            title: 'Velan Billing'.tr,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
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
      ),
        );
      },
    );
  }
}
