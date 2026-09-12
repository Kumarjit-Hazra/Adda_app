import 'package:shared_preferences/shared_preferences.dart';
import '../logging/logger_service.dart';

/// Storage service for local persistence.
class StorageService {
  SharedPreferences? _prefs;
  final Map<String, String> _memoryFallback = {};

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      LoggerService.i('StorageService', 'SharedPreferences initialized');
    } catch (e) {
      LoggerService.w(
        'StorageService',
        'SharedPreferences failed to initialize, using memory fallback: $e',
      );
    }
  }

  String? getString(String key) {
    if (_prefs != null) {
      return _prefs!.getString(key);
    }
    return _memoryFallback[key];
  }

  Future<bool> setString(String key, String value) async {
    _memoryFallback[key] = value;
    if (_prefs != null) {
      return _prefs!.setString(key, value);
    }
    return true;
  }

  Future<bool> remove(String key) async {
    _memoryFallback.remove(key);
    if (_prefs != null) {
      return _prefs!.remove(key);
    }
    return true;
  }

  Future<bool> clear() async {
    _memoryFallback.clear();
    if (_prefs != null) {
      return _prefs!.clear();
    }
    return true;
  }
}
