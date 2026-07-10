import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'mahasiswa/mahasiswa_main.dart';
import 'dosen/dosen_main.dart';
import 'admin/admin_main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Staggered Animation Intervals
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;

  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  late Animation<double>
  _colorTransition; // 0.0 = Green theme, 1.0 = White theme

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 1. Logo Fade & Scale (from 300ms to 1200ms -> Interval 0.1 to 0.4)
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.4, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Text Fade & Slide (from 500ms to 1400ms -> Interval 0.167 to 0.467)
    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.167, 0.467, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(begin: const Offset(-20, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.167, 0.467, curve: Curves.easeOutCubic),
          ),
        );

    // 3. Smooth Color Transition (from 1500ms to 2600ms -> Interval 0.5 to 0.867)
    _colorTransition = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.867, curve: Curves.easeInOutCubic),
    );

    // Start animations
    _controller.forward();

    // Check session status and navigate after animation completes
    _checkSessionAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Wait for the full animation sequence (3.2 seconds)
    await Future.delayed(const Duration(milliseconds: 3200));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (authProvider.isLoggedIn && authProvider.currentUser != null) {
      final user = authProvider.currentUser!;
      Widget targetPage;
      switch (user.role) {
        case 'mahasiswa':
          targetPage = const MahasiswaMain();
          break;
        case 'dosen':
          targetPage = const DosenMain();
          break;
        case 'staf':
          targetPage = const AdminMain();
          break;
        default:
          targetPage = const LoginScreen();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetPage,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Compute colors dynamically based on the transition animation
        final t = _colorTransition.value;

        final backgroundColor = Color.lerp(
          const Color(0xFF39A846), // App Green
          Colors.white, // White
          t,
        )!;

        final logoPrimaryColor = Color.lerp(
          Colors.white,
          const Color(0xFF39A846),
          t,
        )!;

        final logoSecondaryColor = Color.lerp(
          Colors.white.withValues(alpha: 0.75),
          const Color(0xFF2D6A4F),
          t,
        )!;

        final textColor = Color.lerp(
          Colors.white,
          const Color(0xFF2D3142), // Premium dark text
          t,
        )!;

        final sloganColor = Color.lerp(
          Colors.white.withValues(alpha: 0.75),
          const Color(0xFF9098B1), // Soft grey
          t,
        )!;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. LOGO WITH FADE & SCALE ANIMATION
                Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: CustomPaint(
                        painter: BimbinginLogoPainter(
                          primaryColor: logoPrimaryColor,
                          secondaryColor: logoSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                ),

                // Gap
                SizedBox(width: _logoOpacity.value > 0 ? 18 : 0),

                // 2. TEXT (TITLE & SLOGAN) WITH FADE & SLIDE ANIMATION
                Opacity(
                  opacity: _textOpacity.value,
                  child: Transform.translate(
                    offset: _textSlide.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bimbingin',
                          style: GoogleFonts.plusJakartaSans(
                            textStyle: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: 1.2,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your Academic Guidance Partner',
                          style: GoogleFonts.plusJakartaSans(
                            textStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sloganColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BimbinginLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  BimbinginLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw open book pages (at the bottom)
    final bookPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final bookPath = Path();
    // Left Page
    bookPath.moveTo(w * 0.5, h * 0.56);
    bookPath.cubicTo(
      w * 0.42,
      h * 0.51,
      w * 0.28,
      h * 0.52,
      w * 0.16,
      h * 0.56,
    );
    bookPath.lineTo(w * 0.16, h * 0.74);
    bookPath.cubicTo(w * 0.28, h * 0.70, w * 0.42, h * 0.69, w * 0.5, h * 0.74);

    // Right Page
    bookPath.cubicTo(
      w * 0.58,
      h * 0.69,
      w * 0.72,
      h * 0.70,
      w * 0.84,
      h * 0.74,
    );
    bookPath.lineTo(w * 0.84, h * 0.56);
    bookPath.cubicTo(w * 0.72, h * 0.52, w * 0.58, h * 0.51, w * 0.5, h * 0.56);
    bookPath.close();
    canvas.drawPath(bookPath, bookPaint);

    // Book center line (divider)
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.56),
      Offset(w * 0.5, h * 0.74),
      linePaint,
    );

    // Graduation Cap Diamond Top (at the top)
    final capPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final capPath = Path();
    capPath.moveTo(w * 0.5, h * 0.18); // Top
    capPath.lineTo(w * 0.86, h * 0.31); // Right
    capPath.lineTo(w * 0.5, h * 0.44); // Bottom
    capPath.lineTo(w * 0.14, h * 0.31); // Left
    capPath.close();
    canvas.drawPath(capPath, capPaint);

    // Graduation Cap Band (toga base)
    final bandPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final bandPath = Path();
    bandPath.moveTo(w * 0.32, h * 0.37);
    bandPath.lineTo(w * 0.32, h * 0.44);
    bandPath.quadraticBezierTo(w * 0.5, h * 0.50, w * 0.68, h * 0.44);
    bandPath.lineTo(w * 0.68, h * 0.37);
    bandPath.quadraticBezierTo(w * 0.5, h * 0.43, w * 0.32, h * 0.37);
    bandPath.close();
    canvas.drawPath(bandPath, bandPaint);

    // Cap Tassel
    final tasselPaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final tasselPath = Path();
    tasselPath.moveTo(w * 0.5, h * 0.31);
    tasselPath.lineTo(w * 0.82, h * 0.32);
    tasselPath.quadraticBezierTo(w * 0.82, h * 0.42, w * 0.80, h * 0.48);
    canvas.drawPath(tasselPath, tasselPaint);

    // Tassel Tip (small circle)
    final tipPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w * 0.80, h * 0.50), 3.0, tipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
