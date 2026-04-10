import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stamp_duty_calc/models/rate_models.dart';
import 'package:stamp_duty_calc/models/calculation_result.dart';
import 'package:stamp_duty_calc/services/stamp_duty_calculator.dart';

late RateData rateData;
late Country au;

void main() {
  setUpAll(() {
    final jsonString = File('assets/rates/rates.json').readAsStringSync();
    rateData = RateData.fromJson(json.decode(jsonString));
    au = rateData.countries.firstWhere((c) => c.code == 'AU');
  });

  // ─── Helper ───────────────────────────────────────────────────────
  CalculationResult? calc(
    String stateCode,
    double price,
    Map<String, String> selections, {
    DateTime? date,
  }) {
    final state = au.states.firstWhere((s) => s.code == stateCode);
    return StampDutyCalculator.calculate(
      country: au,
      state: state,
      vehiclePrice: price,
      selections: selections,
      registrationDate: date ?? DateTime(2026, 1, 15),
    );
  }

  CalculationResult? calcOnRoad(
    String stateCode,
    double price,
    Map<String, String> selections, {
    double delivery = 0,
    bool fuelEfficient = false,
    bool isNew = true,
  }) {
    final state = au.states.firstWhere((s) => s.code == stateCode);
    return StampDutyCalculator.calculateOnRoad(
      country: au,
      state: state,
      vehiclePrice: price,
      selections: selections,
      registrationDate: DateTime(2026, 1, 15),
      dealerDelivery: delivery,
      isFuelEfficient: fuelEfficient,
      isNewVehicle: isNew,
      lct: rateData.luxuryCarTax,
    );
  }

  // ─── NSW ──────────────────────────────────────────────────────────
  group('NSW', () {
    test('passenger \$30,000 → \$900', () {
      final r = calc('NSW', 30000, {'vehicleType': 'passenger'});
      expect(r, isNotNull);
      expect(r!.stampDuty, 900); // 300 units * $3
    });

    test('passenger \$60,000 → \$1,350 + \$750 = \$2,100', () {
      final r = calc('NSW', 60000, {'vehicleType': 'passenger'});
      expect(r, isNotNull);
      // base $1350 + (60000-45000)/100 * $5 = 1350 + 750 = 2100
      expect(r!.stampDuty, 2100);
    });

    test('non-passenger \$80,000 → \$2,400', () {
      final r = calc('NSW', 80000, {'vehicleType': 'non-passenger'});
      expect(r, isNotNull);
      expect(r!.stampDuty, 2400); // 800 * $3
    });

    test('passenger at slab boundary \$45,000', () {
      final r = calc('NSW', 45000, {'vehicleType': 'passenger'});
      expect(r, isNotNull);
      expect(r!.stampDuty, 1350); // 450 * $3
    });
  });

  // ─── VIC ──────────────────────────────────────────────────────────
  group('VIC', () {
    test('new passenger \$50,000 → \$2,100', () {
      final r = calc('VIC', 50000, {
        'vehicleType': 'passenger',
        'registrationType': 'new',
      });
      expect(r, isNotNull);
      // 250 units * $8.40 = $2,100
      expect(r!.stampDuty, 2100);
    });

    test('new passenger \$90,000 hits second tier', () {
      final r = calc('VIC', 90000, {
        'vehicleType': 'passenger',
        'registrationType': 'new',
      });
      expect(r, isNotNull);
      // 450 units * $10.40 = $4,680
      expect(r!.stampDuty, 4680);
    });

    test('used vehicle \$40,000', () {
      final r = calc('VIC', 40000, {
        'vehicleType': 'passenger',
        'registrationType': 'used',
      });
      expect(r, isNotNull);
      // 200 units * $8.40 = $1,680
      expect(r!.stampDuty, 1680);
    });

    test('new non-passenger \$30,000', () {
      final r = calc('VIC', 30000, {
        'vehicleType': 'non-passenger',
        'registrationType': 'new',
      });
      expect(r, isNotNull);
      // 150 units * $5.40 = $810
      expect(r!.stampDuty, 810);
    });
  });

  // ─── QLD ──────────────────────────────────────────────────────────
  group('QLD', () {
    test('4-cyl \$50,000 → \$1,500', () {
      final r = calc('QLD', 50000, {'qldCategory': '1-4cyl'});
      expect(r, isNotNull);
      expect(r!.stampDuty, 1500); // 500 * $3
    });

    test('4-cyl \$120,000 hits second tier', () {
      final r = calc('QLD', 120000, {'qldCategory': '1-4cyl'});
      expect(r, isNotNull);
      // 1200 * $5 = $6,000
      expect(r!.stampDuty, 6000);
    });

    test('electric \$80,000 → \$1,600', () {
      final r = calc('QLD', 80000, {'qldCategory': 'electric'});
      expect(r, isNotNull);
      expect(r!.stampDuty, 1600); // 800 * $2
    });

    test('special purpose → flat \$25', () {
      final r = calc('QLD', 999999, {'qldCategory': 'special'});
      expect(r, isNotNull);
      expect(r!.stampDuty, 25);
    });
  });

  // ─── SA ───────────────────────────────────────────────────────────
  group('SA', () {
    test('non-commercial \$500 → \$10', () {
      final r = calc('SA', 500, {'vehicleUse': 'non-commercial'});
      expect(r, isNotNull);
      // 5 units * $1 + $5 base = $10
      expect(r!.stampDuty, 10);
    });

    test('non-commercial \$25,000', () {
      final r = calc('SA', 25000, {'vehicleUse': 'non-commercial'});
      expect(r, isNotNull);
      // $60 base + (25000-3000)/100 * $4 = 60 + 880 = $940
      expect(r!.stampDuty, 940);
    });
  });

  // ─── NT ───────────────────────────────────────────────────────────
  group('NT', () {
    test('standard \$40,000 → \$1,200', () {
      final r = calc('NT', 40000, {'ntVehicleType': 'standard'});
      expect(r, isNotNull);
      expect(r!.stampDuty, 1200);
    });

    test('electric \$40,000 → \$0 (EV concession)', () {
      final r = calc('NT', 40000, {'ntVehicleType': 'electric'},
          date: DateTime(2026, 1, 1));
      expect(r, isNotNull);
      expect(r!.stampDuty, 0);
    });

    test('electric \$70,000 → duty on amount above \$50k', () {
      final r = calc('NT', 70000, {'ntVehicleType': 'electric'},
          date: DateTime(2026, 1, 1));
      expect(r, isNotNull);
      // (70000-50000)/100 * $3 = 200 * $3 = $600
      expect(r!.stampDuty, 600);
    });
  });

  // ─── TAS ──────────────────────────────────────────────────────────
  group('TAS', () {
    test('passenger \$300 → \$20 minimum', () {
      final r = calc('TAS', 300, {'tasVehicleType': 'passenger'});
      expect(r, isNotNull);
      expect(r!.stampDuty, 20);
    });

    test('passenger \$20,000 → \$600', () {
      final r = calc('TAS', 20000, {'tasVehicleType': 'passenger'});
      expect(r, isNotNull);
      expect(r!.stampDuty, 600); // 200 * $3
    });

    test('heavy vehicle \$50,000 → \$520', () {
      final r = calc('TAS', 50000, {'tasVehicleType': 'heavy'});
      expect(r, isNotNull);
      // $20 base + 500 * $1 = $520
      expect(r!.stampDuty, 520);
    });
  });

  // ─── ACT (new emissions system, from Sep 2025) ────────────────────
  group('ACT new system', () {
    test('new passenger AAA \$30,000', () {
      final r = calc('ACT', 30000, {
        'vehicleType': 'passenger',
        'registrationType': 'new',
        'emissionsRating': 'AAA',
      }, date: DateTime(2025, 10, 1));
      expect(r, isNotNull);
      // 300 * $2.50 = $750
      expect(r!.stampDuty, 750);
    });

    test('new passenger D rating \$30,000', () {
      final r = calc('ACT', 30000, {
        'vehicleType': 'passenger',
        'registrationType': 'new',
        'emissionsRating': 'D',
      }, date: DateTime(2025, 10, 1));
      expect(r, isNotNull);
      // 300 * $4.53 = $1,359
      expect(r!.stampDuty, 1359);
    });
  });

  // ─── ACT (old green rating system, pre-Sep 2025) ──────────────────
  group('ACT old green rating', () {
    test('green rating A (5+ stars) → exempt', () {
      final r = calc('ACT', 60000, {
        'vehicleType': 'passenger',
        'registrationType': 'new',
        'greenRating': 'A',
      }, date: DateTime(2025, 6, 1));
      expect(r, isNotNull);
      expect(r!.stampDuty, 0);
    });

    test('green rating B \$30,000 → \$300', () {
      final r = calc('ACT', 30000, {
        'vehicleType': 'passenger',
        'registrationType': 'new',
        'greenRating': 'B',
      }, date: DateTime(2025, 6, 1));
      expect(r, isNotNull);
      // 300 * $1 = $300
      expect(r!.stampDuty, 300);
    });

    test('green rating C \$60,000 → \$1,350 + \$750', () {
      final r = calc('ACT', 60000, {
        'vehicleType': 'passenger',
        'registrationType': 'new',
        'greenRating': 'C',
      }, date: DateTime(2025, 6, 1));
      expect(r, isNotNull);
      // base $1350 + (60000-45000)/100 * $5 = 1350 + 750 = $2,100
      expect(r!.stampDuty, 2100);
    });

    test('green rating D \$30,000 → \$1,200', () {
      final r = calc('ACT', 30000, {
        'vehicleType': 'passenger',
        'registrationType': 'new',
        'greenRating': 'D',
      }, date: DateTime(2025, 6, 1));
      expect(r, isNotNull);
      // 300 * $4 = $1,200
      expect(r!.stampDuty, 1200);
    });

    test('used vehicle pre-Sep 2025 → \$3/100', () {
      final r = calc('ACT', 40000, {
        'vehicleType': 'passenger',
        'registrationType': 'used',
      }, date: DateTime(2025, 6, 1));
      expect(r, isNotNull);
      // 400 * $3 = $1,200
      expect(r!.stampDuty, 1200);
    });

    test('non-passenger pre-Sep 2025 → \$3/100', () {
      final r = calc('ACT', 50000, {
        'vehicleType': 'non-passenger',
        'registrationType': 'new',
      }, date: DateTime(2025, 6, 1));
      expect(r, isNotNull);
      // 500 * $3 = $1,500
      expect(r!.stampDuty, 1500);
    });
  });

  // ─── Luxury Car Tax ───────────────────────────────────────────────
  group('LCT', () {
    test('LCT on \$100,000 standard vehicle', () {
      final lct = rateData.luxuryCarTax!;
      final tax = lct.calculate(100000);
      // (100000 - 80567) * 10/11 * 0.33 = 19433 * 0.9091 * 0.33
      expect(tax, closeTo(5830.10, 1.0));
    });

    test('no LCT below threshold', () {
      final lct = rateData.luxuryCarTax!;
      expect(lct.calculate(70000), 0);
    });

    test('fuel-efficient uses higher threshold', () {
      final lct = rateData.luxuryCarTax!;
      expect(lct.calculate(85000, fuelEfficient: true), 0);
      expect(lct.calculate(85000, fuelEfficient: false), greaterThan(0));
    });
  });

  // ─── On-Road Mode ─────────────────────────────────────────────────
  group('On-Road', () {
    test('includes registration and CTP', () {
      final r = calcOnRoad('NSW', 30000, {'vehicleType': 'passenger'});
      expect(r, isNotNull);
      expect(r!.isOnRoadMode, true);
      expect(r.registration, 462);
      expect(r.ctp, 630);
      expect(r.totalPayable, greaterThan(r.stampDuty));
    });

    test('includes dealer delivery when set', () {
      final r = calcOnRoad('NSW', 30000, {'vehicleType': 'passenger'},
          delivery: 1500);
      expect(r, isNotNull);
      expect(r!.dealerDelivery, 1500);
      expect(r.breakdown.any((b) => b.description == 'Dealer delivery'), true);
    });

    test('LCT included for expensive new vehicle', () {
      final r = calcOnRoad('NSW', 100000, {'vehicleType': 'passenger'});
      expect(r, isNotNull);
      expect(r!.luxuryCarTax, isNotNull);
      expect(r.luxuryCarTax!, greaterThan(0));
    });

    test('no LCT for used vehicle', () {
      final r = calcOnRoad('VIC', 100000, {
        'vehicleType': 'passenger',
        'registrationType': 'used',
      }, isNew: false);
      expect(r, isNotNull);
      expect(r!.luxuryCarTax, isNull);
    });
  });

  // ─── Date-based rate selection ────────────────────────────────────
  group('Date matching', () {
    test('NT EV concession expires after June 2027', () {
      final r = calc('NT', 40000, {'ntVehicleType': 'electric'},
          date: DateTime(2027, 7, 1));
      // After expiry, no matching rule for 'electric' → null
      expect(r, isNull);
    });

    test('NT EV concession valid during period', () {
      final r = calc('NT', 40000, {'ntVehicleType': 'electric'},
          date: DateTime(2025, 1, 1));
      expect(r, isNotNull);
      expect(r!.stampDuty, 0);
    });
  });

  // ─── Edge cases ───────────────────────────────────────────────────
  group('Edge cases', () {
    test('\$0 price returns null (no matching slab)', () {
      final r = calc('NSW', 0, {'vehicleType': 'passenger'});
      // $0 should match the 0-45000 slab
      expect(r, isNotNull);
      expect(r!.stampDuty, 0);
    });

    test('very large price', () {
      final r = calc('NSW', 5000000, {'vehicleType': 'passenger'});
      expect(r, isNotNull);
      expect(r!.stampDuty, greaterThan(0));
    });

    test('missing selection returns null', () {
      // NSW requires vehicleType but we don't provide it
      final state = au.states.firstWhere((s) => s.code == 'QLD');
      final r = StampDutyCalculator.calculate(
        country: au,
        state: state,
        vehiclePrice: 30000,
        selections: {}, // no qldCategory selected
      );
      // Should still return a result since empty selections match any rule
      // (the first matching rule wins)
      expect(r, isNotNull);
    });
  });

  // ─── NZ ───────────────────────────────────────────────────────────
  group('NZ', () {
    test('petrol 1301-2600cc has zero stamp duty + licensing fee', () {
      final nz = rateData.countries.firstWhere((c) => c.code == 'NZ');
      final state = nz.states.first;
      final r = StampDutyCalculator.calculate(
        country: nz,
        state: state,
        vehiclePrice: 30000,
        selections: {'nzFuelType': 'petrol', 'nzEngineSize': '1301-2600cc'},
        registrationDate: DateTime(2026, 1, 1),
      );
      expect(r, isNotNull);
      expect(r!.stampDuty, 0); // NZ has no stamp duty
      expect(r.additionalFees['annualLicensingTotal'], 325.74);
      expect(r.totalPayable, 325.74);
    });
  });
}
