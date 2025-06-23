import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 匯入您在 `presentation/screens/` 中建立的所有主要畫面檔案
import 'src/presentation/screens/home_page.dart';
import 'src/presentation/screens/camera_screen.dart';
import 'src/presentation/screens/result_screen.dart';
import 'src/presentation/screens/auth_screen.dart';

// 應用程式進入點
void main() {
  // 確保在 runApp 之前，Flutter 的 widget 綁定已經初始化
  // 這對於異步操作（如初始化套件）是必要的
  WidgetsFlutterBinding.ensureInitialized();

  // 執行應用程式
  runApp(
    // 為了讓 Riverpod 能在整個 App 中運作，
    // 我們需要在最外層用 ProviderScope 包裹住根 Widget
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// 應用程式的根 Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 應用程式的標題，會出現在任務管理器中
      title: 'Secure Capture PoC',
      
      // 應用程式的整體主題
      theme: ThemeData(
        // 使用 Material 3 設計語言
        useMaterial3: true,
        // 設定一個基礎色票，Flutter 會自動產生深淺不同的顏色
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // 關閉右上角的 Debug 標籤
      debugShowCheckedModeBanner: true,

      // 設定應用程式的頁面路由
      // 這是管理多個畫面的標準做法
      // 初始路由設定為 '/'，對應到 HomePage
      initialRoute: '/', 
      routes: {
        // 每個路由對應一個畫面 Widget
        // 這些路由名稱與架構書中定義的畫面相對應 
        '/': (context) => const HomePage(),         // 首頁 
        '/camera': (context) => const CameraScreen(),   // 相機頁 
        '/result': (context) => const ResultScreen(),   // 結果頁 
        '/auth': (context) => const AuthScreen(),     // 認證頁 
      },
    );
  }
}