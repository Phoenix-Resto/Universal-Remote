import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/saved_device.dart';

/// User-initiated discovery: SSDP first, then a bounded scan of private /24 LANs.
/// Every candidate is verified against Samsung's /api/v2/ endpoint.
class SamsungDiscovery {
  static final _ssdp = InternetAddress('239.255.255.250');
  bool _cancelled = false;
  void cancel() => _cancelled = true;

  Future<void> search(void Function(FoundDevice) onFound) async {
    _cancelled = false;
    final seen = <String>{};
    final ips = <String>{};
    RawDatagramSocket? udp;
    StreamSubscription<RawSocketEvent>? events;
    try {
      udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      udp.broadcastEnabled = true;
      events = udp.listen((event) {
        if (event != RawSocketEvent.read) return;
        Datagram? packet;
        while ((packet = udp?.receive()) != null) {
          final address = packet!.address.address;
          if (InternetAddress.tryParse(address)?.isLoopback == false) ips.add(address);
        }
      });
      final request = 'M-SEARCH * HTTP/1.1\r\n'
          'HOST: 239.255.255.250:1900\r\n'
          'MAN: "ssdp:discover"\r\nMX: 2\r\n'
          'ST: ssdp:all\r\n\r\n';
      udp.send(utf8.encode(request), _ssdp, 1900);
      await Future<void>.delayed(const Duration(seconds: 3));
    } catch (_) {
      // SSDP may be blocked by Wi-Fi multicast isolation; subnet fallback below.
    } finally {
      await events?.cancel();
      udp?.close();
    }
    if (_cancelled) return;

    Future<void> check(String ip) async {
      if (_cancelled || !seen.add(ip)) return;
      final device = await probe(ip);
      if (device != null && !_cancelled) onFound(device);
    }

    await Future.wait(ips.map(check));
    if (_cancelled) return;

    final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4, includeLoopback: false);
    final prefixes = <String>{};
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final chunks = address.address.split('.');
        if (chunks.length != 4) continue;
        final a = int.tryParse(chunks[0]) ?? 0;
        final b = int.tryParse(chunks[1]) ?? 0;
        if (a == 10 || (a == 172 && b >= 16 && b <= 31) ||
            (a == 192 && b == 168)) {
          prefixes.add('${chunks[0]}.${chunks[1]}.${chunks[2]}');
        }
      }
    }
    // Probe hosts in bounded batches to prevent hundreds of simultaneous sockets.
    for (final prefix in prefixes.take(2)) {
      for (var start = 1; start < 255 && !_cancelled; start += 20) {
        await Future.wait([
          for (var host = start; host < start + 20 && host < 255; host++)
            check('$prefix.$host'),
        ]);
      }
    }
  }

  static Future<FoundDevice?> probe(String ip) async {
    final address = InternetAddress.tryParse(ip);
    if (address?.type != InternetAddressType.IPv4) return null;
    final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 650);
    try {
      final request = await client.getUrl(Uri.parse('http://$ip:8001/api/v2/'))
          .timeout(const Duration(milliseconds: 750));
      final response = await request.close().timeout(const Duration(milliseconds: 750));
      if (response.statusCode != HttpStatus.ok) return null;
      final raw = await utf8.decoder.bind(response).join()
          .timeout(const Duration(milliseconds: 750));
      final root = jsonDecode(raw) as Map<String, dynamic>;
      final device = root['device'];
      if (device is! Map) return null;
      if (!('${device['type'] ?? root['type'] ?? ''}').contains('Samsung')) return null;
      final support = root['isSupport'];
      if (support is String) {
        final parsed = jsonDecode(support);
        if (parsed is Map && parsed['remote_available'] == 'false') return null;
      }
      final id = (device['id'] ?? root['id'] ?? '').toString();
      if (id.isEmpty) return null;
      return FoundDevice(
        id: id, ip: ip,
        name: (device['name'] ?? root['name'] ?? 'Samsung TV').toString(),
        model: (device['modelName'] ?? 'Samsung TV').toString(),
        type: (device['type'] ?? 'Samsung SmartTV').toString(),
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
