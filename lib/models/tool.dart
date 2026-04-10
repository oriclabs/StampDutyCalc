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
  /// Country codes where this tool is available.
  /// null = available in all countries
  final List<String>? availableIn;

  const Tool({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.needsCountry = false,
    this.availableIn,
  });

  bool isAvailableIn(String? countryCode) {
    if (countryCode == null) {
      // Before a country is selected, only show country-independent tools
      return !needsCountry && availableIn == null;
    }
    if (availableIn == null) return true;
    return availableIn!.contains(countryCode);
  }
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
    availableIn: ['AU'], // NZ has no stamp duty
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
    availableIn: ['AU'], // NZ has only 1 region
  );

  static const lct = Tool(
    id: 'lct',
    name: 'LCT',
    description: 'LCT for high-end vehicles',
    icon: Icons.diamond,
    category: ToolCategory.buying,
    needsCountry: true,
    availableIn: ['AU'], // AU-only tax
  );

  static const novatedLease = Tool(
    id: 'novated_lease',
    name: 'Novated Lease',
    description: 'Salary packaging savings',
    icon: Icons.business_center,
    category: ToolCategory.finance,
    availableIn: ['AU'], // AU-specific FBT laws
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
    description: 'Get free quotes',
    icon: Icons.shield,
    category: ToolCategory.ownership,
  );

  static const evVsIce = Tool(
    id: 'ev_vs_ice',
    name: 'EV vs Petrol',
    description: '5-year cost comparison',
    icon: Icons.electric_car,
    category: ToolCategory.compare,
  );

  /// All tools, ordered by display priority
  static const List<Tool> all = [
    stampDuty,
    onRoad,
    compareStates,
    lct,
    novatedLease,
    fuelCost,
    tco,
    insurance,
    evVsIce,
  ];

  static List<Tool> byCategory(ToolCategory cat, {String? countryCode}) =>
      all
          .where((t) => t.category == cat && t.isAvailableIn(countryCode))
          .toList();

  static List<Tool> availableFor(String? countryCode) =>
      all.where((t) => t.isAvailableIn(countryCode)).toList();

  static Tool? byId(String id) =>
      all.where((t) => t.id == id).firstOrNull;
}
