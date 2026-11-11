import 'package:flutter/material.dart';

import 'services/samsung_tv_remote.dart';
import 'widgets/remote_key.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniversalRemoteApp());
}

class UniversalRemoteApp extends StatelessWidget {
  const UniversalRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Universal Remote',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5468E7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101522),
        brightness: Brightness.dark,
      ),
      home: const TvRemotePage(),
    );
  }
}

class TvRemotePage extends StatefulWidget {
  const TvRemotePage({super.key});

  @override
  State<TvRemotePage> createState() => _TvRemotePageState();
}

class _TvRemotePageState extends State<TvRemotePage> {
  final SamsungTvRemote remote = SamsungTvRemote();

  @override
  void initState() {
    super.initState();
    remote.addListener(_refresh);
    remote.loadSettings();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    remote.removeListener(_refresh);
    remote.dispose();
    super.dispose();
  }

  void _key(String key) {
    if (!remote.sendKey(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect to your TV first.')),
      );
    }
  }

  Future<void> _editIp() async {
    final editor = TextEditingController(text: remote.ip);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TV IP address'),
        content: TextField(
          controller: editor,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '192.168.1.100',
            helperText: 'TV and phone must be on the same Wi-Fi.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, editor.text),
              child: const Text('Save')),
        ],
      ),
    );
    editor.dispose();
    if (value == null) return;
    try {
      await remote.changeIp(value);
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid IPv4 address.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the TV address.')),
      );
    }
  }

  Widget _button({String? label, IconData? icon, required String key,
      bool prominent = false, Color? color}) => RemoteKey(
        label: label, icon: icon, emphasized: prominent, color: color,
        tooltip: label ?? key,
        onPressed: remote.isConnected ? () => _key(key) : null,
      );

  Widget _rowOfKeys(List<Widget> children) => Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(
                width: MediaQuery.sizeOf(context).shortestSide * 0.02),
            Expanded(child: AspectRatio(aspectRatio: 1.38, child: children[i])),
          ],
        ],
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected = remote.isConnected;
    final status = switch (remote.state) {
      TvConnectionState.connected => 'Connected',
      TvConnectionState.connecting => 'Connecting…',
      TvConnectionState.awaitingApproval => 'Approve on TV…',
      TvConnectionState.disconnected => 'Disconnected',
    };
    final screen = MediaQuery.sizeOf(context);
    // Proportional page gutter; no device-specific width breakpoints.
    final gutter = screen.shortestSide * 0.045;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal Remote'),
        actions: [
          IconButton(
            onPressed: _editIp,
            tooltip: 'Change TV IP',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.98,
            child: LayoutBuilder(builder: (context, constraints) {
              // A scroll view keeps controls accessible on short screens or
              // when larger accessibility text is enabled.
              return ListView(
                padding: EdgeInsets.symmetric(horizontal: gutter,
                    vertical: gutter),
                children: [
                  Card.filled(
                    child: Padding(
                      padding: EdgeInsets.all(gutter),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.tv_outlined, size: screen.shortestSide * 0.08),
                            SizedBox(width: gutter),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Samsung UA32M4300',
                                    style: theme.textTheme.titleLarge),
                                Text('${remote.ip} · $status',
                                    style: theme.textTheme.bodyMedium),
                              ],
                            )),
                            Icon(Icons.circle,
                                color: connected ? Colors.greenAccent :
                                    theme.colorScheme.outline,
                                size: screen.shortestSide * 0.035),
                          ]),
                          SizedBox(height: gutter),
                          SizedBox(width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: remote.state == TvConnectionState.connecting ||
                                      remote.state == TvConnectionState.awaitingApproval
                                  ? null
                                  : connected ? remote.disconnect : remote.connect,
                              icon: Icon(connected ? Icons.link_off : Icons.wifi),
                              label: Text(connected ? 'Disconnect' : 'Connect to TV'),
                            ),
                          ),
                          if (remote.error != null) ...[
                            SizedBox(height: gutter / 2),
                            Text(remote.error!,
                                style: TextStyle(color: theme.colorScheme.error)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: gutter),
                  _rowOfKeys([
                    _button(key: 'KEY_POWER', icon: Icons.power_settings_new,
                        prominent: true, color: theme.colorScheme.error),
                    _button(key: 'KEY_HOME', icon: Icons.home_outlined),
                    _button(key: 'KEY_SOURCE', icon: Icons.input),
                    _button(key: 'KEY_MUTE', icon: Icons.volume_off_outlined),
                  ]),
                  SizedBox(height: gutter),
                  Text('Navigation', style: theme.textTheme.titleMedium),
                  SizedBox(height: gutter / 2),
                  // The centre pad expands with its grid cell and the side
                  // controls use the same proportional space.
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(child: _verticalControls(
                      top: _button(key: 'KEY_VOLUP', icon: Icons.add),
                      title: 'VOL',
                      bottom: _button(key: 'KEY_VOLDOWN', icon: Icons.remove),
                    )),
                    SizedBox(width: gutter),
                    Expanded(flex: 3, child: AspectRatio(
                      aspectRatio: 1,
                      child: _navigationPad(),
                    )),
                    SizedBox(width: gutter),
                    Expanded(child: _verticalControls(
                      top: _button(key: 'KEY_CHUP', icon: Icons.add),
                      title: 'CH',
                      bottom: _button(key: 'KEY_CHDOWN', icon: Icons.remove),
                    )),
                  ]),
                  SizedBox(height: gutter),
                  _rowOfKeys([
                    _button(key: 'KEY_RETURN', icon: Icons.arrow_back),
                    _button(key: 'KEY_MENU', icon: Icons.menu),
                    _button(key: 'KEY_EXIT', label: 'EXIT'),
                  ]),
                  SizedBox(height: gutter),
                  Text('Channels', style: theme.textTheme.titleMedium),
                  SizedBox(height: gutter / 2),
                  for (var row = 0; row < 3; row++) ...[
                    _rowOfKeys([
                      for (var col = 1; col <= 3; col++)
                        _button(key: 'KEY_${row * 3 + col}',
                            label: '${row * 3 + col}'),
                    ]),
                    SizedBox(height: gutter / 2),
                  ],
                  _rowOfKeys([
                    _button(key: 'KEY_PRECH', label: 'PRE-CH'),
                    _button(key: 'KEY_0', label: '0'),
                    _button(key: 'KEY_CH_LIST', label: 'LIST'),
                  ]),
                  SizedBox(height: gutter),
                  Text('Additional controls', style: theme.textTheme.titleMedium),
                  SizedBox(height: gutter / 2),
                  _rowOfKeys([
                    _button(key: 'KEY_INFO', label: 'INFO'),
                    _button(key: 'KEY_TOOLS', label: 'TOOLS'),
                    _button(key: 'KEY_CONTENTS', label: 'MEDIA'),
                  ]),
                  SizedBox(height: gutter),
                  Text('Local-network prototype. Secure pairing tokens are saved '
                      'on this phone. The TV certificate is not yet authenticated; '
                      'use only on a trusted home network.',
                      style: theme.textTheme.bodySmall),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _verticalControls({required Widget top, required String title,
      required Widget bottom}) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(aspectRatio: 1, child: top),
          Padding(padding: EdgeInsets.symmetric(
            vertical: MediaQuery.sizeOf(context).shortestSide * 0.02),
              child: Text(title)),
          AspectRatio(aspectRatio: 1, child: bottom),
        ],
      );

  Widget _navigationPad() => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: MediaQuery.sizeOf(context).shortestSide * 0.015,
        crossAxisSpacing: MediaQuery.sizeOf(context).shortestSide * 0.015,
        children: [
          const SizedBox.shrink(),
          _button(key: 'KEY_UP', icon: Icons.keyboard_arrow_up),
          const SizedBox.shrink(),
          _button(key: 'KEY_LEFT', icon: Icons.keyboard_arrow_left),
          _button(key: 'KEY_ENTER', label: 'OK', prominent: true),
          _button(key: 'KEY_RIGHT', icon: Icons.keyboard_arrow_right),
          const SizedBox.shrink(),
          _button(key: 'KEY_DOWN', icon: Icons.keyboard_arrow_down),
          const SizedBox.shrink(),
        ],
      );
}
