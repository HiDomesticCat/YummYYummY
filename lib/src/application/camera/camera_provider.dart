import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 匯入我們剛剛定義的狀態檔案
import 'camera_state.dart';

/// CameraNotifier 負責管理 CameraState。
///
/// 它的職責是封裝所有與 `camera` 套件直接互動的邏輯，
/// 例如初始化控制器、設定閃光燈模式等。
class CameraNotifier extends StateNotifier<CameraState> {
  // 初始化時，傳入一個初始的、空的 CameraState
  CameraNotifier() : super(const CameraState());

  /// 初始化相機。
  /// 這是一個非同步操作，UI 層需要根據狀態顯示載入指示器。
  Future<void> initializeCamera() async {
    try {
      // 獲取裝置上所有可用的相機
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('找不到可用的相機');
      }

      // 建立一個新的 CameraController
      final controller = CameraController(
        cameras[0], // 使用第一個找到的相機（通常是後置鏡頭）
        ResolutionPreset.high, // 設定高解析度
        enableAudio: false, // PoC 不需要音訊
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // 初始化控制器，這會與硬體進行通訊
      await controller.initialize();

      // 初始化成功後，更新狀態
      state = state.copyWith(
        controller: controller,
        isInitialized: true,
        hasError: false,
      );
    } catch (e) {
      // 如果過程中發生任何錯誤，更新狀態以反映錯誤
      state = state.copyWith(
        isInitialized: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  /// 循環切換閃光燈模式。
  Future<void> cycleFlashMode() async {
    // 防呆：如果相機未初始化或控制器不存在，則不執行任何操作
    if (!state.isInitialized || state.controller == null) return;

    final currentMode = state.currentFlashMode;
    FlashMode nextMode;

    // 定義切換順序： 關閉 -> 自動 -> 強制開啟 -> 手電筒 -> 關閉
    switch (currentMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.off;
        break;
    }

    try {
      // 設定新的閃光燈模式
      await state.controller!.setFlashMode(nextMode);
      // 更新狀態以讓 UI 反映變化
      state = state.copyWith(currentFlashMode: nextMode);
    } catch (e) {
      // 處理設定閃光燈時可能發生的錯誤
      print('設定閃光燈失敗: $e');
    }
  }

  /// 覆寫 StateNotifier 的 dispose 方法以釋放資源。
  @override
  void dispose() {
    // 非常重要：當 Notifier 不再被使用時，必須釋放 CameraController，
    // 否則會導致記憶體洩漏和 App 崩潰。
    state.controller?.dispose();
    super.dispose();
  }
}

/// 全域的 Camera Provider。
///
/// 我們使用 `StateNotifierProvider.autoDispose`，這意味著當沒有任何 Widget
/// 正在監聽這個 Provider 時（例如，當使用者離開 CameraScreen 時），
/// 它會被自動銷毀，其 `dispose` 方法也會被自動呼叫，從而安全地釋放相機資源。
final cameraProvider = StateNotifierProvider.autoDispose<CameraNotifier, CameraState>((ref) {
  return CameraNotifier();
});