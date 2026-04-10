import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/calculator_provider.dart';
import '../models/rate_models.dart';
import 'result_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _priceController = TextEditingController();
  final _priceFocusNode = FocusNode();

  @override
  void dispose() {
    _priceController.dispose();
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
          if (provider.selectedState != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset',
              onPressed: () {
                _priceController.clear();
                provider.reset();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step 1: State selection
            _SectionHeader(
              step: 1,
              title: country.states.length == 1
                  ? 'Region'
                  : 'Select State / Territory',
              isCompleted: provider.selectedState != null,
            ),
            const SizedBox(height: 12),
            _buildStateSelector(context, provider, country),

            // Step 2: Vehicle details (shown after state selected)
            if (provider.selectedState != null) ...[
              const SizedBox(height: 28),
              _SectionHeader(
                step: 2,
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
                  step: 3,
                  title: 'On-Road Options',
                  isCompleted: true,
                ),
                const SizedBox(height: 12),
                _buildDeliveryInput(context, provider, country),
                const SizedBox(height: 12),
                _buildFuelEfficientToggle(context, provider),
              ],
            ],

            // Calculate button
            if (provider.selectedState != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: provider.canCalculate
                    ? () {
                        _priceFocusNode.unfocus();
                        provider.calculate();
                        if (provider.result != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ResultScreen(),
                            ),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.calculate),
                label: Text(provider.mode == CalculatorMode.stampDuty
                    ? 'Calculate Stamp Duty'
                    : 'Calculate On-Road Cost'),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStateSelector(
      BuildContext context, CalculatorProvider provider, Country country) {
    // If only 1 state (like NZ), auto-select it
    if (country.states.length == 1 && provider.selectedState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.selectState(country.states.first);
      });
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: country.states.map((state) {
        final isSelected = provider.selectedState?.code == state.code;
        return ChoiceChip(
          label: Text(state.code),
          tooltip: state.name,
          selected: isSelected,
          onSelected: (_) {
            _priceController.clear();
            provider.selectState(state);
          },
          labelStyle: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker(BuildContext context, CalculatorProvider provider) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM yyyy');

    return GestureDetector(
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
    );
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
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      decoration: InputDecoration(
        labelText: 'Vehicle Price / Dutiable Value',
        prefixText: '${country.currencySymbol} ',
        hintText: 'Enter amount',
        suffixIcon: _priceController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _priceController.clear();
                  provider.setVehiclePrice(null);
                },
              )
            : null,
      ),
      onChanged: (value) {
        final price = double.tryParse(value);
        provider.setVehiclePrice(price);
        setState(() {}); // For suffix icon
      },
    );
  }

  Widget _buildDeliveryInput(
      BuildContext context, CalculatorProvider provider, Country country) {
    return TextField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      decoration: InputDecoration(
        labelText: 'Dealer Delivery (optional)',
        prefixText: '${country.currencySymbol} ',
        hintText: '0',
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
          'Under 3.5 L/100km (higher LCT threshold)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: provider.isFuelEfficient,
        onChanged: (value) => provider.setFuelEfficient(value),
      ),
    );
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
                ? Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary)
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
  final List<FieldOption> options;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  const _FieldSelector({
    required this.label,
    required this.options,
    this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use chips for 2-3 options, dropdown for more
    if (options.length <= 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final selected = opt.value == selectedValue;
              return ChoiceChip(
                label: Text(opt.label),
                selected: selected,
                onSelected: (_) => onSelected(opt.value),
                labelStyle: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      );
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
