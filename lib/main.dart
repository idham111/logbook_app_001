import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';                    // BARU
import 'package:logbook_app_001/features/logbook/models/log_model.dart'; // BARU

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  LogHelper.init(level: Level.ALL);
  await dotenv.load(fileName: ".env");

  // INISIALISASI HIVE
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter());
  await Hive.openBox<LogModel>('offline_logs');

  LogHelper.info('ENV loaded', source: 'main.dart');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logbook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.purple,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const OnboardingView(),
    );
  }
}