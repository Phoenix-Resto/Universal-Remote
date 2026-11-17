import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/saved_device.dart';

enum TvConnectionState { disconnected, connecting, awaitingApproval, connected }

/// Samsung Tizen local-network remote. Testing-only TLS exception below:
/// a trusted IP is NOT equivalent to authenticating the certificate.
class SamsungTvRemote extends ChangeNotifier {
  SamsungTvRemote({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _appName = 'UniversalRemoteFlutter'; // Keep stable for remembered grants.
  final FlutterSecureStorage _storage;
  static const _port = 8002;
  WebSocket? _socket;
  HttpClient? _client;
  StreamSubscription<dynamic>? _subscription;
  Completer<bool>? _approval;
  int _generation = 0;
  bool _disposed = false;
  SavedDevice? _device;

  TvConnectionState state = TvConnectionState.disconnected;
  String? error;
  String get ip => _device?.ip ?? '';
  bool get isConnected => state == TvConnectionState.connected &&
      _socket?.readyState == WebSocket.open;
  String get _tokenKey => 'samsung_token_device_${_device!.id}';

  void _update(TvConnectionState value, {String? message}) {
    if (_disposed) return;
    state = value;
    error = message;
    notifyListeners();
  }

  Future<void> configure(SavedDevice device) async {
    await disconnect();
    _device = device;
  }

  Future<void> forgetToken(SavedDevice device) async {
    await _storage.delete(key: 'samsung_token_device_${device.id}');
    await _storage.delete(key: 'samsung_token_${device.ip}');
  }

  Future<void> connect() async {
    if (_device == null) {
      _update(TvConnectionState.disconnected, message: 'No TV selected.');
      return;
    }
    await disconnect();
    final generation = ++_generation;
    final address = ip;
    _update(TvConnectionState.connecting);
    try {
      // Migrate previously saved per-IP tokens from the first Flutter prototype.
      var token = await _storage.read(key: _tokenKey);
      token ??= await _storage.read(key: 'samsung_token_$address');
      if (generation != _generation || _disposed) return;
      final query = <String, String>{
        'name': base64Encode(utf8.encode(_appName)),
        if (token != null && token.isNotEmpty) 'token': token,
      };
      final uri = Uri(scheme: 'wss', host: address, port: _port,
        path: '/api/v2/channels/samsung.remote.control',
        queryParameters: query);
      _client = HttpClient()
        ..badCertificateCallback = (_, host, port) =>
            host == address && port == _port; // DEV ONLY, not for public release.
      final socket = await WebSocket.connect(uri.toString(), customClient: _client)
          .timeout(const Duration(seconds: 10));
      if (_disposed || generation != _generation) {
        await socket.close();
        return;
      }
      _socket = socket;
      final approval = Completer<bool>();
      _approval = approval;
      _subscription = socket.listen(
        (message) => unawaited(_handleMessage(message, generation)),
        onError: (Object _) => _handleClose(generation),
        onDone: () => _handleClose(generation), cancelOnError: true);
      _update(TvConnectionState.awaitingApproval);
      final authorized = await approval.future.timeout(const Duration(seconds: 60));
      if (generation != _generation || _disposed) return;
      if (!authorized) {
        await disconnect();
        _update(TvConnectionState.disconnected,
            message: 'TV declined or closed the pairing request.');
        return;
      }
      _update(TvConnectionState.connected);
    } on TimeoutException {
      if (generation != _generation || _disposed) return;
      await disconnect();
      _update(TvConnectionState.disconnected,
          message: 'Connection timed out. Check the TV and Wi-Fi.');
    } catch (_) {
      if (generation != _generation || _disposed) return;
      await disconnect();
      _update(TvConnectionState.disconnected,
          message: 'Cannot connect. Confirm TV power and local Wi-Fi.');
    }
  }

  Future<void> _handleMessage(dynamic message, int generation) async {
    if (_disposed || generation != _generation) return;
    try {
      final payload = jsonDecode(message.toString());
      if (payload is! Map<String, dynamic>) return;
      switch (payload['event']) {
        case 'ms.channel.connect':
          final body = payload['data'];
          if (body is Map && body['token'] != null && _device != null) {
            // Persist before declaring pairing successful.
            await _storage.write(key: _tokenKey, value: body['token'].toString());
          }
          if (generation == _generation && _approval != null &&
              !_approval!.isCompleted) _approval!.complete(true);
          return;
        case 'ms.channel.unauthorized':
          if (_approval != null && !_approval!.isCompleted) _approval!.complete(false);
          _update(state, message: 'TV denied pairing.');
          return;
        case 'ms.error':
          _update(state, message: 'The TV reported a remote-control error.');
          return;
      }
    } catch (_) {
      if (_approval != null && !_approval!.isCompleted) _approval!.complete(false);
      _update(state, message: 'Could not process the TV response.');
    }
  }

  void _handleClose(int generation) {
    if (_disposed || generation != _generation) return;
    if (_approval != null && !_approval!.isCompleted) _approval!.complete(false);
    _update(TvConnectionState.disconnected,
        message: 'TV connection closed. Reconnect to continue.');
  }

  /// The transport accepting a command doesn't guarantee TV execution.
  bool sendKey(String key) {
    if (!isConnected) return false;
    try {
      _socket!.add(jsonEncode({'method': 'ms.remote.control', 'params': {
        'Cmd': 'Click', 'DataOfCmd': key, 'Option': 'false',
        'TypeOfRemote': 'SendRemoteKey',
      }}));
      return true;
    } catch (_) {
      _update(TvConnectionState.disconnected, message: 'Command failed. Reconnect.');
      return false;
    }
  }

  Future<void> disconnect() async {
    ++_generation;
    if (_approval != null && !_approval!.isCompleted) _approval!.complete(false);
    _approval = null;
    final subscription = _subscription;
    final socket = _socket;
    final client = _client;
    _subscription = null;
    _socket = null;
    _client = null;
    await subscription?.cancel();
    await socket?.close();
    client?.close(force: true);
    _update(TvConnectionState.disconnected);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    super.dispose();
  }
}
