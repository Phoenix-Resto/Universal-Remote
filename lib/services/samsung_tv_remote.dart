import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum TvConnectionState { disconnected, connecting, awaitingApproval, connected }

/// An Android/iOS Dart-IO LAN controller for Samsung's Tizen remote WebSocket.
///
/// This prototype accepts an untrusted TLS certificate ONLY for the chosen
/// IP:8002 endpoint. That does not authenticate the TV; do not ship this trust
/// policy in production. The UI warns users about this development limitation.
class SamsungTvRemote extends ChangeNotifier {
  SamsungTvRemote({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _name = 'UniversalRemoteFlutter';
  static const _port = 8002;
  static const _ipStorageKey = 'samsung_tv_ip';

  final FlutterSecureStorage _storage;
  WebSocket? _socket;
  HttpClient? _client;
  StreamSubscription<dynamic>? _subscription;
  Completer<bool>? _approval;
  int _generation = 0;
  bool _disposed = false;

  String ip = '192.168.29.179'; // Initial suggestion; user can edit.
  TvConnectionState state = TvConnectionState.disconnected;
  String? error;

  bool get isConnected =>
      state == TvConnectionState.connected &&
      _socket?.readyState == WebSocket.open;

  void _update(TvConnectionState next, {String? message}) {
    if (_disposed) return;
    state = next;
    error = message;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    try {
      final saved = await _storage.read(key: _ipStorageKey);
      if (saved != null && InternetAddress.tryParse(saved)?.type ==
          InternetAddressType.IPv4) {
        ip = saved;
        notifyListeners();
      }
    } catch (_) {
      _update(state, message: 'Could not load saved device settings.');
    }
  }

  Future<void> changeIp(String value) async {
    final candidate = value.trim();
    if (InternetAddress.tryParse(candidate)?.type !=
        InternetAddressType.IPv4) {
      throw const FormatException('Enter a valid IPv4 address.');
    }
    await disconnect();
    ip = candidate;
    notifyListeners();
    await _storage.write(key: _ipStorageKey, value: candidate);
  }

  Future<void> connect() async {
    await disconnect();
    final generation = ++_generation;
    _update(TvConnectionState.connecting);
    try {
      final token = await _storage.read(key: 'samsung_token_$ip');
      if (generation != _generation || _disposed) return;

      final query = <String, String>{
        'name': base64Encode(utf8.encode(_name)),
        if (token != null && token.isNotEmpty) 'token': token,
      };
      final uri = Uri(
        scheme: 'wss',
        host: ip,
        port: _port,
        path: '/api/v2/channels/samsung.remote.control',
        queryParameters: query,
      );

      _client = HttpClient()
        ..badCertificateCallback = (certificate, host, port) =>
            host == ip && port == _port;
      final socket = await WebSocket.connect(
        uri.toString(),
        customClient: _client,
      ).timeout(const Duration(seconds: 10));

      if (_disposed || generation != _generation) {
        await socket.close();
        return;
      }
      _socket = socket;
      final approval = Completer<bool>();
      _approval = approval;
      _subscription = socket.listen(
        (message) => _handleMessage(message, generation),
        onError: (Object _) => _handleClose(generation),
        onDone: () => _handleClose(generation),
        cancelOnError: true,
      );
      _update(TvConnectionState.awaitingApproval);
      final authorized = await approval.future.timeout(
        const Duration(seconds: 60),
      );
      if (generation != _generation || _disposed) return;
      if (!authorized) {
        await disconnect();
        _update(TvConnectionState.disconnected,
            message: 'TV declined or closed the connection. Check its device permissions.');
        return;
      }
      _update(TvConnectionState.connected);
    } on TimeoutException {
      if (generation != _generation || _disposed) return;
      await disconnect();
      _update(TvConnectionState.disconnected,
          message: 'Connection timed out. Check the TV, Wi-Fi and approval popup.');
    } catch (_) {
      if (generation != _generation || _disposed) return;
      await disconnect();
      // Never print errors containing a URL with a pairing token.
      _update(TvConnectionState.disconnected,
          message: 'Connection failed. Check IP, TV power, and local Wi-Fi.');
    }
  }

  Future<void> _handleMessage(dynamic message, int generation) async {
    if (_disposed || generation != _generation) return;
    try {
      final data = jsonDecode(message.toString());
      if (data is! Map<String, dynamic>) return;
      switch (data['event']) {
        case 'ms.channel.connect':
          final body = data['data'];
          if (body is Map && body['token'] != null) {
            await _storage.write(
              key: 'samsung_token_$ip',
              value: body['token'].toString(),
            );
          }
          if (generation == _generation &&
              _approval != null && !_approval!.isCompleted) {
            _approval!.complete(true);
          }
          return;
        case 'ms.channel.unauthorized':
          if (_approval != null && !_approval!.isCompleted) {
            _approval!.complete(false);
          }
          _update(state, message: 'TV rejected authorization.');
          return;
        case 'ms.error':
          _update(state, message: 'TV returned an error for the request.');
          return;
      }
    } catch (_) {
      if (_approval != null && !_approval!.isCompleted) {
        _approval!.complete(false);
      }
      _update(state, message: 'Unable to process the TV response.');
    }
  }

  void _handleClose(int generation) {
    if (_disposed || generation != _generation) return;
    if (_approval != null && !_approval!.isCompleted) {
      _approval!.complete(false);
    }
    _update(TvConnectionState.disconnected,
        message: 'TV connection closed. Tap Connect to retry.');
  }

  /// Sending means the WebSocket accepted the payload, not that TV executed it.
  bool sendKey(String key) {
    if (!isConnected) return false;
    try {
      _socket!.add(jsonEncode({
        'method': 'ms.remote.control',
        'params': {
          'Cmd': 'Click',
          'DataOfCmd': key,
          'Option': 'false',
          'TypeOfRemote': 'SendRemoteKey',
        },
      }));
      return true;
    } catch (_) {
      _update(TvConnectionState.disconnected,
          message: 'Could not send the command. Reconnect to the TV.');
      return false;
    }
  }

  Future<void> disconnect() async {
    ++_generation;
    if (_approval != null && !_approval!.isCompleted) {
      _approval!.complete(false);
    }
    _approval = null;
    final oldSubscription = _subscription;
    final oldSocket = _socket;
    final oldClient = _client;
    _subscription = null;
    _socket = null;
    _client = null;
    await oldSubscription?.cancel();
    await oldSocket?.close();
    oldClient?.close(force: true);
    _update(TvConnectionState.disconnected);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    super.dispose();
  }
}
