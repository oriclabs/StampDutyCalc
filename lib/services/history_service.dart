import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  final String id;
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
  String? note;

  HistoryEntry({
    String? id,
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
    this.note,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
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
        'note': note,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'],
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
        note: json['note'],
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
    await _save(history);
  }

  static Future<void> updateNote(String id, String? note) async {
    final history = await getHistory();
    for (final e in history) {
      if (e.id == id) {
        e.note = note;
        break;
      }
    }
    await _save(history);
  }

  static Future<void> deleteEntry(String id) async {
    final history = await getHistory();
    history.removeWhere((e) => e.id == id);
    await _save(history);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> _save(List<HistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(history.map((e) => e.toJson()).toList()));
  }

  /// Generate CSV string from history entries
  static String toCsv(List<HistoryEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Date,Country,State,Vehicle Price,Stamp Duty,Total,Mode,Note');
    for (final e in entries) {
      final note = (e.note ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
      final mode = e.isOnRoad ? 'On-Road' : 'Stamp Duty';
      buffer.writeln(
          '${e.timestamp.toIso8601String()},${e.countryName},${e.stateCode},${e.vehiclePrice},${e.stampDuty},${e.totalPayable},$mode,"$note"');
    }
    return buffer.toString();
  }
}
