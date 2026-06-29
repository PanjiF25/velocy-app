import 'package:flutter/material.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';

class PulsingRadar extends StatefulWidget {
  const PulsingRadar({
    super.key,
    this.color,
    this.size = 120.0,
    this.icon = Icons.wifi_tethering,
  });

  final Color? color;
  final double size;
  final IconData icon;

  @override
  State<PulsingRadar> createState() => _PulsingRadarState();
}

class _PulsingRadarState extends State<PulsingRadar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primary(context);
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_controller.value * 0.8),
                child: Opacity(
                  opacity: 1.0 - _controller.value,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color,
                        width: 4,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_controller.value * 0.4),
                child: Opacity(
                  opacity: (1.0 - _controller.value).clamp(0.0, 0.5),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.2),
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              color: color,
              size: widget.size * 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
