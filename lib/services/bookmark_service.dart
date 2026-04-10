import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  final String countryCode;
  final String stateCode;
  final String stateName;
  final String countryName;
  final Map<String, String> selections;
  final String label;

  Bookmark({
    required this.countryCode,
    required this.stateCode,
    required this.stateName,
    required this.countryName,
    required this.selections,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'countryCode': countryCode,
        'stateCode': stateCode,
        'stateName': stateName,
        'countryName': countryName,
        'selections': selections,
        'label': label,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        countryCode: json['countryCode'] ?? '',
        stateCode: json['stateCode'] ?? '',
        stateName: json['stateName'] ?? '',
        countryName: json['countryName'] ?? '',
        selections: Map<String, String>.from(json['selections'] ?? {}),
        label: json['label'] ?? '',
      );
}

class BookmarkService {
  static const _key = 'bookmarks';

  static Future<List<Bookmark>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];
    final list = json.decode(jsonStr) as List;
    return list.map((e) => Bookmark.fromJson(e)).toList();
  }

  static Future<void> addBookmark(Bookmark bookmark) async {
    final bookmarks = await getBookmarks();
    bookmarks.add(bookmark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(bookmarks.map((b) => b.toJson()).toList()));
  }

  static Future<void> removeBookmark(int index) async {
    final bookmarks = await getBookmarks();
    if (index < bookmarks.length) {
      bookmarks.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, json.encode(bookmarks.map((b) => b.toJson()).toList()));
    }
  }
}
