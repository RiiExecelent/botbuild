import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

// ─── RED THEME CONSTANTS (identik 1:1 dengan dashboard_page.dart) ─────────────
const Color _bgDark       = Color(0xFF0A0E27);
const Color _accentRed    = Color(0xFFF44336);
const Color _darkRed      = Color(0xFFB71C1C);
const Color _softRed      = Color(0xFFEF5350);
const Color _primaryWhite = Color(0xFFFFFFFF);
const Color _softGrey     = Color(0xFF94A3B8);
const Color _glassPrimary = Color(0x1AFFFFFF);
const Color _glassSecond  = Color(0x0DFFFFFF);

const Color _navbarBg     = Color(0xFF0D1B3E);
const Color _navbarBorder = Color(0xFF1E3A6E);

const LinearGradient _redGradient = LinearGradient(
  colors: [_accentRed, _darkRed],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient _secondaryGradient = LinearGradient(
  colors: [_darkRed, _softRed],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
// ──────────────────────────────────────────────────────────────────────────────

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset>  _slideAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setSourceUrl('https://api.deline.web.id/NNbLKcCZxU.mp3');
    await _audioPlayer.resume();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              const Color(0xFF7B1FA2).withOpacity(0.20),
              _bgDark,
              _bgDark,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),

                      // ── Hero thumbnail (rapi, satu container) ────────────
                      _buildHeroSection(),

                      const SizedBox(height: 20),

                      // ── Action card ───────────────────────────────────────
                      _buildActionCard(),

                      const SizedBox(height: 14),

                      // ── Telegram button ───────────────────────────────────
                      _buildTelegramButton(),

                      const SizedBox(height: 28),

                      Text(
                        "APHELION GLITCH • CREATED BY RII",
                        style: TextStyle(
                          color: _softGrey.withOpacity(0.35),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "© 2026 Aphelion Glitch",
                        style: TextStyle(
                            color: _primaryWhite.withOpacity(0.15),
                            fontSize: 10),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero section — satu ClipRRect menyatu, identik _buildFullWidthBanner ────

  Widget _buildHeroSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B1FA2).withOpacity(0.22),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: _accentRed.withOpacity(0.18),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [

            // ── Image full cover ────────────────────────────────────────────
            Image.asset(
              "assets/images/login.png",
              fit: BoxFit.cover,
              errorBuilder: (_, error, __) => Container(
                decoration: const BoxDecoration(gradient: _secondaryGradient),
                child: const Center(
                  child: Icon(Icons.image_not_supported_rounded,
                      color: _primaryWhite, size: 60),
                ),
              ),
            ),

            // ── Gradient overlay bawah — identik dashboard banner ───────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.88),
                    Colors.black.withOpacity(0.40),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.50, 1.0],
                ),
              ),
            ),

            // ── Gradient overlay kiri — identik dashboard banner ────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            // ── LIVE badge kiri atas — identik dashboard ────────────────────
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, color: _primaryWhite, size: 6),
                    SizedBox(width: 5),
                    Text(
                      "LIVE",
                      style: TextStyle(
                        color: _primaryWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── VER badge kanan atas — identik username card ─────────────────
            Positioned(
              right: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _glassPrimary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _primaryWhite.withOpacity(0.15), width: 1),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 10),
                    children: [
                      TextSpan(
                        text: "VER ",
                        style: TextStyle(
                            color: _softGrey.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5),
                      ),
                      const TextSpan(
                        text: "3.0",
                        style: TextStyle(
                            color: _primaryWhite,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Title + subtitle kiri bawah — identik dashboard banner ───────
            Positioned(
              left: 16,
              bottom: 18,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => _redGradient.createShader(
                        Rect.fromLTWH(0, 0, b.width, b.height)),
                    child: const Text(
                      "APHELION GLITCH",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _primaryWhite,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Please Log in or Buy Access to continue",
                    style: TextStyle(
                      color: _primaryWhite.withOpacity(0.60),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // ── CONNECT badge kanan bawah — identik dashboard banner ─────────
            Positioned(
              right: 14,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF4CAF50), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, color: Color(0xFF4CAF50), size: 7),
                    SizedBox(width: 5),
                    Text(
                      "CONNECT",
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
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
  }

  // ── Action card ───────────────────────────────────────────────────────────

  Widget _buildActionCard() {
    final bgIcons = <_BgIconData>[
      _BgIconData(icon: Icons.login_rounded,        left: 230, top: -20, size: 90, opacity: 0.05, rotation: -0.26),
      _BgIconData(icon: Icons.shopping_bag_rounded, left: -20, top: -10, size: 70, opacity: 0.05, rotation:  0.20),
      _BgIconData(icon: Icons.shield_rounded,       left: -15, top: 110, size: 55, opacity: 0.04, rotation: -0.18),
      _BgIconData(icon: Icons.verified_rounded,     left: 245, top: 120, size: 45, opacity: 0.04, rotation:  0.30),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2137),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1628).withOpacity(0.9),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF0A1628).withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(4, 4),
            ),
            BoxShadow(
              color: const Color(0xFF1E4A8A).withOpacity(0.25),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            ...bgIcons.map((d) => Positioned(
              left: d.left,
              top: d.top,
              child: Transform.rotate(
                angle: d.rotation,
                child: Icon(d.icon,
                    size: d.size,
                    color: Colors.white.withOpacity(d.opacity)),
              ),
            )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _accentRed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Get Started",
                      style: TextStyle(
                        color: _primaryWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: _primaryWhite.withOpacity(0.06), height: 1),
                const SizedBox(height: 14),
                _buildRedButton(
                  icon: Icons.login_rounded,
                  label: "Sign In",
                  onTap: () => Navigator.pushNamed(context, "/login"),
                ),
                const SizedBox(height: 10),
                _buildGlassButton(
                  icon: Icons.shopping_bag_rounded,
                  label: "Buy Access To Owner",
                  onTap: () => _openUrl("https://t.me/iamrii"),
                ),
                const SizedBox(height: 14),
                Divider(color: _primaryWhite.withOpacity(0.06), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Row(children: const [
                      Icon(Icons.circle, color: Color(0xFF4CAF50), size: 9),
                      SizedBox(width: 6),
                      Text(
                        "CONNECTED",
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ]),
                    const Spacer(),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11),
                        children: [
                          TextSpan(
                            text: "VER ",
                            style: TextStyle(
                                color: _softGrey.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5),
                          ),
                          const TextSpan(
                            text: "3.0",
                            style: TextStyle(
                                color: _primaryWhite,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Telegram button — identik dashboard ───────────────────────────────────

  Widget _buildTelegramButton() {
    return GestureDetector(
      onTap: () => _openUrl("https://t.me/aphelionlabs"),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primaryWhite.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            FaIcon(FontAwesomeIcons.telegram, color: Color(0xFF29B6F6), size: 20),
            SizedBox(width: 10),
            Text(
              "TELEGRAM",
              style: TextStyle(
                color: _primaryWhite,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Red button — identik dashboard ────────────────────────────────────────

  Widget _buildRedButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: _redGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _accentRed.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _primaryWhite, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _primaryWhite,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Glass button — identik dashboard ──────────────────────────────────────

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [_glassPrimary, _glassSecond],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryWhite.withOpacity(0.1), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _accentRed, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _primaryWhite,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grid Painter — identik dashboard ─────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const gridSize = 30.0;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final accentPaint = Paint()
      ..color = const Color(0xFF7B1FA2).withOpacity(0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += gridSize * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accentPaint);
    }
    for (double y = 0; y <= size.height; y += gridSize * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Bg Icon Data Model ────────────────────────────────────────────────────────

class _BgIconData {
  final IconData icon;
  final double   left;
  final double   top;
  final double   size;
  final double   opacity;
  final double   rotation;

  const _BgIconData({
    required this.icon,
    required this.left,
    required this.top,
    required this.size,
    required this.opacity,
    required this.rotation,
  });
}
