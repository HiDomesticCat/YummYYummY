import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

// 匯入我們建立的核心 Provider
import '../../application/camera/camera_provider.dart';
import '../../application/capture/capture_provider.dart';
import '../../application/capture/capture_provider_state.dart';
import '../../services/user_service.dart';

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

  // 參數類型為 CaptureStatus
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
    // 檢查用戶是否已登入
    final userService = ref.watch(userServiceProvider);
    final isAuthenticated = userService.isAuthenticated;
    
    // 如果用戶未登入，顯示提示並提供登入按鈕
    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('需要登入')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 80, color: Colors.orange),
                const SizedBox(height: 20),
                const Text(
                  '您需要先登入才能使用此功能',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  '請使用您的 Passkey 登入以驗證您的身份，然後再嘗試捕獲數據。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('前往登入'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // 用戶已登入，顯示相機畫面
    // 監聽 CaptureProviderState 的變化
    ref.listen<CaptureProviderState>(captureProvider, (previous, next) {
      if (next.status == CaptureStatus.success) {
        Navigator.of(context).pushReplacementNamed('/result');
      } else if (next.status == CaptureStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '上傳失敗，請重試！')),
        );
      }
    });

    final cameraState = ref.watch(cameraProvider);
    final captureProviderState = ref.watch(captureProvider);
    final captureStatus = captureProviderState.status;
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
              color: Colors.black.withAlpha(178),
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
