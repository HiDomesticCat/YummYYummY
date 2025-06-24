import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('定位服務已被禁用，請在系統設定中開啟。');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('位置權限已被拒絕，無法獲取座標。');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('位置權限已被永久拒絕，我們無法請求權限。請在 App 設定中手動開啟。');
    }

    // 使用正確的參數獲取當前位置
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high, // 我們需要高精度
      timeLimit: const Duration(seconds: 30), // 設定超時時間
    );
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
