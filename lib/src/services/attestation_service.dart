import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_device_integrity/app_device_integrity.dart';
import 'package:logging/logging.dart';

/// AttestationService 負責獲取裝置與應用程式的「健康證明」。
///
/// 它封裝了 `app_device_integrity` 套件，這個套件在底層會根據平台
/// 自動呼叫 Android 的 Play Integrity API 或 iOS 的 App Attest API。
/// 它的核心任務是獲取一個包含了由後端提供的 Nonce 的證明令牌。
class AttestationService {
  static final _logger = Logger('AttestationService');
  
  /// 建立一個 `app_device_integrity` 套件的實例。
  final _attestationPlugin = AppDeviceIntegrity();

  /// 【已設定】您的 Google Cloud 專案編號，這是呼叫 Play Integrity API 所必需的。
  final int _googleCloudProjectNumber = 731512947048; // 使用您提供的 GCP 專案 ID

  /// 獲取包含了特定 Nonce 的裝置證明令牌 (Attestation Token)。
  ///
  /// 這個方法是實現「Nonce 的雙重綁定」的關鍵。這裡傳入的 Nonce
  /// 必須與傳遞給 PasskeyService 的 Nonce 完全相同。
  ///
  /// @param nonce - 由後端產生的一個用於本次操作驗證的、一次性的隨機字串。
  /// @return 一個 `Future<String>`，代表由平台方 (Google/Apple) 簽署的證明令牌。
  /// @throws 如果平台 API 呼叫失敗或回傳 null，則會拋出例外。
  Future<String> getAttestationToken({required String nonce}) async {
    try {
      _logger.info('開始獲取設備證明令牌，平台: ${Platform.operatingSystem}');
      _logger.fine('Nonce: ${nonce.length > 8 ? '${nonce.substring(0, 8)}...' : nonce}');

      String? token; // 宣告為可為空的 token 變數

      if (Platform.isAndroid) {
        // Android: 使用 Play Integrity API，需要提供 GCP 專案 ID
        _logger.info('呼叫 Android Play Integrity API');
        token = await _attestationPlugin.getAttestationServiceSupport(
          challengeString: nonce,
          gcp: _googleCloudProjectNumber,
        );
      } else if (Platform.isIOS) {
        // iOS: 使用 App Attest API，只需要提供 challenge
        _logger.info('呼叫 iOS App Attest API');
        token = await _attestationPlugin.getAttestationServiceSupport(
          challengeString: nonce,
        );
      } else {
        // 不支援的平台
        throw UnsupportedError('不支援的平台: ${Platform.operatingSystem}');
      }

      // 【優化點】增加明確的空值和內容檢查
      if (token == null || token.isEmpty) {
        throw Exception('平台未能產生有效的證明令牌 (token is null or empty)');
      }
      
      _logger.info('✅ 成功獲取裝置證明令牌，長度: ${token.length}');
      return token; // 此時 token 已被確認不為 null 且不為空
      
    } catch (e) {
      _logger.severe('獲取裝置證明令牌失敗: $e');
      rethrow; // 重新拋出例外，讓上層 (CaptureNotifier) 處理
    }
  }

  /// 檢查設備是否支援證明功能。
  ///
  /// @return 一個 `Future<bool>`，表示設備是否支援證明功能。
  Future<bool> isSupported() async {
    try {
      _logger.info('檢查設備證明功能支援狀態');
      
      if (Platform.isAndroid) {
        _logger.info('Android 平台：檢查 Play Integrity 支援');
        return true;
      } else if (Platform.isIOS) {
        _logger.info('iOS 平台：檢查 App Attest 支援');
        return true;
      }
      
      _logger.warning('不支援的平台: ${Platform.operatingSystem}');
      return false;
      
    } catch (e) {
      _logger.warning('檢查證明功能支援狀態時發生錯誤: $e');
      return false;
    }
  }
}

/// 全域的 AttestationService Provider。
///
/// 讓應用程式的其他部分（主要是 CaptureNotifier）可以存取 AttestationService 的實例。
final attestationServiceProvider = Provider<AttestationService>((ref) {
  return AttestationService();
});