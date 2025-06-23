import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// PermissionService 負責處理所有與作業系統權限相關的請求。
///
/// 它將 `permission_handler` 套件的複雜性封裝起來，
/// 提供一個簡單的方法來請求應用程式所需的多個權限。
class PermissionService {
  /// 請求此應用程式運作所需的核心權限（相機和位置）。
  ///
  /// 此方法會同時觸發相機和「使用 App 期間」的位置權限請求對話框。
  /// 只有當使用者授予所有權限時，才會回傳 `true`。
  ///
  /// @return 一個 Future<bool>，表示所有必需權限是否都已被授予。
  Future<bool> requestRequiredPermissions() async {
    // 定義我們需要請求的權限列表
    final List<Permission> permissionsToRequest = [
      Permission.camera,
      Permission.locationWhenInUse,
    ];

    // 一次性請求所有權限，這會向使用者顯示一個或多個系統對話框
    final Map<Permission, PermissionStatus> statuses =
        await permissionsToRequest.request();

    // 檢查回傳的狀態，確保列表中的每一個權限都處於 'granted' 狀態
    // 使用 .every() 方法可以簡潔地檢查是否所有條件都為真
    final bool allPermissionsGranted = statuses.values.every(
      (status) => status.isGranted,
    );

    return allPermissionsGranted;
  }
}

/// 全域的 PermissionService Provider。
///
/// 讓應用程式的其他部分（例如 UI 層或業務邏輯層）可以存取 PermissionService 的實例。
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});