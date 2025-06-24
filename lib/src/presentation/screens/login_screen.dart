import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/passkey_service.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';

/// Passkey 登入畫面
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'user@example.com');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// 處理 Passkey 登入的完整流程
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final email = _emailController.text.trim();

    try {
      // 步驟 1: 向後端請求登入挑戰
      messenger.showSnackBar(const SnackBar(content: Text('正在準備登入...')));
      final loginChallenge = await ref.read(apiServiceProvider).initiateLogin(email);
      
      // 步驟 2: 使用 Passkey 進行身份驗證
      messenger.showSnackBar(const SnackBar(content: Text('請依照系統提示完成驗證...')));
      final authResponse = await ref
          .read(passkeyServiceProvider)
          .authenticate(email: email, loginChallenge: loginChallenge);
      
      // 步驟 3: 將身份驗證結果發送到後端驗證
      final loginResult = await ref.read(apiServiceProvider).completeLogin(authResponse);
      
      // 步驟 4: 將身份驗證結果保存到用戶服務
      await ref.read(userServiceProvider).setCurrentUser(
        email: email,
        authResponse: authResponse,
      );

      messenger.showSnackBar(const SnackBar(
        content: Text('🎉 Passkey 登入成功！'),
        backgroundColor: Colors.green,
      ));
      
      // 登入成功後返回首頁
      navigator.pushNamedAndRemoveUntil('/', (route) => false);
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使用 Passkey 登入')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.fingerprint, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              Text('使用您的 Passkey 登入', 
                textAlign: TextAlign.center, 
                style: Theme.of(context).textTheme.headlineSmall
              ),
              const SizedBox(height: 16),
              const Text(
                '請輸入您的電子郵件地址，然後使用指紋或臉部辨識來登入。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const Divider(height: 40),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '電子郵件',
                  border: OutlineInputBorder(),
                  hintText: 'user@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) 
                  ? '請輸入有效的電子郵件地址' 
                  : null,
              ),
              const SizedBox(height: 24),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                onPressed: _isLoading ? null : _handleLogin,
                icon: _isLoading 
                  ? const SizedBox.shrink() 
                  : const Icon(Icons.login),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('使用 Passkey 登入'),
              ),
              
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/auth'),
                child: const Text('沒有 Passkey？註冊一個新的'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
