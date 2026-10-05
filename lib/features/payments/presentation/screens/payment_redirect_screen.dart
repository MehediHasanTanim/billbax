import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../bills/data/models/bill_account.dart';
import '../../../bills/providers/bill_providers.dart';
import '../../providers/payment_providers.dart';
import '../widgets/log_payment_sheet.dart';
import '../widgets/payment_option_button.dart';

class PaymentRedirectScreen extends ConsumerStatefulWidget {
  const PaymentRedirectScreen({super.key, required this.billId});

  final String billId;

  @override
  ConsumerState<PaymentRedirectScreen> createState() =>
      _PaymentRedirectScreenState();
}

class _PaymentRedirectScreenState extends ConsumerState<PaymentRedirectScreen>
    with WidgetsBindingObserver {
  bool _hasLaunched = false;
  bool _returnedFromPayment = false;
  bool _logSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hasLaunched && !_logSheetOpen) {
      setState(() => _returnedFromPayment = true);
      _showLogPaymentSheet();
    }
  }

  BillAccount? _findAccount() {
    return ref.read(billByIdProvider(widget.billId));
  }

  Future<void> _showLogPaymentSheet() async {
    final account = _findAccount();
    if (account == null || !mounted || _logSheetOpen) return;

    setState(() => _logSheetOpen = true);
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => LogPaymentSheet(billAccount: account),
      );
    } finally {
      if (mounted) setState(() => _logSheetOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billState = ref.watch(billAccountsProvider);
    final remoteUrls = ref.watch(remoteConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('পেমেন্ট')),
      body: billState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          BillAccount? account;
          for (final a in state.accounts) {
            if (a.id == widget.billId) {
              account = a;
              break;
            }
          }
          if (account == null) {
            return const Center(child: Text('বিল পাওয়া যায়নি'));
          }
          return _buildPaymentOptions(account, remoteUrls);
        },
      ),
    );
  }

  Widget _buildPaymentOptions(
    BillAccount account,
    AsyncValue<Map<String, String>> remoteUrls,
  ) {
    if (_returnedFromPayment) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'পেমেন্ট সম্পন্ন হয়েছে?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _showLogPaymentSheet,
                child: const Text('পেমেন্ট রেকর্ড করুন'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  _returnedFromPayment = false;
                  _hasLaunched = false;
                }),
                child: const Text('আবার পেমেন্ট অপশন দেখুন'),
              ),
            ],
          ),
        ),
      );
    }

    final url = account.paymentUrl ??
        remoteUrls.valueOrNull?[account.utilityType.name] ??
        kDefaultPaymentUrls[account.utilityType.name] ??
        '';

    final hasBkash = kBkashBillUrls.containsKey(account.utilityType.name);
    final hasPortal = url.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              title: Text(
                account.nickname,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${account.utilityType.shortLabel} · ${account.accountNumber}',
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'পেমেন্ট অপশন বেছে নিন:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (remoteUrls.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          if (hasBkash)
            PaymentOptionButton(
              iconData: Icons.account_balance_wallet,
              label: 'bKash দিয়ে পে করুন',
              color: const Color(0xFFE2136E),
              onTap: () => _launchUrl(kBkashBillUrls[account.utilityType.name]!),
            ),
          if (hasBkash && hasPortal) const SizedBox(height: 12),
          if (hasPortal)
            PaymentOptionButton(
              iconData: Icons.language,
              label: 'অফিসিয়াল ওয়েবসাইটে পে করুন',
              color: Colors.blue,
              onTap: () => _launchUrl(url),
            ),
          if (!hasBkash && !hasPortal) ...[
            const SizedBox(height: 8),
            Text(
              'এই বিলের জন্য কোনো পেমেন্ট লিংক সেট করা নেই। '
              'ম্যানুয়ালি পে করে নিচে রেকর্ড করুন।',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _showLogPaymentSheet,
            icon: const Icon(Icons.edit_note),
            label: const Text('ইতিমধ্যে পে করেছি — রেকর্ড করুন'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('অবৈধ URL')),
        );
      }
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        setState(() => _hasLaunched = true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('অ্যাপ বা ওয়েবসাইট খোলা যায়নি')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('খোলা যায়নি: $e')),
        );
      }
    }
  }
}
