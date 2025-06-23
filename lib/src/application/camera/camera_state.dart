// 匯入 Flutter 的 foundation 函式庫，它包含了 @immutable 註解
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

/// 一個不可變的資料類別，用於表示相機的當前狀態。
///
/// 使用不可變物件和 `copyWith` 方法是 Riverpod 狀態管理的最佳實踐，
/// 它可以防止意外的狀態修改，並讓狀態變更可追蹤。
/// 這個狀態類別是實現 PoC 目標中「功能完整的應用內相機介面」的基礎。 
@immutable
class CameraState {
  /// 相機控制器，用於與裝置相機硬體互動。
  final CameraController? controller;

  /// 一個旗標，表示相機是否已成功初始化並準備就緒。
  final bool isInitialized;

  /// 當前的閃光燈模式 (例如：關閉、自動、強制開啟)。
  final FlashMode currentFlashMode;

  /// 一個旗標，表示在初始化過程中是否發生錯誤。
  final bool hasError;

  /// 如果發生錯誤，存放錯誤訊息的字串。
  final String? errorMessage;

  /// 提供一個初始狀態的 const 建構子。
  const CameraState({
    this.controller,
    this.isInitialized = false,
    this.currentFlashMode = FlashMode.off, // 預設關閉閃光燈
    this.hasError = false,
    this.errorMessage,
  });

  /// 產生一個新的狀態副本，但可以覆寫指定的屬性。
  ///
  /// 這是實現狀態不可變性的關鍵方法。
  CameraState copyWith({
    CameraController? controller,
    bool? isInitialized,
    FlashMode? currentFlashMode,
    bool? hasError,
    String? errorMessage,
  }) {
    return CameraState(
      // 如果傳入的新值為 null，則使用舊的狀態值
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      currentFlashMode: currentFlashMode ?? this.currentFlashMode,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}