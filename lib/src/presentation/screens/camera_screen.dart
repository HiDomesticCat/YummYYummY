import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

// 匯入我們建立的兩個核心 Provider
import '../../application/camera/camera_provider.dart';
// 修正：匯入新的 provider 狀態檔案
import '../../application/capture/capture_provider.dart';
import '../../application/capture/capture_provider_state.dart';


class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cameraProvider.notifier).initializeCamera());
  }

  IconData _getFlashIcon(FlashMode mode) {
      switch (mode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  // 修正：參數類型改為 CaptureStatus
  String _getLoadingMessage(CaptureStatus status) {
    switch (status) {
      case CaptureStatus.requestingNonce:
        return '正在請求安全令牌...';
      case CaptureStatus.awaitingUserSignature:
        return '請透過指紋/臉部進行簽署...';
      case CaptureStatus.uploading:
        return '正在安全上傳數據...';
      default:
        return '處理中...';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 修正：監聽的類型改為 CaptureProviderState
    ref.listen<CaptureProviderState>(captureProvider, (previous, next) {
      // 修正：檢查的狀態改為 CaptureStatus
      if (next.status == CaptureStatus.success) {
        Navigator.of(context).pushReplacementNamed('/result');
      } else if (next.status == CaptureStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '上傳失敗，請重試！')),
        );
      }
    });

    final cameraState = ref.watch(cameraProvider);
    final captureProviderState = ref.watch(captureProvider); // 整個 state 物件
    final captureStatus = captureProviderState.status; // 當前的流程狀態
    final isProcessing = captureStatus != CaptureStatus.initial && captureStatus != CaptureStatus.error;

    if (!cameraState.isInitialized || cameraState.controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: CameraPreview(cameraState.controller!)),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 60, right: 20),
              child: IconButton(
                icon: Icon(_getFlashIcon(cameraState.currentFlashMode), color: Colors.white, size: 30),
                onPressed: isProcessing ? null : () => ref.read(cameraProvider.notifier).cycleFlashMode(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 70),
                onPressed: isProcessing ? null : () async {
                  // 修正 use_build_context_synchronously 警告
                  if (!mounted) return;
                  
                  try {
                    final image = await cameraState.controller!.takePicture();
                    final imageBytes = await image.readAsBytes();
                    ref.read(captureProvider.notifier).startCaptureProcess(imageBytes);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('拍照失敗: $e')),
                    );
                  }
                },
              ),
            ),
          ),
          if (isProcessing)
            Container(
              // 修正 deprecated_member_use 警告
              color: Colors.black.withAlpha(178), // 70% apha
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      _getLoadingMessage(captureStatus),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}