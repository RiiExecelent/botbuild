import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'nik_check.dart';
import 'admin_page.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'publik_chat.dart';
import 'tq_to.dart';
import 'anime_home.dart';
import 'btrapps/.dart';
import 'sender_management_page.dart';

final baseUrl = Api.api;

// ─── RED THEME CONSTANTS ──────────────────────────────────────────────────────
const Color _bgDark       = Color(0xFF0A0E27);
const Color _accentRed    = Color(0xFFF44336);
const Color _darkRed      = Color(0xFFB71C1C);
const Color _softRed      = Color(0xFFEF5350);
const Color _primaryWhite = Color(0xFFFFFFFF);
const Color _softGrey     = Color(0xFF94A3B8);
const Color _glassPrimary = Color(0x1AFFFFFF);
const Color _glassSecond  = Color(0x0DFFFFFF);

// ─── NAVBAR SOLID BLUE ────────────────────────────────────────────────────────
const Color _navbarBg     = Color(0xFF0D1B3E); // solid biru gelap
const Color _navbarBorder = Color(0xFF1E3A6E); // outline tipis biru

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
// ─────────────────────────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double>   _fadeAnimation;
  late Animation<Offset>   _slideAnimation;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  String androidId = "unknown";
  File?  _profileImage;
  VideoPlayerController? _menuVideoController;

  int _bottomNavIndex = 0;
  late Widget _selectedPage;

  int onlineUsers      = 0;
  int activeConnections = 0;

  // ── UID user (dari /api/users/uid) ──────────────────────────────────────
  String? uid;

  Color get _glassP => _glassPrimary;
  Color get _glassS => _glassSecond;

  @override
  void initState() {
    super.initState();
    sessionKey   = widget.sessionKey;
    username     = widget.username;
    password     = widget.password;
    role         = widget.role;
    expiredDate  = widget.expiredDate;
    listBug      = widget.listBug;
    listDoos     = widget.listDoos;
    newsList     = widget.news;

    _initAnimations();
    _selectedPage = _buildNewsPage();

    _loadProfileImage();
    _initMenuVideo();
    _fetchDashboardStats();
    _fetchUserUid();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final response =
          await http.get(Uri.parse('${Api.api}/api/dashboard-stats'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            onlineUsers       = data['onlineUsers']       ?? 0;
            activeConnections = data['activeConnections'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetch stats: $e");
    }
  }

  // ── Fetch UID user dari endpoint /api/users/uid/:username ───────────────
  Future<void> _fetchUserUid() async {
    try {
      final response = await http.get(
        Uri.parse('${Api.api}/api/users/uid/$username'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List users = data['data'] ?? [];
          if (users.isNotEmpty && mounted) {
            final match = users.first;
            setState(() {
              uid = (match['uid'] ?? match['id'])?.toString();
            });
          }
        }
      } else {
        debugPrint("UID not found for $username (${response.statusCode})");
      }
    } catch (e) {
      debugPrint("Error fetch uid: $e");
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs     = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (!mounted) return;
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() => _profileImage = File(imagePath));
    }
  }

  void _initMenuVideo() {
    _menuVideoController =
        VideoPlayerController.asset('assets/videos/banner.mp4')
          ..initialize().then((_) {
            setState(() {});
            _menuVideoController?.setLooping(true);
            _menuVideoController?.setVolume(0.0);
            _menuVideoController?.play();
          });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  void _handleInvalidSession(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: _primaryWhite.withOpacity(0.1), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              "Session Expired",
              style: TextStyle(
                  color: _accentRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
          ],
        ),
        content: Text(message,
            style: const TextStyle(color: _softGrey, fontSize: 14)),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: _redGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              ),
              child: const Text("OK",
                  style: TextStyle(
                      color: _primaryWhite, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _selectedPage = _buildNewsPage();
      } else if (index == 1) {
        _selectedPage = HomePage(
          username: username,
          password: password,
          listBug: listBug,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
      } else if (index == 2) {
        _selectedPage = InfoPage(sessionKey: sessionKey);
      } else if (index == 3) {
        _selectedPage = ToolsPage(
            username: username,
            sessionKey: sessionKey,
            userRole: role,
            listDoos: listDoos);
      }
    });
  }

  void _onSidebarTabSelected(int index) {
    setState(() {
      if (index == 1) _selectedPage = SellerPage(keyToken: sessionKey);
      if (index == 2) _selectedPage = AdminPage(sessionKey: sessionKey);
      if (index == 3)
        _selectedPage =
            OwnerPage(sessionKey: sessionKey, username: username);
    });
    Navigator.pop(context);
  }

  // ── Main Home / News Page ──────────────────────────────────────────────────

  Widget _buildNewsPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Jarak atas antara AppBar dan banner ─────────────────────────
          const SizedBox(height: 16),

          // ── Full-Width Thumbnail / Video Banner ─────────────────────────
          _buildFullWidthBanner(),

          const SizedBox(height: 16),

          // ── Username Card ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildUsernameCard(),
          ),

          const SizedBox(height: 14),

          // ── Telegram Button (full width) ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildTelegramButton(),
          ),

          const SizedBox(height: 16),

          // ── Feature Cards: WhatsApp + Spy ──────────────────────────────
          _buildFeatureCards(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Full-Width Banner (Video) ───────────────────────────────────────────────

  Widget _buildFullWidthBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 200,
          child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Video background ──────────────────────────────────────
              const _VideoPlayerAsset(),

              // ── Gradient overlay bawah ke atas ───────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.82),
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // ── Gradient overlay kiri (untuk teks kiri bawah) ────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),

              // ── LIVE badge kiri atas ──────────────────────────────────
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accentRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.circle,
                          color: _primaryWhite, size: 6),
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

              // ── Teks kiri bawah: title + subtitle ────────────────────
              Positioned(
                left: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "APHELION GLITCH",
                      style: TextStyle(
                        color: _primaryWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: _accentRed.withOpacity(0.9),
                            blurRadius: 10,
                          ),
                          const Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "CREATED BY RII",
                      style: TextStyle(
                        color: _primaryWhite.withOpacity(0.65),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // ── CONNECT badge kanan bawah ─────────────────────────────
              Positioned(
                right: 14,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF4CAF50), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.circle,
                          color: Color(0xFF4CAF50), size: 7),
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
        ),
      ),
    );
  }

  // ── Username Card ──────────────────────────────────────────────────────────

  Widget _buildUsernameCard() {
    // Background icons profile — style sama seperti carousel card
    final profileBgIcons = [
      _BgIconData(icon: FontAwesomeIcons.userAstronaut, left: 95,  top: -20, size: 90, opacity: 0.20, rotation: -0.26, blur: 0),
      _BgIconData(icon: Icons.shield_rounded,           left: 4,   top:  -8, size: 40, opacity: 0.14, rotation: -0.18, blur: 0),
      _BgIconData(icon: Icons.verified_rounded,         left: 4,   top:  60, size: 32, opacity: 0.13, rotation: -0.32, blur: 0),
      _BgIconData(icon: Icons.star_rounded,             left: 130, top:  60, size: 28, opacity: 0.12, rotation:  0.20, blur: 0),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          // Shadow bawah utama (efek 3D)
          BoxShadow(
            color: const Color(0xFF0A1628).withOpacity(0.9),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          // Shadow samping kanan tipis
          BoxShadow(
            color: const Color(0xFF0A1628).withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(4, 4),
          ),
          // Highlight atas kiri (kesan cahaya)
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
          // ── Background icons tersebar ─────────────────────────────────
          ...profileBgIcons.map((d) => Positioned(
            left: d.left,
            top: d.top,
            child: Transform.rotate(
              angle: d.rotation,
              child: Icon(d.icon,
                  size: d.size,
                  color: Colors.white.withOpacity(d.opacity)),
            ),
          )),

          // ── Konten utama di atas bg icons ─────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // ── Top row: Avatar + Username + Role + Expired ─────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _accentRed.withOpacity(0.4), width: 2),
                      gradient: _secondaryGradient,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _profileImage != null
                          ? Image.file(_profileImage!, fit: BoxFit.cover)
                          : Container(
                              decoration: const BoxDecoration(
                                  gradient: _secondaryGradient),
                              child: const Icon(
                                FontAwesomeIcons.userAstronaut,
                                size: 32,
                                color: _primaryWhite,
                              ),
                            ),
                    ),
                  ),
                  // Online dot
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF111630), width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // Username + UID + Role + Expired
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username.toUpperCase(),
                      style: const TextStyle(
                        color: _primaryWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // ── UID Badge ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF29B6F6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                const Color(0xFF29B6F6).withOpacity(0.35)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: _primaryWhite.withOpacity(0.06),
                            blurRadius: 2,
                            spreadRadius: 0,
                            offset: const Offset(-1, -1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fingerprint_rounded,
                              color: Color(0xFF29B6F6), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "UID: ${uid ?? '-'}",
                            style: const TextStyle(
                              color: Color(0xFF29B6F6),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Role badge
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _softGrey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryWhite.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _primaryWhite.withOpacity(0.15)),
                            // ── Shadow 3D pada badge role ────────────
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 6,
                                spreadRadius: 0,
                                offset: const Offset(0, 3),
                              ),
                              BoxShadow(
                                color: _primaryWhite.withOpacity(0.06),
                                blurRadius: 2,
                                spreadRadius: 0,
                                offset: const Offset(-1, -1),
                              ),
                            ],
                          ),
                          child: Text(
                            "ROLE ANDA: ${role.toUpperCase()}",
                            style: const TextStyle(
                              color: _primaryWhite,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "–",
                          style: TextStyle(
                              color: _softGrey.withOpacity(0.6),
                              fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Expired badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _accentRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _accentRed.withOpacity(0.4), width: 1),
                        // ── Shadow 3D pada badge expired ───────────────
                        boxShadow: [
                          BoxShadow(
                            color: _accentRed.withOpacity(0.25),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.all_inclusive_rounded,
                              color: _accentRed, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            "Expired: $expiredDate",
                            style: const TextStyle(
                              color: _accentRed,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: _primaryWhite.withOpacity(0.06), height: 1),
          const SizedBox(height: 12),

          // ── Bottom row: CONNECTED | VER ────────────────────────────────
          Row(
            children: [
              Row(
                children: const [
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
                ],
              ),

              const Spacer(),

              // Ver
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

  // ── Telegram Button (full width) ───────────────────────────────────────────

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
            Icon(FontAwesomeIcons.telegram,
                color: Color(0xFF29B6F6), size: 20),
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

  // ── Quick Action Carousel ─────────────────────────────────────────────────

  Widget _buildFeatureCards() {
    final cards = [
      // ── WhatsApp ───────────────────────────────────────────────────────────
      _buildReferenceCard(
        title: "WhatsApp",
        subtitle: "Bug & Payload",
        bgColor: const Color(0xFF1A8C4E),
        shadowColor: const Color(0xFF25D366),
        bgIcons: [
          _BgIconData(icon: FontAwesomeIcons.whatsapp,    left: 95,  top: -20, size: 90, opacity: 0.20, rotation: -0.26, blur: 0),
          _BgIconData(icon: Icons.chat_bubble_rounded,    left: 4,   top:  -8, size: 40, opacity: 0.14, rotation: -0.18, blur: 0),
          _BgIconData(icon: Icons.send_rounded,           left: 4,   top:  60, size: 32, opacity: 0.13, rotation: -0.32, blur: 0),
          _BgIconData(icon: Icons.phone_in_talk_rounded,  left: 130, top:  60, size: 28, opacity: 0.12, rotation:  0.22, blur: 0),
        ],
        onTap: () => _onBottomNavTapped(1),
      ),
      // ── Spyware ────────────────────────────────────────────────────────────
      
      // ── Sender Manager ─────────────────────────────────────────────────────
      _buildReferenceCard(
        title: "Sender",
        subtitle: "Manage Sender",
        bgColor: const Color(0xFF6A1B9A),
        shadowColor: const Color(0xFFAB47BC),
        bgIcons: [
          _BgIconData(icon: FontAwesomeIcons.whatsapp,   left: 95,  top: -20, size: 90, opacity: 0.20, rotation: -0.26, blur: 0),
          _BgIconData(icon: Icons.manage_accounts_rounded,left: 4,  top:  -8, size: 40, opacity: 0.14, rotation: -0.18, blur: 0),
          _BgIconData(icon: Icons.devices_rounded,       left: 4,   top:  60, size: 32, opacity: 0.13, rotation: -0.32, blur: 0),
          _BgIconData(icon: Icons.settings_rounded,      left: 130, top:  60, size: 28, opacity: 0.12, rotation:  0.20, blur: 0),
        ],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SenderManagementPage(
              sessionKey: sessionKey,
              username: username,
              role: role,
            ),
          ),
        ),
      ),
      // ── Nonton Anime ───────────────────────────────────────────────────────
      _buildReferenceCard(
        title: "Anime",
        subtitle: "Nonton Anime",
        bgColor: const Color(0xFFE65100),
        shadowColor: const Color(0xFFFF7043),
        bgIcons: [
          _BgIconData(icon: Icons.movie_filter_rounded,  left: 95,  top: -20, size: 90, opacity: 0.20, rotation: -0.26, blur: 0),
          _BgIconData(icon: Icons.play_circle_rounded,   left: 4,   top:  -8, size: 40, opacity: 0.14, rotation: -0.18, blur: 0),
          _BgIconData(icon: Icons.subtitles_rounded,     left: 4,   top:  60, size: 32, opacity: 0.13, rotation: -0.32, blur: 0),
          _BgIconData(icon: Icons.live_tv_rounded,       left: 130, top:  60, size: 28, opacity: 0.12, rotation:  0.20, blur: 0),
        ],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HomeAnimePage()),
        ),
      ),
      // ── Publik Chat ────────────────────────────────────────────────────────
      _buildReferenceCard(
        title: "Publik Chat",
        subtitle: "Community",
        bgColor: const Color(0xFF00695C),
        shadowColor: const Color(0xFF26A69A),
        bgIcons: [
          _BgIconData(icon: Icons.forum_rounded,         left: 95,  top: -20, size: 90, opacity: 0.20, rotation: -0.26, blur: 0),
          _BgIconData(icon: Icons.chat_rounded,          left: 4,   top:  -8, size: 40, opacity: 0.14, rotation: -0.18, blur: 0),
          _BgIconData(icon: Icons.people_rounded,        left: 4,   top:  60, size: 32, opacity: 0.13, rotation: -0.32, blur: 0),
          _BgIconData(icon: Icons.emoji_emotions_rounded,left: 130, top:  60, size: 28, opacity: 0.12, rotation:  0.20, blur: 0),
        ],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommunityPage(username: username, role: role),
          ),
        ),
      ),
      // ── Tq To Team ────────────────────────────────────────────────────────
      _buildReferenceCard(
        title: "Tq To Team",
        subtitle: "Credits",
        bgColor: const Color(0xFFC2185B),
        shadowColor: const Color(0xFFF06292),
        bgIcons: [
          _BgIconData(icon: Icons.favorite_rounded,      left: 95,  top: -20, size: 90, opacity: 0.20, rotation: -0.26, blur: 0),
          _BgIconData(icon: Icons.group_rounded,         left: 4,   top:  -8, size: 40, opacity: 0.14, rotation: -0.18, blur: 0),
          _BgIconData(icon: Icons.stars_rounded,         left: 4,   top:  60, size: 32, opacity: 0.13, rotation: -0.32, blur: 0),
          _BgIconData(icon: Icons.workspace_premium_rounded, left: 130, top: 60, size: 28, opacity: 0.12, rotation: 0.20, blur: 0),
        ],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TqPage()),
        ),
      ),
    ];

    // Pasangkan card jadi 2 kolom per "halaman" carousel
    final List<Widget> pages = [];
    for (int i = 0; i < cards.length; i += 2) {
      final left  = cards[i];
      final right = i + 1 < cards.length ? cards[i + 1] : const SizedBox();
      pages.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 14),
              Expanded(child: i + 1 < cards.length ? right : const SizedBox()),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
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
                "Quick Action",
                style: TextStyle(
                  color: _primaryWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Carousel ───────────────────────────────────────────────────────
        SizedBox(
          height: 110,
          child: PageView.builder(
            controller: PageController(viewportFraction: 1.0),
            itemCount: pages.length,
            itemBuilder: (_, i) => pages[i],
          ),
        ),
      ],
    );
  }

  // ── Reference-style card sesuai gambar ────────────────────────────────────
  Widget _buildReferenceCard({
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color shadowColor,
    required List<_BgIconData> bgIcons,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // ── Background icons tersebar ──────────────────────────────
                ...bgIcons.map((d) => Positioned(
                  left: d.left,
                  top: d.top,
                  child: Transform.rotate(
                    angle: d.rotation,
                    child: Icon(
                      d.icon,
                      size: d.size,
                      color: Colors.white.withOpacity(d.opacity),
                    ),
                  ),
                )),

                // ── Gradient gelap di bawah untuk keterbacaan teks ─────────
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.30),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),

                // ── Teks kiri bawah ────────────────────────────────────────
                Positioned(
                  left: 14,
                  bottom: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _primaryWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _primaryWhite.withOpacity(0.80),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
  // ── Simple single icon widget (unused but kept for compatibility) ──────────
  Widget _buildSimpleIcon({required IconData icon, required Color color}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 1.2),
      ),
      child: Center(child: Icon(icon, color: color, size: 18)),
    );
  }

  // ── Stats Card ─────────────────────────────────────────────────────────────

  Widget _buildStatsCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0, end: 1),
      builder: (_, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_glassP, _glassS],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: _primaryWhite.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: _primaryWhite, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: _softGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable Button Widgets ────────────────────────────────────────────────

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [_glassP, _glassS],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: _primaryWhite.withOpacity(0.1), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _accentRed, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: _primaryWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildRedButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Text(label,
                style: const TextStyle(
                    color: _primaryWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────────

  Widget _buildCustomDrawer() {
    return Drawer(
      backgroundColor: _bgDark,
      width: MediaQuery.of(context).size.width * 0.82,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 280,
            decoration: const BoxDecoration(gradient: _redGradient),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: _primaryWhite, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _accentRed.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _profileImage != null
                            ? Image.file(_profileImage!, fit: BoxFit.cover)
                            : Container(
                                decoration: const BoxDecoration(
                                    gradient: _secondaryGradient),
                                child: Icon(
                                  FontAwesomeIcons.userAstronaut,
                                  size: 45,
                                  color:
                                      _primaryWhite.withOpacity(0.9),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      username,
                      style: const TextStyle(
                          color: _primaryWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: _primaryWhite.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _primaryWhite.withOpacity(0.2)),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                            color: _primaryWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Container(
              color: _bgDark,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  if (role == "reseller")
                    _buildDrawerItem(
                      icon: Icons.storefront_rounded,
                      label: "Seller Page",
                      onTap: () => _onSidebarTabSelected(1),
                    ),
                  if (role == "admin")
                    _buildDrawerItem(
                      icon: Icons.admin_panel_settings_rounded,
                      label: "Admin Page",
                      onTap: () => _onSidebarTabSelected(2),
                    ),
                  if (role == "owner")
                    _buildDrawerItem(
                      icon: Icons.workspace_premium_rounded,
                      label: "Owner Page",
                      onTap: () => _onSidebarTabSelected(3),
                    ),
                  _buildDrawerItem(
                    icon: FontAwesomeIcons.whatsapp,
                    label: "Manage Sender",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SenderManagementPage(
                            sessionKey: sessionKey,
                            username: username,
                            role: role,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    label: "Riwayat Aktivitas",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiwayatPage(
                              sessionKey: sessionKey, role: role),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.movie_filter_rounded,
                    label: "Nonton Anime",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HomeAnimePage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.favorite_rounded,
                    label: "Tq To Team",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TqPage()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.chat_rounded,
                    label: "Publik Chat",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommunityPage(
                              username: username, role: role),
                        ),
                      );
                    },
                  ),
                  const Divider(
                      color: Colors.white10, height: 32, thickness: 0.5),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    label: "Log Out",
                    isLogout: true,
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isLogout
            ? Colors.red.withOpacity(0.1)
            : _glassSecond,
        borderRadius: BorderRadius.circular(16),
        border: isLogout
            ? null
            : Border.all(color: _primaryWhite.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLogout
                ? Colors.red.withOpacity(0.15)
                : _accentRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: isLogout ? Colors.redAccent : _accentRed, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
              color: isLogout ? Colors.redAccent : _primaryWhite,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.3),
        ),
        trailing: isLogout
            ? null
            : const Icon(Icons.chevron_right_rounded,
                color: _softGrey, size: 20),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  // ── Scaffold ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text(
          "Aphelion Glitch",
          style: TextStyle(
            color: _primaryWhite,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        // ── Glass blur effect ─────────────────────────────────────────────
        backgroundColor: Colors.transparent,
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.4),
        centerTitle: true,
        iconTheme: const IconThemeData(color: _primaryWhite),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.10),
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: const Icon(Icons.headset_mic_rounded,
                color: _accentRed, size: 20),
            tooltip: 'Customer Service',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ContactPage())),
          ),
          IconButton(
            padding: const EdgeInsets.only(right: 8),
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            icon: const Icon(FontAwesomeIcons.circleUser,
                color: _accentRed, size: 20),
            tooltip: 'My Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(
                  username: username,
                  password: password,
                  role: role,
                  expiredDate: expiredDate,
                  sessionKey: sessionKey,
                ),
              ),
            ),
          ),
        ],
      ),

      drawer: _buildCustomDrawer(),

      body: Container(
        decoration: BoxDecoration(
          // ── Gradasi ungu menggantikan merah ──────────────────────────────
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              const Color(0xFF7B1FA2).withOpacity(0.20), // ungu
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
                child: _selectedPage,
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _glassPrimary,
          border: Border(
              top:
                  BorderSide(color: _primaryWhite.withOpacity(0.08))),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: _accentRed,
          unselectedItemColor: _softGrey,
          currentIndex: _bottomNavIndex,
          onTap: _onBottomNavTapped,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.whatsapp), label: "WhatsApp"),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications_active_rounded),
                label: "Info"),
            BottomNavigationBarItem(
                icon: Icon(Icons.build_rounded), label: "Tools"),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _menuVideoController?.dispose();
    super.dispose();
  }
}

// ─── Grid Background Painter ───────────────────────────────────────────────────

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
      ..color = const Color(0xFF7B1FA2).withOpacity(0.08) // ungu
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

// ─── Video Player Widget ───────────────────────────────────────────────────────

class _VideoPlayerAsset extends StatefulWidget {
  const _VideoPlayerAsset();

  @override
  __VideoPlayerAssetState createState() => __VideoPlayerAssetState();
}

class __VideoPlayerAssetState extends State<_VideoPlayerAsset> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0.0);
        _controller.play();
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      );
    }
    return Container(
      color: const Color(0xFF0A0E27),
      child: const Center(
        child: CircularProgressIndicator(color: _accentRed),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ─── Background Icon Data Model ────────────────────────────────────────────────

class _BgIconData {
  final IconData icon;
  final double left;
  final double top;
  final double size;
  final double opacity;
  final double rotation; // dalam radian, -0.35 ≈ -20°, -0.17 ≈ -10°
  final double blur;     // 0 = tanpa blur

  const _BgIconData({
    required this.icon,
    required this.left,
    required this.top,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.blur,
  });
}
