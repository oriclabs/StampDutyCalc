import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../services/stamp_duty_calculator.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _priceController = TextEditingController();
  double? _price;
  List<_CompareResult> _results = [];

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (_price == null || _price! <= 0) return;

    final provider = context.read<CalculatorProvider>();
    final country = provider.selectedCountry;
    if (country == null) return;

    final results = <_CompareResult>[];

    for (final state in country.states) {
      // Try to calculate with minimal selections (pick first matching rule)
      final result = StampDutyCalculator.calculate(
        country: country,
        state: state,
        vehiclePrice: _price!,
        selections: {},
        registrationDate: DateTime.now(),
      );

      if (result != null) {
        results.add(_CompareResult(
          stateCode: state.code,
          stateName: state.name,
          stampDuty: result.stampDuty,
          rate: _price! > 0
              ? (result.stampDuty / _price! * 100).toStringAsFixed(2)
              : '0',
        ));
      }
    }

    // Sort by stamp duty (lowest first)
    results.sort((a, b) => a.stampDuty.compareTo(b.stampDuty));

    setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalculatorProvider>();
    final country = provider.selectedCountry;
    if (country == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: country.currencySymbol,
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Compare States')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Compare stamp duty across all ${country.name} states for the same vehicle price',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // Price input
              TextField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Vehicle Price',
                  prefixText: '${country.currencySymbol} ',
                  hintText: 'Enter amount',
                ),
                onChanged: (value) {
                  _price = double.tryParse(value);
                },
                onSubmitted: (_) => _calculate(),
              ),
              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed:
                    _price != null && _price! > 0 ? _calculate : null,
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Compare All States'),
              ),

              if (_results.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Results (lowest to highest)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on default vehicle type for each state',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                ..._results.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  final isLowest = idx == 0;
                  final isHighest = idx == _results.length - 1 &&
                      _results.length > 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      color: isLowest
                          ? theme.colorScheme.primaryContainer
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Rank badge
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isLowest
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme
                                        .surfaceContainerHighest,
                              ),
                              child: Center(
                                child: Text(
                                  '${idx + 1}',
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(
                                    color: isLowest
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme
                                            .onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // State info
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        r.stateCode,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isLowest)
                                        _Badge(
                                            'Lowest',
                                            theme
                                                .colorScheme.primary,
                                            theme
                                                .colorScheme.onPrimary),
                                      if (isHighest)
                                        _Badge(
                                            'Highest',
                                            theme.colorScheme.error,
                                            theme
                                                .colorScheme.onError),
                                    ],
                                  ),
                                  Text(
                                    r.stateName,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Amount
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatter.format(r.stampDuty),
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isLowest
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                                Text(
                                  '${r.rate}%',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: theme
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Badge(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CompareResult {
  final String stateCode;
  final String stateName;
  final double stampDuty;
  final String rate;

  _CompareResult({
    required this.stateCode,
    required this.stateName,
    required this.stampDuty,
    required this.rate,
  });
}
