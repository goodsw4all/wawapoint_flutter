import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/point_record.dart';
import '../../providers/point_view_model.dart';
import '../../providers/dashboard_view_model.dart';
import '../../data/point_manager.dart';
import '../app_theme.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'transaction_form_screen.dart';

/// 앱의 메인 화면으로, 잔액 확인 및 주요 기능(수입/지출 입력)에 접근할 수 있습니다.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DashboardViewModel을 화면 범위의 Provider로 주입
    return ChangeNotifierProvider(
      create: (_) =>
          DashboardViewModel(pointViewModel: context.read<PointViewModel>()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  void _openForm(BuildContext context, TransactionType type) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFormScreen(transactionType: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PointViewModel, DashboardViewModel>(
      builder: (context, pointVm, dashboardVm, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Slim custom AppBar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                    child: Row(
                      children: [
                        const Spacer(),
                        const Text(
                          'WaWa Point',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.cardDarkElevated,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.settings_rounded,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      _BalanceCard(
                        scale: dashboardVm.balanceScale,
                        vm: pointVm,
                      ),
                      const SizedBox(height: 24),
                      _ActionButtons(onTap: (type) => _openForm(context, type)),
                      const SizedBox(height: 28),
                      _RecentTransactions(vm: pointVm),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────── Balance Card ───────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.scale, required this.vm});
  final double scale;
  final PointViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: AppDecorations.balanceCard(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.monetization_on_rounded,
                color: AppColors.greenAccent.withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                '현재 잔액',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppGradients.balanceText.createShader(bounds),
              child: Text(
                vm.formattedBalance,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardDarkElevated,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.amberStar,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  vm.formattedPoints,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Action Buttons ───────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onTap});
  final void Function(TransactionType) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: '포인트 받기',
            icon: Icons.arrow_downward_rounded,
            gradient: AppGradients.incomeButton,
            iconColor: AppColors.greenAccent,
            shadowColor: AppColors.greenAccent.withValues(alpha: 0.3),
            onTap: () => onTap(TransactionType.income),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionButton(
            label: '사용하기',
            icon: Icons.arrow_upward_rounded,
            gradient: AppGradients.expenseButton,
            iconColor: AppColors.redAccent,
            shadowColor: AppColors.redAccent.withValues(alpha: 0.3),
            onTap: () => onTap(TransactionType.expense),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.iconColor,
    required this.shadowColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color iconColor;
  final Color shadowColor;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60, // 시각적 확인을 위해 대폭 확대
                height: 60,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 28,
                  weight: 10,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Recent Transactions ───────────────────────

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.vm});
  final PointViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.access_time_filled_rounded,
              color: AppColors.blueAccent,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              '최근 기록',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '전체보기',
                    style: TextStyle(
                      color: AppColors.blueAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.blueAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (vm.records.isEmpty)
          _EmptyState()
        else
          ...vm.records
              .take(3)
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TransactionTile(record: r),
                ),
              ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, size: 50, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text(
            '아직 기록이 없어요',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '포인트를 받거나 사용해보세요!',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Reusable Transaction Tile ───────────────────────

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.record});
  final PointRecord record;

  @override
  Widget build(BuildContext context) {
    final isIncome = record.type == TransactionType.income;
    final accent = isIncome ? AppColors.greenAccent : AppColors.redAccent;
    final pm = PointManager();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // ── Colored circle icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // ── Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.reason,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMMM d, yyyy').format(record.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Amount + balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isIncome
                    ? '+${pm.formatPoints(record.amount)}'
                    : '-${pm.formatKRW(record.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: accent,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cardDarkElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '잔액: ${pm.formatKRW(record.balanceAfter)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
