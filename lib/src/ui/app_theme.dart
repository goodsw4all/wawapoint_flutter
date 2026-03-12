import 'package:flutter/material.dart';

/// WaWa Point 디자인 시스템 색상 및 그라데이션
class AppColors {
  AppColors._();

  // ── 배경 색상
  static const Color background = Color(0xFF000000);
  static const Color cardDark = Color(0xFF1C1C1E);
  static const Color cardDarkElevated = Color(0xFF2C2C2E);
  static const Color cardDarkSubtle = Color(0xFF141414);

  // ── 강조 색상
  static const Color purpleAccent = Color(0xFFBB44FF);
  static const Color magentaAccent = Color(0xFFDD22CC);
  static const Color blueAccent = Color(0xFF5AC8FA);
  static const Color greenAccent = Color(0xFF34C759);
  static const Color redAccent = Color(0xFFFF3B30);
  static const Color orangeAccent = Color(0xFFFF9500);
  static const Color amberStar = Color(0xFFFFCC00);

  // ── 텍스트 색상
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF636366);

  // ── 구분선
  static const Color divider = Color(0xFF38383A);
}

/// 앱 전체에서 사용되는 그라데이션 정의
class AppGradients {
  AppGradients._();

  static const LinearGradient balanceText = LinearGradient(
    colors: [Color(0xFFDD22CC), Color(0xFFBB44FF)],
  );

  static const LinearGradient incomeButton = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseButton = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient saveButton = LinearGradient(
    colors: [Color(0xFF5856D6), Color(0xFFBB44FF)],
  );

  static const LinearGradient purpleGlow = LinearGradient(
    colors: [Color(0xFF1A0A2E), Color(0xFF0D0D0D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// 앱 위젯들의 데코레이션(BoxDecoration) 모음
class AppDecorations {
  AppDecorations._();

  /// 기본 어두운 카드 스타일
  static BoxDecoration card(BuildContext context) => BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      );

  /// 약간 솟아오른 듯한(Elevated) 카드 스타일
  static BoxDecoration cardElevated(BuildContext context) => BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(20),
      );

  /// 대시보드 메인 잔액 표시 카드 전용 스타일
  static BoxDecoration balanceCard() => BoxDecoration(
        color: AppColors.cardDarkSubtle,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.purpleAccent.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleAccent.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      );

  /// 작고 둥근 필(Pill) 스타일 위젯 배경
  static BoxDecoration pill() => BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(20),
      );
}
