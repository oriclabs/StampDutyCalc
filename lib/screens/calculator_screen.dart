import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/rate_models.dart';
import '../utils/currency_input_formatter.dart';
import '../services/bookmark_service.dart';
import '../utils/page_route.dart';
import 'result_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _priceController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _priceFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Listen to controller changes for clear button visibility
    _priceController.addListener(_onPriceChanged);

    // Auto-select single-state countries on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CalculatorProvider>();
      final country = provider.selectedCountry;
      if (country != null &&
          country.states.length == 1 &&
          provider.selectedState == null) {
        provider.selectState(country.states.first);
      }
    });
  }

  void _onPriceChanged() {
    // Trigger rebuild only for clear button visibility
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _priceController.removeListener(_onPriceChanged);
    _priceController.dispose();
    _deliveryController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalculatorProvider>();
    final country = provider.selectedCountry;
    if (country == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(country.name),
        actions: [
          if (provider.selectedState != null &&
              provider.selections.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: 'Save as bookmark',
              onPressed: () => _saveBookmark(context, provider),
            ),
          if (provider.selectedState != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset all fields and selections',
              onPressed: () {
                _priceController.clear();
                _deliveryController.clear();
                provider.reset();
              },
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step 1: State selection
              if (country.states.length > 1) ...[
                _SectionHeader(
                  step: 1,
                  title: 'Select State / Territory',
                  isCompleted: provider.selectedState != null,
                ),
                const SizedBox(height: 12),
                _buildStateSelector(context, provider, country),
              ],

              // Empty state hint
              if (provider.selectedState == null &&
                  country.states.length > 1) ...[
                const SizedBox(height: 48),
                Icon(Icons.touch_app,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.25)),
                const SizedBox(height: 12),
                Text(
                  'Select a state above to begin',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
              ],

              // Step 2: Vehicle details
              if (provider.selectedState != null) ...[
                const SizedBox(height: 28),
                _SectionHeader(
                  step: country.states.length > 1 ? 2 : 1,
                  title: 'Vehicle Details',
                  isCompleted: provider.canCalculate,
                ),
                const SizedBox(height: 12),
                _buildDatePicker(context, provider),
                const SizedBox(height: 16),
                ..._buildDynamicFields(context, provider),
                const SizedBox(height: 16),
                _buildPriceInput(context, provider, country),

                // On-road specific fields
                if (provider.mode == CalculatorMode.onRoad) ...[
                  const SizedBox(height: 28),
                  _SectionHeader(
                    step: country.states.length > 1 ? 3 : 2,
                    title: 'On-Road Options',
                    isCompleted: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDeliveryInput(context, provider, country),
                  const SizedBox(height: 12),
                  _buildFuelEfficientToggle(context, provider),
                ],
              ],

              // Calculate button + helper text
              if (provider.selectedState != null) ...[
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: provider.canCalculate
                      ? () async {
                          _priceFocusNode.unfocus();
                          await provider.calculate();
                          if (provider.result != null && context.mounted) {
                            Navigator.push(context,
                                slideUpRoute(const ResultScreen()));
                          }
                        }
                      : null,
                  icon: const Icon(Icons.calculate),
                  label: Text(provider.mode == CalculatorMode.stampDuty
                      ? 'Calculate Stamp Duty'
                      : 'Calculate On-Road Cost'),
                ),
                if (!provider.canCalculate) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Complete all required fields above to calculate',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateSelector(
      BuildContext context, CalculatorProvider provider, Country country) {
    return Semantics(
      label: 'Select a state or territory',
      child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: country.states.map((state) {
        final isSelected = provider.selectedState?.code == state.code;
        return Semantics(
          label: '${state.name}${isSelected ? ", selected" : ""}',
          child: ChoiceChip(
          label: Text(state.code),
          tooltip: state.name,
          selected: isSelected,
          onSelected: (_) {
            _priceController.clear();
            _deliveryController.clear();
            provider.selectState(state);
          },
          labelStyle: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ));
      }).toList(),
    ));
  }

  Widget _buildDatePicker(BuildContext context, CalculatorProvider provider) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM yyyy');

    return Semantics(
      label: 'Registration date: ${dateFormat.format(provider.registrationDate)}. Tap to change.',
      button: true,
      child: InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: provider.registrationDate,
          firstDate: DateTime(2010),
          lastDate: DateTime(2030, 12, 31),
          helpText: 'Select registration / purchase date',
        );
        if (picked != null) {
          provider.setRegistrationDate(picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Registration / Purchase Date',
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          dateFormat.format(provider.registrationDate),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    ));
  }

  List<Widget> _buildDynamicFields(
      BuildContext context, CalculatorProvider provider) {
    final fields = provider.requiredFields;
    final definitions = provider.fieldDefinitions;
    final widgets = <Widget>[];

    for (final fieldName in fields) {
      final def = definitions[fieldName];
      if (def == null) continue;
      if (!provider.shouldShowField(fieldName)) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _FieldSelector(
            label: def.label,
            helpText: def.helpText,
            options: def.options,
            selectedValue: provider.selections[fieldName],
            onSelected: (value) => provider.setSelection(fieldName, value),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildPriceInput(
      BuildContext context, CalculatorProvider provider, Country country) {
    return TextField(
      controller: _priceController,
      focusNode: _priceFocusNode,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        CurrencyInputFormatter(),
      ],
      decoration: InputDecoration(
        labelText: 'Vehicle Price / Dutiable Value',
        prefixText: '${country.currencySymbol} ',
        hintText: 'Enter amount',
        helperText: 'Enter the purchase price or market value (whichever is higher)',
        helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        suffixIcon: _priceController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear price',
                onPressed: () {
                  _priceController.clear();
                  provider.setVehiclePrice(null);
                },
              )
            : null,
      ),
      onChanged: (value) {
        final price = CurrencyInputFormatter.parse(value);
        provider.setVehiclePrice(price);
      },
    );
  }

  Widget _buildDeliveryInput(
      BuildContext context, CalculatorProvider provider, Country country) {
    final theme = Theme.of(context);

    return TextField(
      controller: _deliveryController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Dealer Delivery',
        prefixText: '${country.currencySymbol} ',
        hintText: '0',
        helperText: 'Optional - leave empty if not applicable',
        helperStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
      onChanged: (value) {
        provider.setDealerDelivery(double.tryParse(value) ?? 0);
      },
    );
  }

  Widget _buildFuelEfficientToggle(
      BuildContext context, CalculatorProvider provider) {
    final theme = Theme.of(context);

    return Card(
      child: SwitchListTile(
        title: Text(
          'Fuel-efficient vehicle',
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          'Under 3.5 L/100km — qualifies for higher Luxury Car Tax threshold',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: provider.isFuelEfficient,
        onChanged: (value) => provider.setFuelEfficient(value),
      ),
    );
  }

  void _saveBookmark(BuildContext context, CalculatorProvider provider) async {
    final country = provider.selectedCountry;
    final state = provider.selectedState;
    if (country == null || state == null) return;

    final label = '${state.code} - ${provider.selections.values.join(', ')}';

    await BookmarkService.addBookmark(Bookmark(
      countryCode: country.code,
      stateCode: state.code,
      stateName: state.name,
      countryName: country.name,
      selections: Map.from(provider.selections),
      label: label,
    ));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: $label'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final int step;
  final String title;
  final bool isCompleted;

  const _SectionHeader({
    required this.step,
    required this.title,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check,
                    size: 16, color: theme.colorScheme.onPrimary)
                : Text(
                    '$step',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FieldSelector extends StatelessWidget {
  final String label;
  final String? helpText;
  final List<FieldOption> options;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  const _FieldSelector({
    required this.label,
    this.helpText,
    required this.options,
    this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use chips for up to 6 options, dropdown for more
    if (options.length <= 6) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (helpText != null) ...[
            const SizedBox(height: 2),
            Text(
              helpText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final selected = opt.value == selectedValue;
              return ChoiceChip(
                label: Text(opt.label),
                selected: selected,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  onSelected(opt.value);
                },
                labelStyle: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ));
    }

    // Dropdown for many options
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      initialValue: selectedValue,
      items: options
          .map((opt) => DropdownMenuItem(
                value: opt.value,
                child: Text(opt.label),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) onSelected(value);
      },
    );
  }
}
