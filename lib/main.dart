import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/calculator_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_mode_provider.dart';
import 'screens/app_shell.dart';
import 'utils/theme.dart';

void main() {
  runApp(const StampDutyApp());
}

class StampDutyApp extends StatelessWidget {
  const StampDutyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalculatorProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => UserModeProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Vehicle Calculator',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
