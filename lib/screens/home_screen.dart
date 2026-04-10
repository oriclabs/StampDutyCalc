import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/rate_models.dart';
import '../utils/country_flags.dart';
import 'calculator_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalculatorProvider>();
    final theme = Theme.of(context);

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
                          icon: const Icon(Icons.info_outline),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CalculatorScreen(),
                                ),
                              );
                            },
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

  const _CountryCard({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
        provider.setMode(selected.first);
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity.comfortable,
      ),
    );
  }
}
