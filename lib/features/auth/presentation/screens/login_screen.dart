import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      next.whenOrNull(
        data: (state) {
          if (state is OtpSent) {
            context.push(
              '/otp',
              extra: {
                'phone': state.phone ?? _phoneController.text.trim(),
                'verificationId': state.verificationId,
              },
            );
          } else if (state is Authenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('লগইন সফল ✓')),
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
    final isLoading = authAsync.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('লগইন')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.phone_android, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'ফোন নম্বর দিয়ে সাইন ইন করুন',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'ডেটা ব্যাকআপ ও মাল্টি-ডিভাইস সিঙ্কের জন্য (ঐচ্ছিক)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d+\s-]')),
              ],
              decoration: const InputDecoration(
                labelText: 'মোবাইল নম্বর',
                hintText: '017XXXXXXXX',
                prefixText: '+880 ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'নম্বর দিন';
                }
                final normalized = AuthRepository.normalizeBdPhone(v.trim());
                if (!RegExp(r'^\+8801\d{9}$').hasMatch(normalized)) {
                  return 'সঠিক বাংলাদেশি নম্বর দিন';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('OTP পাঠান'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('গেস্ট হিসেবে চালিয়ে যান'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).sendOtp(
          _phoneController.text.trim(),
        );
  }
}
