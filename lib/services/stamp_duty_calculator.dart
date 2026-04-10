import '../models/rate_models.dart';
import '../models/calculation_result.dart';

class StampDutyCalculator {
  /// Calculate stamp duty only
  static CalculationResult? calculate({
    required Country country,
    required StateRegion state,
    required double vehiclePrice,
    required Map<String, String> selections,
    DateTime? registrationDate,
  }) {
    return _calculate(
      country: country,
      state: state,
      vehiclePrice: vehiclePrice,
      selections: selections,
      registrationDate: registrationDate,
      onRoadMode: false,
    );
  }

  /// Calculate full on-road costs (stamp duty + rego + CTP + LCT + delivery)
  static CalculationResult? calculateOnRoad({
    required Country country,
    required StateRegion state,
    required double vehiclePrice,
    required Map<String, String> selections,
    DateTime? registrationDate,
    double dealerDelivery = 0,
    bool isFuelEfficient = false,
    bool isNewVehicle = true,
    LuxuryCarTax? lct,
  }) {
    return _calculate(
      country: country,
      state: state,
      vehiclePrice: vehiclePrice,
      selections: selections,
      registrationDate: registrationDate,
      onRoadMode: true,
      dealerDelivery: dealerDelivery,
      isFuelEfficient: isFuelEfficient,
      isNewVehicle: isNewVehicle,
      lct: lct,
    );
  }

  static CalculationResult? _calculate({
    required Country country,
    required StateRegion state,
    required double vehiclePrice,
    required Map<String, String> selections,
    DateTime? registrationDate,
    required bool onRoadMode,
    double dealerDelivery = 0,
    bool isFuelEfficient = false,
    bool isNewVehicle = true,
    LuxuryCarTax? lct,
  }) {
    final matchingRule = _findMatchingRule(state, selections, registrationDate);
    if (matchingRule == null) return null;

    final slab = _findMatchingSlab(matchingRule.slabs, vehiclePrice);
    if (slab == null) return null;

    final duty = _calculateSlab(slab, vehiclePrice);

    final breakdown = <SlabBreakdown>[
      SlabBreakdown(
        description: 'Vehicle price',
        amount: vehiclePrice,
      ),
      SlabBreakdown(
        description: 'Stamp duty',
        amount: duty,
      ),
    ];

    // Additional fees from rate rule (NZ licensing etc.)
    double ruleFeesTotal = 0;
    final additionalFees = <String, double>{};
    if (matchingRule.additionalFees != null) {
      for (final entry in matchingRule.additionalFees!.entries) {
        additionalFees[entry.key] = entry.value;
        ruleFeesTotal += entry.value;
        breakdown.add(SlabBreakdown(
          description: _formatFeeLabel(entry.key),
          amount: entry.value,
        ));
      }
    }

    double totalPayable = duty + ruleFeesTotal;

    // On-road cost components
    double? registration;
    double? ctp;
    double? platesFee;
    double? luxuryCarTaxAmount;

    if (onRoadMode && state.onRoadCosts != null) {
      final orc = state.onRoadCosts!;

      if (isNewVehicle) {
        registration = orc.registration;
        ctp = orc.ctp;
        platesFee = orc.platesFee;
      } else {
        registration = orc.registration;
        ctp = orc.ctp;
        platesFee = orc.transferFee; // Transfer fee instead of plates
      }

      if (registration > 0) {
        breakdown.add(SlabBreakdown(
            description: 'Registration', amount: registration));
        totalPayable += registration;
      }
      if (ctp > 0) {
        breakdown.add(
            SlabBreakdown(description: 'CTP / Insurance', amount: ctp));
        totalPayable += ctp;
      }
      if (platesFee > 0) {
        breakdown.add(SlabBreakdown(
          description: isNewVehicle ? 'Plates fee' : 'Transfer fee',
          amount: platesFee,
        ));
        totalPayable += platesFee;
      }

      // LCT (only for AU, new vehicles above threshold)
      if (lct != null && isNewVehicle) {
        // Vehicle price is GST-inclusive for LCT purposes
        luxuryCarTaxAmount =
            lct.calculate(vehiclePrice, fuelEfficient: isFuelEfficient);
        if (luxuryCarTaxAmount > 0) {
          breakdown.add(SlabBreakdown(
              description: 'Luxury Car Tax', amount: luxuryCarTaxAmount));
          totalPayable += luxuryCarTaxAmount;
        }
      }

      // Dealer delivery
      if (dealerDelivery > 0) {
        breakdown.add(SlabBreakdown(
            description: 'Dealer delivery', amount: dealerDelivery));
        totalPayable += dealerDelivery;
      }
    }

    return CalculationResult(
      stampDuty: duty,
      vehiclePrice: vehiclePrice,
      currency: country.currency,
      currencySymbol: country.currencySymbol,
      stateName: state.name,
      countryName: country.name,
      registrationDate: registrationDate ?? DateTime.now(),
      additionalFees: additionalFees,
      breakdown: breakdown,
      totalPayable: _roundCents(totalPayable),
      registration: registration,
      ctp: ctp,
      platesFee: platesFee,
      dealerDelivery: dealerDelivery > 0 ? dealerDelivery : null,
      luxuryCarTax: luxuryCarTaxAmount,
      onRoadTotal: onRoadMode ? _roundCents(totalPayable) : null,
      isOnRoadMode: onRoadMode,
    );
  }

  static RateRule? _findMatchingRule(
    StateRegion state,
    Map<String, String> selections,
    DateTime? date,
  ) {
    RateRule? bestMatch;
    DateTime? bestDateFrom;

    for (final rule in state.rates) {
      if (!rule.matches(selections)) continue;

      if (date != null) {
        if (rule.dateFrom != null) {
          final from = DateTime.parse(rule.dateFrom!);
          if (date.isBefore(from)) continue;
        }
        if (rule.dateTo != null) {
          final to = DateTime.parse(rule.dateTo!);
          if (date.isAfter(to)) continue;
        }
      }

      final ruleDateFrom =
          rule.dateFrom != null ? DateTime.parse(rule.dateFrom!) : null;
      if (bestMatch == null ||
          (ruleDateFrom != null &&
              (bestDateFrom == null || ruleDateFrom.isAfter(bestDateFrom)))) {
        bestMatch = rule;
        bestDateFrom = ruleDateFrom;
      }
    }

    return bestMatch;
  }

  static RateSlab? _findMatchingSlab(List<RateSlab> slabs, double price) {
    for (final slab in slabs) {
      final inMin = price >= slab.min;
      final inMax = slab.max == null || price <= slab.max!;
      if (inMin && inMax) return slab;
    }
    return null;
  }

  static double _calculateSlab(RateSlab slab, double price) {
    double amount = price;

    if (slab.chargeFrom != null) {
      amount = price - slab.chargeFrom!;
    }

    double effectiveRate = slab.rate;

    if (slab.graduated && slab.divisor != null && slab.chargeFrom != null) {
      final extra = price - slab.chargeFrom!;
      effectiveRate = slab.rate + (extra / slab.divisor!);
      amount = price;
    }

    final unit = slab.per;
    final units = (amount / unit).floor() + (amount % unit != 0 ? 1 : 0);
    final duty = (slab.base ?? 0) + (units * effectiveRate);

    return _roundCents(duty);
  }

  static double _roundCents(double value) {
    return (value * 100).round() / 100;
  }

  static String _formatFeeLabel(String key) {
    final result = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }
}
