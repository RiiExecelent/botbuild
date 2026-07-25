import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'btrapps/.dart';

final baseUrl = Api.api; // Sesuaikan dengan API Anda

// ─── RED THEME CONSTANTS ──────────────────────────────────────────────────────
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

class ScanSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const ScanSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<ScanSenderPage> createState() => _ScanSenderPageState();
}

class _ScanSenderPageState extends State<ScanSenderPage> {
  late TextEditingController _domainController;
  late TextEditingController _pltaController;
  late TextEditingController _pltcController;

  bool _isLoading = false;
  bool _showResults = false;
  
  int _totalFound = 0;
  int _connected = 0;
  int _failed = 0;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _domainController = TextEditingController();
    _pltaController = TextEditingController();
    _pltcController = TextEditingController();
  }

  @override
  void dispose() {
    _domainController.dispose();
    _pltaController.dispose();
    _pltcController.dispose();
    super.dispose();
  }

  Future<void> _scanCredentials() async {
    final domain = _domainController.text.trim();
    final plta = _pltaController.text.trim();
    final pltc = _pltcController.text.trim();

    if (domain.isEmpty || plta.isEmpty || pltc.isEmpty) {
      _showSnackBar("Semua field harus diisi!", Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _showResults = false;
      _logs.clear();
    });

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/scancreds-connect?key=${widget.sessionKey}&domain=$domain&plta=$plta&pltc=$pltc',
        ),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            _totalFound = data['total'] ?? 0;
            _connected = data['connected'] ?? 0;
            _failed = data['failed'] ?? 0;
            _logs = List<String>.from(data['logs'] ?? []);
            _showResults = true;
          });
          _showSnackBar("Scan berhasil!", Colors.green);
        } else {
          _showSnackBar(data['message'] ?? "Scan gagal", Colors.red);
        }
      } else {
        _showSnackBar("Server error: ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _primaryWhite,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: _primaryWhite.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _primaryWhite.withOpacity(0.12),
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: _primaryWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: _accentRed, size: 18),
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: _softGrey.withOpacity(0.6),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0, end: 1),
      builder: (_, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: _softGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(String log) {
    final isSuccess = log.toLowerCase().contains('connected:');
    final isFailed = log.toLowerCase().contains('failed');
    final isError = log.toLowerCase().contains('error');

    Color logColor = _softGrey;
    IconData logIcon = Icons.info_rounded;

    if (isSuccess) {
      logColor = const Color(0xFF4CAF50);
      logIcon = Icons.check_circle_rounded;
    } else if (isFailed || isError) {
      logColor = _accentRed;
      logIcon = Icons.error_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: logColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: logColor.withOpacity(0.2),
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(logIcon, color: logColor, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    log,
                    style: TextStyle(
                      color: logColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
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

  Widget _buildScanForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _accentRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _accentRed.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, color: _accentRed, size: 6),
                    SizedBox(width: 6),
                    Text(
                      "SCAN CREDENTIALS",
                      style: TextStyle(
                        color: _accentRed,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Scan Sender",
                style: TextStyle(
                  color: _primaryWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Pindai dan koneksikan credentials dari server",
                style: TextStyle(
                  color: _softGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Input Fields ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildInputField(
                label: "Domain Target",
                hint: "Masukkan domain server",
                controller: _domainController,
                icon: Icons.language_rounded,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: "PLTA Parameter",
                hint: "Parameter 1",
                controller: _pltaController,
                icon: Icons.key_rounded,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: "PLTC Parameter",
                hint: "Parameter 2",
                controller: _pltcController,
                icon: Icons.vpn_key_rounded,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Scan Button ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildScanButton(),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _scanCredentials,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: _redGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _accentRed.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: _primaryWhite,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.radar_rounded,
                          color: _primaryWhite, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "MULAI SCAN",
                        style: TextStyle(
                          color: _primaryWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats Row ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  label: "Total Ditemukan",
                  value: _totalFound,
                  color: const Color(0xFF2196F3),
                  icon: Icons.search_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatsCard(
                  label: "Berhasil Koneksi",
                  value: _connected,
                  color: const Color(0xFF4CAF50),
                  icon: Icons.cloud_done_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatsCard(
                  label: "Gagal",
                  value: _failed,
                  color: _accentRed,
                  icon: Icons.error_outline_rounded,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Progress Indicator ─────────────────────────────────────────────
        if (_totalFound > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryWhite.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _primaryWhite.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Success Rate",
                            style: TextStyle(
                              color: _primaryWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            "${((_connected / _totalFound) * 100).toStringAsFixed(1)}%",
                            style: const TextStyle(
                              color: _accentRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _totalFound > 0 ? _connected / _totalFound : 0,
                          minHeight: 8,
                          backgroundColor: _accentRed.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _accentRed.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // ── Logs Section ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
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
                    "Scan Logs",
                    style: TextStyle(
                      color: _primaryWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${_logs.length} logs",
                    style: TextStyle(
                      color: _softGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_logs.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _primaryWhite.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _primaryWhite.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: _logs.map((log) => _buildLogItem(log)).toList(),
                      ),
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _primaryWhite.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _primaryWhite.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Belum ada logs",
                          style: TextStyle(
                            color: _softGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Reset Button ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => setState(() => _showResults = false),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: _primaryWhite.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _primaryWhite.withOpacity(0.12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, color: _softGrey, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Scan Ulang",
                    style: TextStyle(
                      color: _softGrey,
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

        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: _primaryWhite, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Scan Sender",
          style: TextStyle(
            color: _primaryWhite,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              const Color(0xFF7B1FA2).withOpacity(0.15),
              _bgDark,
              _bgDark,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _showResults ? _buildResultsView() : _buildScanForm(),
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
