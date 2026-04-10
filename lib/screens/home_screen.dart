import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/rate_models.dart';
import '../utils/country_flags.dart';
import '../utils/page_route.dart';
import '../services/bookmark_service.dart';
import 'calculator_screen.dart';
import 'compare_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Bookmark> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await BookmarkService.getBookmarks();
    if (mounted) setState(() => _bookmarks = bookmarks);
  }

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
                        'Vehicle Stamp Duty Calculator',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      actions: const [],
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
                    // Bookmarks
                    if (_bookmarks.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Bookmarks',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        sliver: SliverToBoxAdapter(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _bookmarks.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final bm = entry.value;
                              return InputChip(
                                avatar: const Icon(Icons.bookmark, size: 16),
                                label: Text(bm.label),
                                onPressed: () {
                                  // Find country and state, apply selections
                                  final country = provider.countries
                                      .where((c) => c.code == bm.countryCode)
                                      .firstOrNull;
                                  if (country == null) return;
                                  final state = country.states
                                      .where((s) => s.code == bm.stateCode)
                                      .firstOrNull;
                                  if (state == null) return;

                                  provider.selectCountry(country);
                                  provider.selectState(state);
                                  for (final sel in bm.selections.entries) {
                                    provider.setSelection(sel.key, sel.value);
                                  }
                                  Navigator.push(context,
                                      slideUpRoute(const CalculatorScreen()));
                                },
                                onDeleted: () async {
                                  await BookmarkService.removeBookmark(idx);
                                  _loadBookmarks();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],

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
                            onCompare: country.states.length > 1
                                ? () {
                                    provider.selectCountry(country);
                                    Navigator.push(context,
                                        slideUpRoute(const CompareScreen()));
                                  }
                                : null,
                            onTap: () {
                              provider.selectCountry(country);
                              Navigator.push(context,
                                  slideUpRoute(const CalculatorScreen()))
                                  .then((_) {
                                    provider.reset();
                                    _loadBookmarks();
                                  });
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
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, onCompare != null ? 12 : 20),
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
