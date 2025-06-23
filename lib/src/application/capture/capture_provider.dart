import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/capture_data.dart';
import '../../services/api_service.dart';
import '../../services/attestation_service.dart';
import '../../services/image_service.dart';
import '../../services/location_service.dart';
import '../../services/native_bridge_service.dart';
import '../../services/passkey_service.dart';
import 'capture_provider_state.dart';

class CaptureNotifier extends StateNotifier<CaptureProviderState> {
  final Ref _ref;

  CaptureNotifier(this._ref) : super(const CaptureProviderState());

  Future<void> startCaptureProcess(Uint8List imageBytes) async {
    if (state.status == CaptureStatus.gatheringData || state.status == CaptureStatus.uploading) return;
    
    try {
      state = state.copyWith(status: CaptureStatus.gatheringData);
      final pHashFuture = _ref.read(imageServiceProvider).calculatePHash(imageBytes);
      final locationFuture = _ref.read(locationServiceProvider).getCurrentPosition();
      final isMockedFuture = _ref.read(nativeBridgeServiceProvider).isGpsMocked();
      final results = await Future.wait([pHashFuture, locationFuture, isMockedFuture]);
      final pHash = results[0] as String;
      final location = results[1] as Position;
      final isMocked = results[2] as bool;

      state = state.copyWith(status: CaptureStatus.requestingNonce);
      final dynamic webAuthnChallenge = await _ref.read(apiServiceProvider).initiateCapture();

      state = state.copyWith(status: CaptureStatus.awaitingUserSignature);
      
      // 提取 nonce 用於 AttestationService
      String nonce;
      if (webAuthnChallenge is Map<String, dynamic>) {
        final String? challengeValue = webAuthnChallenge['challenge'] as String?;
        if (challengeValue == null) {
          throw Exception('從後端收到的挑戰物件缺少 challenge 欄位。');
        }
        nonce = challengeValue;
      } else {
        throw Exception('從後端收到的挑戰物件格式不正確，期望 Map<String, dynamic>。');
      }
      
      final authResults = await Future.wait([
        // ✅ 正確的 PasskeyService 調用方式
        _ref.read(passkeyServiceProvider).authenticate(
          webAuthnChallenge: webAuthnChallenge,  // 直接傳遞完整的 webAuthnChallenge
        ),
        // ✅ 正確的 AttestationService 調用方式
        _ref.read(attestationServiceProvider).getAttestationToken(nonce: nonce),
      ]);
      
      final passkeyResponseJson = authResults[0].toString(); // 轉換為字符串
      final integrityToken = authResults[1] as String;

      final captureData = CaptureData(
        pHash: pHash,
        latitude: location.latitude,
        longitude: location.longitude,
        isMocked: isMocked,
        passkeyResponse: passkeyResponseJson, 
        integrityToken: integrityToken,
        imageBytes: imageBytes,
        clientTimestamp: DateTime.now(),
      );

      state = state.copyWith(status: CaptureStatus.uploading);
      final bool isSuccess = await _ref.read(apiServiceProvider).submitCapture(captureData);

      if (isSuccess) {
        state = state.copyWith(
          status: CaptureStatus.success,
          lastSuccessfulData: captureData,
        );
      } else {
        throw Exception('後端驗證失敗，數據可能已被竄改。');
      }

    } catch (e) {
      state = state.copyWith(
        status: CaptureStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void resetState() {
    state = const CaptureProviderState();
  }
}

final captureProvider = StateNotifierProvider<CaptureNotifier, CaptureProviderState>((ref) {
  return CaptureNotifier(ref);
});