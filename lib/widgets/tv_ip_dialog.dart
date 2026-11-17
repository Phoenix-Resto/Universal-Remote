import 'package:flutter/material.dart';

/// Owns its input controller until the route is fully disposed.
/// Prevents transient framework errors when Cancel dismisses the dialog.
class TvIpDialog extends StatefulWidget {
  const TvIpDialog({super.key, required this.initialIp});

  final String initialIp;

  @override
  State<TvIpDialog> createState() => _TvIpDialogState();
}

class _TvIpDialogState extends State<TvIpDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialIp);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('TV IP address'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: '192.168.1.100',
          helperText: 'Use the same Wi-Fi network as your TV.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
