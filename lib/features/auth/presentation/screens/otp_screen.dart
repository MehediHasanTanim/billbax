import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../../sync/providers/sync_providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    required this.phone,
    required this.verificationId,
  });

  final String phone;
  final String verificationId;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      next.whenOrNull(
        data: (state) {
          if (state is Authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('লগইন সফল — সিঙ্ক চলছে')),
            );
            context.go('/settings');
          }
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e')),
          );
        },
      );
    });

    final authAsync = ref.watch(authNotifierProvider);
    final syncAsync = ref.watch(syncNotifierProvider);
    final isLoading =
        authAsync.isLoading || syncAsync.valueOrNull is SyncInProgress;

    return Scaffold(
      appBar: AppBar(title: const Text('OTP যাচাই')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'OTP পাঠানো হয়েছে',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.phone,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: '৬ ডিজিটের কোড',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.length != 6) return '৬ ডিজিট দিন';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: isLoading ? null : _verify,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('যাচাই করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).verifyOtp(
          widget.verificationId,
          _otpController.text.trim(),
        );
  }
}
