import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/point_record.dart';
import '../viewmodels/point_view_model.dart';
import '../utils/point_manager.dart';
import '../utils/app_theme.dart';

class EditTransactionScreen extends StatefulWidget {
  final PointRecord record;
  const EditTransactionScreen({super.key, required this.record});

  @override
  State<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late final TextEditingController _reasonCtrl;
  late String _amount;

  bool get _isIncome =>
      widget.record.type == TransactionType.income;
  final pm = PointManager();

  bool get _isValid {
    final v = double.tryParse(_amount) ?? 0;
    return v > 0 && _reasonCtrl.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _amount = widget.record.amount.toStringAsFixed(0);
    _reasonCtrl = TextEditingController(text: widget.record.reason);
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = double.tryParse(_amount) ?? 0;
    final reason = _reasonCtrl.text.trim();
    final vm = context.read<PointViewModel>();
    await vm.updateRecord(widget.record,
        newAmount: v, newReason: reason);
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isIncome ? Colors.green : Colors.red;
    final amountValue = double.tryParse(_amount) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('거래 수정'),
        backgroundColor: AppColors.background,
        leading: TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: const Text('취소'),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: accent,
                      size: 45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.record.type.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatDate(widget.record.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Amount section
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isIncome ? Icons.star_rounded : Icons.payments_rounded,
                        color: AppColors.textTertiary, size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isIncome ? '포인트' : '금액 (원)',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 34, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: _isIncome ? '포인트 입력' : '금액 입력',
                            hintStyle: const TextStyle(color: AppColors.textTertiary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.cardDarkElevated,
                          ),
                          controller: TextEditingController.fromValue(
                            TextEditingValue(
                              text: _amount,
                              selection: TextSelection.collapsed(
                                  offset: _amount.length),
                            ),
                          ),
                          onChanged: (v) => setState(() => _amount = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isIncome ? 'P' : '원',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (amountValue > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.sync_alt_rounded,
                            color: AppColors.blueAccent, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _isIncome
                              ? pm.formatKRW(pm.pointsToKRW(amountValue))
                              : pm.formatPoints(pm.krwToPoints(amountValue)),
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Reason section
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.chat_bubble_rounded,
                          color: AppColors.textTertiary, size: 18),
                      SizedBox(width: 6),
                      Text('사유',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonCtrl,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '무엇에 사용했나요?',
                      hintStyle: const TextStyle(color: AppColors.textTertiary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.cardDarkElevated,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Warning
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.orangeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.orangeAccent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('주의',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.orangeAccent)),
                        const SizedBox(height: 2),
                        const Text(
                          '금액을 수정하면 모든 잔액이 자동으로 재계산됩니다',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Save button
            _SaveButton(isValid: _isValid, onSave: _save),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.isValid, required this.onSave});
  final bool isValid;
  final VoidCallback onSave;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isValid ? (_) => setState(() => _scale = 0.96) : null,
      onTapUp: widget.isValid
          ? (_) {
              setState(() => _scale = 1.0);
              widget.onSave();
            }
          : null,
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isValid
                  ? [const Color(0xFF5856D6), AppColors.purpleAccent]
                  : [
                      AppColors.textTertiary.withValues(alpha: 0.5),
                      AppColors.textTertiary.withValues(alpha: 0.3)
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isValid
                ? [
                    BoxShadow(
                      color: AppColors.purpleAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('저장하기',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
