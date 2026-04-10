import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool.dart';
import '../providers/calculator_provider.dart';
import 'calculator_screen.dart';
import 'compare_screen.dart';
import 'tools/loan_screen.dart';
import 'tools/fuel_cost_screen.dart';
import 'tools/gst_screen.dart';
import 'tools/lct_screen.dart';
import 'tools/novated_lease_screen.dart';
import 'tools/trade_in_screen.dart';
import 'tools/insurance_screen.dart';
import 'tools/tco_screen.dart';
import 'tools/ev_vs_ice_screen.dart';

/// Routes a tool ID to its calculator screen.
/// For country-dependent tools, sets the calculator mode appropriately.
class ToolRouter extends StatelessWidget {
  final Tool tool;

  const ToolRouter({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    // Set mode for stamp duty / on-road
    if (tool.id == Tools.stampDuty.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CalculatorProvider>().setMode(CalculatorMode.stampDuty);
      });
      return const CalculatorScreen();
    }
    if (tool.id == Tools.onRoad.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CalculatorProvider>().setMode(CalculatorMode.onRoad);
      });
      return const CalculatorScreen();
    }
    if (tool.id == Tools.compareStates.id) return const CompareScreen();
    if (tool.id == Tools.lct.id) return const LctScreen();
    if (tool.id == Tools.loan.id) return const LoanScreen();
    if (tool.id == Tools.fuelCost.id) return const FuelCostScreen();
    if (tool.id == Tools.gst.id) return const GstScreen();
    if (tool.id == Tools.novatedLease.id) return const NovatedLeaseScreen();
    if (tool.id == Tools.tradeIn.id) return const TradeInScreen();
    if (tool.id == Tools.insurance.id) return const InsuranceScreen();
    if (tool.id == Tools.tco.id) return const TcoScreen();
    if (tool.id == Tools.evVsIce.id) return const EvVsIceScreen();

    return Scaffold(
      appBar: AppBar(title: Text(tool.name)),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
