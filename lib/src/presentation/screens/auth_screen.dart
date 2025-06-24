import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_capture_app/src/services/passkey_service.dart';
import 'package:sample_capture_app/src/services/user_service.dart';
import 'package:sample_capture_app/src/services/api_service.dart';

/// Passkey 註冊畫面
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _usernameController = TextEditingController(text: 'testuser@example.com');
  final _displayNameController = TextEditingController(text: 'Test User');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }
  
  /// 生成隨機挑戰
  String _generateChallenge() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    // 移除 Base64URL 編碼中的填充字符 ('=')
    return base64Url.encode(values).replaceAll('=', '');
  }

  /// 處理 Passkey 註冊的完整流程
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();

    try {
      // 步驟 1: 向後端請求註冊挑戰
      messenger.showSnackBar(const SnackBar(content: Text('步驟 1/3: 正在準備註冊數據...')));
      final registrationChallenge = await ref
          .read(apiServiceProvider)
          .initiateRegistration(username, displayName);

      // 步驟 2: 呼叫 Passkey 服務，觸發原生 UI (指紋/臉部辨識)
      messenger.showSnackBar(const SnackBar(content: Text('步驟 2/3: 請依照系統提示完成驗證...')));
      final credential = await ref
          .read(passkeyServiceProvider)
          .register(registrationChallenge: registrationChallenge);
      
      // 步驟 3: 將註冊結果發送到後端
      messenger.showSnackBar(const SnackBar(content: Text('步驟 3/3: 正在完成註冊...')));
      await ref.read(apiServiceProvider).completeRegistration(credential);
      
      // 註冊成功後，設置當前用戶
      await ref.read(userServiceProvider).setCurrentUser(
        email: username,
        authResponse: credential,
      );

      messenger.showSnackBar(const SnackBar(
        content: Text('🎉 Passkey 註冊成功！'),
        backgroundColor: Colors.green,
      ));
      navigator.pushNamedAndRemoveUntil('/', (route) => false); // 註冊成功後返回首頁
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('❌ 註冊失敗: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('註冊一個新的 Passkey')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.fingerprint, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text('建立您的數位金鑰', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              const Text(
                'Passkey 將安全地儲存在您的裝置上，讓您可以使用指紋或臉部辨識來進行登入，無需記憶密碼。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const Divider(height: 40),
              
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '使用者名稱 (Email)',
                  border: OutlineInputBorder(),
                  hintText: 'user@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? '請輸入有效的 Email' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: '顯示名稱',
                  border: OutlineInputBorder(),
                  hintText: '您的暱稱',
                ),
                validator: (value) => (value == null || value.isEmpty) ? '請輸入顯示名稱' : null,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _handleRegister,
                icon: _isLoading 
                  ? const SizedBox.shrink() 
                  : const Icon(Icons.app_registration),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('開始註冊 Passkey'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
