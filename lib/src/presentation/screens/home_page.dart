import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/user_service.dart';

/// 應用程式的入口畫面。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 獲取用戶的身份驗證狀態
    final userService = ref.watch(userServiceProvider);
    final isAuthenticated = userService.isAuthenticated;
    final userEmail = userService.currentEmail;
    return Scaffold(
      appBar: AppBar(
        title: const Text('安全數據捕獲 PoC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: '登出',
              onPressed: () async {
                await ref.read(userServiceProvider).logout();
                // 強制重建 UI
                ref.invalidate(userServiceProvider);
              },
            ),
        ],
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
            Text(
              isAuthenticated
                  ? '歡迎回來，${userEmail ?? "用戶"}'
                  : '歡迎使用高可信度數據採集前端',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            if (isAuthenticated) ...[
              // 已登入用戶：顯示拍照捕獲按鈕
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
              
              // 顯示用戶信息
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        '您的 Passkey 已同步',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '您可以在任何設備上使用 $userEmail 登入並使用此應用程序。',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // 未登入用戶：顯示登入和註冊按鈕
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('使用 Passkey 登入'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/auth');
                },
                icon: const Icon(Icons.fingerprint),
                label: const Text('註冊新的 Passkey'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  '註冊或登入後，您可以在任何設備上使用 Passkey 來驗證和上傳照片數據。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
