import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../firebase_options.dart';
import '../../bills/data/models/bill_account.dart';
import '../../bills/data/repositories/bill_repository.dart';
import '../../payments/data/models/payment_record.dart';
import '../../payments/data/repositories/payment_repository.dart';

class FirestoreSyncService {
  FirestoreSyncService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth,
        _firestore = firestore;

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  bool get isAvailable =>
      DefaultFirebaseOptions.isConfigured && Firebase.apps.isNotEmpty;

  FirebaseAuth get _requireAuth {
    if (!isAvailable) {
      throw StateError('Firebase not configured');
    }
    return _auth ??= FirebaseAuth.instance;
  }

  FirebaseFirestore get _fs => _firestore ??= FirebaseFirestore.instance;

  User? get currentUser => isAvailable ? _requireAuth.currentUser : null;

  String get _uid => _requireAuth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _billsRef =>
      _fs.collection('users').doc(_uid).collection('bill_accounts');

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _fs.collection('users').doc(_uid).collection('payment_history');

  /// Pull remote data into local SQLite (replace on conflict).
  Future<void> pullOnLogin(
    BillRepository billRepo,
    PaymentRepository paymentRepo,
  ) async {
    if (currentUser == null) return;

    final billDocs = await _billsRef.get();
    for (final doc in billDocs.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] ??= doc.id;
      if (data['is_active'] is bool) {
        data['is_active'] = (data['is_active'] as bool) ? 1 : 0;
      }
      final account = BillAccount.fromMap(data);
      await billRepo.insert(account);
    }

    final paymentDocs = await _paymentsRef.get();
    for (final doc in paymentDocs.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] ??= doc.id;
      if (data['is_synced'] is bool) {
        data['is_synced'] = (data['is_synced'] as bool) ? 1 : 0;
      }
      data['is_synced'] = 1;
      final record = PaymentRecord.fromMap(data);
      await paymentRepo.insert(record);
    }
  }

  Future<void> pushPendingPayments(PaymentRepository paymentRepo) async {
    if (currentUser == null) return;
    try {
      final unsynced = await paymentRepo.getUnsynced();
      for (final record in unsynced) {
        await _paymentsRef.doc(record.id).set(record.toMap());
        await paymentRepo.markSynced(record.id);
      }
    } catch (e, st) {
      debugPrint('pushPendingPayments failed: $e\n$st');
    }
  }

  Future<void> pushBillAccount(BillAccount account) async {
    if (currentUser == null) return;
    try {
      await _billsRef.doc(account.id).set(account.toMap());
    } catch (e, st) {
      debugPrint('pushBillAccount failed: $e\n$st');
    }
  }

  Future<void> pushAllBillAccounts(BillRepository billRepo) async {
    if (currentUser == null) return;
    final accounts = await billRepo.getAll(activeOnly: false);
    for (final account in accounts) {
      await pushBillAccount(account);
    }
  }

  Future<void> softDeleteRemoteBill(String id) async {
    if (currentUser == null) return;
    try {
      await _billsRef.doc(id).set({'is_active': 0}, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('softDeleteRemoteBill failed: $e\n$st');
    }
  }

  /// Full login sync: push local → pull remote.
  Future<int> syncOnLogin(
    BillRepository billRepo,
    PaymentRepository paymentRepo,
  ) async {
    if (currentUser == null) {
      debugPrint('Sync skipped: not logged in');
      return 0;
    }
    await pushAllBillAccounts(billRepo);
    await pushPendingPayments(paymentRepo);
    await pullOnLogin(billRepo, paymentRepo);
    return (await billRepo.getAll()).length;
  }
}
