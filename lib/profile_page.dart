import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'change_password_page.dart';

// ─── RED THEME CONSTANTS ───────────────────────────────────────────────────────
const Color _bgDark       = Color(0xFF0A0E27);
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

class ProfilePage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;

  const ProfilePage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

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

    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);

    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
              parent: _animController, curve: Curves.easeOutCubic),
        );

    _loadProfileImage();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _loadProfileImage() async {
    final prefs     = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_${widget.username}');
    if (!mounted) return;
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() => _profileImage = File(imagePath));
    }
  }

  String _censorText(String text, {bool isPassword = false}) {
    if (text.isEmpty) return "N/A";
    if (isPassword) return "••••••••";
    if (text.length <= 2) return "${text.substring(0, 1)}••";
    return "${text.substring(0, 2)}${'•' * (text.length - 2)}";
  }

  Future<void> _showImageSourceDialog() {
    return showModalBottomSheet(
      context: context,
      backgroundColor: _bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _bgDark,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
              top: BorderSide(color: _accentRed.withOpacity(0.3), width: 1)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  gradient: _redGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _buildSheetTile(
                icon: Icons.camera_alt_rounded,
                label: "Kamera",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _buildSheetTile(
                icon: Icons.photo_library_rounded,
                label: "Galeri",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_glassPrimary, _glassSecond],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryWhite.withOpacity(0.08)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: _redGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: _accentRed.withOpacity(0.3), blurRadius: 8)
            ],
          ),
          child: Icon(icon, color: _primaryWhite, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(
                color: _primaryWhite, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: _softGrey, size: 20),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'profile_image_${widget.username}', imageFile.path);
        setState(() => _profileImage = imageFile);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
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
            "My Profile",
            style: TextStyle(
              color: _primaryWhite,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1,
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
                    horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    // ── Avatar ────────────────────────────────────────────
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _redGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: _accentRed.withOpacity(0.5),
                                  blurRadius: 24,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(_profileImage!,
                                      fit: BoxFit.cover)
                                  : Icon(
                                      FontAwesomeIcons.userAstronaut,
                                      size: 50,
                                      color: _primaryWhite.withOpacity(0.9),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: _redGradient,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _bgDark, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                      color: _accentRed.withOpacity(0.4),
                                      blurRadius: 8)
                                ],
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 16, color: _primaryWhite),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Username ──────────────────────────────────────────
                    ShaderMask(
                      shaderCallback: (b) => _redGradient.createShader(
                          Rect.fromLTWH(0, 0, b.width, b.height)),
                      child: Text(
                        widget.username,
                        style: const TextStyle(
                          color: _primaryWhite,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Role badge ────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          _accentRed.withOpacity(0.2),
                          _darkRed.withOpacity(0.1)
                        ]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _accentRed.withOpacity(0.4), width: 1),
                      ),
                      child: Text(
                        widget.role.toUpperCase(),
                        style: const TextStyle(
                          color: _softRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Info Grid Row 1 ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.person_outline_rounded,
                            label: "Username",
                            value: _censorText(widget.username),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.lock_outline_rounded,
                            label: "Password",
                            value: _censorText(widget.password,
                                isPassword: true),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Info Grid Row 2 ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.verified_user_outlined,
                            label: "Role",
                            value: widget.role.toUpperCase(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.calendar_today_rounded,
                            label: "Expired",
                            value: widget.expiredDate,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Session Key (full width) ───────────────────────────
                    _buildInfoCard(
                      icon: Icons.vpn_key_rounded,
                      label: "Session Key",
                      value:
                          "${widget.sessionKey.substring(0, 8)}...",
                    ),

                    const SizedBox(height: 36),

                    // ── Change Password Button ────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangePasswordPage(
                            username: widget.username,
                            sessionKey: widget.sessionKey,
                          ),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: _redGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _accentRed.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_reset_rounded,
                                color: _primaryWhite, size: 20),
                            SizedBox(width: 12),
                            Text(
                              "CHANGE PASSWORD",
                              style: TextStyle(
                                color: _primaryWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Info Card ──────────────────────────────────────────────────────────────

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_glassPrimary, _glassSecond],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryWhite.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: _accentRed.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                child: Icon(icon, color: _primaryWhite, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _softGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: _primaryWhite,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
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
