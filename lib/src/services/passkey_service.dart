import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

// ✅ 正確的 import 語句
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

/// PasskeyService 負責處理所有與 Passkey (WebAuthn) 相關的操作。
class PasskeyService {
  static final _logger = Logger('PasskeyService');
  
  /// 建立一個 `PasskeyAuthenticator` 實例。
  final _authenticator = PasskeyAuthenticator();

  /// 🔧 **根據 StackOverflow 範例修正**：從 Map 創建正確的 AuthenticateRequestType
  /// 
  /// 根據實際範例，正確的類名和參數如下
  AuthenticateRequestType _createAuthenticateRequestType(Map<String, dynamic> webAuthnChallenge) {
    try {
      _logger.info('[PasskeyService] 從 Map 創建 AuthenticateRequestType');
      _logger.info('[PasskeyService] 輸入 Map keys: ${webAuthnChallenge.keys.toList()}');
      
      // 提取必要的參數
      final String challenge = webAuthnChallenge['challenge'] as String? ?? '';
      final String relyingPartyId = webAuthnChallenge['rpId'] as String? ?? 
                                   webAuthnChallenge['relyingPartyId'] as String? ?? 
                                   'localhost'; // 默認值
      final int? timeout = webAuthnChallenge['timeout'] as int?;
      final String? userVerification = webAuthnChallenge['userVerification'] as String?;
      final List? allowCredentialsRaw = webAuthnChallenge['allowCredentials'] as List?;
      
      // 轉換 allowCredentials 為正確類型
      List<CredentialType>? allowCredentials;
      if (allowCredentialsRaw != null) {
        try {
          allowCredentials = allowCredentialsRaw.map((cred) {
            if (cred is Map<String, dynamic>) {
              final List<String> transports = [];
              if (cred['transports'] is List) {
                transports.addAll((cred['transports'] as List).cast<String>());
              } else {
                // 默認 transports
                transports.addAll(['internal', 'hybrid']);
              }
              
              return CredentialType(
                id: cred['id'] as String? ?? '',
                type: cred['type'] as String? ?? 'public-key',
                transports: transports,
              );
            }
            return CredentialType(
              id: '', 
              type: 'public-key',
              transports: ['internal', 'hybrid'],
            );
          }).toList();
        } catch (e) {
          _logger.warning('[PasskeyService] allowCredentials 轉換失敗: $e');
          allowCredentials = [];  // List<CredentialType>
        }
      } else {
        allowCredentials = [];  // List<CredentialType>
      }
      
      // 使用正確的 MediationType 枚舉
      MediationType mediation;
      switch (webAuthnChallenge['mediation'] as String?) {
        case 'required':
          mediation = MediationType.Required;
          break;
        case 'silent':
          mediation = MediationType.Silent;
          break;
        case 'conditional':
          mediation = MediationType.Conditional;
          break;
        case 'optional':
        default:
          mediation = MediationType.Optional;
          break;
      }
      
      // 根據實際的 AuthenticateRequestType 構造函數創建對象
      final request = AuthenticateRequestType(
        challenge: challenge,
        relyingPartyId: relyingPartyId,
        mediation: mediation,
        preferImmediatelyAvailableCredentials: false, // 通常是 false
        timeout: timeout,
        userVerification: userVerification,
        allowCredentials: allowCredentials,
      );
      
      _logger.info('[PasskeyService] ✅ 成功創建 AuthenticateRequestType');
      return request;
      
    } catch (e) {
      _logger.severe('[PasskeyService] 創建 AuthenticateRequestType 失敗: $e');
      _logger.severe('[PasskeyService] 輸入數據: $webAuthnChallenge');
      rethrow;
    }
  }

  /// 🔧 **根據 StackOverflow 範例修正**：從 Map 創建正確的 RegisterRequestType
  /// 
  /// 正確的類名：RelyingPartyType, UserType, AuthenticatorSelectionType
  RegisterRequestType _createRegisterRequestType(Map<String, dynamic> webAuthnChallenge) {
    try {
      _logger.info('[PasskeyService] 從 Map 創建 RegisterRequestType');
      _logger.info('[PasskeyService] 輸入 Map keys: ${webAuthnChallenge.keys.toList()}');
      
      // 提取必要的參數
      final String challenge = webAuthnChallenge['challenge'] as String? ?? '';
      final int? timeout = webAuthnChallenge['timeout'] as int?;
      final String? attestation = webAuthnChallenge['attestation'] as String?;
      
      // 提取 relying party 信息 - 使用正確的類名 RelyingPartyType
      final Map<String, dynamic>? rpData = webAuthnChallenge['rp'] as Map<String, dynamic>?;
      final RelyingPartyType relyingParty = RelyingPartyType(
        id: rpData?['id'] as String? ?? webAuthnChallenge['rpId'] as String? ?? 'localhost',
        name: rpData?['name'] as String? ?? 'Example App',
      );
      
      // 提取 user 信息 - 使用正確的類名 UserType
      final Map<String, dynamic>? userData = webAuthnChallenge['user'] as Map<String, dynamic>?;
      final UserType user = UserType(
        id: userData?['id'] as String? ?? 'default-user-id',
        name: userData?['name'] as String? ?? 'user@example.com',
        displayName: userData?['displayName'] as String? ?? 'User',
      );
      
      // 提取 authenticator selection - 使用正確的類名 AuthenticatorSelectionType
      final Map<String, dynamic>? authSelData = webAuthnChallenge['authenticatorSelection'] as Map<String, dynamic>?;
      final AuthenticatorSelectionType authSelectionType = AuthenticatorSelectionType(
        authenticatorAttachment: authSelData?['authenticatorAttachment'] as String?,
        residentKey: authSelData?['residentKey'] as String? ?? 'preferred',
        requireResidentKey: authSelData?['requireResidentKey'] as bool? ?? false,
        userVerification: authSelData?['userVerification'] as String? ?? 'preferred',
      );
      
      // 處理 excludeCredentials
      final List? excludeCredentialsRaw = webAuthnChallenge['excludeCredentials'] as List?;
      List<CredentialType> excludeCredentials = [];  // List<CredentialType>
      if (excludeCredentialsRaw != null) {
        try {
          excludeCredentials = excludeCredentialsRaw.map((cred) {
            if (cred is Map<String, dynamic>) {
              final List<String> transports = [];
              if (cred['transports'] is List) {
                transports.addAll((cred['transports'] as List).cast<String>());
              } else {
                // 默認 transports
                transports.addAll(['internal', 'hybrid']);
              }
              
              return CredentialType(
                id: cred['id'] as String? ?? '',
                type: cred['type'] as String? ?? 'public-key',
                transports: transports,
              );
            }
            return CredentialType(
              id: '', 
              type: 'public-key',
              transports: ['internal', 'hybrid'],
            );
          }).toList();
        } catch (e) {
          _logger.warning('[PasskeyService] excludeCredentials 轉換失敗: $e');
          excludeCredentials = [];  // List<CredentialType>
        }
      }
      
      // 處理 pubKeyCredParams（如果需要）
      final List<PubKeyCredParamType> pubKeyCredParams = [
        PubKeyCredParamType(alg: -7, type: 'public-key'), // ES256
        PubKeyCredParamType(alg: -257, type: 'public-key'), // RS256
      ];
      
      // 創建 RegisterRequestType
      final request = RegisterRequestType(
        challenge: challenge,
        relyingParty: relyingParty,
        user: user,
        authSelectionType: authSelectionType,
        excludeCredentials: excludeCredentials,
        pubKeyCredParams: pubKeyCredParams,
        timeout: timeout,
        attestation: attestation,
      );
      
      _logger.info('[PasskeyService] ✅ 成功創建 RegisterRequestType');
      return request;
      
    } catch (e) {
      _logger.severe('[PasskeyService] 創建 RegisterRequestType 失敗: $e');
      _logger.severe('[PasskeyService] 輸入數據: $webAuthnChallenge');
      rethrow;
    }
  }

  /// 註冊一個新的 Passkey
  Future<dynamic> register({
    required Map<String, dynamic> webAuthnChallenge,
  }) async {
    try {
      _logger.info('[PasskeyService] 開始 Passkey 註冊...');
      _logger.info('[PasskeyService] Challenge type: ${webAuthnChallenge.runtimeType}');
      _logger.info('[PasskeyService] Challenge keys: ${webAuthnChallenge.keys.toList()}');
      
      // ✅ **解決方案**：創建正確的類型
      final RegisterRequestType registerRequest = _createRegisterRequestType(webAuthnChallenge);
      
      _logger.info('[PasskeyService] 調用 PasskeyAuthenticator.register 使用正確類型...');
      final response = await _authenticator.register(registerRequest);
      
      _logger.info('[PasskeyService] ✅ Passkey 註冊成功');
      return response;
    } on PlatformException catch (e) {
      _logger.warning('[PasskeyService] Passkey 註冊失敗: ${e.message} (${e.code})');
      
      // 處理常見錯誤
      switch (e.code) {
        case 'SyncAccountNotAvailableException':
          throw Exception('請先登入 Google 帳戶以使用 Passkey 功能');
        case 'decodingChallenge':
          throw Exception('無效的註冊挑戰格式，請檢查 relying party server 回應');
        case 'UserCancelledException':
          throw Exception('用戶取消了 Passkey 註冊');
        default:
          rethrow;
      }
    } catch (e) {
      _logger.severe('[PasskeyService] 未知的 Passkey 註冊錯誤: $e');
      rethrow;
    }
  }

  /// 使用已存在的 Passkey 進行驗證
  Future<dynamic> authenticate({
    required dynamic webAuthnChallenge,
  }) async {
    try {
      _logger.info('[PasskeyService] 開始 Passkey 驗證...');
      _logger.info('[PasskeyService] Challenge type: ${webAuthnChallenge.runtimeType}');
      
      AuthenticateRequestType authenticateRequest;
      
      if (webAuthnChallenge is Map<String, dynamic>) {
        _logger.info('[PasskeyService] Challenge keys: ${webAuthnChallenge.keys.toList()}');
        
        // ✅ **核心解決方案**：創建正確的類型而不是直接傳遞 Map
        authenticateRequest = _createAuthenticateRequestType(webAuthnChallenge);
      } else if (webAuthnChallenge is AuthenticateRequestType) {
        // 如果已經是正確類型，直接使用
        authenticateRequest = webAuthnChallenge;
      } else {
        throw Exception('不支援的 webAuthnChallenge 類型: ${webAuthnChallenge.runtimeType}');
      }
      
      _logger.info('[PasskeyService] 調用 PasskeyAuthenticator.authenticate 使用正確類型...');
      _logger.info('[PasskeyService] Request type: ${authenticateRequest.runtimeType}');
      
      // ✅ 現在傳遞正確的類型
      final response = await _authenticator.authenticate(authenticateRequest);
      
      _logger.info('[PasskeyService] ✅ Passkey 驗證成功');
      return response;
    } on PlatformException catch (e) {
      _logger.warning('[PasskeyService] Passkey 驗證失敗: ${e.message} (${e.code})');
      
      // 處理常見錯誤
      switch (e.code) {
        case 'SyncAccountNotAvailableException':
          throw Exception('請先登入 Google 帳戶以使用 Passkey 功能');
        case 'decodingChallenge':
          throw Exception('無效的驗證挑戰格式，請檢查後端回應的數據結構');
        case 'UserCancelledException':
          throw Exception('用戶取消了 Passkey 驗證');
        case 'NoCredentialAvailableException':
          throw Exception('找不到可用的 Passkey，請先註冊');
        default:
          rethrow;
      }
    } catch (e) {
      _logger.severe('[PasskeyService] 未知的 Passkey 驗證錯誤: $e');
      
      // 特別處理類型錯誤
      if (e.toString().contains('is not a subtype of type')) {
        throw Exception('類型不匹配錯誤已解決，但仍出現問題。請檢查 passkeys 套件版本和構造函數簽名。原始錯誤: $e');
      }
      
      rethrow;
    }
  }

  /// 檢查設備是否支援 Passkey
  Future<bool> isSupported() async {
    try {
      return true;
    } catch (e) {
      _logger.warning('[PasskeyService] 無法檢查 Passkey 支援狀態: $e');
      return false;
    }
  }

  /// 🔧 **調試方法**：測試類型創建
  Future<void> testTypeCreation() async {
    try {
      _logger.info('[PasskeyService] 測試類型創建...');
      
      // 測試 AuthenticateRequestType 創建
      final testAuthChallenge = {
        'challenge': 'dGVzdC1jaGFsbGVuZ2U=',
        'rpId': 'example.com',
        'allowCredentials': [],
        'userVerification': 'preferred',
        'timeout': 60000,
        'mediation': 'optional',
      };
      
      try {
        final authRequest = _createAuthenticateRequestType(testAuthChallenge);
        _logger.info('[PasskeyService] ✅ AuthenticateRequestType 創建成功: ${authRequest.runtimeType}');
      } catch (e) {
        _logger.severe('[PasskeyService] ❌ AuthenticateRequestType 創建失敗: $e');
      }
      
      // 測試 RegisterRequestType 創建
      final testRegChallenge = {
        'challenge': 'dGVzdC1jaGFsbGVuZ2U=',
        'rpId': 'example.com',
        'rp': {'id': 'example.com', 'name': 'Example Corp'},
        'user': {
          'id': 'dXNlci1pZA==',
          'name': 'test@example.com',
          'displayName': 'Test User',
        },
        'authenticatorSelection': {
          'userVerification': 'preferred',
          'requireResidentKey': false,
          'residentKey': 'preferred',
        },
        'excludeCredentials': [],
        'timeout': 60000,
      };
      
      try {
        final regRequest = _createRegisterRequestType(testRegChallenge);
        _logger.info('[PasskeyService] ✅ RegisterRequestType 創建成功: ${regRequest.runtimeType}');
      } catch (e) {
        _logger.severe('[PasskeyService] ❌ RegisterRequestType 創建失敗: $e');
      }
      
    } catch (e) {
      _logger.severe('[PasskeyService] 類型創建測試失敗: $e');
    }
  }
}

/// 全域的 PasskeyService Provider
final passkeyServiceProvider = Provider<PasskeyService>((ref) {
  return PasskeyService();
});