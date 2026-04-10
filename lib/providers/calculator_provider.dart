import 'package:flutter/material.dart';
import '../models/rate_models.dart';
import '../models/calculation_result.dart';
import '../services/rate_service.dart';
import '../services/stamp_duty_calculator.dart';

enum CalculatorMode { stampDuty, onRoad }

class CalculatorProvider extends ChangeNotifier {
  final RateService _rateService = RateService();

  RateData? _rateData;
  Country? _selectedCountry;
  StateRegion? _selectedState;
  Map<String, String> _selections = {};
  double? _vehiclePrice;
  DateTime _registrationDate = DateTime.now();
  CalculationResult? _result;
  bool _isLoading = true;
  String? _error;

  // On-road specific fields
  CalculatorMode _mode = CalculatorMode.stampDuty;
  double _dealerDelivery = 0;
  bool _isFuelEfficient = false;

  RateData? get rateData => _rateData;
  Country? get selectedCountry => _selectedCountry;
  StateRegion? get selectedState => _selectedState;
  Map<String, String> get selections => _selections;
  double? get vehiclePrice => _vehiclePrice;
  DateTime get registrationDate => _registrationDate;
  CalculationResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CalculatorMode get mode => _mode;
  double get dealerDelivery => _dealerDelivery;
  bool get isFuelEfficient => _isFuelEfficient;

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

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rateData = await _rateService.loadRates();
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

  void setRegistrationDate(DateTime date) {
    _registrationDate = date;
    _result = null;
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

  void calculate() {
    if (!canCalculate) return;

    if (_mode == CalculatorMode.stampDuty) {
      _result = StampDutyCalculator.calculate(
        country: _selectedCountry!,
        state: _selectedState!,
        vehiclePrice: _vehiclePrice!,
        selections: _selections,
        registrationDate: _registrationDate,
      );
    } else {
      _result = StampDutyCalculator.calculateOnRoad(
        country: _selectedCountry!,
        state: _selectedState!,
        vehiclePrice: _vehiclePrice!,
        selections: _selections,
        registrationDate: _registrationDate,
        dealerDelivery: _dealerDelivery,
        isFuelEfficient: _isFuelEfficient,
        isNewVehicle: isNewVehicle,
        lct: _rateData?.luxuryCarTax,
      );
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
    _result = null;
    notifyListeners();
  }

  void resetAll() {
    _selectedCountry = null;
    reset();
    notifyListeners();
  }

  bool shouldShowField(String fieldName) {
    final def = fieldDefinitions[fieldName];
    if (def?.showWhen == null) return true;
    for (final entry in def!.showWhen!.entries) {
      if (_selections[entry.key] != entry.value) return false;
    }
    return true;
  }
}
