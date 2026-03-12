import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/point_record.dart';
import '../../providers/point_view_model.dart';
import '../../providers/history_view_model.dart';
import '../../data/point_manager.dart';
import '../app_theme.dart';
import 'dashboard_screen.dart';
import 'edit_transaction_screen.dart';


/// 앱의 모든 거래 기록을 보여주고 통계를 제공하는 화면입니다.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // HistoryViewModel을 화면 범위의 Provider로 주입
    return ChangeNotifierProvider(
      create: (_) => HistoryViewModel(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  void _showDeleteConfirm(BuildContext context, PointViewModel vm, PointRecord record) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('정말 삭제하시겠어요?'),
        content: Text('「${record.reason}」 기록이 삭제됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              vm.deleteRecord(record);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _validateData(BuildContext context, PointViewModel vm) {
    final issues = vm.validateBalances();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('데이터 검증 결과'),
        content: Text(issues.isEmpty
            ? '✅ 모든 잔액이 정확합니다!'
            : '${issues.length}개의 문제 발견:\n\n${issues.join('\n')}'),
        actions: [
          if (issues.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                vm.recalculateAllBalances();
                HapticFeedback.mediumImpact();
              },
              child: const Text('재계산하기'),
            ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 전역 상태인 PointViewModel과 화면 상태인 HistoryViewModel을 함께 구독
    return Consumer2<PointViewModel, HistoryViewModel>(
      builder: (context, pointVm, historyVm, _) {
        final filtered = historyVm.getFilteredRecords(pointVm.records);
        final totalIncome = historyVm.calculateTotalIncome(pointVm.records);
        final totalExpense = historyVm.calculateTotalExpense(pointVm.records);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: const Text('전체 기록'),
                backgroundColor: AppColors.background,
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'recalc',
                        child: ListTile(
                          leading: Icon(Icons.sync_rounded),
                          title: Text('잔액 재계산'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'validate',
                        child: ListTile(
                          leading: Icon(Icons.verified_rounded),
                          title: Text('데이터 검증'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'recalc') {
                        pointVm.recalculateAllBalances();
                        HapticFeedback.mediumImpact();
                      } else {
                        _validateData(context, pointVm);
                      }
                    },
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _StatsCard(
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      count: pointVm.records.length,
                    ),
                    const SizedBox(height: 16),
                    _ChartSection(
                      records: pointVm.records,
                      filtered: filtered,
                      selectedPeriod: historyVm.selectedPeriod,
                      onPeriodChanged: historyVm.setPeriod,
                    ),
                    const SizedBox(height: 16),
                    _TransactionList(
                      records: pointVm.records,
                      onEdit: (record) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditTransactionScreen(record: record),
                        ),
                      ),
                      onDelete: (record) => _showDeleteConfirm(context, pointVm, record),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────── 통계 카드 위젯 ───────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.totalIncome,
    required this.totalExpense,
    required this.count,
  });

  final double totalIncome;
  final double totalExpense;
  final int count;

  @override
  Widget build(BuildContext context) {
    final pm = PointManager();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    title: '총 수입',
                    value: pm.formatKRW(totalIncome),
                    icon: Icons.arrow_downward_rounded,
                    color: AppColors.greenAccent,
                  ),
                ),
                VerticalDivider(width: 1, color: AppColors.divider),
                Expanded(
                  child: _StatItem(
                    title: '총 지출',
                    value: pm.formatKRW(totalExpense),
                    icon: Icons.arrow_upward_rounded,
                    color: AppColors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24, color: AppColors.divider),
          Row(
            children: [
              const Icon(Icons.list_alt_rounded, color: AppColors.blueAccent, size: 20),
              const SizedBox(width: 8),
              const Text('전체 거래',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              Text('$count건',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.blueAccent)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
      ],
    );
  }
}

// ─────────────────────── 차트 섹션 (지출 추이) ───────────────────────

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.records,
    required this.filtered,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final List<PointRecord> records;
  final List<PointRecord> filtered;
  final TimePeriod selectedPeriod;
  final void Function(TimePeriod) onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    // ViewModel의 그룹화 로직을 사용하여 차트 데이터 준비
    final historyVm = context.read<HistoryViewModel>();
    final grouped = historyVm.groupExpensesByDay(filtered);
    final spots = grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.purpleAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                '지출 추이',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<TimePeriod>(
            segments: TimePeriod.values
                .map(
                  (p) => ButtonSegment(value: p, label: Text(p.label)),
                )
                .toList(),
            selected: {selectedPeriod},
            onSelectionChanged: (s) => onPeriodChanged(s.first),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: spots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bar_chart_rounded,
                            size: 50, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        const Text('데이터가 없습니다', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      barGroups: spots.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.value,
                              gradient: const LinearGradient(
                                colors: [Colors.orange, Colors.red],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            getTitlesWidget: (v, _) => Text(
                              NumberFormat('#,###').format(v.toInt()),
                              style:
                                  const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= spots.length) {
                                return const SizedBox();
                              }
                              return Text(
                                DateFormat('M/d').format(spots[idx].key),
                                style:
                                    const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: AppColors.divider,
                          strokeWidth: 0.5,
                        ),
                        getDrawingVerticalLine: (v) => FlLine(
                          color: AppColors.divider,
                          strokeWidth: 0.5,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── 전체 거래 내역 리스트 ───────────────────────

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.records,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PointRecord> records;
  final void Function(PointRecord) onEdit;
  final void Function(PointRecord) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.blueAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              '전체 기록',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 60),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.inbox_rounded, size: 50, color: AppColors.textTertiary),
                SizedBox(height: 12),
                Text('아직 기록이 없어요', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          )
        else
          ...records.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: Key(r.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  onDelete(r);
                  return false;
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_rounded, color: AppColors.redAccent, size: 24),
                ),
                child: GestureDetector(
                  onLongPress: () => _showMenu(context, r),
                  child: TransactionTile(record: r),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showMenu(BuildContext context, PointRecord r) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('수정'),
              onTap: () {
                Navigator.pop(context);
                onEdit(r);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete(r);
              },
            ),
          ],
        ),
      ),
    );
  }
}
