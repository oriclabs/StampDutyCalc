class RateData {
  final String version;
  final String lastUpdated;
  final List<Country> countries;
  final Map<String, FieldDefinition> fieldDefinitions;
  final LuxuryCarTax? luxuryCarTax;
  final List<InsuranceProvider> insuranceProviders;
  final String? insuranceDisclaimer;

  RateData({
    required this.version,
    required this.lastUpdated,
    required this.countries,
    required this.fieldDefinitions,
    this.luxuryCarTax,
    this.insuranceProviders = const [],
    this.insuranceDisclaimer,
  });

  factory RateData.fromJson(Map<String, dynamic> json) {
    return RateData(
      version: json['version'] ?? '',
      lastUpdated: json['lastUpdated'] ?? '',
      countries: (json['countries'] as List)
          .map((c) => Country.fromJson(c))
          .toList(),
      fieldDefinitions: (json['fieldDefinitions'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, FieldDefinition.fromJson(v))) ??
          {},
      luxuryCarTax: json['luxuryCarTax'] != null
          ? LuxuryCarTax.fromJson(json['luxuryCarTax'])
          : null,
      insuranceProviders: (json['insuranceProviders'] as List?)
              ?.map((p) => InsuranceProvider.fromJson(p))
              .toList() ??
          [],
      insuranceDisclaimer: json['insuranceDisclaimer'],
    );
  }
}

class InsuranceProvider {
  final String name;
  final String description;
  final String url;
  final String logo;
  final int colorHex;
  final String? country;

  InsuranceProvider({
    required this.name,
    required this.description,
    required this.url,
    required this.logo,
    required this.colorHex,
    this.country,
  });

  factory InsuranceProvider.fromJson(Map<String, dynamic> json) {
    return InsuranceProvider(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      logo: json['logo'] ?? '',
      colorHex: int.tryParse(
              (json['colorHex'] ?? '0xFF000000').toString().replaceAll('0x', ''),
              radix: 16) ??
          0xFF000000,
      country: json['country'],
    );
  }
}

class Country {
  final String code;
  final String name;
  final String currency;
  final String currencySymbol;
  final String flag;
  final List<StateRegion> states;

  Country({
    required this.code,
    required this.name,
    required this.currency,
    required this.currencySymbol,
    required this.flag,
    required this.states,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      currency: json['currency'] ?? '',
      currencySymbol: json['currencySymbol'] ?? '\$',
      flag: json['flag'] ?? '',
      states: (json['states'] as List)
          .map((s) => StateRegion.fromJson(s))
          .toList(),
    );
  }
}

class StateRegion {
  final String code;
  final String name;
  final String? description;
  final List<String> vehicleFields;
  final List<RateRule> rates;
  final OnRoadCosts? onRoadCosts;

  StateRegion({
    required this.code,
    required this.name,
    this.description,
    required this.vehicleFields,
    required this.rates,
    this.onRoadCosts,
  });

  factory StateRegion.fromJson(Map<String, dynamic> json) {
    return StateRegion(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      vehicleFields: List<String>.from(json['vehicleFields'] ?? []),
      rates: (json['rates'] as List)
          .map((r) => RateRule.fromJson(r))
          .toList(),
      onRoadCosts: json['onRoadCosts'] != null
          ? OnRoadCosts.fromJson(json['onRoadCosts'])
          : null,
    );
  }
}

class OnRoadCosts {
  final double registration;
  final double ctp;
  final double platesFee;
  final double transferFee;
  final String? note;

  OnRoadCosts({
    required this.registration,
    required this.ctp,
    required this.platesFee,
    required this.transferFee,
    this.note,
  });

  factory OnRoadCosts.fromJson(Map<String, dynamic> json) {
    return OnRoadCosts(
      registration: (json['registration'] as num?)?.toDouble() ?? 0,
      ctp: (json['ctp'] as num?)?.toDouble() ?? 0,
      platesFee: (json['platesFee'] as num?)?.toDouble() ?? 0,
      transferFee: (json['transferFee'] as num?)?.toDouble() ?? 0,
      note: json['note'],
    );
  }
}

class LuxuryCarTax {
  final double rate;
  final double gstRate;
  final double standardThreshold;
  final double fuelEfficientThreshold;

  LuxuryCarTax({
    required this.rate,
    required this.gstRate,
    required this.standardThreshold,
    required this.fuelEfficientThreshold,
  });

  factory LuxuryCarTax.fromJson(Map<String, dynamic> json) {
    return LuxuryCarTax(
      rate: (json['rate'] as num).toDouble(),
      gstRate: (json['gstRate'] as num).toDouble(),
      standardThreshold: (json['standardThreshold'] as num).toDouble(),
      fuelEfficientThreshold:
          (json['fuelEfficientThreshold'] as num).toDouble(),
    );
  }

  /// LCT = (GST-inclusive price - threshold) * 10/11 * rate
  double calculate(double gstInclusivePrice, {bool fuelEfficient = false}) {
    final threshold =
        fuelEfficient ? fuelEfficientThreshold : standardThreshold;
    if (gstInclusivePrice <= threshold) return 0;
    final taxableAmount = (gstInclusivePrice - threshold) * 10 / 11;
    return (taxableAmount * rate * 100).round() / 100;
  }
}

class RateRule {
  final String? dateFrom;
  final String? dateTo;
  /// String/choice-based filters (equality match)
  final Map<String, String> filters;
  /// Numeric range filters: e.g. {"engineSizeMin": 1500, "engineSizeMax": 2500}
  final Map<String, double> numericFilters;
  final List<RateSlab> slabs;
  final Map<String, double>? additionalFees;

  RateRule({
    this.dateFrom,
    this.dateTo,
    required this.filters,
    this.numericFilters = const {},
    required this.slabs,
    this.additionalFees,
  });

  // Known non-filter keys in the JSON
  static const _nonFilterKeys = {
    'dateFrom', 'dateTo', 'slabs', 'additionalFees',
  };

  factory RateRule.fromJson(Map<String, dynamic> json) {
    final filters = <String, String>{};
    final numericFilters = <String, double>{};
    for (final entry in json.entries) {
      if (_nonFilterKeys.contains(entry.key)) continue;
      if (entry.value is String) {
        filters[entry.key] = entry.value;
      } else if (entry.value is num) {
        numericFilters[entry.key] = (entry.value as num).toDouble();
      }
    }

    return RateRule(
      dateFrom: json['dateFrom'],
      dateTo: json['dateTo'],
      filters: filters,
      numericFilters: numericFilters,
      slabs: (json['slabs'] as List)
          .map((s) => RateSlab.fromJson(s))
          .toList(),
      additionalFees: (json['additionalFees'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  /// Check if this rule matches the user's selections.
  ///
  /// String filters: equality match (filter "any" matches everything).
  /// Numeric filters: keys ending in "Min" or "Max" are range bounds.
  ///   E.g. engineSizeMin=1500, engineSizeMax=2500 + user enters 2000 → matches
  bool matches(Map<String, String> selections, [Map<String, double>? numericSelections]) {
    // String equality
    for (final entry in filters.entries) {
      if (entry.value == 'any') continue;
      final sel = selections[entry.key];
      if (sel != null && sel != entry.value) return false;
    }

    // Numeric range matching
    if (numericFilters.isNotEmpty && numericSelections != null) {
      for (final entry in numericFilters.entries) {
        final key = entry.key;
        final value = entry.value;

        if (key.endsWith('Min')) {
          final fieldName = key.substring(0, key.length - 3);
          final userValue = numericSelections[fieldName];
          if (userValue != null && userValue < value) return false;
        } else if (key.endsWith('Max')) {
          final fieldName = key.substring(0, key.length - 3);
          final userValue = numericSelections[fieldName];
          if (userValue != null && userValue > value) return false;
        }
      }
    }

    return true;
  }
}

class RateSlab {
  final double min;
  final double? max;
  final double rate;
  final double per;
  final double? base;
  final double? chargeFrom;
  final bool graduated;
  final double? divisor;

  RateSlab({
    required this.min,
    this.max,
    required this.rate,
    required this.per,
    this.base,
    this.chargeFrom,
    this.graduated = false,
    this.divisor,
  });

  factory RateSlab.fromJson(Map<String, dynamic> json) {
    return RateSlab(
      min: (json['min'] as num).toDouble(),
      max: json['max'] != null ? (json['max'] as num).toDouble() : null,
      rate: (json['rate'] as num).toDouble(),
      per: (json['per'] as num?)?.toDouble() ?? 100,
      base: json['base'] != null ? (json['base'] as num).toDouble() : null,
      chargeFrom: json['chargeFrom'] != null
          ? (json['chargeFrom'] as num).toDouble()
          : null,
      graduated: json['graduated'] ?? false,
      divisor: json['divisor'] != null
          ? (json['divisor'] as num).toDouble()
          : null,
    );
  }
}

class FieldDefinition {
  final String label;
  /// 'choice' (default), 'number', 'boolean'
  final String type;
  final String? helpText;
  final String? prefix;
  final String? suffix;
  final double? min;
  final double? max;
  final double? defaultValue;
  final List<FieldOption> options;
  final Map<String, String>? showWhen;
  final DateTime? showBeforeDate;
  final DateTime? showFromDate;

  FieldDefinition({
    required this.label,
    required this.type,
    this.helpText,
    this.prefix,
    this.suffix,
    this.min,
    this.max,
    this.defaultValue,
    required this.options,
    this.showWhen,
    this.showBeforeDate,
    this.showFromDate,
  });

  factory FieldDefinition.fromJson(Map<String, dynamic> json) {
    return FieldDefinition(
      label: json['label'] ?? '',
      type: json['type'] ?? 'choice',
      helpText: json['helpText'],
      prefix: json['prefix'],
      suffix: json['suffix'],
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      defaultValue: (json['default'] as num?)?.toDouble(),
      options: (json['options'] as List?)
              ?.map((o) => FieldOption.fromJson(o))
              .toList() ??
          [],
      showWhen: (json['showWhen'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      showBeforeDate: json['showBeforeDate'] != null
          ? DateTime.parse(json['showBeforeDate'])
          : null,
      showFromDate: json['showFromDate'] != null
          ? DateTime.parse(json['showFromDate'])
          : null,
    );
  }
}

class FieldOption {
  final String value;
  final String label;

  FieldOption({required this.value, required this.label});

  factory FieldOption.fromJson(Map<String, dynamic> json) {
    return FieldOption(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
    );
  }
}
