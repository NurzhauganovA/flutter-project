import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart'; // Импорт нового провайдера

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: CoinFlowApp()));
}

class CoinFlowApp extends ConsumerWidget {
  const CoinFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Слушаем изменения темы
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CoinFlow',
      debugShowCheckedModeBanner: false,
      routerConfig: router,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode, // Передаем сюда динамическое значение
    );
  }
}