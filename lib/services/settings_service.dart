import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Available theme color options.
enum ThemeOption {
  deepPurple(Colors.deepPurple, 'Deep Purple'),
  teal(Colors.teal, 'Teal'),
  orange(Colors.deepOrange, 'Orange');

  final Color color;
  final String label;
  const ThemeOption(this.color, this.label);
}

/// Manages persisting and loading user settings via shared_preferences.
/// Supabase sync is optional and only active when the user signs in.
/// Uses last-write-wins conflict resolution based on `updated_at` timestamps.
class SettingsService extends ChangeNotifier {
  // ── Keys ─────────────────────────────────────────────
  static const _keyDefaultDuration = 'defaultDuration';
  static const _keyBreakDuration = 'breakDuration';
  static const _keyThemeColor = 'themeColor';
  static const _keySoundEnabled = 'soundEnabled';
  static const _keyVibrationEnabled = 'vibrationEnabled';
  static const _keyDndEnabled = 'dndEnabled';

  /// SharedPreferences key for persisting local timestamps map.
  static const _keyLocalTimestamps = 'localTimestamps';

  /// SharedPreferences key for remembering if Supabase was initialized.
  static const _keySupabaseWasInitialized = 'supabaseWasInitialized';

  /// All syncable setting keys.
  static const _allKeys = [
    _keyDefaultDuration,
    _keyBreakDuration,
    _keyThemeColor,
    _keySoundEnabled,
    _keyVibrationEnabled,
    _keyDndEnabled,
  ];

  // ── Supabase state ──────────────────────────────────
  static bool _supabaseInitialized = false;

  /// Whether Supabase has been initialized (user opted in to sync).
  static bool get isSupabaseReady => _supabaseInitialized;

  /// Call after successfully initializing Supabase to enable sync.
  static Future<void> markSupabaseReady() async {
    _supabaseInitialized = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySupabaseWasInitialized, true);
  }

  /// Call after signing out / disabling sync.
  static Future<void> markSupabaseUnavailable() async {
    _supabaseInitialized = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySupabaseWasInitialized, false);
  }

  /// Check if the user had previously initialized Supabase.
  static Future<bool> wasSupabasePreviouslyInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySupabaseWasInitialized) ?? false;
  }

  // ── State ────────────────────────────────────────────
  int _defaultDuration = 25; // minutes
  int _breakDuration = 5; // minutes
  ThemeOption _themeOption = ThemeOption.deepPurple;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _dndEnabled = false;

  /// Per-key local modification timestamps for last-write-wins.
  Map<String, DateTime> _localTimestamps = {};

  /// When the last successful sync occurred.
  DateTime? _lastSyncedAt;

  // ── Getters ──────────────────────────────────────────
  int get defaultDuration => _defaultDuration;
  int get breakDuration => _breakDuration;
  ThemeOption get themeOption => _themeOption;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get dndEnabled => _dndEnabled;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  // ── Load ─────────────────────────────────────────────

  /// Loads settings from shared_preferences. Call once at app start.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultDuration = prefs.getInt(_keyDefaultDuration) ?? 25;
    _breakDuration = prefs.getInt(_keyBreakDuration) ?? 5;
    _themeOption = ThemeOption.values[
        (prefs.getInt(_keyThemeColor) ?? 0).clamp(0, ThemeOption.values.length - 1)];
    _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
    _vibrationEnabled = prefs.getBool(_keyVibrationEnabled) ?? true;
    _dndEnabled = prefs.getBool(_keyDndEnabled) ?? false;

    // Load local timestamps
    final tsJson = prefs.getString(_keyLocalTimestamps);
    if (tsJson != null) {
      try {
        final decoded = jsonDecode(tsJson) as Map<String, dynamic>;
        _localTimestamps = decoded.map(
          (k, v) => MapEntry(k, DateTime.parse(v as String)),
        );
      } catch (_) {
        _localTimestamps = {};
      }
    }

    notifyListeners();
  }

  // ── Setters (persist immediately) ────────────────────

  Future<void> setDefaultDuration(int minutes) async {
    _defaultDuration = minutes;
    notifyListeners();
    await _save(_keyDefaultDuration, minutes);
  }

  Future<void> setBreakDuration(int minutes) async {
    _breakDuration = minutes;
    notifyListeners();
    await _save(_keyBreakDuration, minutes);
  }

  Future<void> setThemeOption(ThemeOption option) async {
    _themeOption = option;
    notifyListeners();
    await _save(_keyThemeColor, option.index);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    await _save(_keySoundEnabled, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    notifyListeners();
    await _save(_keyVibrationEnabled, value);
  }

  Future<void> setDndEnabled(bool value) async {
    _dndEnabled = value;
    notifyListeners();
    await _save(_keyDndEnabled, value);
  }

  // ── Private persistence helpers ──────────────────────

  Future<void> _save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }

    // Record local timestamp
    final now = DateTime.now().toUtc();
    _localTimestamps[key] = now;
    await _persistTimestamps(prefs);

    // Sync to Supabase only if initialized and authenticated
    await _syncToSupabase(key, value.toString(), now);
  }

  /// Persist the local timestamps map to SharedPreferences.
  Future<void> _persistTimestamps(SharedPreferences prefs) async {
    final encoded = _localTimestamps.map(
      (k, v) => MapEntry(k, v.toIso8601String()),
    );
    await prefs.setString(_keyLocalTimestamps, jsonEncode(encoded));
  }

  Future<void> _syncToSupabase(String key, String value, DateTime updatedAt) async {
    if (!_supabaseInitialized) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('settings').upsert({
        'user_id': user.id,
        'key': key,
        'value': value,
        'updated_at': updatedAt.toIso8601String(),
      }, onConflict: 'user_id,key');
    } catch (e) {
      // Silently fail — local settings still work without Supabase sync.
      debugPrint('Supabase sync failed for $key: $e');
    }
  }

  // ── Sync: Pull from Supabase (last-write-wins) ──────

  /// Pull latest settings from Supabase. Only overwrites local values
  /// when the remote `updated_at` is newer (last-write-wins).
  Future<void> syncFromSupabase() async {
    if (!_supabaseInitialized) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final rows = await Supabase.instance.client
          .from('settings')
          .select()
          .eq('user_id', user.id);

      final prefs = await SharedPreferences.getInstance();
      for (final row in rows) {
        final key = row['key'] as String;
        final val = row['value'] as String;
        final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);

        // Last-write-wins: skip if local is newer
        final localTs = _localTimestamps[key];
        if (localTs != null && localTs.isAfter(remoteUpdatedAt)) {
          continue;
        }

        // Remote is newer (or no local timestamp) — apply
        _localTimestamps[key] = remoteUpdatedAt;

        switch (key) {
          case _keyDefaultDuration:
            _defaultDuration = int.tryParse(val) ?? _defaultDuration;
            await prefs.setInt(key, _defaultDuration);
          case _keyBreakDuration:
            _breakDuration = int.tryParse(val) ?? _breakDuration;
            await prefs.setInt(key, _breakDuration);
          case _keyThemeColor:
            final idx = int.tryParse(val) ?? 0;
            _themeOption = ThemeOption.values[idx.clamp(0, ThemeOption.values.length - 1)];
            await prefs.setInt(key, _themeOption.index);
          case _keySoundEnabled:
            _soundEnabled = val == 'true';
            await prefs.setBool(key, _soundEnabled);
          case _keyVibrationEnabled:
            _vibrationEnabled = val == 'true';
            await prefs.setBool(key, _vibrationEnabled);
          case _keyDndEnabled:
            _dndEnabled = val == 'true';
            await prefs.setBool(key, _dndEnabled);
        }
      }

      await _persistTimestamps(prefs);
      _lastSyncedAt = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Supabase pull failed: $e');
    }
  }

  // ── Sync: Push all local settings to Supabase ────────

  /// Pushes all local settings to Supabase. Called on first sign-in
  /// to seed the remote with any local values.
  Future<void> pushAllToSupabase() async {
    if (!_supabaseInitialized) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final localValues = _getAllSettingsAsStrings();

      for (final entry in localValues.entries) {
        final ts = _localTimestamps[entry.key] ?? DateTime.now().toUtc();
        await Supabase.instance.client.from('settings').upsert({
          'user_id': user.id,
          'key': entry.key,
          'value': entry.value,
          'updated_at': ts.toIso8601String(),
        }, onConflict: 'user_id,key');
      }
    } catch (e) {
      debugPrint('Supabase push-all failed: $e');
    }
  }

  // ── Sync: Full bidirectional sync ────────────────────

  /// Performs a full sync: pull remote (last-write-wins) then push any
  /// locally-newer settings. Call from the "Sync Now" button or on app start.
  Future<void> syncNow() async {
    if (!_supabaseInitialized) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Pull remote rows
      final rows = await Supabase.instance.client
          .from('settings')
          .select()
          .eq('user_id', user.id);

      final prefs = await SharedPreferences.getInstance();
      final remoteTimestamps = <String, DateTime>{};

      // Apply remote-wins
      for (final row in rows) {
        final key = row['key'] as String;
        final val = row['value'] as String;
        final remoteTs = DateTime.parse(row['updated_at'] as String);
        remoteTimestamps[key] = remoteTs;

        final localTs = _localTimestamps[key];
        if (localTs != null && localTs.isAfter(remoteTs)) {
          continue; // local is newer, will push later
        }

        _localTimestamps[key] = remoteTs;
        _applySettingLocally(key, val, prefs);
      }

      // 2. Push locally-newer settings
      final localValues = _getAllSettingsAsStrings();
      for (final key in _allKeys) {
        final localTs = _localTimestamps[key];
        final remoteTs = remoteTimestamps[key];

        // Push if local is newer or remote doesn't exist
        if (localTs != null && (remoteTs == null || localTs.isAfter(remoteTs))) {
          final val = localValues[key];
          if (val != null) {
            await Supabase.instance.client.from('settings').upsert({
              'user_id': user.id,
              'key': key,
              'value': val,
              'updated_at': localTs.toIso8601String(),
            }, onConflict: 'user_id,key');
          }
        }
      }

      await _persistTimestamps(prefs);
      _lastSyncedAt = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Sync now failed: $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────

  /// Returns all current settings as string key-value pairs.
  Map<String, String> _getAllSettingsAsStrings() {
    return {
      _keyDefaultDuration: _defaultDuration.toString(),
      _keyBreakDuration: _breakDuration.toString(),
      _keyThemeColor: _themeOption.index.toString(),
      _keySoundEnabled: _soundEnabled.toString(),
      _keyVibrationEnabled: _vibrationEnabled.toString(),
      _keyDndEnabled: _dndEnabled.toString(),
    };
  }

  /// Apply a single setting value locally (used during sync).
  Future<void> _applySettingLocally(
      String key, String val, SharedPreferences prefs) async {
    switch (key) {
      case _keyDefaultDuration:
        _defaultDuration = int.tryParse(val) ?? _defaultDuration;
        await prefs.setInt(key, _defaultDuration);
      case _keyBreakDuration:
        _breakDuration = int.tryParse(val) ?? _breakDuration;
        await prefs.setInt(key, _breakDuration);
      case _keyThemeColor:
        final idx = int.tryParse(val) ?? 0;
        _themeOption =
            ThemeOption.values[idx.clamp(0, ThemeOption.values.length - 1)];
        await prefs.setInt(key, _themeOption.index);
      case _keySoundEnabled:
        _soundEnabled = val == 'true';
        await prefs.setBool(key, _soundEnabled);
      case _keyVibrationEnabled:
        _vibrationEnabled = val == 'true';
        await prefs.setBool(key, _vibrationEnabled);
      case _keyDndEnabled:
        _dndEnabled = val == 'true';
        await prefs.setBool(key, _dndEnabled);
    }
  }
}
