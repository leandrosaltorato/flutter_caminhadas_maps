import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/storage_service.dart';

final ValueNotifier<ThemeMode> temaNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final escuro = await StorageService.temaEscuro();
  temaNotifier.value = escuro ? ThemeMode.dark : ThemeMode.light;
  runApp(const CaminhadasApp());
}

class CaminhadasApp extends StatelessWidget {
  const CaminhadasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaNotifier,
      builder: (_, modo, __) => MaterialApp(
        title: 'Caminhadas',
        debugShowCheckedModeBanner: false,
        themeMode: modo,
        theme: ThemeData(
          colorSchemeSeed: Colors.green,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.green,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
