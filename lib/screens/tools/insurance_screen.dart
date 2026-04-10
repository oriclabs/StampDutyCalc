import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/tool.dart';
import '../../widgets/tool_scaffold.dart';

class InsuranceScreen extends StatelessWidget {
  const InsuranceScreen({super.key});

  static const _providers = [
    _Provider(
      name: 'Compare the Market',
      description: 'Compare quotes from 12+ insurers',
      url: 'https://www.comparethemarket.com.au/car-insurance/',
      logo: '🦦',
      colorHex: 0xFF1A4789,
    ),
    _Provider(
      name: 'iSelect',
      description: 'Free quote comparison service',
      url: 'https://www.iselect.com.au/car-insurance/',
      logo: '✓',
      colorHex: 0xFFE30613,
    ),
    _Provider(
      name: 'Finder',
      description: 'Compare 30+ Australian insurers',
      url: 'https://www.finder.com.au/car-insurance',
      logo: '🔍',
      colorHex: 0xFF0B57D0,
    ),
    _Provider(
      name: 'Budget Direct',
      description: 'Direct quotes, often cheapest',
      url: 'https://www.budgetdirect.com.au/car-insurance/',
      logo: '💰',
      colorHex: 0xFFE60028,
    ),
    _Provider(
      name: 'Youi',
      description: 'Personalised pricing',
      url: 'https://www.youi.com.au/car-insurance',
      logo: '🚗',
      colorHex: 0xFF00B050,
    ),
    _Provider(
      name: 'AAMI',
      description: 'Lucky you\'re with AAMI',
      url: 'https://www.aami.com.au/car-insurance.html',
      logo: '🔵',
      colorHex: 0xFF003DA5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ToolScaffold(
      toolId: Tools.insurance.id,
      title: Tools.insurance.name,
      icon: Tools.insurance.icon,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Get accurate quotes',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Insurance premiums depend on your driving history, postcode, vehicle, and personal details. We connect you to insurers and comparison services for accurate, personalised quotes.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Compare & Quote',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a provider to get a free quote',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ..._providers.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _launch(context, p.url),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(p.colorHex).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                p.logo,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.open_in_new,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 24),
          Card(
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'External links open in your browser. We may receive a referral fee from some providers, which helps keep this app free.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }
}

class _Provider {
  final String name;
  final String description;
  final String url;
  final String logo;
  final int colorHex;

  const _Provider({
    required this.name,
    required this.description,
    required this.url,
    required this.logo,
    required this.colorHex,
  });
}
