import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/calculator_provider.dart';
import '../providers/theme_provider.dart';
import '../services/rate_service.dart';
import '../services/onboarding_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checkingUpdates = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final calcProvider = context.watch<CalculatorProvider>();
    final rateData = calcProvider.rateData;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ──────────────────────────────────
          _SectionTitle('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(themeProvider.themeMode)),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                ),
              ],
              selected: {themeProvider.themeMode},
              onSelectionChanged: (selected) {
                themeProvider.setThemeMode(selected.first);
              },
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Default Country'),
            subtitle: Text(
              calcProvider.selectedCountry?.name ?? 'Not set',
            ),
            trailing: DropdownButton<String>(
              value: calcProvider.selectedCountry?.code,
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('None'),
                ),
                ...calcProvider.countries.map((c) => DropdownMenuItem(
                      value: c.code,
                      child: Text(c.name),
                    )),
              ],
              onChanged: (code) {
                if (code == null) {
                  calcProvider.resetAll();
                } else {
                  final country = calcProvider.countries
                      .firstWhere((c) => c.code == code);
                  calcProvider.selectCountry(country);
                }
              },
            ),
          ),

          const Divider(),

          // ── Rates ───────────────────────────────────────
          _SectionTitle('Rate Data'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(rateData?.version ?? 'Unknown'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Last Updated'),
            subtitle: Text(rateData?.lastUpdated ?? 'Unknown'),
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Countries Supported'),
            subtitle: Text(
              rateData?.countries.map((c) => c.name).join(', ') ?? 'None',
            ),
          ),
          if (calcProvider.selectedCountry != null)
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text('${calcProvider.selectedCountry!.name} Regions'),
              subtitle: Text(
                calcProvider.selectedCountry!.states
                    .map((s) => s.code)
                    .join(', '),
              ),
            )
          else
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Total Regions'),
              subtitle: Text(
                '${rateData?.countries.expand((c) => c.states).length ?? 0} across ${rateData?.countries.length ?? 0} countries',
              ),
            ),

          const Divider(),

          // ── Update ──────────────────────────────────────
          _SectionTitle('Updates'),
          ListTile(
            leading: _checkingUpdates
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            title: const Text('Check for Rate Updates'),
            subtitle: const Text('Fetch the latest rates from the server'),
            onTap: _checkingUpdates ? null : () => _checkForUpdates(context),
          ),

          const Divider(),

          // ── Share & Feedback ───────────────────────────
          _SectionTitle('Share'),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share this app'),
            subtitle: const Text('Tell others about Vehicle Calculator'),
            onTap: () => _shareApp(),
          ),
          ListTile(
            leading: const Icon(Icons.replay),
            title: const Text('Show welcome tour'),
            subtitle: const Text('Replay the introduction'),
            onTap: () async {
              await OnboardingService.reset();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tour will show on next app launch'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),

          const Divider(),

          // ── About ───────────────────────────────────────
          _SectionTitle('About'),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('Vehicle Calculator'),
            subtitle: const Text('Version 1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Disclaimer'),
            subtitle: const Text(
              'This app provides estimates only. Always consult your '
              'state/territory revenue office for official calculations.',
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _shareApp() async {
    await Share.share(
      'Check out Vehicle Calculator - Australian & NZ vehicle stamp duty, '
      'on-road costs, fuel, and more in one app.\n\n'
      'https://github.com/oriclabs/StampDutyCalc',
      subject: 'Vehicle Calculator',
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    setState(() => _checkingUpdates = true);

    final provider = context.read<CalculatorProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final service = RateService();
    final updated = await service.forceRefresh();

    if (!mounted) return;
    setState(() => _checkingUpdates = false);

    if (updated) {
      await provider.init();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Rates updated to the latest version!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('You already have the latest rates'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
