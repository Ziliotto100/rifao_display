import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';
import 'screens/display_screen.dart';
import 'theme/brand_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // window_manager só existe pra Windows/Linux/macOS — em outras
  // plataformas nem tenta inicializar, pra não quebrar o build.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
  }
  runApp(const RifaoApp());
}

class RifaoApp extends StatelessWidget {
  const RifaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rifão da Festa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: BrandColors.darkGreen,
        useMaterial3: true,
      ),
      home: const DisplayScreen(),
    );
  }
}
