import 'package:uuid/uuid.dart';

class PaymentRecord {
  final String id;
  final String billAccountId;
  final double amount;
  final DateTime paidAt;
  final String? notes;
  final String? receiptImagePath;
  final bool isSynced;

  const PaymentRecord({
    required this.id,
    required this.billAccountId,
    required this.amount,
    required this.paidAt,
    this.notes,
    this.receiptImagePath,
    this.isSynced = false,
  });

  factory PaymentRecord.create({
    required String billAccountId,
    required double amount,
    DateTime? paidAt,
    String? notes,
    String? receiptImagePath,
  }) =>
      PaymentRecord(
        id: const Uuid().v4(),
        billAccountId: billAccountId,
        amount: amount,
        paidAt: paidAt ?? DateTime.now(),
        notes: notes,
        receiptImagePath: receiptImagePath,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'bill_account_id': billAccountId,
        'amount': amount,
        'paid_at': paidAt.toIso8601String(),
        'notes': notes,
        'receipt_image_path': receiptImagePath,
        'is_synced': isSynced ? 1 : 0,
      };

  factory PaymentRecord.fromMap(Map<String, dynamic> map) => PaymentRecord(
        id: map['id'] as String,
        billAccountId: map['bill_account_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        paidAt: DateTime.parse(map['paid_at'] as String),
        notes: map['notes'] as String?,
        receiptImagePath: map['receipt_image_path'] as String?,
        isSynced: (map['is_synced'] as int) == 1,
      );

  PaymentRecord copyWith({
    double? amount,
    DateTime? paidAt,
    String? notes,
    String? receiptImagePath,
    bool? isSynced,
  }) =>
      PaymentRecord(
        id: id,
        billAccountId: billAccountId,
        amount: amount ?? this.amount,
        paidAt: paidAt ?? this.paidAt,
        notes: notes ?? this.notes,
        receiptImagePath: receiptImagePath ?? this.receiptImagePath,
        isSynced: isSynced ?? this.isSynced,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MonthlyTotal {
  final int month;
  final double total;

  const MonthlyTotal({required this.month, required this.total});
}
