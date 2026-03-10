import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/point_record.dart';
import '../viewmodels/point_view_model.dart';
import '../utils/point_manager.dart';
import '../utils/app_theme.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionType transactionType;
  const TransactionFormScreen({super.key, required this.transactionType});

  @override
  State<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _reasonCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  final _reasonFocus = FocusNode();
  String _amount = '';

  bool get _isIncome => widget.transactionType == TransactionType.income;
  final pm = PointManager();

  bool get _isValid {
    final v = double.tryParse(_amount) ?? 0;
    return v > 0 && _reasonCtrl.text.trim().isNotEmpty;
  }

  void _increaseAmount() {
    final v = double.tryParse(_amount) ?? 0;
    final step = _isIncome ? 1.0 : 1000.0;
    setState(() => _amount = (v + step).toStringAsFixed(0));
    HapticFeedback.lightImpact();
  }

  void _decreaseAmount() {
    final v = double.tryParse(_amount) ?? 0;
    final step = _isIncome ? 1.0 : 1000.0;
    final newV = (v - step).clamp(0, double.infinity);
    setState(() => _amount = newV.toStringAsFixed(0));
    HapticFeedback.lightImpact();
  }

  Future<void> _save() async {
    final vm = context.read<PointViewModel>();
    final v = double.tryParse(_amount) ?? 0;
    final reason = _reasonCtrl.text.trim();

    if (_isIncome) {
      await vm.addPointIncome(v.toInt(), reason);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context);
    } else {
      final ok = await vm.addExpense(v, reason);
      if (!mounted) return;
      if (ok) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
      } else {
        HapticFeedback.heavyImpact();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('알림'),
            content: const Text('잔액이 부족합니다'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'))
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _amountFocus.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isIncome ? Colors.green : Colors.red;
    final amountValue = double.tryParse(_amount) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: AppColors.cardDark,
                title: Text(widget.transactionType.displayName),
                leading: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: const Text('취소'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Header icon
                    Center(
                      child: Container(
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
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        widget.transactionType.displayName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Amount section
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isIncome
                                    ? Icons.star_rounded
                                  : Icons.payments_rounded,
                                color: AppColors.textTertiary,
                                size: 18,
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
                              _CircleButton(
                                icon: Icons.remove_rounded,
                                color: Colors.red,
                                onTap: _decreaseAmount,
                              ),
                              Expanded(
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      IntrinsicWidth(
                                        child: TextField(
                                          focusNode: _amountFocus,
                                          keyboardType:
                                              TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 44,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: '0',
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.zero,
                                          ),
                                          onChanged: (v) =>
                                              setState(() => _amount = v),
                                          controller:
                                              TextEditingController.fromValue(
                                            TextEditingValue(
                                              text: _amount,
                                              selection:
                                                  TextSelection.collapsed(
                                                      offset:
                                                          _amount.length),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isIncome ? 'P' : '원',
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _CircleButton(
                                icon: Icons.add_rounded,
                                color: Colors.green,
                                onTap: _increaseAmount,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Quick buttons
                          _QuickButtons(
                            isIncome: _isIncome,
                            onSelect: (v) =>
                                setState(() => _amount = v),
                          ),
                          // Conversion hint
                          if (amountValue > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.sync_alt_rounded,
                                    color: AppColors.blueAccent, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _isIncome
                                      ? pm.formatKRW(pm.pointsToKRW(
                                          amountValue))
                                      : pm.formatPoints(
                                          pm.krwToPoints(amountValue)),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Reason section
                    _SectionCard(
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
                            focusNode: _reasonFocus,
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: _isIncome
                                  ? '어떻게 받았나요?'
                                  : '무엇에 사용했나요?',
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

                    // ── Balance info (expense only)
                    if (!_isIncome)
                      Consumer<PointViewModel>(
                        builder: (context, vm, child) => _SectionCard(
                          child: Row(
                            children: [
                              const Icon(Icons.credit_card_rounded,
                                  color: AppColors.greenAccent, size: 22),
                              const SizedBox(width: 8),
                              const Text('현재 잔액',
                                  style: TextStyle(color: AppColors.textSecondary)),
                              const Spacer(),
                              Text(
                                vm.formattedBalance,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.greenAccent),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!_isIncome) const SizedBox(height: 16),

                    // ── Save button
                    _SaveButton(
                      isValid: _isValid,
                      onSave: _save,
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Reusable widgets ───────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton(
      {required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 40),
    );
  }
}

class _QuickButtons extends StatelessWidget {
  const _QuickButtons(
      {required this.isIncome, required this.onSelect});

  final bool isIncome;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final items = isIncome
        ? [('1', Colors.blue), ('2', Colors.blue), ('3', Colors.blue), ('4', Colors.green)]
        : [('1000', Colors.orange), ('3000', Colors.orange), ('5000', Colors.red), ('10000', Colors.red)];

    final labels = isIncome
        ? ['1', '2', '3', '4']
        : ['1,000', '3,000', '5,000', '10,000'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('빠른 입력',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(height: 6),
        Row(
          children: List.generate(items.length, (i) {
            final (value, color) = items[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < items.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelect(value);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        labels[i],
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
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
                  : [AppColors.textTertiary.withValues(alpha: 0.5), AppColors.textTertiary.withValues(alpha: 0.3)],
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
