import 'package:flutter/material.dart';

enum BadgeType { b, ipv6 }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.type});

  final BadgeType type;

  factory StatusBadge.fromServerBadge(dynamic badge) {
    // badge is ServerBadge enum from server_models
    // Avoiding import cycle – we pass the enum value's index
    return StatusBadge(type: BadgeType.b);
  }

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      BadgeType.b    => _BBadge(),
      BadgeType.ipv6 => _Ipv6Badge(),
    };
  }
}

class _BBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFFE5483D),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: const Text(
        'B',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _Ipv6Badge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF9BF29B), Color(0xFF2FA84F)],
          stops: [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2FA84F).withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'IPV6',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
    );
  }
}
