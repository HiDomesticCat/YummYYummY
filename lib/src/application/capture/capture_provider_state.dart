import 'package:flutter/foundation.dart';
import '../../data/capture_data.dart';

/// 定義數據捕獲流程的所有可能狀態。
enum CaptureStatus {
  initial,               // 初始狀態
  gatheringData,         // 正在採集本地數據 (pHash, GPS 等)
  requestingNonce,       // 正在向後端請求 Nonce
  awaitingUserSignature, // 等待使用者透過 Passkey 簽署
  uploading,             // 正在上傳所有數據到後端
  success,               // 成功
  error,                 // 失敗
}

/// 用於表示捕獲流程狀態的不可變資料類別。
@immutable
class CaptureProviderState {
  /// 當前的流程狀態。
  final CaptureStatus status;

  /// 如果發生錯誤，存放錯誤訊息。
  final String? errorMessage;

  /// 保存最後一次成功捕獲的數據，用於在 ResultScreen 上顯示。
  final CaptureData? lastSuccessfulData;

  const CaptureProviderState({
    this.status = CaptureStatus.initial,
    this.errorMessage,
    this.lastSuccessfulData,
  });

  /// 產生一個新的狀態副本。
  CaptureProviderState copyWith({
    CaptureStatus? status,
    String? errorMessage,
    CaptureData? lastSuccessfulData,
  }) {
    return CaptureProviderState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSuccessfulData: lastSuccessfulData ?? this.lastSuccessfulData,
    );
  }
}