import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';
import 'btrapps/.dart';

final baseUrl = Api.api;

// ─── RED THEME CONSTANTS (identik 1:1 dengan dashboard_page.dart) ─────────────
const Color _bgDark       = Color(0xFF0A0E27);
const Color _bgSecondary  = Color(0xFF111630);
const Color _accentRed    = Color(0xFFF44336);
const Color _darkRed      = Color(0xFFB71C1C);
const Color _softRed      = Color(0xFFEF5350);
const Color _primaryWhite = Color(0xFFFFFFFF);
const Color _softGrey     = Color(0xFF94A3B8);
const Color _glassPrimary = Color(0x1AFFFFFF);
const Color _glassSecond  = Color(0x0DFFFFFF);

// ─── NAVBAR (sama dengan dashboard walaupun tidak dipakai di login) ───────────
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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey       = GlobalKey<FormState>();

  bool isLoading        = false;
  bool _obscurePassword = true;
  String? androidId;

  late AnimationController _controller;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _initAnim();
    initLogin();
  }

  // ── Animasi identik dengan dashboard (800ms, easeOut + easeOutCubic) ─────────
  void _initAnim() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
  }

  Future<void> initLogin() async {
    androidId = await _getAndroidId();

    final prefs     = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey  = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse(
          "$baseUrl/myInfo?username=$savedUser&password=$savedPass"
          "&androidId=$androidId&key=$savedKey");
      try {
        final res  = await http.get(uri);
        final data = jsonDecode(res.body);
        if (data['valid'] == true && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SplashScreen(
                username:    savedUser,
                password:    savedPass,
                role:        data['role'],
                sessionKey:  data['key'],
                expiredDate: data['expiredDate'],
                listBug: (data['listBug'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                listDoos: (data['listDDoS'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                news: (data['news'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
              ),
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<String> _getAndroidId() async {
    final android = await DeviceInfoPlugin().androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userController.text.trim();
    final password = passController.text.trim();
    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );

      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showPopup(
          title: "⏳ Access Expired",
          message: "Masa akses Anda telah habis.\nSilakan perpanjang akses.",
          color: Colors.orange,
          showContact: true,
        );
      } else if (validData['valid'] != true) {
        final String errorMsg = (validData['message'] ?? "").toLowerCase();
        if (errorMsg.contains("perangkat") ||
            errorMsg.contains("device") ||
            errorMsg.contains("another")) {
          _showPopup(
            title: "⚠️ Sesi Aktif",
            message:
                "Akun ini sedang login di perangkat lain.\nSilakan logout terlebih dahulu di perangkat lama.",
            color: Colors.orangeAccent,
          );
        } else {
          _showPopup(
            title: "❌ Login Gagal",
            message: "Username atau password salah.",
            color: _softRed,
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SplashScreen(
                username:    username,
                password:    password,
                role:        validData['role'],
                sessionKey:  validData['key'],
                expiredDate: validData['expiredDate'],
                listBug: (validData['listBug'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                listDoos: (validData['listDDoS'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                news: (validData['news'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showPopup(
        title: "⚠️ Connection Error",
        message: "Gagal terhubung ke server.\nPeriksa koneksi internet Anda.",
        color: _accentRed,
      );
    }

    setState(() => isLoading = false);
  }

  // ── Dialog — identik dengan _handleInvalidSession di dashboard ────────────────
  void _showPopup({
    required String title,
    required String message,
    Color color = const Color(0xFFF44336),
    bool showContact = false,
  }) {
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
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_amber_rounded, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: _softGrey, fontSize: 14, height: 1.5),
        ),
        actions: [
          if (showContact)
            Container(
              decoration: BoxDecoration(
                color: _accentRed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextButton(
                onPressed: () async {
                  await launchUrl(Uri.parse("https://t.me/iamrii"),
                      mode: LaunchMode.externalApplication);
                },
                child: const Text(
                  "Contact Admin",
                  style: TextStyle(
                      color: _accentRed, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: _redGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                    color: _primaryWhite, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // ── RadialGradient — UNGU identik dengan body dashboard ───────────────
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              const Color(0xFF7B1FA2).withOpacity(0.20), // ungu — sama dashboard
              _bgDark,
              _bgDark,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),

        // ── GridPainter identik dengan dashboard ─────────────────────────────
        child: CustomPaint(
          painter: _GridPainter(),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),

                        // ── Logo ─────────────────────────────────────────────
                        _buildLogo(),

                        const SizedBox(height: 28),

                        // ── Title ─────────────────────────────────────────────
                        ShaderMask(
                          shaderCallback: (b) => _redGradient.createShader(
                              Rect.fromLTWH(0, 0, b.width, b.height)),
                          child: const Text(
                            "Welcome Back",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: _primaryWhite,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // ── Subtitle dengan divider kiri-kanan ────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 24, height: 1,
                                color: _softGrey.withOpacity(0.3)),
                            const SizedBox(width: 10),
                            const Text(
                              "Sign in to continue",
                              style: TextStyle(
                                  color: _softGrey,
                                  fontSize: 14,
                                  letterSpacing: 0.3),
                            ),
                            const SizedBox(width: 10),
                            Container(width: 24, height: 1,
                                color: _softGrey.withOpacity(0.3)),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ── Form Card (gaya username card dashboard) ───────────
                        _buildFormCard(),

                        const SizedBox(height: 20),

                        // ── Footer ────────────────────────────────────────────
                        Text(
                          "APHELION GLITCH • CREATED BY RII",
                          style: TextStyle(
                            color: _softGrey.withOpacity(0.35),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
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
      ),
    );
  }

  // ── Logo dengan glow ring ──────────────────────────────────────────────────

  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring — glow ungu tipis (warna sama dengan radial bg)
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF7B1FA2).withOpacity(0.20), width: 1),
          ),
        ),
        // Mid ring — merah tipis
        Container(
          width: 114,
          height: 114,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: _accentRed.withOpacity(0.25), width: 1),
          ),
        ),
        // Logo — gaya sama dengan avatar di username card dashboard
        Hero(
          tag: "logo",
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: _secondaryGradient, // pakai _secondaryGradient — sama avatar
              border: Border.all(
                  color: _accentRed.withOpacity(0.4), width: 2),
              boxShadow: [
                // Shadow utama bawah — sama dengan avatar card
                BoxShadow(
                  color: const Color(0xFF0A1628).withOpacity(0.9),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                // Glow merah
                BoxShadow(
                  color: _accentRed.withOpacity(0.40),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Form Card — identik dengan _buildUsernameCard() di dashboard ──────────────

  Widget _buildFormCard() {
    // Bg icons dekoratif — sama pola dengan profileBgIcons di username card
    final bgIcons = <_BgIconData>[
      _BgIconData(icon: Icons.lock_rounded,          left: 200, top: -20, size: 90, opacity: 0.05, rotation: -0.26),
      _BgIconData(icon: Icons.person_rounded,        left: -20, top: -10, size: 70, opacity: 0.05, rotation:  0.20),
      _BgIconData(icon: Icons.shield_rounded,        left: -15, top: 150, size: 55, opacity: 0.04, rotation: -0.18),
      _BgIconData(icon: Icons.verified_rounded,      left: 220, top: 160, size: 45, opacity: 0.04, rotation:  0.30),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Warna bg card — identik dengan _buildUsernameCard
          color: const Color(0xFF0D2137),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            // Shadow 3-layer — copy-paste dari username card
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
            // ── Bg icons tersebar ─────────────────────────────────────────
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

            // ── Konten form ───────────────────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Section label — identik dengan "Quick Action" di dashboard
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
                        "Credentials",
                        style: TextStyle(
                          color: _primaryWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Divider tipis — sama dengan divider di username card
                  Divider(color: _primaryWhite.withOpacity(0.06), height: 1),

                  const SizedBox(height: 16),

                  _buildInput(userController, "Username",
                      Icons.person_outline_rounded),

                  const SizedBox(height: 12),

                  _buildInput(passController, "Password",
                      Icons.lock_outline_rounded, isPassword: true),

                  const SizedBox(height: 20),

                  // Divider sebelum button
                  Divider(color: _primaryWhite.withOpacity(0.06), height: 1),

                  const SizedBox(height: 16),

                  _buildButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Input Field ────────────────────────────────────────────────────────────

  Widget _buildInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        // Glass gradient — sama dengan _buildGlassButton di dashboard
        gradient: LinearGradient(
          colors: [_glassPrimary, _glassSecond],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _primaryWhite.withOpacity(0.10), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: _primaryWhite, fontSize: 15),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? "$label tidak boleh kosong" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _softGrey, fontSize: 14),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // Prefix icon pakai _redGradient — sama dengan icon container di drawer
              gradient: _redGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _accentRed.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: _primaryWhite, size: 18),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 52, minHeight: 40),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _softGrey,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          errorStyle: const TextStyle(color: _softRed, fontSize: 11),
        ),
      ),
    );
  }

  // ── Login Button — identik dengan _buildRedButton() di dashboard ──────────────

  Widget _buildButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isLoading ? 62 : double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: _redGradient,
        borderRadius: BorderRadius.circular(isLoading ? 31 : 20),
        boxShadow: [
          BoxShadow(
            color: _accentRed.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : login,
          borderRadius: BorderRadius.circular(isLoading ? 31 : 20),
          splashColor: _primaryWhite.withOpacity(0.12),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_primaryWhite),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.login_rounded,
                          color: _primaryWhite, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "Sign In",
                        style: TextStyle(
                          color: _primaryWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Grid Painter — IDENTIK dengan dashboard_page.dart ────────────────────────

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

    // Accent lines — UNGU 0xFF7B1FA2, identik dengan dashboard
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

// ─── Bg Icon Data Model — identik dengan dashboard_page.dart ─────────────────

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
