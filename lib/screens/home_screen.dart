import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/rate_models.dart';
import '../models/tool.dart';
import '../utils/country_flags.dart';
import '../utils/page_route.dart';
import '../services/favourites_service.dart';
import 'tool_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Set<String> _favourites = {};
  bool _showCountryList = false;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    final favs = await FavouritesService.getFavourites();
    if (mounted) setState(() => _favourites = favs);
  }

  List<Country> _otherCountries(CalculatorProvider provider) {
    if (provider.selectedCountry == null) return provider.countries;
    return provider.countries
        .where((c) => c.code != provider.selectedCountry!.code)
        .toList();
  }

  void _openTool(Tool tool) {
    Navigator.push(context, slideUpRoute(ToolRouter(tool: tool)))
        .then((_) => _loadFavourites());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalculatorProvider>();
    final theme = Theme.of(context);

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(provider.error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => provider.init(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final favouriteTools =
        Tools.all.where((t) => _favourites.contains(t.id)).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              'Vehicle Calculator',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Country continue card
          if (provider.selectedCountry != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _CountryContinueCard(
                  country: provider.selectedCountry!,
                  onReset: () {
                    provider.resetAll();
                    setState(() => _showCountryList = false);
                  },
                ),
              ),
            ),

          // Country selector / toggle
          if (provider.selectedCountry == null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Select your country',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _showCountryList = !_showCountryList),
                  icon: Icon(_showCountryList
                      ? Icons.expand_less
                      : Icons.expand_more),
                  label: Text(_showCountryList
                      ? 'Hide countries'
                      : 'Choose another country'),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
            ),

          // Country list
          if (provider.selectedCountry == null || _showCountryList)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverList.separated(
                itemCount: _otherCountries(provider).length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final country = _otherCountries(provider)[index];
                  return _CountryListItem(
                    country: country,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      provider.selectCountry(country);
                      setState(() => _showCountryList = false);
                    },
                  );
                },
              ),
            ),

          // Favourites
          if (favouriteTools.isNotEmpty) ...[
            _SectionHeader('★ Favourites'),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 140,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tool = favouriteTools[index];
                    return _ToolCard(
                      tool: tool,
                      onTap: () => _openTool(tool),
                      isFavourite: true,
                    );
                  },
                  childCount: favouriteTools.length,
                ),
              ),
            ),
          ],

          // Tools by category
          ..._buildCategorySections(context, provider),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  List<Widget> _buildCategorySections(
      BuildContext context, CalculatorProvider provider) {
    final widgets = <Widget>[];
    for (final cat in ToolCategory.values) {
      final tools = Tools.byCategory(cat);
      if (tools.isEmpty) continue;
      widgets.add(_SectionHeader(cat.label));
      widgets.add(SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final tool = tools[index];
              return _ToolCard(
                tool: tool,
                onTap: () => _openTool(tool),
                isFavourite: _favourites.contains(tool.id),
              );
            },
            childCount: tools.length,
          ),
        ),
      ));
    }
    return widgets;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      sliver: SliverToBoxAdapter(
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final Tool tool;
  final VoidCallback onTap;
  final bool isFavourite;

  const _ToolCard({
    required this.tool,
    required this.onTap,
    this.isFavourite = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tool.icon,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tool.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isFavourite)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.star, color: Colors.amber, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountryContinueCard extends StatelessWidget {
  final Country country;
  final VoidCallback onReset;

  const _CountryContinueCard({
    required this.country,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Text(
              countryFlag(country.code),
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Country-specific tools will use these rates',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Reset country',
              color: theme.colorScheme.onPrimaryContainer,
              onPressed: onReset,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryListItem extends StatelessWidget {
  final Country country;
  final VoidCallback onTap;

  const _CountryListItem({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                countryFlag(country.code),
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      country.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${country.states.length} ${country.states.length == 1 ? "region" : "states"} - ${country.currency}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
