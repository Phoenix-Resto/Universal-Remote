import 'package:flutter/material.dart';

/// A key occupies space supplied by its parent rather than requesting fixed
/// width/height. Its label and icon adapt to the current typography scale.
class RemoteKey extends StatelessWidget {
  const RemoteKey({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.emphasized = false,
    this.color,
    this.tooltip,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool emphasized;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.titleMedium;
    final child = icon != null
        ? Icon(icon, color: color)
        : Text(label ?? '', style: style?.copyWith(color: color),
            textAlign: TextAlign.center);
    return Semantics(
      button: true,
      label: tooltip ?? label ?? 'Remote key',
      child: Material(
        color: emphasized ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(child: child),
        ),
      ),
    );
  }
}
