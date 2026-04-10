class CalculationResult {
  final double stampDuty;
  final double vehiclePrice;
  final String currency;
  final String currencySymbol;
  final String stateName;
  final String countryName;
  final DateTime registrationDate;
  final Map<String, double> additionalFees;
  final List<SlabBreakdown> breakdown;
  final double totalPayable;

  CalculationResult({
    required this.stampDuty,
    required this.vehiclePrice,
    required this.currency,
    required this.currencySymbol,
    required this.stateName,
    required this.countryName,
    required this.registrationDate,
    this.additionalFees = const {},
    this.breakdown = const [],
    required this.totalPayable,
  });
}

class SlabBreakdown {
  final String description;
  final double amount;

  SlabBreakdown({required this.description, required this.amount});
}
