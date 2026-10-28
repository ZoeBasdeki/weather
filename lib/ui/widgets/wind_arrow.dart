import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Arrow pointing where the wind is blowing TO.
/// [direction] is meteorological (degrees the wind comes FROM), hence +180°.
class WindArrow extends StatelessWidget {
  const WindArrow({super.key, required this.direction, this.size = 16});

  final int? direction;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dir = direction;
    if (dir == null) return SizedBox(width: size, height: size);
    return Transform.rotate(
      angle: (dir + 180) * math.pi / 180,
      child: Icon(Icons.navigation, size: size),
    );
  }
}
