import 'package:flutter/material.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'telegram.dart';
import 'anime_home.dart';

// ─── RED THEME CONSTANTS ───────────────────────────────────────────────────────
const Color _bgDark       = Color(0xFF0A0E27);
const Color _cardBg       = Color(0xFF111630);
const Color _accentRed    = Color(0xFFF44336);
const Color _darkRed      = Color(0xFFB71C1C);
const Color _softRed      = Color(0xFFEF5350);
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

class ToolsPage extends StatelessWidget {
  final String username;
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.username,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _accentRed.withOpacity(0.18),
                      _darkRed.withOpacity(0.1),
                      _accentRed.withOpacity(0.18),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  border: Border.all(
                      color: _accentRed.withOpacity(0.25), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: _accentRed.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: _redGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.build_rounded,
                              color: _primaryWhite, size: 22),
                        ),
                        const SizedBox(width: 14),
                        ShaderMask(
                          shaderCallback: (b) => _redGradient.createShader(
                              Rect.fromLTWH(0, 0, b.width, b.height)),
                          child: const Text(
                            "TOOLS DASHBOARD",
                            style: TextStyle(
                              color: _primaryWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Advanced Security & OSINT Tools",
                      style: TextStyle(color: _softGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // ── Grid ─────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.15,
                    children: [
                      _buildToolCard(
                        icon: Icons.flash_on_rounded,
                        title: "DDoS Tools",
                        subtitle: "Attack & Server",
                        onTap: () => _showDDoSTools(context),
                        accentColor: _accentRed,
                      ),
                      _buildToolCard(
                        icon: Icons.wifi_rounded,
                        title: "Network",
                        subtitle: "WiFi & Spam",
                        onTap: () => _showNetworkTools(context),
                        accentColor: _softRed,
                      ),
                      _buildToolCard(
                        icon: Icons.search_rounded,
                        title: "OSINT",
                        subtitle: "Investigation",
                        onTap: () => _showOSINTTools(context),
                        accentColor: _accentRed,
                      ),
                      _buildToolCard(
                        icon: Icons.download_rounded,
                        title: "Downloader",
                        subtitle: "Social Media",
                        onTap: () => _showDownloaderTools(context),
                        accentColor: _softRed,
                      ),
                      _buildToolCard(
                        icon: Icons.build_rounded,
                        title: "Utilities",
                        subtitle: "Extra Tools",
                        onTap: () => _showUtilityTools(context),
                        accentColor: _accentRed,
                      ),
                      _buildToolCard(
                        icon: Icons.play_circle_fill_rounded,
                        title: "Streaming",
                        subtitle: "Nonton & Hiburan",
                        onTap: () => _showStreamingTools(context),
                        accentColor: _softRed,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tool Card ──────────────────────────────────────────────────────────────

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_glassPrimary, _glassSecond],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: accentColor.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: _primaryWhite, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: _primaryWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: _softGrey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Sheet Builder ───────────────────────────────────────────────────

  Widget _buildSheet({
    required BuildContext context,
    required IconData icon,
    required String title,
    required double heightFactor,
    required Widget body,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border.all(color: _accentRed.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: _accentRed.withOpacity(0.2),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              gradient: _redGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Sheet header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: _redGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _accentRed.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: _primaryWhite, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: _primaryWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: body,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tool Option Row ────────────────────────────────────────────────────────

  Widget _buildToolOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_glassPrimary, _glassSecond],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryWhite.withOpacity(0.08), width: 1),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: _redGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: _accentRed.withOpacity(0.3), blurRadius: 6)
            ],
          ),
          child: Icon(icon, color: _primaryWhite, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
              color: _primaryWhite,
              fontWeight: FontWeight.w600,
              fontSize: 14),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _accentRed.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.chevron_right_rounded,
              color: _accentRed, size: 18),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  // ── Bottom Sheet Methods ───────────────────────────────────────────────────

  void _showDDoSTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildSheet(
        context: context,
        icon: Icons.flash_on_rounded,
        title: "DDoS Tools",
        heightFactor: 0.55,
        body: Column(
          children: [
            _buildToolOption(
              icon: Icons.flash_on_rounded,
              label: "Attack Panel",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AttackPanel(
                      sessionKey: sessionKey, listDoos: listDoos),
                ));
              },
            ),
            _buildToolOption(
              icon: Icons.dns_rounded,
              label: "Manage Server",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ManageServerPage(keyToken: sessionKey),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNetworkTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildSheet(
        context: context,
        icon: Icons.wifi_rounded,
        title: "Network Tools",
        heightFactor: 0.72,
        body: SingleChildScrollView(
          child: Column(
            children: [
  
              _buildToolOption(
                icon: Icons.telegram_rounded,
                label: "TG Spam",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) =>
                        TelegramSpamPage(sessionKey: sessionKey),
                  ));
                },
              ),
              _buildToolOption(
                icon: Icons.newspaper_rounded,
                label: "Spam NGL",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => NglPage()));
                },
              ),
              _buildToolOption(
                icon: Icons.wifi_off_rounded,
                label: "WiFi Killer (Internal)",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => WifiKillerPage()));
                },
              ),
              _buildToolOption(
                icon: Icons.router_rounded,
                label: "WiFi Killer (External)",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) =>
                        WifiInternalPage(sessionKey: sessionKey),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOSINTTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildSheet(
        context: context,
        icon: Icons.search_rounded,
        title: "OSINT Tools",
        heightFactor: 0.68,
        body: Column(
          children: [
            _buildToolOption(
              icon: Icons.badge_rounded,
              label: "NIK Detail",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const NikCheckerPage()));
              },
            ),
            _buildToolOption(
              icon: Icons.domain_rounded,
              label: "Domain OSINT",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const DomainOsintPage()));
              },
            ),
            _buildToolOption(
              icon: Icons.person_search_rounded,
              label: "Phone Lookup",
              onTap: () => _showComingSoon(context),
            ),
            _buildToolOption(
              icon: Icons.email_rounded,
              label: "Email OSINT",
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloaderTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildSheet(
        context: context,
        icon: Icons.download_rounded,
        title: "Media Downloader",
        heightFactor: 0.55,
        body: Column(
          children: [
            _buildToolOption(
              icon: Icons.video_library_rounded,
              label: "TikTok Downloader",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const TiktokDownloaderPage()));
              },
            ),
            _buildToolOption(
              icon: Icons.camera_alt_rounded,
              label: "Instagram Downloader",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const InstagramDownloaderPage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUtilityTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildSheet(
        context: context,
        icon: Icons.build_rounded,
        title: "Utility Tools",
        heightFactor: 0.62,
        body: Column(
          children: [
            _buildToolOption(
              icon: Icons.qr_code_rounded,
              label: "QR Generator",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const QrGeneratorPage()));
              },
            ),
            _buildToolOption(
              icon: Icons.security_rounded,
              label: "IP Scanner",
              onTap: () => _showComingSoon(context),
            ),
            _buildToolOption(
              icon: Icons.network_check_rounded,
              label: "Port Scanner",
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showStreamingTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildSheet(
        context: context,
        icon: Icons.play_circle_fill_rounded,
        title: "Streaming & Hiburan",
        heightFactor: 0.65,
        body: Column(
          children: [
            _buildToolOption(
              icon: Icons.movie_filter_rounded,
              label: "Anime Stream",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const HomeAnimePage()));
              },
            ),
            _buildToolOption(
              icon: Icons.video_library_rounded,
              label: "Donghua Stream",
              onTap: () => _showComingSoon(context),
            ),
            _buildToolOption(
              icon: Icons.theaters_rounded,
              label: "Drama China (Drachin)",
              onTap: () => _showComingSoon(context),
            ),
            _buildToolOption(
              icon: Icons.live_tv_rounded,
              label: "Movies & Series",
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: _primaryWhite),
            SizedBox(width: 10),
            Text(
              'Feature Coming Soon!',
              style: TextStyle(
                  color: _primaryWhite, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: _accentRed,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
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
