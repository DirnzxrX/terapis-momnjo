// File: lib/ui/widgets/hourglass_loading.dart
import 'package:flutter/material.dart';

class HourglassLoading extends StatefulWidget {
  final double size;
  final Color color;

  const HourglassLoading({
    Key? key,
    this.size = 24.0,
    this.color = Colors.white,
  }) : super(key: key);

  @override
  _HourglassLoadingState createState() => _HourglassLoadingState();
}

class _HourglassLoadingState extends State<HourglassLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Bikin controller animasi biar jam pasirnya muter terus (repeat)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Kecepatan muter (1.2 detik)
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.hourglass_bottom, // Pakai icon bawaan material
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}