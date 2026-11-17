import 'dart:async';
import 'package:flutter/material.dart';

import 'models/saved_device.dart';
import 'services/device_store.dart';
import 'services/samsung_discovery.dart';
import 'services/samsung_tv_remote.dart';
import 'widgets/samsung_remote_surface.dart';

const navy = Color(0xFF142C4D);
const green = Color(0xFF35D68A);
const cement = Color(0xFF20242A);
const panel = Color(0xFF2C3139);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniversalRemoteApp());
}

class UniversalRemoteApp extends StatelessWidget {
  const UniversalRemoteApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Universal Remote',
    theme: ThemeData(
      useMaterial3: true, brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: navy,
        brightness: Brightness.dark, secondary: green),
      scaffoldBackgroundColor: cement,
      appBarTheme: const AppBarTheme(backgroundColor: navy,
        foregroundColor: Colors.white),
      cardTheme: const CardThemeData(color: panel),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    ),
    home: const DeviceHome(),
  );
}

class DeviceHome extends StatefulWidget {
  const DeviceHome({super.key});
  @override
  State<DeviceHome> createState() => _DeviceHomeState();
}

class _DeviceHomeState extends State<DeviceHome> {
  final store = DeviceStore();
  List<SavedDevice> devices = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await store.load();
      if (mounted) setState(() { devices = saved; loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() => loading = false);
        _toast('Could not load saved devices.');
      }
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    final found = await Navigator.push<FoundDevice>(context,
      MaterialPageRoute(builder: (_) => const AddDevicePage()));
    if (!mounted || found == null) return;
    final existing = devices.where((d) => d.id == found.id).firstOrNull;
    if (existing != null) {
      // Same TV, new address: retain stable ID and token, update DHCP IP.
      final refreshed = existing.copyWith(ip: found.ip);
      if (refreshed.ip != existing.ip) {
        final updated = [for (final d in devices)
          if (d.id == existing.id) refreshed else d];
        try {
          await store.save(updated);
          if (mounted) setState(() => devices = updated);
        } catch (_) {
          _toast('Failed to update TV address.');
          return;
        }
      }
      await _open(refreshed);
      return;
    }
    final device = SavedDevice(id: found.id, ip: found.ip,
      model: found.model, name: found.name, type: found.type);
    await _pair(device, adding: true);
  }

  Future<void> _pair(SavedDevice device, {required bool adding}) async {
    final controller = SamsungTvRemote();
    await controller.configure(device);
    if (!mounted) { controller.dispose(); return; }
    final result = await showDialog<bool>(context: context,
      barrierDismissible: false,
      builder: (_) => PairingDialog(controller: controller));
    if (!mounted) { controller.dispose(); return; }
    if (result == true) {
      if (adding) {
        final updated = [...devices, device];
        try {
          await store.save(updated);
          setState(() => devices = updated);
        } catch (_) {
          _toast('Connected, but failed to save the device.');
          controller.dispose();
          return;
        }
      }
      _toast('Connected to ${device.name}');
      // Transfer ownership of the live connection to the remote page.
      await Navigator.push(context, MaterialPageRoute(builder: (_) =>
          TvRemotePage(device: device, controller: controller,
            onChanged: (replacement) async {
              final updated = [for (final current in devices)
                if (current.id == device.id) replacement else current];
              await store.save(updated);
              if (mounted) setState(() => devices = updated);
            },
            onRemoved: () async {
              final updated = devices.where((d) => d.id != device.id).toList();
              await store.save(updated);
              if (mounted) setState(() => devices = updated);
            })),);
      controller.dispose();
    } else {
      controller.dispose();
    }
  }

  Future<void> _open(SavedDevice device) async {
    await _pair(device, adding: false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Devices')),
    body: SafeArea(child: loading
        ? const Center(child: CircularProgressIndicator(color: green))
        : devices.isEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.settings_remote, color: green, size: 64),
                const SizedBox(height: 16),
                Text('No devices yet', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Add a device to control it over your local network.',
                  textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add),
                  label: const Text('Add device')),
              ])))
          : ListView(padding: const EdgeInsets.all(16), children: [
              FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add),
                label: const Text('Add device')),
              const SizedBox(height: 12),
              for (final device in devices) Card(
                child: ListTile(
                  leading: const Icon(Icons.tv, color: green),
                  title: Text(device.name),
                  subtitle: Text('${device.brand} · ${device.model}\nWi-Fi · ${device.ip}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(device),
                ),
              ),
            ])),
  );
}

class AddDevicePage extends StatelessWidget {
  const AddDevicePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add Device')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Choose a connection method'),
      const SizedBox(height: 12),
      Card(child: ListTile(
        leading: const Icon(Icons.wifi, color: green), title: const Text('Wi-Fi'),
        subtitle: const Text('Find compatible devices on the same network'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final found = await Navigator.push<FoundDevice>(context,
            MaterialPageRoute(builder: (_) => const WifiDiscoveryPage()));
          if (context.mounted && found != null) Navigator.pop(context, found);
        },
      )),
      for (final option in [(Icons.bluetooth, 'Bluetooth'),
          (Icons.settings_input_antenna, 'Infrared (IR)')])
        Card(child: ListTile(leading: Icon(option.$1), title: Text(option.$2),
          subtitle: const Text('Coming soon'), enabled: false)),
    ])),
  );
}

class WifiDiscoveryPage extends StatefulWidget {
  const WifiDiscoveryPage({super.key});
  @override
  State<WifiDiscoveryPage> createState() => _WifiDiscoveryPageState();
}

class _WifiDiscoveryPageState extends State<WifiDiscoveryPage> {
  SamsungDiscovery? discovery;
  final Map<String, FoundDevice> results = {};
  bool scanning = false;
  String? message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    discovery?.cancel();
    final search = SamsungDiscovery();
    discovery = search;
    setState(() { scanning = true; message = null; results.clear(); });
    try {
      await search.search((device) {
        if (mounted && identical(discovery, search)) {
          setState(() => results[device.id] = device);
        }
      });
    } catch (_) {
      message = 'Network discovery failed. Try manual IP entry.';
    } finally {
      if (mounted && identical(discovery, search)) setState(() => scanning = false);
    }
  }

  Future<void> _manual() async {
    final ip = await showDialog<String>(context: context,
      builder: (_) => const _InputDialog(title: 'Enter TV IP address',
        initial: '', hint: '192.168.1.100'));
    if (!mounted || ip == null) return;
    setState(() { message = 'Checking $ip…'; });
    final found = await SamsungDiscovery.probe(ip.trim());
    if (!mounted) return;
    if (found == null) {
      setState(() => message = 'No compatible Samsung TV found at that address.');
    } else {
      Navigator.pop(context, found);
    }
  }

  @override
  void dispose() {
    discovery?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Wi-Fi Devices')),
    body: SafeArea(child: Column(children: [
      if (scanning) const LinearProgressIndicator(color: green),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(scanning ? 'Searching for compatible Samsung TVs…'
            : results.isEmpty ? 'No compatible devices found.' : 'Available devices',
          style: Theme.of(context).textTheme.titleMedium),
        if (message != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(message!)),
        for (final device in results.values) Card(child: ListTile(
          leading: const Icon(Icons.tv, color: green),
          title: Text(device.name),
          subtitle: Text('${device.model} · ${device.ip}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pop(context, device),
        )),
      ])),
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        SizedBox(width: double.infinity,
          child: OutlinedButton.icon(onPressed: scanning ? null : _scan,
            icon: const Icon(Icons.refresh), label: const Text('Scan again'))),
        SizedBox(width: double.infinity,
          child: TextButton(onPressed: _manual, child: const Text('Enter IP manually'))),
      ])),
    ])),
  );
}

class PairingDialog extends StatefulWidget {
  const PairingDialog({super.key, required this.controller});
  final SamsungTvRemote controller;
  @override
  State<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<PairingDialog> {
  bool failed = false;
  bool running = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attempt());
  }

  Future<void> _attempt() async {
    if (running) return;
    setState(() { running = true; failed = false; });
    await widget.controller.connect();
    if (!mounted) return;
    if (widget.controller.isConnected) {
      Navigator.pop(context, true);
    } else {
      setState(() { running = false; failed = true; });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(failed ? 'Connection failed' : 'Connecting to TV'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      if (!failed) const CircularProgressIndicator(color: green)
      else const Icon(Icons.error_outline, color: Colors.redAccent),
      const SizedBox(height: 16),
      Text(failed ? widget.controller.error ?? 'Unable to connect.'
        : 'Waiting for TV response. Select Allow on the television if asked.',
        textAlign: TextAlign.center),
    ]),
    actions: [
      TextButton(onPressed: () async {
        await widget.controller.disconnect();
        if (context.mounted) Navigator.pop(context, false);
      }, child: const Text('Cancel')),
      FilledButton(onPressed: failed ? _attempt : null, child: const Text('Retry')),
    ],
  );
}

class TvRemotePage extends StatefulWidget {
  const TvRemotePage({super.key, required this.device, required this.controller,
    required this.onChanged, required this.onRemoved});
  final SavedDevice device;
  final SamsungTvRemote controller;
  final Future<void> Function(SavedDevice) onChanged;
  final Future<void> Function() onRemoved;
  @override
  State<TvRemotePage> createState() => _TvRemotePageState();
}

class _TvRemotePageState extends State<TvRemotePage> {
  late SavedDevice device;
  @override
  void initState() {
    super.initState();
    device = widget.device;
    widget.controller.addListener(_refresh);
  }

  void _refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _send(String key) {
    if (!widget.controller.sendKey(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect to the TV first.')));
    }
  }

  Future<void> _rename() async {
    final name = await showDialog<String>(context: context,
      builder: (_) => _InputDialog(title: 'Edit display name',
        initial: device.name, hint: 'Living Room TV'));
    if (!mounted || name == null || name.trim().isEmpty) return;
    final replacement = device.copyWith(name: name.trim());
    try {
      await widget.onChanged(replacement);
      if (mounted) setState(() => device = replacement);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save device name.')));
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove device?'),
        content: const Text('This removes the TV from your devices and deletes its saved pairing token on this phone. It does not revoke permission on the TV itself.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)))],
      ));
    if (confirmed != true || !mounted) return;
    try {
      await widget.controller.disconnect();
      await widget.controller.forgetToken(device);
      await widget.onRemoved();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove the device.')));
    }
  }

  void _details() => showDialog<void>(context: context, builder: (_) => AlertDialog(
    title: const Text('Device details'),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final row in [
        ('Name', device.name), ('Brand', device.brand), ('Model', device.model),
        ('IP address', device.ip), ('Device ID', device.id),
        ('Type', device.type), ('Connection', device.protocol),
        ('Status', widget.controller.isConnected ? 'Connected' : 'Disconnected'),
      ]) Padding(padding: const EdgeInsets.symmetric(vertical: 4),
        child: SelectableText('${row.$1}: ${row.$2}'))]),
    actions: [TextButton(onPressed: () => Navigator.pop(context),
      child: const Text('Close'))],
  ));

  @override
  Widget build(BuildContext context) {
    final connected = widget.controller.isConnected;
    final connection = switch (widget.controller.state) {
      TvConnectionState.connected => 'Connected',
      TvConnectionState.connecting => 'Connecting',
      TvConnectionState.awaitingApproval => 'Waiting for TV',
      TvConnectionState.disconnected => 'Disconnected',
    };
    return Scaffold(
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(device.name), Text('${device.brand} ${device.model}',
          style: Theme.of(context).textTheme.labelSmall)]),
        actions: [PopupMenuButton<String>(onSelected: (value) {
          switch (value) {
            case 'details': _details(); break;
            case 'rename': _rename(); break;
            case 'remove': _remove(); break;
          }
        }, itemBuilder: (_) => const [
          PopupMenuItem(value: 'details', child: Text('Device details')),
          PopupMenuItem(value: 'rename', child: Text('Edit name')),
          PopupMenuItem(value: 'remove', child: Text('Remove device',
            style: TextStyle(color: Colors.redAccent))),
        ])]),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Icon(Icons.wifi, color: connected ? green : Colors.white54),
          const SizedBox(width: 8),
          Expanded(child: Text(connection)),
          OutlinedButton(onPressed: () async {
            if (connected) {
              await widget.controller.disconnect();
            } else {
              await showDialog<bool>(context: context,
                barrierDismissible: false,
                builder: (_) => PairingDialog(controller: widget.controller));
            }
          }, child: Text(connected ? 'Disconnect' : 'Connect')),
        ])),
        if (widget.controller.error != null)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(widget.controller.error!,
              style: const TextStyle(color: Colors.orangeAccent))),
        Expanded(child: LayoutBuilder(builder: (context, constraints) =>
          ListView(children: [
            // The handset is narrow and tall, like the physical RR URC-116.
            FractionallySizedBox(widthFactor: .82,
              child: Padding(padding: const EdgeInsets.only(bottom: 20),
                child: SamsungRemoteSurface(onKey: _send, enabled: connected))),
          ]))),
      ])),
    );
  }
}

class _InputDialog extends StatefulWidget {
  const _InputDialog({required this.title, required this.initial,
    required this.hint});
  final String title;
  final String initial;
  final String hint;
  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final TextEditingController controller;
  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initial);
  }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(controller: controller, autofocus: true,
      decoration: InputDecoration(hintText: widget.hint)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()),
        child: const Text('Save')),
    ],
  );
}
