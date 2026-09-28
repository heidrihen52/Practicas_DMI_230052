import 'package:flutter/material.dart';

class MessageTime extends StatelessWidget {
  const MessageTime({super.key, required this.sentAt});

  final DateTime sentAt;

  @override
  Widget build(BuildContext context) {
    final local = sentAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return Text(
      time,
      style: const TextStyle(color: Colors.white70, fontSize: 11),
    );
  }
}
