import 'dart:io';
import 'package:flutter/material.dart';
import 'app_state_persistence.dart';
import 'csv_loader.dart';
import 'iap_service.dart';
import 'splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar el estado del usuario guardado primero
  await AppStatePersistence.load();

  // Sincronizar CSVs desde GitHub en segundo plano.
  // No bloquea el inicio — si no hay conexión, se usan los archivos incluidos/en caché.
  CsvUpdater.syncIfNeeded();

  // Inicializar servicio IAP — solo iOS y Android
  if (Platform.isIOS || Platform.isAndroid) {
    await IAPService.instance.initialize();
  }

  runApp(const SafePrepApp());
}

class SafePrepApp extends StatelessWidget {
  const SafePrepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePrep Español',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0077C8)),
        useMaterial3: true,
      ),
      home: const SplashPage(),
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390, maxHeight: 844),
            child: child!,
          ),
        );
      },
    );
  }
}
