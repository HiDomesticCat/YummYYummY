import 'package:flutter/foundation.dart';

/// 一個不可變的資料模型，用於封裝一次安全數據捕獲的所有相關資訊。
///
/// 這個類別的實例將在數據採集完成後被建立，並用於提交給後端進行驗證。
@immutable
class CaptureData {
  /// 業務數據：圖片的感知雜湊值 (pHash)。
  final String pHash;

  /// 業務數據：GPS 緯度。
  final double latitude;

  /// 業務數據：GPS 經度。
  final double longitude;

  /// 驗證數據：GPS 模擬狀態。
  final bool isMocked;

  /// 驗證數據：包含對 Nonce 簽名的 Passkey 回應。
  final String passkeyResponse;

  /// 驗證數據：包含 Nonce 的裝置與應用程式證明令牌。
  final String integrityToken;
  
  /// 原始數據：照片檔案本身的位元組數據。
  /// 注意：這個欄位通常只用於傳遞給 ApiService，
  /// 在序列化為 JSON 時可能會被省略，因為它是透過 multipart/form-data 上傳的。
  final Uint8List imageBytes;

  /// 用於日誌記錄或偵錯的客戶端時間戳。
  final DateTime clientTimestamp;

  const CaptureData({
    required this.pHash,
    required this.latitude,
    required this.longitude,
    required this.isMocked,
    required this.passkeyResponse,
    required this.integrityToken,
    required this.imageBytes,
    required this.clientTimestamp,
  });

  /// 將此物件轉換為用於 API 請求的 JSON 格式 (Map)。
  /// 
  /// 注意我們在這裡排除了 `imageBytes`，因為圖片檔案通常
  /// 是透過 `multipart/form-data` 的方式作為獨立部分上傳，
  /// 而不是作為 JSON 的一個欄位。
  Map<String, dynamic> toJson() {
    return {
      'pHash': pHash,
      'latitude': latitude,
      'longitude': longitude,
      'isMocked': isMocked,
      'passkeyResponse': passkeyResponse,
      'integrityToken': integrityToken,
      'clientTimestamp': clientTimestamp.toIso8601String(),
    };
  }

  /// 覆寫 toString 方法，方便偵錯 (debug) 時印出可讀的資訊。
  @override
  String toString() {
    return 'CaptureData(\n'
        '  pHash: $pHash,\n'
        '  latitude: $latitude,\n'
        '  longitude: $longitude,\n'
        '  isMocked: $isMocked,\n'
        '  passkeyResponse: ${passkeyResponse.substring(0, 10)}...,\n'
        '  integrityToken: ${integrityToken.substring(0, 10)}...,\n'
        '  imageBytes length: ${imageBytes.length},\n'
        '  clientTimestamp: $clientTimestamp\n'
        ')';
  }
}