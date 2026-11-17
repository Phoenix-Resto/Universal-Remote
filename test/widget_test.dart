import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_remote/models/saved_device.dart';
import 'package:universal_remote/widgets/samsung_remote_surface.dart';

void main() {
  test('Saving and restoring a Samsung device preserves identity', () {
    const device = SavedDevice(
      id: 'uuid:test', name: 'Living Room TV',
      ip: '192.168.29.179', model: 'UA32M4300');
    final restored = SavedDevice.fromJson(device.toJson());
    expect(restored.id, device.id);
    expect(restored.ip, device.ip);
    expect(restored.copyWith(name: 'Bedroom TV').name, 'Bedroom TV');
    expect(restored.copyWith(name: 'Bedroom TV').id, device.id);
  });

  testWidgets('The realistic remote contains HDMI and media rows', (tester) async {
    final commands = <String>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: SamsungRemoteSurface(onKey: commands.add)),
    )));
    expect(find.text('HDMI'), findsOneWidget);
    expect(find.text('P.MODE'), findsOneWidget);
    expect(find.text('SRS'), findsOneWidget);
    await tester.ensureVisible(find.text('HDMI'));
    await tester.tap(find.text('HDMI'));
    expect(commands, contains('KEY_HDMI'));
  });
}
