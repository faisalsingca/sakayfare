import 'package:flutter/material.dart';

const _ink = Color(0xFF173B32);
const _mint = Color(0xFFA8D8B4);
const _lime = Color(0xFFE6B84B);

InputDecoration authInputDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD9DFD7)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD9DFD7)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _ink, width: 1.5),
    ),
  );
}

class AuthRouteHeader extends StatefulWidget {
  const AuthRouteHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  State<AuthRouteHeader> createState() => _AuthRouteHeaderState();
}

class _AuthRouteHeaderState extends State<AuthRouteHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 194,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _ink),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) =>
                  CustomPaint(painter: _RoutePainter(_controller.value)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_bus_filled,
                        color: _lime,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SAKAYFARE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final route = Path()
      ..moveTo(size.width * 0.34, size.height * 0.83)
      ..cubicTo(
        size.width * 0.43,
        size.height * 0.62,
        size.width * 0.51,
        size.height * 0.97,
        size.width * 0.62,
        size.height * 0.76,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.55,
        size.width * 0.79,
        size.height * 0.87,
        size.width * 1.1,
        size.height * 0.63,
      );
    final routePaint = Paint()
      ..color = _mint.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(route, routePaint);

    final metric = route.computeMetrics().first;
    for (final fraction in [0.08, 0.48, 0.93]) {
      final tangent = metric.getTangentForOffset(metric.length * fraction);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 3.5, Paint()..color = _lime);
      }
    }

    final tangent = metric.getTangentForOffset(metric.length * progress);
    if (tangent == null) return;

    canvas.save();
    canvas.translate(tangent.position.dx, tangent.position.dy);
    canvas.rotate(tangent.angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -6, 20, 12),
        const Radius.circular(3),
      ),
      Paint()..color = _lime,
    );
    canvas.drawRect(const Rect.fromLTWH(-6, -4, 5, 3), Paint()..color = _ink);
    canvas.drawRect(const Rect.fromLTWH(1, -4, 5, 3), Paint()..color = _ink);
    canvas.drawCircle(const Offset(-5, 6), 2, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(6, 6), 2, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

const authBackground = Color(0xFFF3F2E9);
const authInk = _ink;

ButtonStyle authButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: _ink,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);
