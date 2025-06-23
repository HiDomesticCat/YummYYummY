.
├── android/              # Android 原生專案資料夾
├── ios/                  # iOS 原生專案資料夾
├── lib/                  # Flutter 應用程式核心程式碼
│   ├── main.dart (OK)         # 應用程式進入點與根 Widget
│   └── src/
│       ├── application/ (OK)    # 業務邏輯層 (State Management)
│       │   ├── camera/
│       │   │   ├── camera_provider.dart    # (新) 管理相機硬體狀態 (閃光燈、縮放)
│       │   │   └── camera_state.dart       # (新) 定義相機狀態的資料類別
│       │   └── capture/
│       │       └── capture_provider.dart   # (不變) 管理數據捕獲與上傳的核心流程
│       │
│       ├── data/ (OK)           # 數據模型 (可選，但建議)
│       │   └── capture_data.dart         # 定義上傳數據的資料模型
│       │
│       ├── presentation/ (ok)   # 表現層 (UI)
│       │   ├── screens/
│       │   │   ├── auth_screen.dart        # Passkey 註冊與管理介面 
│       │   │   ├── camera_screen.dart      # 全螢幕相機預覽與拍照介面 
│       │   │   ├── home_page.dart          # 應用程式入口，提供開始捕獲按鈕 
│       │   │   └── result_screen.dart      # 展示捕獲成功後的所有驗證數據 
│       │   └── widgets/
│       │       └── ... (未來可放置共用的 UI 元件)
│       │
│       └── services/         # 服務層 (封裝所有外部互動)
│           ├── api_service.dart          # 處理與後端 API 的網路通訊 
│           ├── attestation_service.dart  # (簡化後) 封裝 app_device_integrity 套件
│           ├── image_service.dart        # 處理拍照和圖片的 pHash 計算 
│           ├── location_service.dart     # 封裝 geolocator，獲取 GPS 位置 
│           ├── native_bridge_service.dart# 封裝與原生溝通的平台通道 (如 GPS 欺騙檢測) 
│           ├── passkey_service.dart      # 處理每次上傳前的 Passkey 操作簽名 
│           └── permission_service.dart   # 專門處理權限請求邏輯 
│
├── pubspec.yaml          # 專案的依賴與中繼資料
└── ... (其他 Flutter 自動產生的設定檔)