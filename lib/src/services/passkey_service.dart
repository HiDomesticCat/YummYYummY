import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

// 正確的導入語句
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

/// PasskeyService 負責處理所有與 Passkey (WebAuthn) 相關的操作。
class PasskeyService {
  static final _logger = Logger('PasskeyService');
  
  /// 建立 PasskeyAuthenticator 實例
  final PasskeyAuthenticator _authenticator;
  final String _baseUrl = 'https://yummyyummy.hiorangecat12888.workers.dev';
  final http.Client _client = http.Client();

  PasskeyService() : _authenticator = PasskeyAuthenticator(debugMode: true) {
    _logger.info('[PasskeyService] PasskeyAuthenticator 初始化成功');
  }

  /// 註冊一個新的 Passkey
  /// 
  /// @param registrationChallenge 從後端獲取的註冊挑戰數據
  /// @param webAuthnChallenge 可選的 WebAuthn 挑戰數據
  Future<dynamic> register({
    required Map<String, dynamic> registrationChallenge,
    Map<String, dynamic>? webAuthnChallenge,
  }) async {
    try {
      _logger.info('[PasskeyService] 開始 Passkey 註冊...');
      _logger.info('[PasskeyService] 註冊挑戰: $registrationChallenge');
      
      // 從挑戰中提取用戶信息
      final String username = registrationChallenge['username'] ?? '';
      final String displayName = registrationChallenge['displayName'] ?? username;
      
      if (username.isEmpty) {
        throw Exception('註冊挑戰中缺少 username 字段');
      }
      
      _logger.info('[PasskeyService] 使用用戶名: $username');
      
      // 檢查是否已經是 WebAuthn 格式的挑戰
      if (registrationChallenge.containsKey('rp') && 
          registrationChallenge.containsKey('user') && 
          registrationChallenge.containsKey('challenge')) {
        
        _logger.info('[PasskeyService] 使用完整的 WebAuthn 挑戰...');
        
        // 手動創建 RegisterRequestType 實例
        final rp = RelyingPartyType(
          name: registrationChallenge['rp']['name'],
          id: registrationChallenge['rp']['id'],
        );
        
        final user = UserType(
          displayName: registrationChallenge['user']['displayName'],
          name: registrationChallenge['user']['name'],
          id: registrationChallenge['user']['id'],
        );
        
        final authSelectionType = AuthenticatorSelectionType(
          requireResidentKey: registrationChallenge['authenticatorSelection']['requireResidentKey'] ?? false,
          residentKey: registrationChallenge['authenticatorSelection']['residentKey'] ?? 'required',
          userVerification: registrationChallenge['authenticatorSelection']['userVerification'] ?? 'preferred',
        );
        
        final pubKeyCredParams = (registrationChallenge['pubKeyCredParams'] as List)
            .map((param) => PubKeyCredParamType(
                  type: param['type'],
                  alg: param['alg'],
                ))
            .toList();
        
        final request = RegisterRequestType(
          challenge: registrationChallenge['challenge'],
          relyingParty: rp,
          user: user,
          authSelectionType: authSelectionType,
          pubKeyCredParams: pubKeyCredParams,
          excludeCredentials: [],
          timeout: registrationChallenge['timeout'] ?? 60000,
        );
        
        // 使用 PasskeyAuthenticator API 註冊
        final registerResponse = await _authenticator.register(request);
        
        // 將 RegisterResponseType 轉換為 Map
        final responseMap = <String, dynamic>{
          'id': registerResponse.id,
          'rawId': registerResponse.rawId,
          'clientDataJSON': registerResponse.clientDataJSON,
          'attestationObject': registerResponse.attestationObject,
          'transports': registerResponse.transports,
          // 添加 username 到響應中，以便後端可以識別用戶
          'username': username,
        };
        
        _logger.info('[PasskeyService] ✅ Passkey 註冊成功');
        return responseMap;
      } else {
        // 創建註冊請求
        final request = _createRegisterRequest(
          username: username,
          displayName: displayName,
          challenge: registrationChallenge['challenge'] ?? _generateChallenge(),
        );
      
        // 使用 PasskeyAuthenticator API 註冊
        final registerResponse = await _authenticator.register(request);
        
        // 將 RegisterResponseType 轉換為 Map
        final responseMap = <String, dynamic>{
          'id': registerResponse.id,
          'rawId': registerResponse.rawId,
          'clientDataJSON': registerResponse.clientDataJSON,
          'attestationObject': registerResponse.attestationObject,
          'transports': registerResponse.transports,
          // 添加 username 到響應中，以便後端可以識別用戶
          'username': username,
        };
        
        _logger.info('[PasskeyService] ✅ Passkey 註冊成功');
        return responseMap;
      }
      
    } on PlatformException catch (e) {
      _logger.warning('[PasskeyService] Passkey 註冊失敗: ${e.message} (${e.code})');
      
      // 處理常見錯誤
      switch (e.code) {
        case 'android-sync-account-not-available':
          throw Exception('請先登入 Google 帳戶以使用 Passkey 功能');
        case 'cancelled':
          throw Exception('用戶取消了 Passkey 註冊');
        default:
          throw Exception('Passkey 註冊失敗: ${e.message}');
      }
    } catch (e) {
      _logger.severe('[PasskeyService] 未知的 Passkey 註冊錯誤: $e');
      rethrow;
    }
  }

  /// 使用已存在的 Passkey 進行驗證
  Future<dynamic> authenticate({
    required String email,
    Map<String, dynamic>? loginChallenge,
  }) async {
    try {
      _logger.info('[PasskeyService] 開始 Passkey 驗證...');
      _logger.info('[PasskeyService] Email: $email');
      
      AuthenticateRequestType request;
      
      // 檢查是否提供了登入挑戰
      if (loginChallenge != null && loginChallenge.containsKey('challenge')) {
        _logger.info('[PasskeyService] 使用提供的登入挑戰...');
        
        // 使用提供的登入挑戰創建請求
        request = AuthenticateRequestType(
          relyingPartyId: loginChallenge['rpId'] ?? 'yummyyummy.hiorangecat12888.workers.dev',
          challenge: loginChallenge['challenge'],
          allowCredentials: [],
          userVerification: loginChallenge['userVerification'] ?? 'preferred',
          timeout: loginChallenge['timeout'] ?? 60000,
          mediation: MediationType.Optional,
          preferImmediatelyAvailableCredentials: false,
        );
      } else {
        // 創建默認的驗證請求
        _logger.info('[PasskeyService] 使用默認的登入挑戰...');
        request = _createAuthenticateRequest(
          relyingPartyId: 'yummyyummy.hiorangecat12888.workers.dev',
          challenge: _generateChallenge(),
        );
      }
      
      // 使用 PasskeyAuthenticator API 驗證
      final signInResponse = await _authenticator.authenticate(request);
      
      // 將 AuthenticateResponseType 轉換為 Map，並添加 email
      final responseMap = <String, dynamic>{
        'id': signInResponse.id,
        'rawId': signInResponse.rawId,
        'clientDataJSON': signInResponse.clientDataJSON,
        'authenticatorData': signInResponse.authenticatorData,
        'signature': signInResponse.signature,
        'userHandle': signInResponse.userHandle,
        // 添加 email 到響應中，以便後端可以識別用戶
        'username': email,
      };
      
      _logger.info('[PasskeyService] ✅ Passkey 驗證成功');
      return responseMap;
      
    } on PlatformException catch (e) {
      _logger.warning('[PasskeyService] Passkey 驗證失敗: ${e.message} (${e.code})');
      
      // 處理常見錯誤
      switch (e.code) {
        case 'android-sync-account-not-available':
          throw Exception('請先登入 Google 帳戶以使用 Passkey 功能');
        case 'no-credentials-available':
          throw Exception('找不到可用的 Passkey，請先註冊');
        case 'cancelled':
          throw Exception('用戶取消了 Passkey 驗證');
        default:
          throw Exception('Passkey 驗證失敗: ${e.message}');
      }
    } catch (e) {
      _logger.severe('[PasskeyService] 未知的 Passkey 驗證錯誤: $e');
      rethrow;
    }
  }

  /// 檢查設備是否支援 Passkey
  Future<bool> isSupported() async {
    try {
      // 使用 PasskeyAuthenticator 的 getAvailability 方法檢查支援狀態
      final availability = _authenticator.getAvailability();
      
      // 根據平台檢查支援狀態
      try {
        // 嘗試獲取 Android 平台的支援狀態
        final androidAvailability = await availability.android();
        return androidAvailability.hasPasskeySupport;
      } catch (_) {
        try {
          // 嘗試獲取 iOS 平台的支援狀態
          final iosAvailability = await availability.iOS();
          return iosAvailability.hasPasskeySupport && iosAvailability.hasBiometrics;
        } catch (_) {
          // 如果以上都失敗，嘗試獲取 Web 平台的支援狀態
          try {
            final webAvailability = await availability.web();
            return webAvailability.hasPasskeySupport;
          } catch (_) {
            return false;
          }
        }
      }
    } catch (e) {
      _logger.warning('[PasskeyService] 無法檢查 Passkey 支援狀態: $e');
      return false;
    }
  }

  /// 🔧 簡化的測試方法
  Future<void> testTypeCreation() async {
    try {
      _logger.info('[PasskeyService] 測試 Passkey 功能...');
      
      // 測試 PasskeyAuthenticator 創建
      _logger.info('[PasskeyService] ✅ PasskeyAuthenticator 創建成功: ${_authenticator.runtimeType}');
      
      // 測試設備支援狀態
      final isSupported = await this.isSupported();
      _logger.info('[PasskeyService] ✅ 設備支援狀態: $isSupported');
      
      _logger.info('[PasskeyService] ✅ 所有基礎測試通過！');
      
    } catch (e) {
      _logger.severe('[PasskeyService] 測試失敗: $e');
      rethrow;
    }
  }
  
  /// 創建註冊請求
  RegisterRequestType _createRegisterRequest({
    required String username,
    required String displayName,
    required String challenge,
  }) {
    // 創建 RelyingParty 信息
    final rp = RelyingPartyType(
      name: 'Sample Capture App',
      id: 'yummyyummy.hiorangecat12888.workers.dev',
    );
    
    // 創建用戶信息
    final user = UserType(
      displayName: displayName,
      name: username,
      id: base64Url.encode(utf8.encode(username)),
    );
    
    // 創建驗證器選擇信息
    final authenticatorSelection = AuthenticatorSelectionType(
      requireResidentKey: false,
      residentKey: 'required',
      userVerification: 'preferred',
    );
    
    // 創建註冊請求
    return RegisterRequestType(
      challenge: challenge,
      relyingParty: rp,
      user: user,
      authSelectionType: authenticatorSelection,
      pubKeyCredParams: [
        PubKeyCredParamType(type: 'public-key', alg: -7),
        PubKeyCredParamType(type: 'public-key', alg: -257),
      ],
      excludeCredentials: [],
      timeout: 60000,
    );
  }
  
  /// 創建驗證請求
  AuthenticateRequestType _createAuthenticateRequest({
    required String relyingPartyId,
    required String challenge,
  }) {
    return AuthenticateRequestType(
      relyingPartyId: relyingPartyId,
      challenge: challenge,
      mediation: MediationType.Optional,
      userVerification: 'preferred',
      timeout: 60000,
      preferImmediatelyAvailableCredentials: false,
    );
  }
  
  /// 生成隨機挑戰
  String _generateChallenge() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    // 移除 Base64URL 編碼中的填充字符 ('=')
    return base64Url.encode(values).replaceAll('=', '');
  }
}


/// 全域的 PasskeyService Provider
final passkeyServiceProvider = Provider<PasskeyService>((ref) {
  return PasskeyService();
});
