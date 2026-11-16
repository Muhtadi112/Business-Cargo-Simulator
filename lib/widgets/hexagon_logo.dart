import 'package:flutter/material.dart';

class HexagonLogo extends StatelessWidget {
  const HexagonLogo({super.key, required this.iconId, required this.accentColor, this.size = 72});
  final String iconId;
  final Color accentColor;
  final double size;

  static const Map<String, IconData> iconOptions = {
    'truck': Icons.local_shipping_rounded,
    'globe': Icons.public_rounded,
    'anchor': Icons.anchor_rounded,
    'bolt': Icons.bolt_rounded,
    'shield': Icons.shield_rounded,
    'rocket': Icons.rocket_launch_rounded,
  };

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: Stack(alignment: Alignment.center, children: [
      ClipPath(clipper: const _HexClipper(), child: Container(color: accentColor.withValues(alpha: .17))),
      Padding(
        padding: const EdgeInsets.all(2.5),
        child: ClipPath(clipper: const _HexClipper(), child: Container(
          color: const Color(0xFF10211E),
          child: Icon(iconOptions[iconId] ?? Icons.local_shipping_rounded, color: accentColor, size: size * .43),
        )),
      ),
      CustomPaint(size: Size.square(size), painter: _HexBorder(accentColor)),
    ]),
  );
}

class _HexClipper extends CustomClipper<Path> {
  const _HexClipper();
  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width*.25,s.height*.03)..lineTo(s.width*.75,s.height*.03)
    ..lineTo(s.width*.98,s.height*.5)..lineTo(s.width*.75,s.height*.97)
    ..lineTo(s.width*.25,s.height*.97)..lineTo(s.width*.02,s.height*.5)..close();
  @override
  bool shouldReclip(covariant _HexClipper oldClipper) => false;
}

class _HexBorder extends CustomPainter {
  const _HexBorder(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = const _HexClipper().getClip(size);
    canvas.drawPath(p, Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=2.4);
  }
  @override
  bool shouldRepaint(covariant _HexBorder oldDelegate) => oldDelegate.color != color;
}
