import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sample_capture_app/src/presentation/screens/auth_screen.dart';

import 'src/presentation/screens/home_page.dart';
import 'src/presentation/screens/camera_screen.dart';
import 'src/presentation/screens/result_screen.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: [${record.loggerName}] ${record.message}');
  });
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Capture PoC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/camera': (context) => const CameraScreen(),
        '/result': (context) => const ResultScreen(),
        // 【新增】註冊 Passkey 頁面的路由
        '/auth': (context) => const AuthScreen(),
      },
    );
  }
}
