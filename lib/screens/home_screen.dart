import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/rate_models.dart';
import '../utils/country_flags.dart';
import '../utils/page_route.dart';
import 'calculator_screen.dart';
import 'compare_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalculatorProvider>();
    final theme = Theme.of(context);

    // Show rate update snackbar
    if (provider.ratesUpdated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.clearRatesUpdated();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Rates have been updated to the latest version'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(label: 'OK', onPressed: () {}),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    }

    return Scaffold(
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _buildError(context, provider)
              : CustomScrollView(
                  slivers: [
                    SliverAppBar.large(
                      title: Text(
                        'Stamp Duty Calculator',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.history),
                          tooltip: 'Calculation history',
                          onPressed: () => Navigator.push(
                              context, slideUpRoute(const HistoryScreen())),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'About',
                          onPressed: () => _showAbout(context),
                        ),
                      ],
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: _ModeSelector(provider: provider),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          provider.mode == CalculatorMode.stampDuty
                              ? 'Select a country to calculate vehicle stamp duty'
                              : 'Select a country to calculate total on-road costs',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.separated(
                        itemCount: provider.countries.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final country = provider.countries[index];
                          return _CountryCard(
                            country: country,
                            onTap: () {
                              provider.selectCountry(country);
                              Navigator.push(context,
                                  slideUpRoute(const CalculatorScreen()));
                            },
                            onCompare: country.states.length > 1
                                ? () {
                                    provider.selectCountry(country);
                                    Navigator.push(context,
                                        slideUpRoute(const CompareScreen()));
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverToBoxAdapter(
                        child: _buildRateInfo(context, provider),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError(BuildContext context, CalculatorProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(provider.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => provider.init(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateInfo(BuildContext context, CalculatorProvider provider) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.update, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rates version ${provider.rateData?.version ?? ''} - Last updated ${provider.rateData?.lastUpdated ?? ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Stamp Duty Calculator',
      applicationVersion: '1.0.0',
      applicationLegalese:
          'Vehicle stamp duty calculator for Australia & New Zealand.\nRates are updated periodically.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'This app calculates stamp duty payable on vehicle purchases and transfers. '
          'Rates are sourced from official government publications and may change.',
        ),
      ],
    );
  }
}

class _CountryCard extends StatelessWidget {
  final Country country;
  final VoidCallback onTap;
  final VoidCallback? onCompare;

  const _CountryCard({
    required this.country,
    required this.onTap,
    this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Text(
                    countryFlag(country.code),
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${country.states.length} ${country.states.length == 1 ? 'region' : 'states/territories'} - ${country.currency}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (onCompare != null) ...[
            const Divider(height: 1),
            InkWell(
              onTap: onCompare,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.compare_arrows,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Compare all states',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final CalculatorProvider provider;

  const _ModeSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CalculatorMode>(
      segments: const [
        ButtonSegment(
          value: CalculatorMode.stampDuty,
          label: Text('Stamp Duty'),
          icon: Icon(Icons.receipt_long),
        ),
        ButtonSegment(
          value: CalculatorMode.onRoad,
          label: Text('On-Road Cost'),
          icon: Icon(Icons.directions_car),
        ),
      ],
      selected: {provider.mode},
      onSelectionChanged: (selected) {
        HapticFeedback.selectionClick();
        provider.setMode(selected.first);
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity.comfortable,
      ),
    );
  }
}
