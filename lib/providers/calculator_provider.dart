import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rate_models.dart';
import '../models/calculation_result.dart';
import '../services/rate_service.dart';
import '../services/stamp_duty_calculator.dart';
import '../services/history_service.dart';

enum CalculatorMode { stampDuty, onRoad }

class CalculatorProvider extends ChangeNotifier {
  final RateService _rateService = RateService();

  RateData? _rateData;
  Country? _selectedCountry;
  StateRegion? _selectedState;
  Map<String, String> _selections = {};
  final Map<String, double> _numericSelections = {};
  double? _vehiclePrice;
  DateTime _registrationDate = DateTime.now();
  CalculationResult? _result;
  bool _isLoading = true;
  String? _error;

  // On-road specific fields
  CalculatorMode _mode = CalculatorMode.stampDuty;
  double _dealerDelivery = 0;
  bool _isFuelEfficient = false;
  bool _ratesUpdated = false;

  // Embedded features
  bool _hasTradeIn = false;
  double _tradeInValue = 0;
  bool _hasAbn = false;
  String _customerName = '';

  // Dealer quote adjustments (applied on top of calculated result)
  double _discount = 0;
  final List<QuoteLineItem> _customItems = [];
  final Map<String, double> _overrides = {};

  // Finance section (in result screen)
  bool _hasFinance = false;
  double _loanDeposit = 0;
  double _loanRate = 7.5;
  int _loanTermYears = 5;

  static const _abnPrefKey = 'has_abn';
  static const _tradeInPrefKey = 'remembers_trade_in';

  /// Australian states that allow stamp duty on net price after trade-in
  static const _tradeInEligibleStates = {'NSW', 'NT', 'QLD', 'SA', 'WA'};

  RateData? get rateData => _rateData;
  Country? get selectedCountry => _selectedCountry;
  StateRegion? get selectedState => _selectedState;
  Map<String, String> get selections => _selections;
  Map<String, double> get numericSelections => _numericSelections;
  double? get vehiclePrice => _vehiclePrice;
  DateTime get registrationDate => _registrationDate;
  CalculationResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CalculatorMode get mode => _mode;
  double get dealerDelivery => _dealerDelivery;
  bool get isFuelEfficient => _isFuelEfficient;
  bool get ratesUpdated => _ratesUpdated;
  bool get hasTradeIn => _hasTradeIn;
  double get tradeInValue => _tradeInValue;
  bool get hasAbn => _hasAbn;
  String get customerName => _customerName;
  double get discount => _discount;
  List<QuoteLineItem> get customItems => List.unmodifiable(_customItems);
  Map<String, double> get overrides => Map.unmodifiable(_overrides);

  /// Total after dealer adjustments (overrides, discount, custom items)
  double get adjustedTotal {
    if (_result == null) return 0;
    double total = _result!.totalPayable;
    // Apply overrides (replace original amount with override)
    for (final entry in _overrides.entries) {
      final originalItem = _result!.breakdown
          .where((b) => b.description == entry.key)
          .firstOrNull;
      if (originalItem != null) {
        total -= originalItem.amount;
        total += entry.value;
      }
    }
    // Apply discount (subtract)
    total -= _discount;
    // Apply custom items (add)
    for (final item in _customItems) {
      total += item.amount;
    }
    return total;
  }
  bool get hasFinance => _hasFinance;
  double get loanDeposit => _loanDeposit;
  double get loanRate => _loanRate;
  int get loanTermYears => _loanTermYears;

  bool get tradeInEligible {
    final code = _selectedState?.code;
    return code != null && _tradeInEligibleStates.contains(code);
  }

  /// Effective price for stamp duty calculation:
  /// = vehicle price - discount - trade-in (if eligible state)
  double get dutiablePrice {
    if (_vehiclePrice == null) return 0;
    var price = _vehiclePrice! - _discount;
    if (_hasTradeIn && tradeInEligible) {
      price -= _tradeInValue;
    }
    return price.clamp(0, double.infinity);
  }

  /// Net price after discount only (used for display, not for trade-in handling)
  double get netVehiclePrice {
    if (_vehiclePrice == null) return 0;
    return (_vehiclePrice! - _discount).clamp(0, double.infinity);
  }

  List<Country> get countries => _rateData?.countries ?? [];

  List<String> get requiredFields => _selectedState?.vehicleFields ?? [];

  Map<String, FieldDefinition> get fieldDefinitions =>
      _rateData?.fieldDefinitions ?? {};

  bool get isNewVehicle =>
      _selections['registrationType'] == 'new' ||
      !_selections.containsKey('registrationType');

  bool get canCalculate {
    if (_selectedCountry == null || _selectedState == null) return false;
    if (_vehiclePrice == null || _vehiclePrice! <= 0) return false;
    for (final field in requiredFields) {
      final def = fieldDefinitions[field];
      if (def?.showWhen != null) {
        bool shouldShow = true;
        for (final entry in def!.showWhen!.entries) {
          if (_selections[entry.key] != entry.value) {
            shouldShow = false;
            break;
          }
        }
        if (!shouldShow) continue;
      }
      if (!_selections.containsKey(field)) return false;
    }
    return true;
  }

  void clearRatesUpdated() {
    _ratesUpdated = false;
  }

  static const _defaultCountryKey = 'default_country';

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rateData = await _rateService.loadRates();

      // Restore preferences
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_defaultCountryKey);
      if (savedCode != null && _rateData != null) {
        final match = _rateData!.countries
            .where((c) => c.code == savedCode)
            .firstOrNull;
        if (match != null) {
          _selectedCountry = match;
        }
      }
      _hasAbn = prefs.getBool(_abnPrefKey) ?? false;
      _hasTradeIn = prefs.getBool(_tradeInPrefKey) ?? false;

      // Check for background updates after a short delay
      Future.delayed(const Duration(seconds: 3), () async {
        if (_rateService.hasRemoteUpdate) {
          _rateData = _rateService.rateData;
          _ratesUpdated = true;
          notifyListeners();
        }
      });
    } catch (e) {
      _error = 'Failed to load rates: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setMode(CalculatorMode mode) {
    _mode = mode;
    _result = null;
    notifyListeners();
  }

  void selectCountry(Country country) {
    _selectedCountry = country;
    _selectedState = null;
    _selections = {};
    _vehiclePrice = null;
    _result = null;
    notifyListeners();
    // Persist
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_defaultCountryKey, country.code));
  }

  void selectState(StateRegion state) {
    _selectedState = state;
    _selections = {};
    _result = null;
    notifyListeners();
  }

  void setSelection(String field, String value) {
    _selections[field] = value;
    _result = null;

    if (field == 'vehicleType' || field == 'registrationType') {
      for (final f in requiredFields) {
        final def = fieldDefinitions[f];
        if (def?.showWhen != null) {
          bool shouldShow = true;
          for (final entry in def!.showWhen!.entries) {
            if (_selections[entry.key] != entry.value) {
              shouldShow = false;
              break;
            }
          }
          if (!shouldShow) {
            _selections.remove(f);
          }
        }
      }
    }

    notifyListeners();
  }

  void setVehiclePrice(double? price) {
    _vehiclePrice = price;
    _result = null;
    notifyListeners();
  }

  void setNumericSelection(String field, double value) {
    _numericSelections[field] = value;
    _result = null;
    notifyListeners();
  }

  void setRegistrationDate(DateTime date) {
    _registrationDate = date;
    _result = null;
    // Clear fields that are no longer visible for the new date
    for (final field in requiredFields) {
      if (!shouldShowField(field)) {
        _selections.remove(field);
      }
    }
    notifyListeners();
  }

  void setDealerDelivery(double value) {
    _dealerDelivery = value;
    _result = null;
    notifyListeners();
  }

  void setFuelEfficient(bool value) {
    _isFuelEfficient = value;
    _result = null;
    notifyListeners();
  }

  void setHasTradeIn(bool value) {
    _hasTradeIn = value;
    _result = null;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_tradeInPrefKey, value));
  }

  void setTradeInValue(double value) {
    _tradeInValue = value;
    _result = null;
    notifyListeners();
  }

  void setHasAbn(bool value) {
    _hasAbn = value;
    _result = null;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_abnPrefKey, value));
  }

  void setCustomerName(String name) {
    _customerName = name;
    notifyListeners();
  }

  void setDiscount(double value) {
    _discount = value;
    _result = null;
    notifyListeners();
  }

  void addCustomItem(String label, double amount) {
    _customItems.add(QuoteLineItem(label: label, amount: amount));
    notifyListeners();
  }

  void removeCustomItem(int index) {
    if (index >= 0 && index < _customItems.length) {
      _customItems.removeAt(index);
      notifyListeners();
    }
  }

  void setOverride(String description, double value) {
    _overrides[description] = value;
    notifyListeners();
  }

  void clearOverride(String description) {
    _overrides.remove(description);
    notifyListeners();
  }

  void resetQuoteAdjustments() {
    _discount = 0;
    _customItems.clear();
    _overrides.clear();
    notifyListeners();
  }

  void setHasFinance(bool value) {
    _hasFinance = value;
    notifyListeners();
  }

  void setLoanDeposit(double value) {
    _loanDeposit = value;
    notifyListeners();
  }

  void setLoanRate(double value) {
    _loanRate = value;
    notifyListeners();
  }

  void setLoanTermYears(int value) {
    _loanTermYears = value;
    notifyListeners();
  }

  Future<void> calculate() async {
    if (!canCalculate) return;

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Clear quote adjustments for fresh calculation
    _discount = 0;
    _customItems.clear();
    _overrides.clear();

    // Use dutiable price (net of trade-in if eligible state)
    final priceForDuty = dutiablePrice;

    if (_mode == CalculatorMode.stampDuty) {
      _result = StampDutyCalculator.calculate(
        country: _selectedCountry!,
        state: _selectedState!,
        vehiclePrice: priceForDuty,
        selections: _selections,
        numericSelections: _numericSelections,
        registrationDate: _registrationDate,
      );
    } else {
      _result = StampDutyCalculator.calculateOnRoad(
        country: _selectedCountry!,
        state: _selectedState!,
        vehiclePrice: priceForDuty,
        selections: _selections,
        numericSelections: _numericSelections,
        registrationDate: _registrationDate,
        dealerDelivery: _dealerDelivery,
        isFuelEfficient: _isFuelEfficient,
        isNewVehicle: isNewVehicle,
        lct: _rateData?.luxuryCarTax,
      );
    }

    // Save to history
    if (_result != null) {
      await HistoryService.addEntry(HistoryEntry(
        countryName: _result!.countryName,
        stateName: _result!.stateName,
        stateCode: _selectedState!.code,
        vehiclePrice: _vehiclePrice!,
        stampDuty: _result!.stampDuty,
        totalPayable: _result!.totalPayable,
        isOnRoad: _result!.isOnRoadMode,
        currency: _result!.currency,
        currencySymbol: _result!.currencySymbol,
        timestamp: DateTime.now(),
      ));
    }

    notifyListeners();
  }

  void reset() {
    _selectedState = null;
    _selections = {};
    _vehiclePrice = null;
    _registrationDate = DateTime.now();
    _dealerDelivery = 0;
    _isFuelEfficient = false;
    _customerName = '';
    _tradeInValue = 0;
    _discount = 0;
    _customItems.clear();
    _overrides.clear();
    _result = null;
    notifyListeners();
  }

  void resetAll() {
    _selectedCountry = null;
    reset();
    notifyListeners();
    // Clear persisted default
    SharedPreferences.getInstance()
        .then((prefs) => prefs.remove(_defaultCountryKey));
  }

  bool shouldShowField(String fieldName) {
    final def = fieldDefinitions[fieldName];
    if (def == null) return true;

    // Check date-based visibility
    if (def.showBeforeDate != null &&
        !_registrationDate.isBefore(def.showBeforeDate!)) {
      return false;
    }
    if (def.showFromDate != null &&
        _registrationDate.isBefore(def.showFromDate!)) {
      return false;
    }

    // Check field-based visibility
    if (def.showWhen != null) {
      for (final entry in def.showWhen!.entries) {
        if (_selections[entry.key] != entry.value) return false;
      }
    }
    return true;
  }
}

class QuoteLineItem {
  final String label;
  final double amount;

  const QuoteLineItem({required this.label, required this.amount});
}
