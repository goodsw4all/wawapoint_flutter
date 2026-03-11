import 'package:uuid/uuid.dart';

enum TransactionType {
  income,
  expense;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return '포인트 지급';
      case TransactionType.expense:
        return '사용';
    }
  }
}

class PointRecord {
  final String id;
  final DateTime date;
  final TransactionType type;
  double amount;
  String reason;
  double balanceAfter;

  PointRecord({
    String? id,
    required this.date,
    required this.type,
    required this.amount,
    required this.reason,
    required this.balanceAfter,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'type': type.name,
        'amount': amount,
        'reason': reason,
        'balanceAfter': balanceAfter,
      };

  factory PointRecord.fromJson(Map<String, dynamic> json) => PointRecord(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        type: TransactionType.values.firstWhere(
          (e) => e.name == (json['type'] as String),
        ),
        amount: (json['amount'] as num).toDouble(),
        reason: json['reason'] as String,
        balanceAfter: (json['balanceAfter'] as num).toDouble(),
      );
}
