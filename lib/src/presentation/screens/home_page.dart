import 'package:flutter/material.dart';

/// 應用程式的入口畫面。
///
/// 這個畫面提供一個按鈕，讓使用者可以導航到相機畫面，
/// 從而開始整個安全數據捕獲流程。
/// 根據架構書，這是應用程式的入口頁面 。
class HomePage extends StatelessWidget {
  /// `const` constructor for a stateless widget.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 頁面頂部的應用程式標題欄
      appBar: AppBar(
        title: const Text('安全數據捕獲 PoC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // 頁面的主要內容
      body: Center(
        // 將所有子元件置於畫面中央
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 顯示一個提示性圖示
            const Icon(
              Icons.shield_outlined,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            // 顯示歡迎或說明文字
            const Text(
              '歡迎使用高可信度數據採集前端',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            // 提供開始捕獲數據的主要操作按鈕 
            ElevatedButton.icon(
              // 按下按鈕後，導航到 '/camera' 路由 (這個路由在 main.dart 中定義)
              onPressed: () {
                Navigator.pushNamed(context, '/camera');
              },
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('開始捕獲數據'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}