import 'package:uuid/uuid.dart';

import '../../../../core/constants/utility_types.dart';

export '../../../../core/constants/utility_types.dart';

class BillAccount {
  final String id;
  final UtilityType utilityType;
  final String accountNumber;
  final String nickname;
  final String? area;
  final int? typicalDueDay; // 1–31
  final String? paymentUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastPaidAt;

  const BillAccount({
    required this.id,
    required this.utilityType,
    required this.accountNumber,
    required this.nickname,
    this.area,
    this.typicalDueDay,
    this.paymentUrl,
    this.isActive = true,
    required this.createdAt,
    this.lastPaidAt,
  });

  factory BillAccount.create({
    required UtilityType utilityType,
    required String accountNumber,
    required String nickname,
    String? area,
    int? typicalDueDay,
    String? paymentUrl,
  }) {
    return BillAccount(
      id: const Uuid().v4(),
      utilityType: utilityType,
      accountNumber: accountNumber,
      nickname: nickname,
      area: area,
      typicalDueDay: typicalDueDay,
      paymentUrl: paymentUrl,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'utility_type': utilityType.name,
        'account_number': accountNumber,
        'nickname': nickname,
        'area': area,
        'typical_due_day': typicalDueDay,
        'payment_url': paymentUrl,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'last_paid_at': lastPaidAt?.toIso8601String(),
      };

  factory BillAccount.fromMap(Map<String, dynamic> map) => BillAccount(
        id: map['id'] as String,
        utilityType: UtilityType.values.byName(map['utility_type'] as String),
        accountNumber: map['account_number'] as String,
        nickname: map['nickname'] as String,
        area: map['area'] as String?,
        typicalDueDay: map['typical_due_day'] as int?,
        paymentUrl: map['payment_url'] as String?,
        isActive: (map['is_active'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        lastPaidAt: map['last_paid_at'] != null
            ? DateTime.parse(map['last_paid_at'] as String)
            : null,
      );

  BillAccount copyWith({
    String? nickname,
    String? area,
    int? typicalDueDay,
    String? paymentUrl,
    bool? isActive,
    DateTime? lastPaidAt,
  }) =>
      BillAccount(
        id: id,
        utilityType: utilityType,
        accountNumber: accountNumber,
        nickname: nickname ?? this.nickname,
        area: area ?? this.area,
        typicalDueDay: typicalDueDay ?? this.typicalDueDay,
        paymentUrl: paymentUrl ?? this.paymentUrl,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        lastPaidAt: lastPaidAt ?? this.lastPaidAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillAccount &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
