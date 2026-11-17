import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/saved_device.dart';

/// Small local device registry. Tokens are stored separately by the controller.
/// Secure storage avoids introducing a database for the first Wi-Fi prototype.
class DeviceStore {
  DeviceStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'universal_remote_saved_devices_v2';

  Future<List<SavedDevice>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    final parsed = jsonDecode(raw) as List<dynamic>;
    return parsed.map((e) => SavedDevice.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<SavedDevice> devices) => _storage.write(
      key: _key, value: jsonEncode(devices.map((e) => e.toJson()).toList()));
}
