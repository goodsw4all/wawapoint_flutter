import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'src/providers/point_view_model.dart';
import 'src/providers/backup_view_model.dart';
import 'src/providers/settings_view_model.dart';
import 'src/ui/screens/dashboard_screen.dart';
import 'src/ui/app_theme.dart';

/// 앱의 진입점 (Entry Point)
/// 
/// `main` 함수에서 Flutter 바인딩을 초기화하고 전역 상태(Provider)를 설정하여
/// `WaWaPointApp` 루트 위젯을 실행합니다.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
    ),
  );
  runApp(const WaWaPointApp());
}

/// WaWa Point 최상위 애플리케이션 위젯
/// 
/// `MultiProvider`를 통해 전역 ViewModel들을 주입하고, 앱의 글로벌 테마 및 색상
/// 팔레트를 정의합니다.
class WaWaPointApp extends StatelessWidget {
  const WaWaPointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PointViewModel()..loadRecords(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel()..load(),
        ),
        ChangeNotifierProxyProvider<PointViewModel, BackupViewModel>(
          create: (ctx) => BackupViewModel(ctx.read<PointViewModel>()),
          update: (_, pointVM, prev) => prev ?? BackupViewModel(pointVM),
        ),
      ],
      child: MaterialApp(
        title: 'WaWa Point',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: const ColorScheme.dark(
            surface: AppColors.cardDark,
            onSurface: AppColors.textPrimary,
            primary: AppColors.purpleAccent,
            onPrimary: Colors.white,
            secondary: AppColors.blueAccent,
            surfaceContainerHighest: AppColors.cardDarkElevated,
            surfaceContainerLow: AppColors.cardDark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: AppColors.textPrimary),
          ),
          dividerTheme: const DividerThemeData(
            color: AppColors.divider,
            thickness: 0.5,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.cardDarkElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: AppColors.cardDarkElevated,
            contentTextStyle: const TextStyle(color: AppColors.textPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: AppColors.cardDark,
            modalBackgroundColor: AppColors.cardDark,
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(color: AppColors.textPrimary),
            displayMedium: TextStyle(color: AppColors.textPrimary),
            displaySmall: TextStyle(color: AppColors.textPrimary),
            headlineLarge: TextStyle(color: AppColors.textPrimary),
            headlineMedium: TextStyle(color: AppColors.textPrimary),
            headlineSmall: TextStyle(color: AppColors.textPrimary),
            titleLarge: TextStyle(color: AppColors.textPrimary),
            titleMedium: TextStyle(color: AppColors.textPrimary),
            titleSmall: TextStyle(color: AppColors.textPrimary),
            bodyLarge: TextStyle(color: AppColors.textPrimary),
            bodyMedium: TextStyle(color: AppColors.textPrimary),
            bodySmall: TextStyle(color: AppColors.textSecondary),
            labelLarge: TextStyle(color: AppColors.textPrimary),
            labelMedium: TextStyle(color: AppColors.textSecondary),
            labelSmall: TextStyle(color: AppColors.textTertiary),
          ),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
