import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/providers/auth_providers.dart';
import '../../../notifications/services/reminder_service.dart';
import '../../../sync/providers/sync_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final syncState = ref.watch(syncNotifierProvider).valueOrNull;
    final authRepo = ref.watch(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস')),
      body: ListView(
        children: [
          authAsync.when(
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('অ্যাকাউন্ট লোড হচ্ছে…'),
            ),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: const Text('অ্যাকাউন্ট এরর'),
              subtitle: Text('$e'),
            ),
            data: (state) => switch (state) {
              Authenticated(:final user) => ListTile(
                  leading: const Icon(Icons.verified_user, color: Colors.green),
                  title: Text(user.phoneNumber ?? 'লগইন করা আছে'),
                  subtitle: const Text('ক্লাউড সিঙ্ক চালু'),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('সাইন আউট হয়েছে')),
                        );
                      }
                    },
                    child: const Text('সাইন আউট'),
                  ),
                ),
              _ => ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('লগইন / ব্যাকআপ'),
                  subtitle: Text(
                    authRepo.isAvailable
                        ? 'ফোন OTP দিয়ে সাইন ইন করুন'
                        : 'Firebase কনফিগার করা নেই',
                  ),
                  onTap: () {
                    if (!authRepo.isAvailable) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'আগে flutterfire configure চালান '
                            '(docs/setup/firebase-setup.md)',
                          ),
                        ),
                      );
                      return;
                    }
                    context.push('/login');
                  },
                ),
            },
          ),
          if (syncState is SyncInProgress)
            const ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('সিঙ্ক চলছে…'),
            ),
          if (syncState is SyncSuccess)
            ListTile(
              leading: const Icon(Icons.cloud_done, color: Colors.green),
              title: Text(syncState.message),
            ),
          if (syncState is SyncError)
            ListTile(
              leading: const Icon(Icons.cloud_off, color: Colors.orange),
              title: const Text('সিঙ্ক ব্যর্থ'),
              subtitle: Text(syncState.message),
            ),
          if (authAsync.valueOrNull is Authenticated)
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('এখনই সিঙ্ক করুন'),
              onTap: () =>
                  ref.read(syncNotifierProvider.notifier).syncOnLogin(),
            ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('টেস্ট রিমাইন্ডার (২ মিনিট)'),
            subtitle: const Text('নোটিফিকেশন পারমিশন যাচাই'),
            onTap: () async {
              await ref.read(reminderServiceProvider).scheduleTestReminder(
                    billNickname: 'টেস্ট বিল',
                    billId: 'qa-test',
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('২ মিনিট পর টেস্ট নোটিফিকেশন আসবে'),
                  ),
                );
              }
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('বিলবাক্স'),
            subtitle: Text('v1.0.0 · Phase 6'),
          ),
        ],
      ),
    );
  }
}
