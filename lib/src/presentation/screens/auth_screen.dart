import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 假設我們在 application 層建立了一個 auth_provider 來處理註冊邏輯
// import '../../application/auth/auth_provider.dart';

// --- 為了 PoC 演示，我們先定義一個簡單的 Provider 和狀態 ---
// 在真實專案中，您應該將此邏輯移至 'application/auth/auth_provider.dart'

enum AuthScreenState { initial, registering, success, error }

final authScreenProvider = StateNotifierProvider<AuthScreenNotifier, AuthScreenState>((ref) {
  return AuthScreenNotifier();
});

class AuthScreenNotifier extends StateNotifier<AuthScreenState> {
  AuthScreenNotifier() : super(AuthScreenState.initial);

  Future<void> registerPasskey({required String username}) async {
    if (username.isEmpty) {
      state = AuthScreenState.error;
      return;
    }
    try {
      state = AuthScreenState.registering;
      // 1. 呼叫 ApiService 從後端獲取註冊用的 Challenge
      // 2. 呼叫 PasskeyService，傳入 Challenge，觸發平台原生 UI 進行註冊
      // 3. 呼叫 ApiService 將註冊結果回傳給後端儲存
      
      // 模擬一個網路延遲和成功結果
      await Future.delayed(const Duration(seconds: 3));
      
      state = AuthScreenState.success;
    } catch (e) {
      state = AuthScreenState.error;
    }
  }
}
// ----------------------------------------------------


/// 認證畫面，用於使用者註冊 Passkey。
///
/// 這是使用者首次設定無密碼登入或簽章的入口。
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 為了在回呼函數中使用，我們需要一個 TextEditingController
    final usernameController = TextEditingController();
    
    // 監聽狀態變化以顯示 SnackBar
    ref.listen<AuthScreenState>(authScreenProvider, (previous, next) {
      if (next == AuthScreenState.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passkey 建立成功！'),
            backgroundColor: Colors.green,
          ),
        );
        // 成功後可以返回上一頁
        Navigator.of(context).pop();
      } else if (next == AuthScreenState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passkey 建立失敗，請重試。'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // 訂閱狀態以更新 UI
    final authState = ref.watch(authScreenProvider);
    final isRegistering = authState == AuthScreenState.registering;

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定 Passkey 驗證'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.fingerprint,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            const Text(
              '建立您的數位金鑰',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Passkey 將安全地儲存在您的裝置上，讓您可以使用指紋或臉部辨識來進行操作驗證，無需記憶密碼，更加安全便捷。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const Divider(height: 40),
            
            // Passkey 註冊需要綁定一個使用者名稱
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: '使用者名稱',
                border: OutlineInputBorder(),
                hintText: '例如：user@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            
            // 註冊按鈕
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              // 如果正在註冊中，則禁用按鈕
              onPressed: isRegistering
                  ? null
                  : () {
                      // 觸發註冊流程
                      ref.read(authScreenProvider.notifier)
                         .registerPasskey(username: usernameController.text);
                    },
              child: isRegistering
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : const Text('建立 Passkey'),
            ),
          ],
        ),
      ),
    );
  }
}