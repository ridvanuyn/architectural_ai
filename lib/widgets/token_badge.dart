import 'package:flutter/material.dart';

class TokenBadge extends StatelessWidget {
  const TokenBadge({
    super.key,
    required this.tokens,
  });

  final int tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD3E3E2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 16),
          const SizedBox(width: 6),
          Text('$tokens tokens'),
        ],
      ),
    );
  }
}

