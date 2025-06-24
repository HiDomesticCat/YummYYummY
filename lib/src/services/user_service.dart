import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用戶服務，負責管理用戶的身份驗證狀態和信息
class UserService {
  static final _logger = Logger('UserService');
  
  // 用戶信息的鍵
  static const _keyEmail = 'user_email';
  static const _keyIsAuthenticated = 'user_is_authenticated';
  
  // 內存中的用戶狀態
  String? _currentEmail;
  bool _isAuthenticated = false;
  
  /// 初始化用戶服務，從持久化存儲中加載用戶狀態
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentEmail = prefs.getString(_keyEmail);
      _isAuthenticated = prefs.getBool(_keyIsAuthenticated) ?? false;
      
      _logger.info('[UserService] 初始化完成，用戶狀態: ${isAuthenticated ? '已登入' : '未登入'}');
    } catch (e) {
      _logger.warning('[UserService] 初始化失敗: $e');
      _isAuthenticated = false;
      _currentEmail = null;
    }
  }
  
  /// 獲取當前用戶的電子郵件
  String? get currentEmail => _currentEmail;
  
  /// 檢查用戶是否已經通過身份驗證
  bool get isAuthenticated => _isAuthenticated;
  
  /// 設置當前用戶並更新身份驗證狀態
  /// 
  /// @param email 用戶的電子郵件
  /// @param authResponse Passkey 身份驗證的響應
  Future<void> setCurrentUser({
    required String email,
    required dynamic authResponse,
  }) async {
    try {
      _currentEmail = email;
      _isAuthenticated = true;
      
      // 保存到持久化存儲
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEmail, email);
      await prefs.setBool(_keyIsAuthenticated, true);
      
      _logger.info('[UserService] 用戶 $email 已成功登入');
    } catch (e) {
      _logger.severe('[UserService] 設置用戶失敗: $e');
      rethrow;
    }
  }
  
  /// 登出當前用戶
  Future<void> logout() async {
    try {
      _currentEmail = null;
      _isAuthenticated = false;
      
      // 從持久化存儲中移除
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyEmail);
      await prefs.setBool(_keyIsAuthenticated, false);
      
      _logger.info('[UserService] 用戶已登出');
    } catch (e) {
      _logger.warning('[UserService] 登出失敗: $e');
      rethrow;
    }
  }
}

/// 全域的 UserService Provider
final userServiceProvider = Provider<UserService>((ref) {
  final service = UserService();
  // 初始化服務（非同步操作）
  Future.microtask(() => service.initialize());
  return service;
});
