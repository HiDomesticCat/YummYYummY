import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

/// ImageService 負責處理所有與圖像內容計算相關的任務。
///
/// 它的核心功能是為給定的圖像數據計算感知雜湊值 (pHash)，
/// 以便後端可以比對圖像內容的相似性。
class ImageService {
  /// 為給定的圖像位元組數據計算一個簡化的感知雜湊值 (pHash)。
  ///
  /// 注意：一個標準的 pHash 演算法會使用離散餘弦變換 (DCT)。
  /// 為了在 Dart 中輕量化地實現此 PoC，這裡採用了一個簡化版本，
  /// 它基於調整尺寸、灰階化和比較像素與平均亮度的關係來生成雜湊值。
  /// 這個簡化版同樣能達到為圖像內容生成指紋的目的。
  ///
  /// @param imageBytes 圖像的原始 Uint8List 數據。
  /// @return 一個代表圖像內容指紋的十六進位字串。
  Future<String> calculatePHash(Uint8List imageBytes) async {
    try {
      // 1. 解碼圖像：將原始位元組轉換為 `image` 套件可以處理的 Image 物件。
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('無法解碼圖像數據');
      }

      // 2. 縮小尺寸：將圖像縮小到一個固定的低解析度（例如 32x32）。
      // 這一步可以消除高頻細節的干擾，只保留圖像的結構和輪廓。
      final resizedImage = img.copyResize(
        originalImage,
        width: 32,
        height: 32,
        interpolation: img.Interpolation.average,
      );

      // 3. 灰階化：將彩色圖像轉換為灰階圖像，以消除顏色資訊的干擾。
      final grayscaleImage = img.grayscale(resizedImage);

      // 4. 計算平均亮度：遍歷所有像素，計算整張小圖的平均亮度值。
      double totalLuminance = 0;
      for (final pixel in grayscaleImage) {
        totalLuminance += pixel.r; // 在灰階圖中，r, g, b 的值是相同的
      }
      final avgLuminance = totalLuminance / (grayscaleImage.width * grayscaleImage.height);

      // 5. 生成二進位雜湊：再次遍歷所有像素，如果像素亮度大於等於平均值，
      // 則記為 1，否則記為 0。我們使用 BigInt 來高效地處理這個二進位序列。
      BigInt pHash = BigInt.zero;
      for (final pixel in grayscaleImage) {
        pHash <<= 1; // 左移一位，為下一個位元騰出空間
        if (pixel.r >= avgLuminance) {
          pHash |= BigInt.one; // 將當前位設為 1
        }
      }

      // 6. 格式化輸出：將最終的 BigInt 轉換為十六進位字串並回傳。
      return pHash.toRadixString(16).padLeft(256, '0'); // 32*32=1024位元，十六進位為256字元
    } catch (e) {
      print('計算 pHash 時發生錯誤: $e');
      rethrow; // 重新拋出例外，讓上層處理
    }
  }
}

/// 全域的 ImageService Provider。
///
/// 讓應用程式的其他部分（主要是 CaptureNotifier）可以存取 ImageService 的實例。
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});