import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../firebase_options.dart';

class FirebaseNotConfiguredException implements Exception {
  @override
  String toString() =>
      'Firebase কনফিগার করা নেই। docs/setup/firebase-setup.md দেখুন।';
}

class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth;

  FirebaseAuth? _auth;

  bool get isAvailable =>
      DefaultFirebaseOptions.isConfigured && Firebase.apps.isNotEmpty;

  FirebaseAuth get _requireAuth {
    if (!isAvailable) throw FirebaseNotConfiguredException();
    return _auth ??= FirebaseAuth.instance;
  }

  User? get currentUser {
    if (!isAvailable) return null;
    return (_auth ?? FirebaseAuth.instance).currentUser;
  }

  Stream<User?> get userChanges {
    if (!isAvailable) return Stream.value(null);
    return (_auth ?? FirebaseAuth.instance).authStateChanges();
  }

  /// Normalizes BD numbers to E.164 (`+8801XXXXXXXXX`).
  static String normalizeBdPhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+880') && digits.length >= 14) {
      return digits;
    }
    if (digits.startsWith('880') && digits.length >= 13) {
      return '+$digits';
    }
    if (digits.startsWith('0') && digits.length == 11) {
      return '+880${digits.substring(1)}';
    }
    if (digits.startsWith('1') && digits.length == 10) {
      return '+880$digits';
    }
    return digits.startsWith('+') ? digits : '+$digits';
  }

  Future<void> sendOtp(
    String phoneNumber, {
    required void Function(PhoneAuthCredential) onVerified,
    required void Function(FirebaseAuthException) onFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
  }) async {
    final auth = _requireAuth;
    final normalized = normalizeBdPhone(phoneNumber);
    await auth.verifyPhoneNumber(
      phoneNumber: normalized,
      verificationCompleted: onVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<void> signInWithCode(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _requireAuth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (!isAvailable) return;
    await _requireAuth.signOut();
  }
}
