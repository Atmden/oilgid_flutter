import 'package:oil_gid/core/storage/token_storage.dart';

class AuthRegistrationPayload {
  final String phoneNumber;
  final String passwordHash;
  final String pinHash;
  final String firebaseUid;

  const AuthRegistrationPayload({
    required this.phoneNumber,
    required this.passwordHash,
    required this.pinHash,
    required this.firebaseUid,
  });
}

class AuthRegistrationService {
  final TokenStorage _tokenStorage;

  AuthRegistrationService({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  Future<void> completeRegistration(AuthRegistrationPayload payload) async {
    // Placeholder for future backend integration:
    // send firebase ID token / profile payload and receive API token.
    await _tokenStorage.saveRegisteredPhone(payload.phoneNumber);
    await _tokenStorage.savePasswordHash(payload.passwordHash);
    await _tokenStorage.savePinHash(payload.pinHash);
    await _tokenStorage.saveUserToken(payload.firebaseUid);
    await _tokenStorage.setPhoneRegistrationCompleted(true);
  }
}
