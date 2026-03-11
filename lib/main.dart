import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'src/providers/point_view_model.dart';
import 'src/providers/backup_view_model.dart';
import 'src/providers/settings_view_model.dart';
import 'src/ui/screens/dashboard_screen.dart';
import 'src/ui/app_theme.dart';

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
