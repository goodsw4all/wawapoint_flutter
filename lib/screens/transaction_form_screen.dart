import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/point_record.dart';
import '../viewmodels/point_view_model.dart';
import '../viewmodels/transaction_form_view_model.dart';
import '../utils/point_manager.dart';
import '../utils/app_theme.dart';

/// 거래(수입/지출) 내역을 입력받는 화면입니다.
class TransactionFormScreen extends StatelessWidget {
  final TransactionType transactionType;

  const TransactionFormScreen({super.key, required this.transactionType});

  @override
  Widget build(BuildContext context) {
    // TransactionFormViewModel을 화면 범위의 Provider로 주입
    return ChangeNotifierProvider(
      create: (_) => TransactionFormViewModel(
        transactionType: transactionType,
        pointViewModel: context.read<PointViewModel>(),
      ),
      child: const _TransactionFormView(),
    );
  }
}

class _TransactionFormView extends StatefulWidget {
  const _TransactionFormView();

  @override
  State<_TransactionFormView> createState() => _TransactionFormViewState();
}

class _TransactionFormViewState extends State<_TransactionFormView> {
  final _reasonCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  final _reasonFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // 초기 사유 값 동기화 (필요 시)
    _reasonCtrl.addListener(() {
      context.read<TransactionFormViewModel>().setReason(_reasonCtrl.text);
    });
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _amountFocus.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSave(TransactionFormViewModel vm) async {
    final success = await vm.save();
    if (!mounted) return;

    if (success) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    } else if (!vm.isIncome) {
      HapticFeedback.heavyImpact();
      _showInsufficientBalanceDialog();
    }
  }

  void _showInsufficientBalanceDialog() {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionFormViewModel>(
      builder: (context, vm, _) {
        final accent = vm.isIncome ? Colors.green : Colors.red;

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
                    title: Text(vm.transactionType.displayName),
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
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              vm.isIncome
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
                            vm.transactionType.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    vm.isIncome
                                        ? Icons.star_rounded
                                        : Icons.payments_rounded,
                                    color: AppColors.textTertiary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    vm.isIncome ? '포인트' : '금액 (원)',
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
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      vm.decreaseAmount();
                                    },
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
                                              onChanged: vm.setAmount,
                                              controller:
                                                  TextEditingController.fromValue(
                                                TextEditingValue(
                                                  text: vm.amount,
                                                  selection:
                                                      TextSelection.collapsed(
                                                          offset:
                                                              vm.amount.length),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            vm.isIncome ? 'P' : '원',
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
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      vm.increaseAmount();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _QuickButtons(
                                isIncome: vm.isIncome,
                                onSelect: vm.setAmount,
                              ),
                              if (vm.conversionHint.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.sync_alt_rounded,
                                        color: AppColors.blueAccent, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      vm.conversionHint,
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
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.chat_bubble_rounded,
                                      color: AppColors.textTertiary, size: 18),
                                  const SizedBox(width: 6),
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
                                decoration: InputDecoration(
                                  hintText: vm.isIncome
                                      ? '어떻게 받았나요?'
                                      : '무엇에 사용했나요?',
                                  hintStyle: const TextStyle(
                                      color: AppColors.textTertiary),
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
                        if (!vm.isIncome)
                          _SectionCard(
                            child: Row(
                              children: [
                                const Icon(Icons.credit_card_rounded,
                                    color: AppColors.greenAccent, size: 22),
                                const SizedBox(width: 8),
                                const Text('현재 잔액',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                                const Spacer(),
                                Text(
                                  vm.pointViewModel.formattedBalance,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.greenAccent),
                                ),
                              ],
                            ),
                          ),
                        if (!vm.isIncome) const SizedBox(height: 16),
                        _SaveButton(
                          isValid: vm.isValid,
                          onSave: () => _handleSave(vm),
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
      },
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
  const _QuickButtons({required this.isIncome, required this.onSelect});

  final bool isIncome;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final items = isIncome
        ? [
            ('1', Colors.blue),
            ('2', Colors.blue),
            ('3', Colors.blue),
            ('4', Colors.green)
          ]
        : [
            ('1000', Colors.orange),
            ('3000', Colors.orange),
            ('5000', Colors.red),
            ('10000', Colors.red)
          ];

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
                            color: Colors.white, fontWeight: FontWeight.bold),
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
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
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
