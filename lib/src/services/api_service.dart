import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sample_capture_app/src/data/capture_data.dart';

class ApiService {
  static final _logger = Logger('ApiService');
  final String _baseUrl = 'https://yummyyummy.hiorangecat12888.workers.dev';

  /// 請求超時時間
  static const Duration _timeout = Duration(seconds: 30);

  // =======================================================================
  // Capture (Authentication/Signing) Flow - For Camera Screen
  // =======================================================================

  /// 向後端請求 WebAuthn 挑戰數據 (用於拍照簽章)
  Future<Map<String, dynamic>> initiateCapture() async {
    _logger.info('[ApiService] Calling initiateCapture...');
    final uri = Uri.parse('$_baseUrl/api/v1/capture/initiate');
    final response = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(_timeout);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      _logger.severe('[ApiService] Failed to initiate capture: ${response.body}');
      throw Exception('無法從伺服器獲取簽章挑戰');
    }
  }

  /// 從 WebAuthn 挑戰中提取 nonce 用於 AttestationService
  String extractNonce(dynamic webAuthnChallenge) {
    if (webAuthnChallenge is Map<String, dynamic>) {
      final String? challenge = webAuthnChallenge['challenge'] as String?;
      if (challenge != null) return challenge;
    }
    throw const FormatException('從後端收到的挑戰物件格式不正確');
  }

  /// 提交捕獲數據到後端
  Future<bool> submitCapture(CaptureData data) async {
    _logger.info('[ApiService] Calling submitCapture...');
    final uri = Uri.parse('$_baseUrl/api/v1/capture/submit');
    final request = http.MultipartRequest('POST', uri)
      ..fields.addAll(data.toJson().map((key, value) => MapEntry(key, value.toString())))
      ..files.add(http.MultipartFile.fromBytes(
        'photo',
        data.imageBytes,
        filename: 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

    final streamedResponse = await request.send().timeout(_timeout);
    return streamedResponse.statusCode == 200;
  }

  // =======================================================================
  // Passkey Registration Flow - For Auth Screen
  // =======================================================================

  /// 【新增】向後端發起 Passkey 註冊請求，以獲取註冊挑戰
  ///
  /// @param username 使用者提供的唯一識別碼 (通常是 email)
  /// @param displayName 使用者顯示的名稱
  /// @return 從後端收到的 WebAuthn 註冊挑戰 (JSON 物件)
  Future<Map<String, dynamic>> initiateRegistration(String username, String displayName) async {
    _logger.info('[ApiService] Initiating registration for $username...');
    final uri = Uri.parse('$_baseUrl/register/initiate');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'displayName': displayName,
      }),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      _logger.info('[ApiService] Registration challenge received.');
      return json.decode(response.body);
    } else {
      _logger.severe('[ApiService] Failed to initiate registration: ${response.body}');
      throw Exception('無法從伺服器獲取註冊挑戰: ${response.body}');
    }
  }

  /// 【新增】將使用者完成 Passkey 註冊後生成的憑證傳送回後端儲存
  ///
  /// @param credential 由 `passkeys` 套件返回的註冊結果
  /// @return 一個 Future<bool>，表示後端是否成功儲存憑證
  Future<bool> completeRegistration(Map<String, dynamic> credential) async {
    _logger.info('[ApiService] Completing registration...');
    final uri = Uri.parse('$_baseUrl/register/complete');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(credential),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      _logger.info('[ApiService] Registration completed successfully on backend.');
      return true;
    } else {
      _logger.severe('[ApiService] Failed to complete registration: ${response.body}');
      throw Exception('無法完成註冊: ${response.body}');
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
