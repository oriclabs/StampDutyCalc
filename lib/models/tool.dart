import 'package:flutter/material.dart';

enum ToolCategory {
  buying('Buying'),
  finance('Finance'),
  ownership('Ownership'),
  compare('Compare');

  final String label;
  const ToolCategory(this.label);
}

class Tool {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final ToolCategory category;
  final bool needsCountry;

  const Tool({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.needsCountry = false,
  });
}

/// All available tools in the app
class Tools {
  static const stampDuty = Tool(
    id: 'stamp_duty',
    name: 'Stamp Duty',
    description: 'Calculate vehicle stamp duty',
    icon: Icons.receipt_long,
    category: ToolCategory.buying,
    needsCountry: true,
  );

  static const onRoad = Tool(
    id: 'on_road',
    name: 'On-Road Cost',
    description: 'Total drive-away price',
    icon: Icons.directions_car,
    category: ToolCategory.buying,
    needsCountry: true,
  );

  static const compareStates = Tool(
    id: 'compare_states',
    name: 'Compare',
    description: 'Find the cheapest state',
    icon: Icons.compare_arrows,
    category: ToolCategory.compare,
    needsCountry: true,
  );

  static const lct = Tool(
    id: 'lct',
    name: 'LCT',
    description: 'LCT for high-end vehicles',
    icon: Icons.diamond,
    category: ToolCategory.buying,
    needsCountry: true,
  );

  static const loan = Tool(
    id: 'loan',
    name: 'Car Loan',
    description: 'Monthly repayments',
    icon: Icons.account_balance,
    category: ToolCategory.finance,
  );

  static const novatedLease = Tool(
    id: 'novated_lease',
    name: 'Novated Lease',
    description: 'Salary packaging savings',
    icon: Icons.business_center,
    category: ToolCategory.finance,
  );

  static const tradeIn = Tool(
    id: 'trade_in',
    name: 'Trade-in',
    description: 'Net duty after trade-in',
    icon: Icons.swap_horiz,
    category: ToolCategory.finance,
    needsCountry: true,
  );

  static const fuelCost = Tool(
    id: 'fuel_cost',
    name: 'Fuel Cost',
    description: 'Daily, weekly, yearly fuel',
    icon: Icons.local_gas_station,
    category: ToolCategory.ownership,
  );

  static const tco = Tool(
    id: 'tco',
    name: '5-Yr Cost',
    description: 'Total cost of ownership',
    icon: Icons.assessment,
    category: ToolCategory.ownership,
  );

  static const insurance = Tool(
    id: 'insurance',
    name: 'Insurance',
    description: 'CTP + comprehensive',
    icon: Icons.shield,
    category: ToolCategory.ownership,
    needsCountry: true,
  );

  static const service = Tool(
    id: 'service',
    name: 'Service Cost',
    description: 'Yearly service estimate',
    icon: Icons.build,
    category: ToolCategory.ownership,
  );

  static const depreciation = Tool(
    id: 'depreciation',
    name: 'Depreciation',
    description: 'Resale value over time',
    icon: Icons.trending_down,
    category: ToolCategory.ownership,
  );

  static const evVsIce = Tool(
    id: 'ev_vs_ice',
    name: 'EV vs Petrol',
    description: '5-year cost comparison',
    icon: Icons.electric_car,
    category: ToolCategory.compare,
  );

  static const gst = Tool(
    id: 'gst',
    name: 'GST',
    description: 'Add or remove GST',
    icon: Icons.percent,
    category: ToolCategory.finance,
    needsCountry: true,
  );

  /// All tools, ordered by display priority
  static const List<Tool> all = [
    stampDuty,
    onRoad,
    compareStates,
    lct,
    loan,
    novatedLease,
    tradeIn,
    gst,
    fuelCost,
    tco,
    insurance,
    service,
    depreciation,
    evVsIce,
  ];

  static List<Tool> byCategory(ToolCategory cat) =>
      all.where((t) => t.category == cat).toList();

  static Tool? byId(String id) =>
      all.where((t) => t.id == id).firstOrNull;
}
