import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/tool.dart';
import '../../widgets/tool_scaffold.dart';
import '../../widgets/number_input.dart';
import '../../widgets/result_card.dart';

class EvVsIceScreen extends StatefulWidget {
  const EvVsIceScreen({super.key});

  @override
  State<EvVsIceScreen> createState() => _EvVsIceScreenState();
}

class _EvVsIceScreenState extends State<EvVsIceScreen> {
  final _evPriceCtrl = TextEditingController(text: '60,000');
  final _icePriceCtrl = TextEditingController(text: '40,000');
  final _kmCtrl = TextEditingController(text: '15,000');

  double _evPrice = 60000;
  double _icePrice = 40000;
  double _kmYear = 15000;
  final double _consumption = 8.0;
  final double _fuelPrice = 1.95;
  final double _kwhPer100km = 18;
  final double _electricityPrice = 0.30;

  @override
  void dispose() {
    _evPriceCtrl.dispose();
    _icePriceCtrl.dispose();
    _kmCtrl.dispose();
    super.dispose();
  }

  List<double> _yearlyCosts(bool ev) {
    final base = ev ? _evPrice : _icePrice;
    final yearlyEnergy = ev
        ? (_kwhPer100km / 100) * _kmYear * _electricityPrice
        : (_consumption / 100) * _kmYear * _fuelPrice;
    final yearlyService = ev ? 350.0 : 700.0;
    final yearlyOther = 1500.0; // rego + insurance avg

    return List.generate(8, (year) {
      // Cumulative cost: purchase + (energy + service + other) * years
      return base + (yearlyEnergy + yearlyService + yearlyOther) * (year + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final evCosts = _yearlyCosts(true);
    final iceCosts = _yearlyCosts(false);

    // Find crossover year
    int? crossoverYear;
    for (var i = 0; i < evCosts.length; i++) {
      if (evCosts[i] < iceCosts[i]) {
        crossoverYear = i + 1;
        break;
      }
    }

    final evAt5 = evCosts[4];
    final iceAt5 = iceCosts[4];
    final saving = iceAt5 - evAt5;

    return ToolScaffold(
      toolId: Tools.evVsIce.id,
      title: Tools.evVsIce.name,
      icon: Tools.evVsIce.icon,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NumberInput(
              controller: _evPriceCtrl,
              label: 'EV Price',
              prefix: '\$ ',
              currencyFormat: true,
              onChanged: (v) => setState(() => _evPrice = v ?? 0),
            ),
            const SizedBox(height: 12),
            NumberInput(
              controller: _icePriceCtrl,
              label: 'Petrol/Diesel Price',
              prefix: '\$ ',
              currencyFormat: true,
              onChanged: (v) => setState(() => _icePrice = v ?? 0),
            ),
            const SizedBox(height: 12),
            NumberInput(
              controller: _kmCtrl,
              label: 'Annual km',
              suffix: 'km',
              currencyFormat: true,
              onChanged: (v) => setState(() => _kmYear = v ?? 0),
            ),

            const SizedBox(height: 24),

            ResultCard(
              label: 'EV Saves Over 5 Years',
              value: saving > 0
                  ? formatter.format(saving)
                  : '${formatter.format(saving.abs())} more',
              subtitle: crossoverYear != null
                  ? 'EV becomes cheaper in year $crossoverYear'
                  : 'ICE remains cheaper for 8+ years',
              isPrimary: true,
            ),

            const SizedBox(height: 16),

            // Line chart
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Cumulative Cost',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) =>
                                  theme.colorScheme.inverseSurface,
                              getTooltipItems: (spots) => spots
                                  .map((s) => LineTooltipItem(
                                        '${s.barIndex == 0 ? "EV" : "Petrol"} Y${(s.x + 1).toInt()}\n\$${(s.y / 1000).toStringAsFixed(1)}k',
                                        TextStyle(
                                          color: theme
                                              .colorScheme.onInverseSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          gridData: const FlGridData(drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (v, _) => Text(
                                  'Y${v.toInt() + 1}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (v, _) => Text(
                                  '\$${(v / 1000).toStringAsFixed(0)}k',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 7,
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                evCosts.length,
                                (i) => FlSpot(i.toDouble(), evCosts[i]),
                              ),
                              isCurved: false,
                              color: theme.colorScheme.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                            ),
                            LineChartBarData(
                              spots: List.generate(
                                iceCosts.length,
                                (i) => FlSpot(i.toDouble(), iceCosts[i]),
                              ),
                              isCurved: false,
                              color: theme.colorScheme.tertiary,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _LegendItem(
                            color: theme.colorScheme.primary, label: 'EV'),
                        _LegendItem(
                            color: theme.colorScheme.tertiary,
                            label: 'Petrol'),
                      ],
                    ),
                    const Divider(height: 32),
                    BreakdownRow(
                      label: 'EV @ 5 years',
                      value: formatter.format(evAt5),
                    ),
                    BreakdownRow(
                      label: 'Petrol @ 5 years',
                      value: formatter.format(iceAt5),
                    ),
                    const Divider(),
                    BreakdownRow(
                      label: saving > 0 ? 'EV Saves' : 'EV Costs More',
                      value: formatter.format(saving.abs()),
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
