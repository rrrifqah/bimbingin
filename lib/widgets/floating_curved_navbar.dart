import 'package:flutter/material.dart';

class FloatingCurvedNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<IconData> items;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;

  const FloatingCurvedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.activeColor = const Color(0xFF39A846), // Warna utama hijau
    this.inactiveColor = const Color(0xFF9098B1), // Abu-abu
    this.backgroundColor = Colors.white,
  });

  @override
  State<FloatingCurvedNavBar> createState() => _FloatingCurvedNavBarState();
}

class _FloatingCurvedNavBarState extends State<FloatingCurvedNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _animation =
        Tween<double>(
          begin: widget.currentIndex.toDouble(),
          end: widget.currentIndex.toDouble(),
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
        );
  }

  @override
  void didUpdateWidget(FloatingCurvedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animation =
          Tween<double>(
            begin: _animation.value,
            end: widget.currentIndex.toDouble(),
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
          );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width =
        MediaQuery.of(context).size.width -
        48; // Margin horizontal 24 kiri & kanan (total 48)
    const double height = 65.0; // Tinggi dari bottom nav bar

    return SizedBox(
      height:
          100, // 65 (bar) + 20 (float overhang) + 12 (bottom margin) + 3 (buffer)
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final double progress = _animation.value;
            final double itemWidth = width / widget.items.length;
            final double activeX = (progress + 0.5) * itemWidth;

            return Container(
              width: width,
              height:
                  height + 20, // Tambahan tinggi untuk floating active circle
              margin: const EdgeInsets.only(bottom: 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background navbar dengan notch/lengkungan custom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: height,
                    child: CustomPaint(
                      painter: BottomNavPainter(
                        progress: progress,
                        backgroundColor: widget.backgroundColor,
                        itemCount: widget.items.length,
                      ),
                    ),
                  ),

                  // Active Floating Circle (Lingkaran Hijau Melayang)
                  Positioned(
                    left:
                        activeX -
                        25, // 25 adalah setengah diameter lingkaran (50)
                    top: 0, // Posisi melayang sedikit di atas navbar
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.activeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.activeColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.items[widget.currentIndex],
                        color: Colors
                            .white, // Ikon aktif berwarna putih kontras di atas hijau
                        size: 24,
                      ),
                    ),
                  ),

                  // Barisan Ikon Non-aktif
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: height,
                    child: Row(
                      children: List.generate(widget.items.length, (index) {
                        final distance = (progress - index).abs();
                        // Jika lingkaran aktif berada di atas ikon ini, sembunyikan ikon abu-abu
                        final double iconOpacity = (distance).clamp(0.0, 1.0);

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => widget.onTap(index),
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: Opacity(
                                opacity: iconOpacity,
                                child: Icon(
                                  widget.items[index],
                                  color: widget.inactiveColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class BottomNavPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final int itemCount;

  BottomNavPainter({
    required this.progress,
    required this.backgroundColor,
    required this.itemCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final double width = size.width;
    final double height = size.height;
    const double radius = 24.0; // Sudut membulat navbar

    // Tentukan titik tengah lingkaran aktif
    final double itemWidth = width / itemCount;
    final double cx = (progress + 0.5) * itemWidth;

    const double w = 45.0; // Lebar lengkungan notch
    const double d = 26.0; // Kedalaman lengkungan notch

    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);

    // Garis lurus ke awal lengkungan notch
    path.lineTo(cx - w, 0);

    // Lengkungan notch menggunakan Cubic Bezier agar sangat halus (smooth)
    path.cubicTo(cx - 20, 0, cx - 20, d, cx, d);
    path.cubicTo(cx + 20, d, cx + 20, 0, cx + w, 0);

    // Garis lurus ke ujung kanan
    path.lineTo(width - radius, 0);
    path.quadraticBezierTo(width, 0, width, radius);
    path.lineTo(width, height - radius);
    path.quadraticBezierTo(width, height, width - radius, height);
    path.lineTo(radius, height);
    path.quadraticBezierTo(0, height, 0, height - radius);
    path.close();

    // Menggambar bayangan halus di belakang navbar
    try {
      canvas.drawShadow(path, Colors.black.withValues(alpha: 0.04), 12.0, true);
    } catch (_) {
      // Catch drawShadow unsupported error on Flutter Web HTML renderer
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BottomNavPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.itemCount != itemCount;
  }
}
