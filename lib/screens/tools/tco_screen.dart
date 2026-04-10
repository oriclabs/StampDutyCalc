import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/tool.dart';
import '../../widgets/tool_scaffold.dart';
import '../../widgets/number_input.dart';
import '../../widgets/result_card.dart';

/// Vehicle category for service/depreciation defaults
/// Sources: RACV/NRMA published service costs, RedBook depreciation guide
enum VehicleCategory {
  smallPetrol(
    label: 'Small Petrol',
    yearlyService: 400,
    year1Drop: 0.20,
    laterDrop: 0.10,
  ),
  mediumPetrol(
    label: 'Medium Petrol',
    yearlyService: 550,
    year1Drop: 0.20,
    laterDrop: 0.10,
  ),
  largeOrDiesel(
    label: 'Large / Diesel',
    yearlyService: 700,
    year1Drop: 0.22,
    laterDrop: 0.11,
  ),
  luxury(
    label: 'Luxury / European',
    yearlyService: 1100,
    year1Drop: 0.25,
    laterDrop: 0.12,
  ),
  electric(
    label: 'Electric',
    yearlyService: 250,
    year1Drop: 0.20,
    laterDrop: 0.10,
  );

  final String label;
  final double yearlyService;
  final double year1Drop;
  final double laterDrop;

  const VehicleCategory({
    required this.label,
    required this.yearlyService,
    required this.year1Drop,
    required this.laterDrop,
  });

  /// Estimated value after [years] using year-1 drop then steady curve
  double valueAfter(double initial, int years) {
    if (years <= 0) return initial;
    var value = initial * (1 - year1Drop);
    for (var i = 1; i < years; i++) {
      value = value * (1 - laterDrop);
    }
    return value;
  }
}

class TcoScreen extends StatefulWidget {
  const TcoScreen({super.key});

  @override
  State<TcoScreen> createState() => _TcoScreenState();
}

class _TcoScreenState extends State<TcoScreen> {
  final _priceCtrl = TextEditingController(text: '40,000');
  final _kmCtrl = TextEditingController(text: '15,000');
  final _consumptionCtrl = TextEditingController(text: '8.0');
  final _fuelPriceCtrl = TextEditingController(text: '1.95');

  double _price = 40000;
  double _kmYear = 15000;
  double _consumption = 8.0;
  double _fuelPrice = 1.95;
  int _years = 5;
  VehicleCategory _category = VehicleCategory.mediumPetrol;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _kmCtrl.dispose();
    _consumptionCtrl.dispose();
    _fuelPriceCtrl.dispose();
    super.dispose();
  }

  Map<String, double> _calculate() {
    final stampDuty = _price * 0.04;
    final isEv = _category == VehicleCategory.electric;

    // EV uses electricity instead of fuel
    final yearlyEnergy = isEv
        ? (18 / 100) * _kmYear * 0.30 // 18kWh/100km @ $0.30/kWh
        : (_consumption / 100) * _kmYear * _fuelPrice;

    final yearlyRego = 800.0;
    // Insurance: ~3% of value + $620 CTP, scaled by category
    final insuranceMultiplier = switch (_category) {
      VehicleCategory.luxury => 1.6,
      VehicleCategory.largeOrDiesel => 1.1,
      VehicleCategory.electric => 1.2,
      _ => 1.0,
    };
    final yearlyInsurance =
        (_price * 0.030 + 620) * insuranceMultiplier;
    final yearlyService = _category.yearlyService;

    final totalEnergy = yearlyEnergy * _years;
    final totalRego = yearlyRego * _years;
    final totalInsurance = yearlyInsurance * _years;
    final totalService = yearlyService * _years;

    final residualValue = _category.valueAfter(_price, _years);
    final depreciation = _price - residualValue;

    return {
      'stampDuty': stampDuty,
      'energy': totalEnergy,
      'rego': totalRego,
      'insurance': totalInsurance,
      'service': totalService,
      'depreciation': depreciation,
      'residualValue': residualValue,
      'total': stampDuty +
          totalEnergy +
          totalRego +
          totalInsurance +
          totalService +
          depreciation,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final result = _calculate();
    final isEv = _category == VehicleCategory.electric;

    return ToolScaffold(
      toolId: Tools.tco.id,
      title: Tools.tco.name,
      icon: Tools.tco.icon,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vehicle category
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle Category',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: VehicleCategory.values.map((cat) {
                      return ChoiceChip(
                        label: Text(cat.label),
                        selected: _category == cat,
                        onSelected: (_) => setState(() => _category = cat),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            NumberInput(
              controller: _priceCtrl,
              label: 'Vehicle Price',
              prefix: '\$ ',
              currencyFormat: true,
              onChanged: (v) => setState(() => _price = v ?? 0),
            ),
            const SizedBox(height: 12),
            NumberInput(
              controller: _kmCtrl,
              label: 'Annual km',
              suffix: 'km',
              currencyFormat: true,
              onChanged: (v) => setState(() => _kmYear = v ?? 0),
            ),
            if (!isEv) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: NumberInput(
                      controller: _consumptionCtrl,
                      label: 'Fuel L/100km',
                      onChanged: (v) =>
                          setState(() => _consumption = v ?? 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NumberInput(
                      controller: _fuelPriceCtrl,
                      label: 'Fuel \$/L',
                      onChanged: (v) => setState(() => _fuelPrice = v ?? 0),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Period',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [3, 5, 7, 10].map((y) {
                      return ChoiceChip(
                        label: Text('$y years'),
                        selected: _years == y,
                        onSelected: (_) => setState(() => _years = y),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ResultCard(
              label: '$_years-Year Total Cost',
              value: formatter.format(result['total']),
              subtitle:
                  '${formatter.format(result['total']! / (_kmYear * _years))} per km',
              isPrimary: true,
            ),

            const SizedBox(height: 16),

            // Pie chart of cost breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cost Breakdown',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (_, _) {},
                          ),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            _section(result['depreciation']!,
                                theme.colorScheme.error, 'Depr'),
                            _section(result['energy']!,
                                theme.colorScheme.tertiary,
                                isEv ? 'Power' : 'Fuel'),
                            _section(result['insurance']!,
                                theme.colorScheme.primary, 'Ins'),
                            _section(result['service']!,
                                theme.colorScheme.secondary, 'Svc'),
                            _section(result['rego']!,
                                Colors.amber, 'Rego'),
                            _section(result['stampDuty']!,
                                Colors.purple, 'Duty'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    BreakdownRow(
                      label: 'Depreciation',
                      value: formatter.format(result['depreciation']),
                    ),
                    BreakdownRow(
                      label: isEv ? 'Electricity' : 'Fuel',
                      value: formatter.format(result['energy']),
                    ),
                    BreakdownRow(
                      label: 'Insurance',
                      value: formatter.format(result['insurance']),
                    ),
                    BreakdownRow(
                      label: 'Service',
                      value: formatter.format(result['service']),
                    ),
                    BreakdownRow(
                      label: 'Registration',
                      value: formatter.format(result['rego']),
                    ),
                    BreakdownRow(
                      label: 'Stamp Duty',
                      value: formatter.format(result['stampDuty']),
                    ),
                    const Divider(),
                    BreakdownRow(
                      label: 'Total',
                      value: formatter.format(result['total']),
                      bold: true,
                    ),
                    const SizedBox(height: 8),
                    BreakdownRow(
                      label: 'Residual Value (Year $_years)',
                      value: formatter.format(result['residualValue']),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Service costs: industry averages from RACV/NRMA published data. '
                  'Depreciation: generic curves (~20% year 1, ~10%/yr after). '
                  'Actual costs vary by make, model, condition, and location.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _section(double value, Color color, String label) {
    return PieChartSectionData(
      value: value,
      color: color,
      title: label,
      radius: 60,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
