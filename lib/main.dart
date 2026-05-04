import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/models/model_repository.dart';
import 'src/ui/screens/chat_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise database
  final db = await initDatabase();
  final sharedPrefs = await SharedPreferences.getInstance();

  // Initialise model repository
  final modelRepo = ModelRepository(db: db, sharedPrefs: sharedPrefs);
  await modelRepo.refresh();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        modelRepositoryProvider.overrideWithValue(modelRepo),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local LLM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const ChatListScreen(),
    );
  }
}
