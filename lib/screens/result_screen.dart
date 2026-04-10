import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/calculator_provider.dart';
import '../models/calculation_result.dart';
import '../services/finance_calculator.dart';
import '../utils/currency_input_formatter.dart';
import '../widgets/result_card.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalculatorProvider>();
    final result = provider.result;

    if (result == null) {
      // Don't auto-pop - just show empty state
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }

    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: result.currencySymbol,
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(result.isOnRoadMode ? 'On-Road Cost' : 'Stamp Duty'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboard',
            onPressed: () => _copyResult(context, result, formatter),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share as image',
            onPressed: () => _shareAsImage(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shareable content wrapped in RepaintBoundary
            RepaintBoundary(
              key: _repaintKey,
              child: Container(
                color: theme.colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            // Main result card
            _ResultHeroCard(result: result, formatter: formatter),

            const SizedBox(height: 24),

            // Breakdown
            Text(
              'Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _BreakdownCard(result: result, formatter: formatter),

            const SizedBox(height: 24),

            // Details
            Text(
              'Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _DetailsCard(result: result, formatter: formatter),
                  ],
                ),
              ),
            ), // end RepaintBoundary

            // ABN GST credit (if business buyer)
            if (provider.hasAbn) ...[
              const SizedBox(height: 16),
              _AbnGstCard(provider: provider, formatter: formatter),
            ],

            // Trade-in info (if applicable)
            if (provider.hasTradeIn && provider.tradeInValue > 0) ...[
              const SizedBox(height: 16),
              _TradeInInfoCard(provider: provider, formatter: formatter),
            ],

            // Finance section (on-road mode only)
            if (result.isOnRoadMode) ...[
              const SizedBox(height: 16),
              _FinanceSection(provider: provider),
            ],

            const SizedBox(height: 24),

            // Quick recalculate
            _QuickRecalculate(provider: provider, formatter: formatter),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      // Pop first - result screen disappears immediately
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      // Then reset state after pop completes
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        provider.reset();
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Disclaimer
            Card(
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is an estimate only. Actual amounts may vary. '
                        'Consult your state/territory revenue office for official figures.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
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

  Future<void> _shareAsImage(BuildContext context) async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/stamp_duty_result.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Stamp Duty Calculator Result',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to share. Try copying instead.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyResult(
      BuildContext context, CalculationResult result, NumberFormat formatter) {
    final text = StringBuffer()
      ..writeln(result.isOnRoadMode
          ? 'On-Road Cost Calculation'
          : 'Stamp Duty Calculation')
      ..writeln('${result.countryName} - ${result.stateName}')
      ..writeln('Date: ${DateFormat('d MMM yyyy').format(result.registrationDate)}')
      ..writeln('---');

    for (final item in result.breakdown) {
      text.writeln('${item.description}: ${formatter.format(item.amount)}');
    }

    text
      ..writeln('---')
      ..writeln('Total: ${formatter.format(result.totalPayable)}');

    Clipboard.setData(ClipboardData(text: text.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _ResultHeroCard extends StatelessWidget {
  final CalculationResult result;
  final NumberFormat formatter;

  const _ResultHeroCard({required this.result, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '${result.isOnRoadMode ? "Total on-road cost" : "Stamp duty"}: ${formatter.format(result.totalPayable)}, ${result.stateName}, ${result.countryName}',
      child: Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Text(
              result.isOnRoadMode ? 'Total On-Road Cost' : 'Stamp Duty',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer
                    .withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(result.totalPayable),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimaryContainer
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${result.stateName}, ${result.countryName}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _BreakdownCard extends StatelessWidget {
  final CalculationResult result;
  final NumberFormat formatter;

  const _BreakdownCard({required this.result, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...result.breakdown.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        formatter.format(item.amount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  formatter.format(result.totalPayable),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final CalculationResult result;
  final NumberFormat formatter;

  const _DetailsCard({required this.result, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _detailRow(theme, 'Country', result.countryName),
            _detailRow(theme, 'State / Territory', result.stateName),
            _detailRow(theme, 'Date',
                DateFormat('d MMM yyyy').format(result.registrationDate)),
            _detailRow(theme, 'Vehicle Price',
                formatter.format(result.vehiclePrice)),
            _detailRow(
                theme, 'Stamp Duty', formatter.format(result.stampDuty)),
            if (result.additionalFees.isNotEmpty) ...[
              const Divider(height: 16),
              ...result.additionalFees.entries.map(
                (e) => _detailRow(
                    theme, _formatFeeLabel(e.key), formatter.format(e.value)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFeeLabel(String key) {
    final result = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }
}

class _QuickRecalculate extends StatelessWidget {
  final CalculatorProvider provider;
  final NumberFormat formatter;

  const _QuickRecalculate({
    required this.provider,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = provider.vehiclePrice ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Recalculate',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Adjust the price to see how duty changes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _adjustButton(context, '-5,000', -5000, price),
                _adjustButton(context, '-1,000', -1000, price),
                _adjustButton(context, '+1,000', 1000, price),
                _adjustButton(context, '+5,000', 5000, price),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adjustButton(
      BuildContext context, String label, double delta, double currentPrice) {
    final theme = Theme.of(context);
    final newPrice = currentPrice + delta;
    final enabled = newPrice > 0;

    return OutlinedButton(
      onPressed: enabled
          ? () async {
              provider.setVehiclePrice(newPrice);
              await provider.calculate();
            }
          : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size.zero,
        textStyle: theme.textTheme.labelMedium,
      ),
      child: Text(label),
    );
  }
}

class _AbnGstCard extends StatelessWidget {
  final CalculatorProvider provider;
  final NumberFormat formatter;

  const _AbnGstCard({required this.provider, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = provider.vehiclePrice ?? 0;
    final gstCredit = price / 11;
    final netCost = price - gstCredit;

    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business_center,
                    color: theme.colorScheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Text(
                  'ABN / Business Buyer',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BreakdownRow(
              label: 'GST Credit (claimable)',
              value: formatter.format(gstCredit),
            ),
            BreakdownRow(
              label: 'Net Cost (after GST credit)',
              value: formatter.format(netCost),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TradeInInfoCard extends StatelessWidget {
  final CalculatorProvider provider;
  final NumberFormat formatter;

  const _TradeInInfoCard({required this.provider, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = provider.vehiclePrice ?? 0;
    final tradeIn = provider.tradeInValue;
    final outOfPocket = price - tradeIn;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Trade-in',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BreakdownRow(
              label: 'Vehicle Price',
              value: formatter.format(price),
            ),
            BreakdownRow(
              label: 'Trade-in Value',
              value: '- ${formatter.format(tradeIn)}',
            ),
            const Divider(),
            BreakdownRow(
              label: 'Cash Out of Pocket',
              value: formatter.format(outOfPocket),
              bold: true,
            ),
            if (provider.tradeInEligible) ...[
              const SizedBox(height: 8),
              Text(
                'Stamp duty was calculated on the net price',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinanceSection extends StatefulWidget {
  final CalculatorProvider provider;

  const _FinanceSection({required this.provider});

  @override
  State<_FinanceSection> createState() => _FinanceSectionState();
}

class _FinanceSectionState extends State<_FinanceSection> {
  final _depositCtrl = TextEditingController(text: '5,000');

  @override
  void initState() {
    super.initState();
    widget.provider.setLoanDeposit(5000);
  }

  @override
  void dispose() {
    _depositCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final p = widget.provider;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.account_balance, color: theme.colorScheme.primary),
        title: const Text('Finance this?',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Calculate monthly repayments'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _depositCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Deposit',
                    prefixText: '\$ ',
                    isDense: true,
                  ),
                  onChanged: (v) => p.setLoanDeposit(
                      CurrencyInputFormatter.parse(v) ?? 0),
                ),
                const SizedBox(height: 12),
                _FinanceSlider(
                  label: 'Term',
                  value: p.loanTermYears.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  suffix: ' yrs',
                  decimals: 0,
                  onChanged: (v) => p.setLoanTermYears(v.round()),
                ),
                const SizedBox(height: 8),
                _FinanceSlider(
                  label: 'Rate',
                  value: p.loanRate,
                  min: 0,
                  max: 15,
                  divisions: 150,
                  suffix: '%',
                  decimals: 2,
                  onChanged: (v) => p.setLoanRate(v),
                ),
                const SizedBox(height: 12),
                _MonthlyRepayment(provider: p, formatter: formatter),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyRepayment extends StatelessWidget {
  final CalculatorProvider provider;
  final NumberFormat formatter;

  const _MonthlyRepayment({required this.provider, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = provider.result;
    if (result == null) return const SizedBox.shrink();

    final loanAmount = (result.totalPayable - provider.loanDeposit)
        .clamp(0, double.infinity);
    if (loanAmount <= 0) {
      return Text(
        'Deposit covers the full cost - no loan needed',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      );
    }

    final monthly = FinanceCalculator.monthlyPayment(
      principal: loanAmount.toDouble(),
      annualRate: provider.loanRate / 100,
      termMonths: provider.loanTermYears * 12,
    );
    final totalInterest = FinanceCalculator.totalInterest(
      principal: loanAmount.toDouble(),
      annualRate: provider.loanRate / 100,
      termMonths: provider.loanTermYears * 12,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Monthly Repayment',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer
                  .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatter.format(monthly),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total interest: ${formatter.format(totalInterest)} - Loan: ${formatter.format(loanAmount)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer
                  .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final int decimals;
  final ValueChanged<double> onChanged;

  const _FinanceSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.decimals,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            '${value.toStringAsFixed(decimals)}$suffix',
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
