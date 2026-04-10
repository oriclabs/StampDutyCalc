import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/calculator_provider.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() {
  runApp(const StampDutyApp());
}

class StampDutyApp extends StatelessWidget {
  const StampDutyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalculatorProvider()..init(),
      child: MaterialApp(
        title: 'Vehicle Stamp Duty Calculator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
