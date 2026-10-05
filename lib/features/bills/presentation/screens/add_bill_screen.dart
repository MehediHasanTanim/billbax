import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/bill_account.dart';
import '../../providers/bill_providers.dart';

class AddBillScreen extends ConsumerStatefulWidget {
  const AddBillScreen({super.key, this.existingAccount});

  final BillAccount? existingAccount;

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  late UtilityType _selectedType;
  late TextEditingController _accountController;
  late TextEditingController _nicknameController;
  late TextEditingController _areaController;
  int? _dueDayValue;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAccount;
    _selectedType = existing?.utilityType ?? UtilityType.desco;
    _accountController =
        TextEditingController(text: existing?.accountNumber ?? '');
    _nicknameController =
        TextEditingController(text: existing?.nickname ?? '');
    _areaController = TextEditingController(text: existing?.area ?? '');
    _dueDayValue = existing?.typicalDueDay;
  }

  @override
  void dispose() {
    _accountController.dispose();
    _nicknameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAccount != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'বিল সম্পাদনা' : 'নতুন বিল')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<UtilityType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'সেবা প্রদানকারী',
                border: OutlineInputBorder(),
              ),
              items: UtilityType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_labelForType(type)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountController,
              decoration: const InputDecoration(
                labelText: 'অ্যাকাউন্ট নম্বর',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'অ্যাকাউন্ট নম্বর দিন' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'নাম (যেমন: বাড়ি, অফিস)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'নাম দিন' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'এলাকা (ঐচ্ছিক)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              initialValue: _dueDayValue,
              decoration: const InputDecoration(
                labelText: 'মাসিক বকেয়া তারিখ (ঐচ্ছিক)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('নির্ধারিত নেই')),
                ...List.generate(
                  28,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1} তারিখ'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _dueDayValue = v),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'আপডেট করুন' : 'সংরক্ষণ করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final notifier = ref.read(billAccountsProvider.notifier);
      final area = _areaController.text.trim();
      final existing = widget.existingAccount;

      if (existing != null) {
        await notifier.updateAccount(
          BillAccount(
            id: existing.id,
            utilityType: _selectedType,
            accountNumber: _accountController.text.trim(),
            nickname: _nicknameController.text.trim(),
            area: area.isEmpty ? null : area,
            typicalDueDay: _dueDayValue,
            paymentUrl: existing.paymentUrl,
            isActive: existing.isActive,
            createdAt: existing.createdAt,
            lastPaidAt: existing.lastPaidAt,
          ),
        );
      } else {
        await notifier.addAccount(
          BillAccount.create(
            utilityType: _selectedType,
            accountNumber: _accountController.text.trim(),
            nickname: _nicknameController.text.trim(),
            area: area.isEmpty ? null : area,
            typicalDueDay: _dueDayValue,
          ),
        );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _labelForType(UtilityType type) => type.displayNameBn;
}
