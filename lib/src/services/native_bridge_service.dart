import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// NativeBridgeService 負責處理所有與原生平台 (Android/iOS) 的通訊。
///
/// 它使用 Flutter 的平台通道 (Platform Channels) 來呼叫原生程式碼，
/// 以獲取 Dart 層無法直接取得的敏感或底層資訊，例如 GPS 模擬狀態。
class NativeBridgeService {
  /// 建立一個平台通道。
  ///
  /// 這個名稱是一個唯一的識別符，Dart 端和原生端必須使用完全相同的名稱
  /// 才能建立通訊。推薦使用反向域名風格來確保唯一性。
  static const _platform = MethodChannel('com.spectralens.poc/gps_mock');

  /// 呼叫原生方法來檢查裝置是否正在使用模擬位置 (Mock Location)。
  ///
  /// @return 一個 Future<bool>，如果正在使用模擬位置則為 true，否則為 false。
  ///         如果呼叫失敗或原生端未實現此方法，則會回傳 false 作為安全的預設值。
  Future<bool> isGpsMocked() async {
    try {
      // 透過通道呼叫名為 'isGpsMocked' 的原生方法。
      // 'await' 會等待原生端處理完畢並回傳結果。
      final bool isMocked = await _platform.invokeMethod('isGpsMocked');
      return isMocked;
    } on PlatformException catch (e) {
      // 如果原生端沒有實現這個方法，或者在執行時發生錯誤，
      // Flutter 會拋出一個 PlatformException。
      print("呼叫原生 isGpsMocked 失敗: ${e.message}");
      // 在發生錯誤時，回傳 false 作為一個安全的預設值，避免誤判正常使用者。
      return false;
    } catch (e) {
      print("呼叫 isGpsMocked 時發生未知錯誤: $e");
      return false;
    }
  }
}

/// 全域的 NativeBridgeService Provider。
///
/// 讓應用程式的其他部分（主要是 CaptureNotifier）可以存取 NativeBridgeService 的實例。
final nativeBridgeServiceProvider = Provider<NativeBridgeService>((ref) {
  return NativeBridgeService();
});