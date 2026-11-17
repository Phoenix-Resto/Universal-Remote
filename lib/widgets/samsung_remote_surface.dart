import 'package:flutter/material.dart';
import 'remote_key.dart';

/// RR URC-116 / Samsung UNI-9 inspired physical-button arrangement.
/// Uses proportional cells and a scrollable parent rather than screen-size
/// assumptions. Unsupported model-specific keys may be ignored by the TV.
class SamsungRemoteSurface extends StatelessWidget {
  const SamsungRemoteSurface({super.key, required this.onKey, this.enabled = true});

  final ValueChanged<String> onKey;
  final bool enabled;

  Widget _key(String command, {String? label, IconData? icon,
      Color? color, bool power = false, bool compact = false,
      String? tooltip}) {
    return RemoteKey(
      label: label,
      icon: icon,
      color: color,
      power: power,
      compact: compact,
      tooltip: tooltip ?? label ?? command,
      onPressed: enabled ? () => onKey(command) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final gap = width * .045;
      final vertical = width * .025;
      final inset = width * .09;

      Widget three(Widget a, Widget b, Widget c, {double ratio = 1.75}) {
        return Row(children: [
          Expanded(child: AspectRatio(aspectRatio: ratio, child: a)),
          SizedBox(width: gap),
          Expanded(child: AspectRatio(aspectRatio: ratio, child: b)),
          SizedBox(width: gap),
          Expanded(child: AspectRatio(aspectRatio: ratio, child: c)),
        ]);
      }

      Widget four(Widget a, Widget b, Widget c, Widget d,
          {double ratio = 1.55}) {
        return Row(children: [
          for (final entry in [a, b, c, d]) ...[
            if (!identical(entry, a)) SizedBox(width: gap),
            Expanded(child: AspectRatio(aspectRatio: ratio, child: entry)),
          ],
        ]);
      }

      Widget rocker({required String up, required String down,
          required String title, bool channel = false}) {
        // One tall housing with two independently tappable zones.
        final symbolUp = channel ? Icons.keyboard_arrow_up : Icons.add;
        final symbolDown = channel ? Icons.keyboard_arrow_down : Icons.remove;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF292C31),
            borderRadius: BorderRadius.circular(width * .018),
            border: Border.all(color: const Color(0xFF484B52)),
            boxShadow: const [BoxShadow(color: Colors.black87,
              blurRadius: 4, offset: Offset(1, 3))],
          ),
          child: Column(children: [
            Expanded(child: Material(color: Colors.transparent,
              child: InkWell(onTap: enabled ? () => onKey(up) : null,
                child: Center(child: Icon(symbolUp, color: Colors.white)),
              ))),
            Text(title, style: TextStyle(color: Colors.white70,
              fontSize: width * .035, fontWeight: FontWeight.bold)),
            Expanded(child: Material(color: Colors.transparent,
              child: InkWell(onTap: enabled ? () => onKey(down) : null,
                child: Center(child: Icon(symbolDown, color: Colors.white)),
              ))),
          ]),
        );
      }

      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF17191D),
          borderRadius: BorderRadius.circular(width * .11),
          border: Border.all(color: const Color(0xFF35383E)),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 14)],
        ),
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Physical handset: power at upper left, source at upper right.
            Row(children: [
              Expanded(child: AspectRatio(aspectRatio: 1.25,
                child: _key('KEY_POWER', icon: Icons.power_settings_new,
                  power: true, tooltip: 'Power'))),
              Expanded(child: Center(child: Text('  ·  ·  ·  ',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38,
                  fontSize: width * .034, fontWeight: FontWeight.w700)))),
              Expanded(child: AspectRatio(aspectRatio: 1.25,
                child: _key('KEY_SOURCE', icon: Icons.input,
                  label: 'SOURCE', compact: true))),
            ]),
            SizedBox(height: vertical * 1.8),
            for (var r = 0; r < 3; r++) ...[
              three(
                _key('KEY_${r * 3 + 1}', label: '${r * 3 + 1}'),
                _key('KEY_${r * 3 + 2}', label: '${r * 3 + 2}'),
                _key('KEY_${r * 3 + 3}', label: '${r * 3 + 3}'),
              ),
              SizedBox(height: vertical),
            ],
            three(
              _key('KEY_TTX_MIX', label: 'TTX/MIX', compact: true),
              _key('KEY_0', label: '0'),
              _key('KEY_PRECH', label: 'PRE-CH', compact: true),
            ),
            SizedBox(height: vertical * 1.8),
            // Two tall rockers on the sides and mute/list in the centre.
            SizedBox(
              height: width * .40,
              child: Row(children: [
                Expanded(child: rocker(up: 'KEY_VOLUP', down: 'KEY_VOLDOWN',
                  title: 'VOL')),
                SizedBox(width: gap),
                Expanded(child: Column(children: [
                  Expanded(child: _key('KEY_MUTE', label: 'MUTE',
                    icon: Icons.volume_off_outlined, compact: true)),
                  SizedBox(height: vertical),
                  Expanded(child: _key('KEY_CH_LIST', label: 'CH LIST',
                    compact: true)),
                ])),
                SizedBox(width: gap),
                Expanded(child: rocker(up: 'KEY_CHUP', down: 'KEY_CHDOWN',
                  title: 'CH', channel: true)),
              ]),
            ),
            SizedBox(height: vertical * 1.8),
            three(
              _key('KEY_CONTENTS', label: 'MEDIA.P', compact: true),
              _key('KEY_MENU', label: 'MENU', icon: Icons.menu, compact: true),
              _key('KEY_HDMI', label: 'HDMI', compact: true),
            ),
            SizedBox(height: vertical),
            three(
              _key('KEY_TOOLS', label: 'TOOLS', compact: true),
              _key('KEY_UP', icon: Icons.arrow_drop_up),
              _key('KEY_INFO', label: 'INFO', icon: Icons.info_outline,
                compact: true),
            ),
            SizedBox(height: vertical),
            three(
              _key('KEY_LEFT', icon: Icons.arrow_left),
              _key('KEY_ENTER', icon: Icons.keyboard_return, tooltip: 'OK / Enter'),
              _key('KEY_RIGHT', icon: Icons.arrow_right),
            ),
            SizedBox(height: vertical),
            three(
              _key('KEY_RETURN', label: 'RETURN', icon: Icons.undo,
                compact: true),
              _key('KEY_DOWN', icon: Icons.arrow_drop_down),
              _key('KEY_EXIT', label: 'EXIT', icon: Icons.exit_to_app,
                compact: true),
            ),
            SizedBox(height: vertical * 1.8),
            four(
              _key('KEY_RED', label: 'A', color: const Color(0xFFB82F3D)),
              _key('KEY_GREEN', label: 'B', color: const Color(0xFF188566)),
              _key('KEY_YELLOW', label: 'C', color: const Color(0xFFB69B27)),
              _key('KEY_BLUE', label: 'D', color: const Color(0xFF2272A5)),
            ),
            SizedBox(height: vertical),
            four(
              _key('KEY_PMODE', label: 'P.MODE', compact: true),
              _key('KEY_PSIZE', label: 'P.SIZE', compact: true),
              _key('KEY_SRS', label: 'SRS', compact: true),
              _key('KEY_STOP', icon: Icons.stop),
            ),
            SizedBox(height: vertical),
            four(
              _key('KEY_REWIND', icon: Icons.fast_rewind),
              _key('KEY_PLAY', icon: Icons.play_arrow),
              _key('KEY_PAUSE', icon: Icons.pause),
              _key('KEY_FF', icon: Icons.fast_forward),
            ),
            SizedBox(height: vertical * 1.8),
            Text('URC-116   ·   SAMSUNG UNI-9',
              style: TextStyle(fontWeight: FontWeight.w800,
                letterSpacing: 1.1, color: Colors.white54,
                fontSize: width * .032)),
          ]),
        ),
      );
    });
  }
}
