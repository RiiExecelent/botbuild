import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── RED THEME CONSTANTS ───────────────────────────────────────────────────────
const Color _bgDark       = Color(0xFF0A0E27);
const Color _accentRed    = Color(0xFFF44336);
const Color _darkRed      = Color(0xFFB71C1C);
const Color _primaryWhite = Color(0xFFFFFFFF);
const Color _softGrey     = Color(0xFF94A3B8);
const Color _glassPrimary = Color(0x1AFFFFFF);
const Color _glassSecond  = Color(0x0DFFFFFF);

const LinearGradient _redGradient = LinearGradient(
  colors: [_accentRed, _darkRed],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
// ──────────────────────────────────────────────────────────────────────────────

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,

      // ── AppBar ───────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: _glassPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _primaryWhite.withOpacity(0.08), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _accentRed, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: _redGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _accentRed.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            "Customer Service",
            style: TextStyle(
              color: _primaryWhite,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ),
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              _accentRed.withOpacity(0.12),
              _bgDark,
              _bgDark,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // ── Hero icon ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: _redGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _accentRed.withOpacity(0.45),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    size: 56,
                    color: _primaryWhite,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Title ───────────────────────────────────────────────────
                ShaderMask(
                  shaderCallback: (b) => _redGradient.createShader(
                      Rect.fromLTWH(0, 0, b.width, b.height)),
                  child: const Text(
                    "Need Help?",
                    style: TextStyle(
                      color: _primaryWhite,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Contact us through our social media platforms below.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _softGrey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Decorative divider
                Container(
                  height: 3,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: _redGradient,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                          color: _accentRed.withOpacity(0.4), blurRadius: 6)
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── Contact Buttons ─────────────────────────────────────────
                _buildContactButton(
                  label: "Telegram Developer",
                  icon: FontAwesomeIcons.telegram,
                  iconColor: const Color(0xFF0088cc),
                  url: "https://t.me/iamrii",
                ),
                const SizedBox(height: 14),
                _buildContactButton(
                  label: "Telegram Support",
                  icon: FontAwesomeIcons.telegram,
                  iconColor: const Color(0xFF0088cc),
                  url: "https://t.me/aphelionlabs",
                ),
                const SizedBox(height: 14),
                _buildContactButton(
                  label: "Telegram Channel",
                  icon: FontAwesomeIcons.telegram,
                  iconColor: const Color(0xFF0088cc),
                  url: "https://t.me/Riitechchannel",
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String url,
  }) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_glassPrimary, _glassSecond],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _primaryWhite.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: _accentRed.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: iconColor.withOpacity(0.3), width: 1),
              ),
              child: FaIcon(icon, color: iconColor, size: 22),
            ),

            const SizedBox(width: 18),

            // Label
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),

            // Chevron
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: _redGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: _accentRed.withOpacity(0.3), blurRadius: 6)
                ],
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: _primaryWhite, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grid Background Painter ───────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const grid = 30.0;
    for (double x = 0; x <= size.width; x += grid) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thin);
    }
    for (double y = 0; y <= size.height; y += grid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), thin);
    }

    final accent = Paint()
      ..color = const Color(0xFFF44336).withOpacity(0.07)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += grid * 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), accent);
    }
    for (double y = 0; y <= size.height; y += grid * 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accent);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
