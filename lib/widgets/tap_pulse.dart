import 'package:flutter/material.dart';

/// วงกระเพื่อมรอบไอคอนแตะบัตร บอกว่าเครื่องกำลังรอให้แตะ
class TapPulse extends StatefulWidget {
  const TapPulse({
    Key? key,
    required this.size,
    required this.color,
    required this.child,
    this.strokeWidth = 3,
  }) : super(key: key);

  final double size;
  final Color color;
  final double strokeWidth;
  final Widget child;

  @override
  State<TapPulse> createState() => _TapPulseState();
}

class _TapPulseState extends State<TapPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))
    ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _ring(double t) {
    return Transform.scale(
      scale: 0.72 + 0.46 * t,
      child: Opacity(
        opacity: (1 - t) * 0.6,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color, width: widget.strokeWidth),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [_ring(t), _ring((t + 0.5) % 1), child!],
          );
        },
        child: widget.child,
      ),
    );
  }
}
