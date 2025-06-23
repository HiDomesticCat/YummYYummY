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

    // --- 以下是修正部分 ---
    // 建立一個 LocationSettings 物件來設定精度
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // 我們需要高精度
      distanceFilter: 10, // 位置更新之間的最小距離（米）
    );

    // 將 settings 物件傳入 getCurrentPosition
    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
    // --- 修正結束 ---
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});