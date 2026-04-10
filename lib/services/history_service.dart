import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  final String countryName;
  final String stateName;
  final String stateCode;
  final double vehiclePrice;
  final double stampDuty;
  final double totalPayable;
  final bool isOnRoad;
  final String currency;
  final String currencySymbol;
  final DateTime timestamp;

  HistoryEntry({
    required this.countryName,
    required this.stateName,
    required this.stateCode,
    required this.vehiclePrice,
    required this.stampDuty,
    required this.totalPayable,
    required this.isOnRoad,
    required this.currency,
    required this.currencySymbol,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'countryName': countryName,
        'stateName': stateName,
        'stateCode': stateCode,
        'vehiclePrice': vehiclePrice,
        'stampDuty': stampDuty,
        'totalPayable': totalPayable,
        'isOnRoad': isOnRoad,
        'currency': currency,
        'currencySymbol': currencySymbol,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        countryName: json['countryName'] ?? '',
        stateName: json['stateName'] ?? '',
        stateCode: json['stateCode'] ?? '',
        vehiclePrice: (json['vehiclePrice'] as num).toDouble(),
        stampDuty: (json['stampDuty'] as num).toDouble(),
        totalPayable: (json['totalPayable'] as num).toDouble(),
        isOnRoad: json['isOnRoad'] ?? false,
        currency: json['currency'] ?? '',
        currencySymbol: json['currencySymbol'] ?? '\$',
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class HistoryService {
  static const _key = 'calculation_history';
  static const _maxEntries = 50;

  static Future<List<HistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];

    final list = json.decode(jsonStr) as List;
    return list.map((e) => HistoryEntry.fromJson(e)).toList();
  }

  static Future<void> addEntry(HistoryEntry entry) async {
    final history = await getHistory();
    history.insert(0, entry);
    if (history.length > _maxEntries) {
      history.removeRange(_maxEntries, history.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(history.map((e) => e.toJson()).toList()));
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
