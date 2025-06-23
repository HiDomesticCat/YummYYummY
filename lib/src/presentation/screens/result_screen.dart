import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 匯入 CaptureProvider 以讀取捕獲的數據
// 我們需要修改 CaptureState 來包含最後一次成功的數據

/// 結果畫面，用於展示成功捕獲並經過驗證的數據。
///
/// 這個畫面是一個 `ConsumerWidget`，因為它需要從 `CaptureProvider`
/// 讀取狀態以顯示數據，但它本身沒有內部狀態。
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 訂閱 CaptureProvider 的狀態
    // 假設 CaptureState 中有一個 lastSuccessfulData 屬性
    // final lastCaptureData = ref.watch(captureProvider.select((state) => state.lastSuccessfulData));

    // --- 為了 PoC 演示，我們暫時使用靜態的模擬數據 ---
    // 在真實應用中，您應該從上面的 provider 中讀取真實數據
    final mockData = {
      'pHash': 'f8c3c7e1e3c3c3c3',
      'gps': '25.0330° N, 121.5654° E',
      'isMocked': '否 (已驗證)',
      'passkeyVerified': '成功',
      'integrityVerified': '成功',
      'timestamp': DateTime.now().toIso8601String(),
    };
    // ------------------------------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text('驗證成功'),
        backgroundColor: Colors.green[100],
        automaticallyImplyLeading: false, // 禁用返回按鈕
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 頂部的成功指示器
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              '數據已安全上傳並驗證',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '以下是後端重建信任鏈後的可信數據：',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(height: 40),

            // 數據列表
            Expanded(
              child: ListView(
                children: [
                  _buildResultTile(
                    icon: Icons.fingerprint,
                    title: 'pHash 感知雜湊值',
                    subtitle: mockData['pHash']!,
                  ),
                  _buildResultTile(
                    icon: Icons.location_on,
                    title: 'GPS 位置',
                    subtitle: mockData['gps']!,
                  ),
                  _buildResultTile(
                    icon: Icons.developer_mode,
                    title: 'GPS 模擬狀態',
                    subtitle: mockData['isMocked']!,
                    valueColor: Colors.green,
                  ),
                  _buildResultTile(
                    icon: Icons.security,
                    title: 'Passkey 操作簽名驗證',
                    subtitle: mockData['passkeyVerified']!,
                    valueColor: Colors.green,
                  ),
                  _buildResultTile(
                    icon: Icons.verified_user,
                    title: '裝置與應用程式完整性 (Play Integrity)',
                    subtitle: mockData['integrityVerified']!,
                    valueColor: Colors.green,
                  ),
                  _buildResultTile(
                    icon: Icons.access_time,
                    title: '伺服器端信任時間戳',
                    subtitle: mockData['timestamp']!,
                  ),
                ],
              ),
            ),

            // 底部的操作按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 返回首頁，並移除導航堆疊中的所有舊頁面
                  // 防止使用者按返回鍵回到相機或結果頁
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text('返回首頁'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 一個輔助方法，用於建立統一樣式的結果顯示卡片。
  Widget _buildResultTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? valueColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: valueColor ?? Colors.black87,
            fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}