import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/providers/sync_providers.dart';
import '../data/repositories/auth_repository.dart';

sealed class AuthState {
  const AuthState();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class OtpSent extends AuthState {
  const OtpSent(this.verificationId, {this.phone});

  final String verificationId;
  final String? phone;
}

class Authenticated extends AuthState {
  const Authenticated(this.user);

  final User user;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends AsyncNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    final user = _repo.currentUser;
    return user != null ? Authenticated(user) : const Unauthenticated();
  }

  Future<void> sendOtp(String phone) async {
    state = const AsyncLoading();
    try {
      if (!_repo.isAvailable) {
        throw FirebaseNotConfiguredException();
      }

      await _repo.sendOtp(
        phone,
        onVerified: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            state = AsyncData(Authenticated(user));
            await ref.read(syncNotifierProvider.notifier).syncOnLogin();
          }
        },
        onFailed: (e) {
          state = AsyncError(e, StackTrace.current);
        },
        onCodeSent: (verificationId, _) {
          state = AsyncData(
            OtpSent(
              verificationId,
              phone: AuthRepository.normalizeBdPhone(phone),
            ),
          );
        },
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> verifyOtp(String verificationId, String smsCode) async {
    state = const AsyncLoading();
    try {
      await _repo.signInWithCode(verificationId, smsCode);
      final user = _repo.currentUser;
      if (user == null) {
        throw StateError('সাইন-ইন সফল হয়েছিল কিন্তু ইউজার পাওয়া যায়নি');
      }
      state = AsyncData(Authenticated(user));
      await ref.read(syncNotifierProvider.notifier).syncOnLogin();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncData(Unauthenticated());
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final isLoggedInProvider = Provider<bool>((ref) {
  final auth = ref.watch(authNotifierProvider).valueOrNull;
  return auth is Authenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authNotifierProvider).valueOrNull;
  return auth is Authenticated ? auth.user : null;
});
