import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/point_record.dart';
import '../../data/point_manager.dart';
import '../app_theme.dart';

/// 거래 내역의 상세 정보를 보여주는 프리미엄 팝업 카드 다이얼로그입니다.
///
/// BackdropFilter를 활용해 뒷배경에 글래스모피즘 블러 처리를 적용하고,
/// 거래 분류에 적합한 포인트/원화 포맷을 사용해 세부 거래 내역을 가독성 높게 표시합니다.
class TransactionDetailDialog extends StatelessWidget {
  /// 상세 정보를 표시할 거래 기록 데이터 객체
  final PointRecord record;

  /// '수정' 버튼 클릭 시 트리거할 콜백
  final VoidCallback? onEdit;

  /// '삭제' 버튼 클릭 시 트리거할 콜백
  final VoidCallback? onDelete;

  const TransactionDetailDialog({
    super.key,
    required this.record,
    this.onEdit,
    this.onDelete,
  });

  /// 다이얼로그를 화면에 띄우는 정적 헬퍼 함수
  ///
  /// [showGeneralDialog]를 사용하여 등장할 때 바운스하는 Scale & Fade 트랜지션 애니메이션을 적용합니다.
  static Future<void> show(
    BuildContext context, {
    required PointRecord record,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Detail Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return TransactionDetailDialog(
          record: record,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutBack,
          ).value,
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = record.type == TransactionType.income;
    final accentColor = isIncome ? AppColors.greenAccent : AppColors.redAccent;
    final pm = PointManager();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.cardDark.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.purpleAccent.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.purpleAccent.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 상단 헤더 영역 (닫기 버튼)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 12),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                
                // ── 본문 스크롤 가능한 상세 정보 영역
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 거래 유형 아이콘 데코레이션
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: accentColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 거래 구분 텍스트
                        Text(
                          record.type.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 거래 금액 강조 표시
                        Text(
                          isIncome
                              ? '+${pm.formatPoints(record.amount)}'
                              : '-${pm.formatKRW(record.amount)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 28),
                        const Divider(color: AppColors.divider, height: 1),
                        const SizedBox(height: 20),
                        
                        // ── 상세 필드 리스트
                        _buildDetailRow('상세 설명 / 사유', record.reason, isLongText: true),
                        const SizedBox(height: 16),
                        _buildDetailRow('거래 일시', DateFormat('yyyy년 M월 d일 HH:mm:ss').format(record.date)),
                        const SizedBox(height: 16),
                        _buildDetailRow('정산 후 잔액', pm.formatKRW(record.balanceAfter)),
                      ],
                    ),
                  ),
                ),
                
                // ── 하단 액션 버튼 바
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.cardDarkElevated,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 수정 액션 버튼
                      if (onEdit != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onEdit!();
                            },
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('수정', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.divider),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // 삭제 액션 버튼
                      if (onDelete != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onDelete!();
                            },
                            icon: const Icon(Icons.delete_rounded, size: 16),
                            label: const Text('삭제', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.redAccent,
                              side: BorderSide(color: AppColors.redAccent.withValues(alpha: 0.2)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // 확인/닫기 버튼
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 단일 정보 쌍(Label-Value)을 카드 형태의 필드로 생성하는 메서드
  Widget _buildDetailRow(String label, String value, {bool isLongText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDarkSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5), width: 1),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isLongText ? 14 : 13,
              fontWeight: isLongText ? FontWeight.w500 : FontWeight.bold,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
