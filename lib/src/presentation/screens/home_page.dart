import 'package:flutter/material.dart';

/// 應用程式的入口畫面。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('安全數據捕獲 PoC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.shield_outlined,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            const Text(
              '歡迎使用高可信度數據採集前端',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            
            // 主要功能：開始拍照捕獲
            ElevatedButton.icon(
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
            const SizedBox(height: 20),

            // 輔助功能：註冊新的 Passkey
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/auth');
              },
              icon: const Icon(Icons.fingerprint),
              label: const Text('註冊 Passkey'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
