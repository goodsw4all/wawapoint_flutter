import 'package:uuid/uuid.dart';

/// 거래 유형 (수입 또는 지출)
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

/// 잔액 및 거래 내역을 구성하는 단일 포인트 기록 엔티티
class PointRecord {
  /// 고유 식별자 (UUID)
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

  /// 로컬 DB 저장을 위해 객체를 JSON 단일 맵 포맷으로 직렬화
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'type': type.name,
        'amount': amount,
        'reason': reason,
        'balanceAfter': balanceAfter,
      };

  /// JSON 단일 맵 포맷으로부터 도메인 객체로 역직렬화
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
