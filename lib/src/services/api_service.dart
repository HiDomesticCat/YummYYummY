import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../data/capture_data.dart';

class ApiService {
  static final _logger = Logger('ApiService');
  final String _baseUrl = 'https://yummyyummy.hiorangecat12888.workers.dev'; 

  /// 請求超時時間
  static const Duration _timeout = Duration(seconds: 30);

  /// 向後端請求 WebAuthn 挑戰數據
  /// 
  /// 返回的數據將直接傳遞給 PasskeyAuthenticator
  Future<dynamic> initiateCapture() async {
    _logger.info('[ApiService] Calling initiateCapture...');
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/capture/initiate');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'SpectraLens-Mobile/1.0',
        },
      ).timeout(_timeout);

      _logger.info('[ApiService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final dynamic data = json.decode(response.body);
          
          // 驗證回應格式
          if (data is Map<String, dynamic>) {
            if (!data.containsKey('challenge')) {
              _logger.warning('[ApiService] Response missing challenge field');
              throw FormatException('後端回應缺少 challenge 欄位');
            }
            _logger.info('[ApiService] Got valid WebAuthn challenge');
            _logger.fine('[ApiService] Challenge keys: ${data.keys.toList()}');
          } else {
            _logger.warning('[ApiService] Unexpected response format: ${data.runtimeType}');
          }
          
          return data; // 返回原始數據供 PasskeyAuthenticator 使用
        } catch (e) {
          _logger.severe('[ApiService] Failed to parse response body: $e');
          throw FormatException('無法解析後端回應: $e');
        }
      } else {
        final errorMsg = 'HTTP ${response.statusCode}: ${response.body}';
        _logger.severe('[ApiService] Server error: $errorMsg');
        
        // 根據狀態碼提供更具體的錯誤信息
        switch (response.statusCode) {
          case 400:
            throw Exception('請求格式錯誤');
          case 401:
            throw Exception('未授權訪問');
          case 403:
            throw Exception('禁止訪問');
          case 404:
            throw Exception('API 端點不存在');
          case 500:
            throw Exception('伺服器內部錯誤');
          case 503:
            throw Exception('伺服器暫時不可用');
          default:
            throw Exception('網絡請求失敗: $errorMsg');
        }
      }
    } on FormatException {
      rethrow;
    } catch (e) {
      _logger.severe('[ApiService] Error during initiateCapture: $e');
      
      if (e.toString().contains('timeout')) {
        throw Exception('請求超時，請檢查網絡連接');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('網絡連接失敗，請檢查網絡設定');
      }
      
      rethrow;
    }
  }

  /// 從 WebAuthn 挑戰中提取 nonce 用於 AttestationService
  String extractNonce(dynamic webAuthnChallenge) {
    try {
      if (webAuthnChallenge is Map<String, dynamic>) {
        final String? challenge = webAuthnChallenge['challenge'] as String?;
        if (challenge == null || challenge.isEmpty) {
          throw FormatException('WebAuthn 挑戰中的 challenge 欄位為空');
        }
        return challenge;
      } else {
        throw FormatException('WebAuthn 挑戰格式不正確: ${webAuthnChallenge.runtimeType}');
      }
    } catch (e) {
      _logger.severe('[ApiService] Error extracting nonce: $e');
      rethrow;
    }
  }

  /// 提交捕獲數據到後端
  Future<bool> submitCapture(CaptureData data) async {
    _logger.info('[ApiService] Calling submitCapture...');
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/capture/submit');
      final request = http.MultipartRequest('POST', uri);

      // 添加 headers
      request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'SpectraLens-Mobile/1.0',
      });

      // 添加表單字段（排除 imageBytes）
      final jsonData = data.toJson();
      jsonData.forEach((key, value) {
        if (key != 'imageBytes') {
          request.fields[key] = value.toString();
        }
      });

      // 添加額外的元數據
      request.fields['clientTimestamp'] = data.clientTimestamp.toIso8601String();
      request.fields['uploadVersion'] = '1.0';

      // 添加圖片文件
      request.files.add(http.MultipartFile.fromBytes(
        'photo', // 確保與後端 API 期望的字段名一致
        data.imageBytes,
        filename: 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      _logger.info('[ApiService] Uploading ${data.imageBytes.length} bytes');

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      _logger.info('[ApiService] Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          _logger.info('[ApiService] Submission successful');
          _logger.fine('[ApiService] Response: $responseData');
          
          // 檢查後端的成功標記
          if (responseData is Map<String, dynamic>) {
            final bool? success = responseData['success'] as bool?;
            final bool? verified = responseData['verified'] as bool?;
            
            if (success == true || verified == true) {
              return true;
            } else {
              _logger.warning('[ApiService] Backend verification failed: ${responseData['message'] ?? 'Unknown reason'}');
              return false;
            }
          }
          
          return true; // 默認成功
        } catch (e) {
          _logger.warning('[ApiService] Failed to parse success response: $e');
          return true; // 如果無法解析但狀態碼是 200，假設成功
        }
      } else {
        final errorMsg = 'HTTP ${response.statusCode}: ${response.body}';
        _logger.warning('[ApiService] Submission failed: $errorMsg');
        return false;
      }
    } catch (e) {
      _logger.severe('[ApiService] Error during submitCapture: $e');
      
      if (e.toString().contains('timeout')) {
        throw Exception('上傳超時，請檢查網絡連接');
      }
      
      rethrow;
    }
  }

  /// 檢查 API 服務健康狀態
  Future<bool> checkHealth() async {
    try {
      _logger.info('[ApiService] Checking service health...');
      
      final uri = Uri.parse('$_baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bool isHealthy = data['status'] == 'healthy' || data['status'] == 'ok';
        _logger.info('[ApiService] Service health: ${isHealthy ? 'healthy' : 'unhealthy'}');
        return isHealthy;
      }
      
      return false;
    } catch (e) {
      _logger.warning('[ApiService] Health check failed: $e');
      return false;
    }
  }

  /// 獲取服務配置信息
  Map<String, dynamic> getServiceInfo() {
    return {
      'baseUrl': _baseUrl,
      'timeout': _timeout.inSeconds,
      'version': '1.0',
      'endpoints': {
        'initiate': '$_baseUrl/api/v1/capture/initiate',
        'submit': '$_baseUrl/api/v1/capture/submit',
        'health': '$_baseUrl/health',
      },
    };
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});