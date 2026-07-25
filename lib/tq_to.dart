import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'btrapps/.dart';

final baseUrl = Api.api;

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

class TqPage extends StatefulWidget {
  const TqPage({super.key});

  @override
  State<TqPage> createState() => TqPageState();
}

class TqPageState extends State<TqPage> with SingleTickerProviderStateMixin {
  List<dynamic> _tqList      = [];
  bool          _isLoading   = true;
  String?       _errorMessage;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchTqData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Network ────────────────────────────────────────────────────────────────

  Future<void> _fetchTqData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tq'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == true && data['result'] != null) {
          setState(() { _tqList = data['result']; _isLoading = false; });
        } else {
          setState(() { _errorMessage = 'Failed to load data'; _isLoading = false; });
        }
      } else {
        setState(() { _errorMessage = 'Error: ${response.statusCode}'; _isLoading = false; });
      }
    } catch (_) {
      setState(() { _errorMessage = 'Connection error'; _isLoading = false; });
    }
  }

  Future<void> _launchTelegram(String contact) async {
    final url = Uri.parse(
        contact.startsWith('http') ? contact : 'https://$contact');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not launch $contact',
            style: const TextStyle(color: _primaryWhite)),
        backgroundColor: _accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: _primaryWhite.withOpacity(0.08), width: 1)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _glassPrimary,
                shape: BoxShape.circle,
                border: Border.all(
                    color: _primaryWhite.withOpacity(0.08), width: 1),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: _accentRed, size: 20),
            ),
          ),
          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => _redGradient.createShader(
                      Rect.fromLTWH(0, 0, b.width, b.height)),
                  child: const Text(
                    'SPECIAL THANKS TO',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _primaryWhite,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_tqList.length} contributors',
                  style: const TextStyle(color: _softGrey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Refresh button
          GestureDetector(
            onTap: _fetchTqData,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _glassPrimary,
                shape: BoxShape.circle,
                border: Border.all(
                    color: _primaryWhite.withOpacity(0.08), width: 1),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: _accentRed, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTqCard(Map<String, dynamic> item, int index) {
    final isLast = index == _tqList.length - 1;

    return Container(
      margin: EdgeInsets.only(
          left: 16, right: 16, bottom: isLast ? 16 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_glassPrimary, _glassSecond],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: _primaryWhite.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: _accentRed.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _accentRed, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _accentRed.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  item['ppUrl'] ?? '',
                  fit: BoxFit.cover,
                  width: 70,
                  height: 70,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: _glassPrimary,
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: _accentRed, strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: _glassPrimary,
                    child: const Icon(Icons.person_rounded,
                        color: _softGrey, size: 30),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Name + Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name']
                            ?.toString()
                            .replaceAll(RegExp(r'<[^>]*>'), '') ??
                        'Unknown',
                    style: const TextStyle(
                      color: _primaryWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        _accentRed.withOpacity(0.15),
                        _darkRed.withOpacity(0.1)
                      ]),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _accentRed.withOpacity(0.35), width: 1),
                    ),
                    child: Text(
                      item['status'] ?? 'Member',
                      style: const TextStyle(
                        color: _softRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Telegram button
            GestureDetector(
              onTap: () => _launchTelegram(item['contac'] ?? ''),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _redGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _accentRed.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const FaIcon(FontAwesomeIcons.telegram,
                    color: _primaryWhite, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _accentRed,
              backgroundColor: _glassPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading contributors...',
            style: TextStyle(color: _softGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _accentRed.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _accentRed.withOpacity(0.3)),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: _accentRed, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Error Loading Data',
              style: TextStyle(
                  color: _primaryWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: const TextStyle(
                  color: _softGrey, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _fetchTqData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: _redGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: _accentRed.withOpacity(0.4), blurRadius: 16)
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        color: _primaryWhite, size: 18),
                    SizedBox(width: 8),
                    Text('Try Again',
                        style: TextStyle(
                            color: _primaryWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _accentRed.withOpacity(0.12),
                _darkRed.withOpacity(0.08)
              ]),
              shape: BoxShape.circle,
              border:
                  Border.all(color: _accentRed.withOpacity(0.3), width: 1),
            ),
            child: const Icon(Icons.people_outline_rounded,
                color: _accentRed, size: 44),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Contributors Found',
            style: TextStyle(
                color: _primaryWhite,
                fontSize: 17,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'The list is empty',
            style: TextStyle(color: _softGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Scaffold ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Container(
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
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingState()
                        : _errorMessage != null
                            ? _buildErrorState()
                            : _tqList.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    physics:
                                        const BouncingScrollPhysics(),
                                    padding:
                                        const EdgeInsets.only(top: 16),
                                    itemCount: _tqList.length,
                                    itemBuilder: (_, i) =>
                                        _buildTqCard(_tqList[i], i),
                                  ),
                  ),
                ],
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
