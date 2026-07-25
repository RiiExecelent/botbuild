import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'btrapps/.dart';

final baseUrl = Api.api;

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

class ChangePasswordPage extends StatefulWidget {
  final String username;
  final String sessionKey;

  const ChangePasswordPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with SingleTickerProviderStateMixin {
  final oldPassCtrl     = TextEditingController();
  final newPassCtrl     = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool isLoading       = false;
  bool _obscureOld     = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animController.dispose();
    oldPassCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  // ── Logic ──────────────────────────────────────────────────────────────────

  Future<void> _changePassword() async {
    final oldPass     = oldPassCtrl.text.trim();
    final newPass     = newPassCtrl.text.trim();
    final confirmPass = confirmPassCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showMessage("Semua field harus diisi.");
      return;
    }
    if (newPass != confirmPass) {
      _showMessage("Password baru tidak cocok dengan konfirmasi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/changepass"),
        body: {
          "username":   widget.username,
          "oldPass":    oldPass,
          "newPass":    newPass,
          "sessionKey": widget.sessionKey,
        },
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _showMessage("Password berhasil diubah!", isSuccess: true);
        oldPassCtrl.clear();
        newPassCtrl.clear();
        confirmPassCtrl.clear();
      } else {
        _showMessage(data['message'] ?? "Gagal mengubah password");
      }
    } catch (e) {
      _showMessage("Koneksi error: $e");
    }
    setState(() => isLoading = false);
  }

  void _showMessage(String msg, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: _accentRed.withOpacity(0.4), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: isSuccess
                    ? const LinearGradient(
                        colors: [Colors.green, Color(0xFF00C853)])
                    : _redGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isSuccess ? Colors.green : _accentRed)
                        .withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                isSuccess
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                color: _primaryWhite,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isSuccess ? "Sukses" : "Peringatan",
              style: const TextStyle(
                  color: _primaryWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ],
        ),
        content: Text(msg,
            style: const TextStyle(
                color: _softGrey, fontSize: 14, height: 1.5)),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: _redGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: _accentRed.withOpacity(0.3), blurRadius: 8)
              ],
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK",
                  style: TextStyle(
                      color: _primaryWhite, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Field ─────────────────────────────────────────────────────────────

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_glassPrimary, _glassSecond],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryWhite.withOpacity(0.1), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: _primaryWhite, fontSize: 15),
        cursorColor: _accentRed,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _softGrey, fontSize: 13),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: _redGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primaryWhite, size: 16),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 50, minHeight: 48),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _softGrey,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: _glassPrimary,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: _primaryWhite.withOpacity(0.08)),
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
                  offset: const Offset(0, 2))
            ],
          ),
          child: const Text(
            "CHANGE PASSWORD",
            style: TextStyle(
              color: _primaryWhite,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),

      // ── Body ───────────────────────────────────────────────────────────────
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // ── Hero Icon ──────────────────────────────────────────
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: _redGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _accentRed.withOpacity(0.45),
                            blurRadius: 28,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: _primaryWhite, size: 48),
                    ),

                    const SizedBox(height: 20),

                    // ── Title ──────────────────────────────────────────────
                    ShaderMask(
                      shaderCallback: (b) => _redGradient.createShader(
                          Rect.fromLTWH(0, 0, b.width, b.height)),
                      child: const Text(
                        "SECURITY UPDATE",
                        style: TextStyle(
                          color: _primaryWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Masukkan password lama dan baru.",
                      style: TextStyle(color: _softGrey, fontSize: 13),
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
                              color: _accentRed.withOpacity(0.4),
                              blurRadius: 6)
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Inputs ─────────────────────────────────────────────
                    _buildInput(
                      controller: oldPassCtrl,
                      label: "Old Password",
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscureOld,
                      onToggle: () =>
                          setState(() => _obscureOld = !_obscureOld),
                    ),
                    _buildInput(
                      controller: newPassCtrl,
                      label: "New Password",
                      icon: Icons.vpn_key_rounded,
                      obscure: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    _buildInput(
                      controller: confirmPassCtrl,
                      label: "Confirm Password",
                      icon: Icons.enhanced_encryption_rounded,
                      obscure: _obscureConfirm,
                      onToggle: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),

                    const SizedBox(height: 28),

                    // ── Submit Button ──────────────────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isLoading
                          ? 62
                          : double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: _redGradient,
                        borderRadius:
                            BorderRadius.circular(isLoading ? 31 : 20),
                        boxShadow: [
                          BoxShadow(
                            color: _accentRed.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isLoading ? null : _changePassword,
                          borderRadius: BorderRadius.circular(
                              isLoading ? 31 : 20),
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: _primaryWhite,
                                    ),
                                  )
                                : const Text(
                                    "UPDATE PASSWORD",
                                    style: TextStyle(
                                      color: _primaryWhite,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
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
