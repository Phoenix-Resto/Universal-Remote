import 'package:flutter/material.dart';

/// Tactile key that scales with its parent cell.
class RemoteKey extends StatelessWidget {
  const RemoteKey({super.key, this.label, this.icon, this.onPressed,
    this.tooltip, this.color, this.power = false, this.compact = false,
    this.labelBelowIcon = false});
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final bool power;
  final bool compact;
  final bool labelBelowIcon;

  @override
  Widget build(BuildContext context) {
    final foreground = color == null ? const Color(0xFFF0F0EF) : Colors.white;
    final background = color ?? (power ? const Color(0xFFE0424D) : const Color(0xFF25282D));
    final style = TextStyle(color: foreground, fontWeight: FontWeight.w800,
      fontSize: compact ? 11 : 20);
    Widget content;
    if (icon != null && label != null) {
      content = Flex(direction: labelBelowIcon ? Axis.vertical : Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Flexible(child: Icon(icon, color: foreground, size: 17)),
          Flexible(child: FittedBox(fit: BoxFit.scaleDown,
            child: Text(label!, maxLines: 1, style: style)))],
      );
    } else if (icon != null) {
      content = Icon(icon, color: foreground);
    } else {
      content = FittedBox(fit: BoxFit.scaleDown,
        child: Text(label ?? '', style: style, textAlign: TextAlign.center));
    }
    final radius = BorderRadius.circular(power ? 200 : 7);
    return Semantics(button: true, enabled: onPressed != null,
      label: tooltip ?? label ?? 'Remote key',
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black,
          borderRadius: radius,
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 3))]),
        child: Material(
          color: background, borderRadius: radius,
          child: InkWell(onTap: onPressed, borderRadius: radius,
            child: Container(
              decoration: BoxDecoration(borderRadius: radius,
                border: Border.all(color: const Color(0xFF484C55), width: 0.8),
                gradient: LinearGradient(begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(background, Colors.white, .12)!, background,
                    Color.lerp(background, Colors.black, .23)!])),
              padding: const EdgeInsets.all(3),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}
