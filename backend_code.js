export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    
    // 添加 CORS 支援
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    // 處理 OPTIONS 請求
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // 🔑 處理 assetlinks.json 請求
      if (path === '/.well-known/assetlinks.json') {
        return handleAssetLinks();
      }

      // 處理 API 路由
      if (path.startsWith('/api/v1/capture/')) {
        return handleCaptureAPI(request, path);
      }
      
      // 【新增】處理 Passkey 註冊路由
      if (path.startsWith('/register/')) {
        return handleRegisterAPI(request, path);
      }
      
      // 【新增】處理 Passkey 登入路由
      if (path.startsWith('/login/')) {
        return handleLoginAPI(request, path);
      }

      // 健康檢查端點
      if (path === '/health') {
        return new Response(JSON.stringify({ 
          status: 'healthy',
          timestamp: new Date().toISOString(),
          version: '1.0.0'
        }), {
          headers: { 'Content-Type': 'application/json', ...corsHeaders }
        });
      }

      // 默認響應
      return new Response(JSON.stringify({ 
        error: 'Not Found',
        availableEndpoints: [
          '/.well-known/assetlinks.json',
          '/api/v1/capture/initiate',
          '/api/v1/capture/submit',
          '/register/initiate',
          '/register/complete',
          '/login/initiate',
          '/login/complete',
          '/health'
        ]
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json', ...corsHeaders }
      });

    } catch (error) {
      console.error('Worker error:', error);
      return new Response(JSON.stringify({ 
        error: 'Internal Server Error',
        message: error.message 
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders }
      });
    }
  }
};

// 🔑 修正的 assetlinks.json 處理（使用你實際的包名）
function handleAssetLinks() {
  const assetLinks = [
    {
      "relation": ["delegate_permission/common.handle_all_urls"],
      "target": {
        "namespace": "android_app",
        "package_name": "com.example.sample_capture_app", // 🚨 請替換為你的實際包名
        "sha256_cert_fingerprints": [
          "36:2F:AE:BA:28:A2:82:25:2B:B3:C9:51:53:07:B6:A8:D9:9D:A5:1E:A8:85:57:05:B8:08:68:F6:73:F8:35:A4"
        ]
      }
    },
    {
      "relation": ["delegate_permission/common.get_login_creds"],
      "target": {
        "namespace": "android_app",
        "package_name": "com.example.sample_capture_app", // 🚨 請替換為你的實際包名
        "sha256_cert_fingerprints": [
          "36:2F:AE:BA:28:A2:82:25:2B:B3:C9:51:53:07:B6:A8:D9:9D:A5:1E:A8:85:57:05:B8:08:68:F6:73:F8:35:A4"
        ]
      }
    }
  ];

  console.log('Serving assetlinks.json:', JSON.stringify(assetLinks, null, 2));

  return new Response(JSON.stringify(assetLinks, null, 2), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Cache-Control': 'public, max-age=3600',
    },
  });
}

// 🔧 修正的工具函數：生成正確的 Base64URL challenge
function generateBase64URLChallenge(length = 32) {
  // 生成隨機字節
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  
  // 轉換為 Base64URL（無 padding）
  return btoa(String.fromCharCode.apply(null, array))
    .replace(/\+/g, '-')    // 替換 + 為 -
    .replace(/\//g, '_')    // 替換 / 為 _
    .replace(/=/g, '');     // 移除 padding (=)
}

// 🔧 修正的工具函數：生成用戶ID
function generateUserID() {
  const array = new Uint8Array(16); // 16 字節 = 128 位
  crypto.getRandomValues(array);
  
  return btoa(String.fromCharCode.apply(null, array))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

// 處理 Capture API
async function handleCaptureAPI(request, path) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };

  if (path === '/api/v1/capture/initiate') {
    return handleInitiateCapture();
  } else if (path === '/api/v1/capture/submit') {
    return handleSubmitCapture(request);
  }

  return new Response(JSON.stringify({ error: 'API endpoint not found' }), {
    status: 404,
    headers: { 'Content-Type': 'application/json', ...corsHeaders }
  });
}

// 【新增】處理 Passkey 註冊 API
async function handleRegisterAPI(request, path) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };

  if (path === '/register/initiate') {
    return handleInitiateRegistration(request);
  } else if (path === '/register/complete') {
    return handleCompleteRegistration(request);
  }

  return new Response(JSON.stringify({ error: 'API endpoint not found' }), {
    status: 404,
    headers: { 'Content-Type': 'application/json', ...corsHeaders }
  });
}

// 【新增】處理 Passkey 登入 API
async function handleLoginAPI(request, path) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };

  if (path === '/login/initiate') {
    return handleInitiateLogin(request);
  } else if (path === '/login/complete') {
    return handleCompleteLogin(request);
  }

  return new Response(JSON.stringify({ error: 'API endpoint not found' }), {
    status: 404,
    headers: { 'Content-Type': 'application/json', ...corsHeaders }
  });
}

// 🔧 修正的初始化捕獲請求處理
function handleInitiateCapture() {
  // 生成符合 WebAuthn 標準的挑戰
  const challenge = generateBase64URLChallenge(32); // 32 字節的隨機挑戰
  const userID = generateUserID();
  
  // 生成符合 WebAuthn 標準的完整響應
  const webAuthnChallenge = {
    // 🔧 關鍵修正：使用正確的 Base64URL 編碼
    challenge: challenge,
    
    // Relying Party 信息
    rp: {
      id: 'yummyyummy.hiorangecat12888.workers.dev',
      name: 'SpectraLens Secure Capture'
    },
    
    // 用戶信息
    user: {
      id: userID,
      name: 'user@example.com',
      displayName: 'User'
    },
    
    // 公鑰參數
    pubKeyCredParams: [
      { alg: -7, type: 'public-key' },   // ES256
      { alg: -257, type: 'public-key' }  // RS256
    ],
    
    // 認證器選擇
    authenticatorSelection: {
      authenticatorAttachment: 'platform',
      userVerification: 'preferred',
      requireResidentKey: false,
      residentKey: 'preferred'
    },
    
    // 超時設置
    timeout: 60000,
    
    // 證明設置
    attestation: 'none',
    
    // 排除憑證（空列表）
    excludeCredentials: [],
    
    // 🔧 新增：rpId 字段（用於認證）
    rpId: 'yummyyummy.hiorangecat12888.workers.dev',
    allowCredentials: [],
    userVerification: 'preferred',
    mediation: 'optional'
  };

  console.log('Generated WebAuthn challenge with Base64URL encoding:');
  console.log('Challenge:', challenge);
  console.log('Challenge length:', challenge.length);
  console.log('UserID:', userID);
  console.log('Full challenge object:', JSON.stringify(webAuthnChallenge, null, 2));

  return new Response(JSON.stringify(webAuthnChallenge), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    }
  });
}

// 處理提交捕獲數據（保持不變）
async function handleSubmitCapture(request) {
  try {
    const contentType = request.headers.get('content-type') || '';
    
    if (contentType.includes('multipart/form-data')) {
      const formData = await request.formData();
      
      const receivedData = {};
      for (const [key, value] of formData.entries()) {
        if (key === 'photo') {
          receivedData[key] = `[File: ${value.size} bytes]`;
        } else {
          receivedData[key] = value;
        }
      }
      
      console.log('Received capture data:', receivedData);
      
      const response = {
        success: true,
        verified: true,
        message: '數據驗證成功',
        timestamp: new Date().toISOString(),
        receivedFields: Object.keys(receivedData)
      };
      
      return new Response(JSON.stringify(response), {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      });
    } else {
      return new Response(JSON.stringify({ 
        error: 'Content-Type must be multipart/form-data' 
      }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      });
    }
  } catch (error) {
    console.error('Submit capture error:', error);
    return new Response(JSON.stringify({ 
      error: 'Failed to process capture data',
      message: error.message 
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      }
    });
  }
}

// 【新增】處理初始化註冊請求
async function handleInitiateRegistration(request) {
  try {
    const data = await request.json();
    const { username, displayName } = data;
    
    if (!username || !displayName) {
      return new Response(JSON.stringify({ 
        error: 'Username and displayName are required' 
      }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      });
    }
    
    // 生成用戶 ID 和挑戰
    const userId = btoa(username)
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '');
    const challenge = generateBase64URLChallenge(32);
    
    // 創建註冊挑戰
    const registrationChallenge = {
      challenge: challenge,
      rp: {
        name: 'SpectraLens Secure Capture',
        id: 'yummyyummy.hiorangecat12888.workers.dev'
      },
      user: {
        id: userId,
        name: username,
        displayName: displayName
      },
      pubKeyCredParams: [
        { type: 'public-key', alg: -7 },   // ES256
        { type: 'public-key', alg: -257 }  // RS256
      ],
      authenticatorSelection: {
        authenticatorAttachment: 'platform',
        requireResidentKey: true,
        residentKey: 'required',
        userVerification: 'preferred'
      },
      timeout: 60000,
      attestation: 'none',
      
      // 【修正】添加 username 字段，這是 Flutter 應用程序需要的
      username: username,
      displayName: displayName
    };
    
    console.log('Generated registration challenge:', JSON.stringify(registrationChallenge, null, 2));
    
    return new Response(JSON.stringify(registrationChallenge), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      }
    });
  } catch (error) {
    console.error('Registration initiation error:', error);
    return new Response(JSON.stringify({ 
      error: 'Failed to initiate registration',
      message: error.message 
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      }
    });
  }
}

// 【新增】處理完成註冊請求
async function handleCompleteRegistration(request) {
  try {
    const credential = await request.json();
    
    console.log('Received registration credential:', JSON.stringify(credential, null, 2));
    
    // 在實際應用中，這裡應該驗證憑證並將其存儲在數據庫中
    // 為了簡化，我們只返回成功響應
    
    return new Response(JSON.stringify({
      success: true,
      message: 'Registration successful',
      userId: credential.id || 'unknown'
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      }
    });
  } catch (error) {
    console.error('Registration completion error:', error);
    return new Response(JSON.stringify({ 
      error: 'Failed to complete registration',
      message: error.message 
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      }
    });
  }
}

// 【新增】處理初始化登入請求
async function handleInitiateLogin(request) {
  try {
    const data = await request.json();
    const { username } = data;
    
    if (!username) {
      return new Response(JSON.stringify({ 
        error: 'Username is required' 
      }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      });
    }
    
    // 生成挑戰
    const challenge = generateBase64URLChallenge(32);
    
    // 創建登入挑戰
    const loginChallenge = {
      challenge: challenge,
      rpId: 'yummyyummy.hiorangecat12888.workers.dev',
      allowCredentials: [], // 空數組表示允許任何憑證
      userVerification: 'preferred',
      timeout: 60000
    };
    
    console.log('Generated login challenge:', JSON.stringify(loginChallenge, null, 2));
    
    return new Response(JSON.stringify(loginChallenge), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      }
    });
  } catch (error) {
    console.error('Login initiation error:', error);
    return new Response(JSON.stringify({ 
      error: 'Failed to initiate login',
      message: error.message 
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      }
    });
  }
}

// 【新增】處理完成登入請求
async function handleCompleteLogin(request) {
  try {
    const credential = await request.json();
    
    console.log('Received login credential:', JSON.stringify(credential, null, 2));
    
    // 在實際應用中，這裡應該驗證憑證
    // 為了簡化，我們只返回成功響應
    
    return new Response(JSON.stringify({
      success: true,
      message: 'Login successful',
      userId: credential.id || 'unknown',
      username: credential.username || 'user@example.com'
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      }
    });
  } catch (error) {
    console.error('Login completion error:', error);
    return new Response(JSON.stringify({ 
      error: 'Failed to complete login',
      message: error.message 
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      }
    });
  }
}
