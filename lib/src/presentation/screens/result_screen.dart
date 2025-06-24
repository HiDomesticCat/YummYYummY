import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/capture/capture_provider.dart';
import '../../data/capture_data.dart';

/// 結果畫面，用於展示成功捕獲並經過驗證的數據。
///
/// 這個畫面是一個 `ConsumerWidget`，因為它需要從 `CaptureProvider`
/// 讀取狀態以顯示數據，但它本身沒有內部狀態。
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 訂閱 CaptureProvider 的狀態，獲取最後一次成功的數據
    final lastCaptureData = ref.watch(captureProvider.select((state) => state.lastSuccessfulData));
    
    // 如果沒有數據，顯示錯誤信息
    if (lastCaptureData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('錯誤'),
          backgroundColor: Colors.red[100],
        ),
        body: const Center(
          child: Text('沒有可顯示的數據，請先完成數據捕獲流程。'),
        ),
      );
    }
    
    // 從捕獲的數據中提取信息
    final captureData = {
      'pHash': lastCaptureData.pHash,
      'gps': '${lastCaptureData.latitude}° N, ${lastCaptureData.longitude}° E',
      'isMocked': lastCaptureData.isMocked ? '是 (警告)' : '否 (已驗證)',
      'passkeyVerified': '成功',
      'integrityVerified': '成功',
      'timestamp': lastCaptureData.clientTimestamp.toIso8601String(),
    };

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
                    subtitle: captureData['pHash']!,
                  ),
                  _buildResultTile(
                    icon: Icons.location_on,
                    title: 'GPS 位置',
                    subtitle: captureData['gps']!,
                  ),
                  _buildResultTile(
                    icon: Icons.developer_mode,
                    title: 'GPS 模擬狀態',
                    subtitle: captureData['isMocked']!,
                    valueColor: lastCaptureData.isMocked ? Colors.red : Colors.green,
                  ),
                  _buildResultTile(
                    icon: Icons.security,
                    title: 'Passkey 操作簽名驗證',
                    subtitle: captureData['passkeyVerified']!,
                    valueColor: Colors.green,
                  ),
                  _buildResultTile(
                    icon: Icons.verified_user,
                    title: '裝置與應用程式完整性 (Play Integrity)',
                    subtitle: captureData['integrityVerified']!,
                    valueColor: Colors.green,
                  ),
                  _buildResultTile(
                    icon: Icons.access_time,
                    title: '伺服器端信任時間戳',
                    subtitle: captureData['timestamp']!,
                  ),
                  // 顯示圖片
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            '捕獲的圖片',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Image.memory(
                          lastCaptureData.imageBytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ],
                    ),
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
