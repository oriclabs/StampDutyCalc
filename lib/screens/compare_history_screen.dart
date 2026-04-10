import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';

class CompareHistoryScreen extends StatelessWidget {
  final HistoryEntry left;
  final HistoryEntry right;

  const CompareHistoryScreen({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leftFmt = NumberFormat.currency(
      symbol: left.currencySymbol,
      decimalDigits: 2,
    );
    final rightFmt = NumberFormat.currency(
      symbol: right.currencySymbol,
      decimalDigits: 2,
    );
    final dateFmt = DateFormat('d MMM yyyy');

    final leftWins = left.totalPayable < right.totalPayable;
    final difference = (left.totalPayable - right.totalPayable).abs();
    final differencePct = right.totalPayable > 0
        ? (difference / right.totalPayable * 100).toStringAsFixed(1)
        : '0';

    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary card
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Difference',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      leftFmt.format(difference),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$differencePct% ${leftWins ? "less" : "more"} on the left',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Side by side cards
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SideCard(
                      entry: left,
                      formatter: leftFmt,
                      isWinner: leftWins,
                      label: 'A',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SideCard(
                      entry: right,
                      formatter: rightFmt,
                      isWinner: !leftWins,
                      label: 'B',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Detail rows
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _CompareRow(
                      label: 'Date',
                      left: dateFmt.format(left.timestamp),
                      right: dateFmt.format(right.timestamp),
                    ),
                    _CompareRow(
                      label: 'Country',
                      left: left.countryName,
                      right: right.countryName,
                    ),
                    _CompareRow(
                      label: 'State',
                      left: left.stateCode,
                      right: right.stateCode,
                    ),
                    _CompareRow(
                      label: 'Vehicle Price',
                      left: leftFmt.format(left.vehiclePrice),
                      right: rightFmt.format(right.vehiclePrice),
                    ),
                    _CompareRow(
                      label: 'Stamp Duty',
                      left: leftFmt.format(left.stampDuty),
                      right: rightFmt.format(right.stampDuty),
                    ),
                    _CompareRow(
                      label: 'Mode',
                      left: left.isOnRoad ? 'On-Road' : 'Stamp Duty',
                      right: right.isOnRoad ? 'On-Road' : 'Stamp Duty',
                    ),
                    const Divider(height: 24),
                    _CompareRow(
                      label: 'Total',
                      left: leftFmt.format(left.totalPayable),
                      right: rightFmt.format(right.totalPayable),
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

class _SideCard extends StatelessWidget {
  final HistoryEntry entry;
  final NumberFormat formatter;
  final bool isWinner;
  final String label;

  const _SideCard({
    required this.entry,
    required this.formatter,
    required this.isWinner,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: isWinner ? theme.colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isWinner
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isWinner
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isWinner
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              entry.stateCode,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isWinner
                    ? theme.colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(entry.totalPayable),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isWinner
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.primary,
              ),
            ),
            if (isWinner) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'CHEAPER',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String left;
  final String right;
  final bool bold;

  const _CompareRow({
    required this.label,
    required this.left,
    required this.right,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: bold ? FontWeight.w700 : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              left,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              right,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
