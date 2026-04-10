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

  // On-road cost fields (null if stamp-duty-only mode)
  final double? registration;
  final double? ctp;
  final double? platesFee;
  final double? dealerDelivery;
  final double? luxuryCarTax;
  final double? gst;
  final double? onRoadTotal;
  final bool isOnRoadMode;

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
    this.registration,
    this.ctp,
    this.platesFee,
    this.dealerDelivery,
    this.luxuryCarTax,
    this.gst,
    this.onRoadTotal,
    this.isOnRoadMode = false,
  });
}

class SlabBreakdown {
  final String description;
  final double amount;

  SlabBreakdown({required this.description, required this.amount});
}
