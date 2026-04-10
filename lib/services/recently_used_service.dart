import 'package:shared_preferences/shared_preferences.dart';

class RecentlyUsedService {
  static const _key = 'recently_used_tools';
  static const _maxItems = 5;

  static Future<List<String>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> recordUsage(String toolId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    current.remove(toolId); // Remove if exists (move to top)
    current.insert(0, toolId);
    if (current.length > _maxItems) {
      current.removeRange(_maxItems, current.length);
    }
    await prefs.setStringList(_key, current);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
