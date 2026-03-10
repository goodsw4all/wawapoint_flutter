import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../viewmodels/point_view_model.dart';
import '../viewmodels/backup_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _rateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settingsVM = context.read<SettingsViewModel>();
    _rateCtrl.text = settingsVM.formattedRate;
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final rate = double.tryParse(_rateCtrl.text);
    if (rate == null || rate <= 0) return;
    final settingsVM = context.read<SettingsViewModel>();
    await settingsVM.setRate(rate);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    _showSnack('설정이 저장되었습니다');
  }

  Future<void> _backup(BackupViewModel backupVM) async {
    try {
      final file = await backupVM.exportBackup();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      final result = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('백업 완료'),
          content: const Text('백업 파일이 생성되었습니다'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('확인')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('공유하기')),
          ],
        ),
      );
      if (result == true) {
        await Share.shareXFiles([XFile(file.path)]);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _restore(BackupViewModel backupVM) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.first.path;
    if (path == null) return;

    try {
      final content = await File(path).readAsString();
      if (!mounted) return;
      final count = await backupVM.importBackup(content);
      HapticFeedback.mediumImpact();
      if (mounted) _showSnack('$count개의 거래를 복원했습니다');
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) _showError('올바른 백업 파일이 아닙니다');
    }
  }

  Future<void> _recalculate(PointViewModel pointVM) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('잔액 재계산'),
        content: const Text(
            '모든 거래의 잔액을 처음부터 다시 계산합니다. 이 작업은 데이터 불일치 문제를 해결할 수 있습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('재계산')),
        ],
      ),
    );
    if (confirmed != true) return;
    await pointVM.recalculateAllBalances();
    HapticFeedback.mediumImpact();
    if (mounted) _showSnack('잔액 재계산 완료');
  }

  Future<void> _deleteAll(BackupViewModel backupVM) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('모든 데이터 삭제'),
        content: const Text(
            '모든 포인트 기록이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await backupVM.clearAllData();
    HapticFeedback.heavyImpact();
    if (mounted) _showSnack('모든 데이터가 삭제되었습니다');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('오류'),
        content: Text(msg),
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
    final pointVM = context.watch<PointViewModel>();
    final backupVM = context.read<BackupViewModel>();
    return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: const Text('설정'),
                  backgroundColor: AppColors.background,
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.purpleAccent.withValues(alpha: 0.2),
                                    AppColors.blueAccent.withValues(alpha: 0.1)
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.settings_rounded,
                                  size: 50, color: AppColors.purpleAccent),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '설정',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Point settings
                      _SectionHeader(
                          icon: Icons.star_rounded,
                          label: '포인트 설정',
                          color: AppColors.orangeAccent),
                      const SizedBox(height: 8),
                      _SettingsCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('1 포인트 가치',
                                      style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                SizedBox(
                                  width: 100,
                                  child: TextField(
                                    controller: _rateCtrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.cardDarkElevated,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('원',
                                    style:
                                        TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.info_rounded,
                                      color: AppColors.blueAccent, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '1 포인트 = ${_rateCtrl.text}원으로 환산됩니다',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Backup
                      _SectionHeader(
                          icon: Icons.storage_rounded,
                          label: '백업 및 복원',
                          color: AppColors.purpleAccent),
                      const SizedBox(height: 8),
                      _SettingsCard(
                        child: Column(
                          children: [
                            _ActionRow(
                              icon: Icons.upload_rounded,
                              color: AppColors.purpleAccent,
                              title: '백업하기',
                              subtitle: '모든 데이터를 파일로 저장합니다',
                              onTap: () => _backup(backupVM),
                            ),
                            const Divider(height: 16, color: AppColors.divider),
                            _ActionRow(
                              icon: Icons.download_rounded,
                              color: AppColors.greenAccent,
                              title: '복원하기',
                              subtitle: '백업 파일에서 데이터를 가져옵니다',
                              onTap: () => _restore(backupVM),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── App info
                      _SectionHeader(
                          icon: Icons.info_rounded,
                          label: '앱 정보',
                          color: AppColors.blueAccent),
                      const SizedBox(height: 8),
                      _SettingsCard(
                        child: Column(
                          children: [
                            _InfoRow(
                                icon: Icons.description_rounded,
                                title: '앱 버전',
                                value: '1.0.0',
                                color: AppColors.greenAccent),
                            const Divider(height: 16, color: AppColors.divider),
                            _InfoRow(
                                icon: Icons.person_rounded,
                                title: '개발자',
                                value: 'Myoungwoo Jang',
                                color: AppColors.purpleAccent),
                            const Divider(height: 16, color: AppColors.divider),
                            _InfoRow(
                                icon: Icons.calendar_today_rounded,
                                title: '출시일',
                                value: '2026년 1월',
                                color: AppColors.orangeAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Data management
                      _SectionHeader(
                          icon: Icons.dns_rounded,
                          label: '데이터 관리',
                          color: AppColors.blueAccent),
                      const SizedBox(height: 8),
                      _SettingsCard(
                        child: Column(
                          children: [
                            _ActionRow(
                              icon: Icons.sync_rounded,
                              color: AppColors.blueAccent,
                              title: '잔액 재계산',
                              subtitle: '모든 거래의 잔액을 다시 계산합니다',
                              onTap: () => _recalculate(pointVM),
                            ),
                            const Divider(height: 16, color: AppColors.divider),
                            _ActionRow(
                              icon: Icons.delete_rounded,
                              color: AppColors.redAccent,
                              title: '모든 데이터 삭제',
                              subtitle: '모든 포인트 기록이 삭제됩니다',
                              onTap: () => _deleteAll(backupVM),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Save button
                      _SaveButton(onSave: _saveSettings),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
        );
  }
}

// ─────────────────────── Helper widgets ───────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary, size: 18),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Text(title),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.onSave});
  final VoidCallback onSave;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onSave();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF5856D6), AppColors.purpleAccent]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.purpleAccent.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('설정 저장',
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
