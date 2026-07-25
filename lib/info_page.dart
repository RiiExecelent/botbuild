import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

class InfoPage extends StatefulWidget {
  final String sessionKey;

  const InfoPage({super.key, required this.sessionKey});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? serverInfo;
  bool isLoading = true;

  bool isApiOnline = false;
  int apiPingMs = 0;
  Color apiStatusColor = Colors.grey;
  String apiStatusText = "Checking...";
  Timer? _pingTimer;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Rules data ─────────────────────────────────────────────────────────────
  static const List<Map<String, String>> _rulesList = [
    {
      "title": "Larangan Barter Akun",
      "desc":
          "Akun tidak boleh ditukar dengan barang, jasa, atau akun lain dalam bentuk apa pun."
    },
    {
      "title": "Larangan Membagikan Akun",
      "desc":
          "Setiap akun bersifat pribadi dan hanya boleh digunakan oleh pemilik akun yang terdaftar."
    },
    {
      "title": "Larangan Menjual Akun",
      "desc":
          "Member TIDAK diperbolehkan menjual akun. Penjualan akun hanya boleh dilakukan oleh role yang diizinkan secara resmi."
    },
    {
      "title": "Larangan Jual Durasi Ilegal",
      "desc":
          "Dilarang menjual akses harian, mingguan, trial, atau sejenisnya di luar ketentuan yang telah ditetapkan."
    },
    {
      "title": "Larangan Banting Harga",
      "desc":
          "Dilarang merusak atau menurunkan harga yang telah ditentukan (banting harga) di bawah ketentuan FIXCH."
    },
  ];

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _fetchServerInfo();
    _startApiPingLoop();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchServerInfo() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/getServerInfo?key=${widget.sessionKey}'),
      );
      if (res.statusCode == 200) {
        setState(() {
          serverInfo = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  void _startApiPingLoop() {
    _checkApiPing();
    _pingTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _checkApiPing());
  }

  Future<void> _checkApiPing() async {
    final start = DateTime.now();
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/ping?key=${widget.sessionKey}'))
          .timeout(const Duration(seconds: 3));

      final ms = DateTime.now().difference(start).inMilliseconds;

      if (res.statusCode == 200) {
        setState(() {
          isApiOnline   = true;
          apiPingMs     = ms;
          apiStatusColor = ms < 200
              ? Colors.greenAccent
              : ms < 500
                  ? Colors.amber
                  : Colors.orangeAccent;
          apiStatusText = "Online (${ms}ms)";
        });
      } else {
        throw Exception("Failed");
      }
    } catch (_) {
      setState(() {
        isApiOnline    = false;
        apiPingMs      = 0;
        apiStatusColor = _accentRed;
        apiStatusText  = "Offline";
      });
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: _bgDark,
        child: const Center(
          child: CircularProgressIndicator(color: _accentRed),
        ),
      );
    }

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
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page Title ──────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: _redGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (b) => _redGradient.createShader(
                          Rect.fromLTWH(0, 0, b.width, b.height)),
                      child: const Text(
                        "PERATURAN & INFO",
                        style: TextStyle(
                          color: _primaryWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── API Status ──────────────────────────────────────────────
                _buildApiStatus(),

                const SizedBox(height: 28),

                // ── Rules Header ────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: _redGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _accentRed.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.gavel_rounded,
                          color: _primaryWhite, size: 18),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      "PERATURAN PENGGUNA",
                      style: TextStyle(
                        color: _primaryWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Rules List ──────────────────────────────────────────────
                ..._rulesList.asMap().entries.map((entry) {
                  final idx  = entry.key + 1;
                  final rule = entry.value;
                  return _buildRuleCard(idx, rule);
                }).toList(),

                const SizedBox(height: 24),

                // ── Sanksi Card ─────────────────────────────────────────────
                _buildSanksiCard(),

                const SizedBox(height: 28),

                // ── Footer ──────────────────────────────────────────────────
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── API Status Widget ──────────────────────────────────────────────────────

  Widget _buildApiStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_glassPrimary, _glassSecond],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryWhite.withOpacity(0.08), width: 1),
      ),
      child: Row(
        children: [
          // Pulsing dot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            builder: (_, val, __) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: apiStatusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: apiStatusColor.withOpacity(val * 0.6),
                    blurRadius: 8 * val,
                    spreadRadius: val,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "System Status",
                  style: TextStyle(
                      color: _softGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  apiStatusText.toUpperCase(),
                  style: TextStyle(
                    color: apiStatusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Ping badge
          if (isApiOnline)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: _redGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: _accentRed.withOpacity(0.3), blurRadius: 6)
                ],
              ),
              child: Text(
                "${apiPingMs}ms",
                style: const TextStyle(
                    color: _primaryWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // ── Rule Card ──────────────────────────────────────────────────────────────

  Widget _buildRuleCard(int idx, Map<String, String> rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
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
            // Rule badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _accentRed.withOpacity(0.2),
                  _darkRed.withOpacity(0.1)
                ]),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _accentRed.withOpacity(0.4), width: 1),
              ),
              child: Text(
                "Rule $idx",
                style: const TextStyle(
                  color: _softRed,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              rule['title']!,
              style: const TextStyle(
                color: _primaryWhite,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              rule['desc']!,
              style: const TextStyle(
                color: _softGrey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sanksi Card ────────────────────────────────────────────────────────────

  Widget _buildSanksiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentRed.withOpacity(0.12),
            _darkRed.withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accentRed.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _accentRed.withOpacity(0.15),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: _redGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _accentRed.withOpacity(0.4), blurRadius: 10)
                  ],
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: _primaryWhite, size: 24),
              ),
              const SizedBox(width: 14),
              ShaderMask(
                shaderCallback: (b) => _redGradient.createShader(
                    Rect.fromLTWH(0, 0, b.width, b.height)),
                child: const Text(
                  "SANKSI",
                  style: TextStyle(
                    color: _primaryWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Jika pengguna terbukti melanggar salah satu peraturan di atas:",
            style: TextStyle(color: _softGrey, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _accentRed.withOpacity(0.3), width: 1),
            ),
            child: const Text(
              "Akun akan DIHAPUS secara permanen 🚫",
              style: TextStyle(
                color: _primaryWhite,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tanpa pengembalian akun, saldo, atau kompensasi apa pun ‼️",
            style: TextStyle(
              color: _softRed,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: _redGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _accentRed.withOpacity(0.35), blurRadius: 14)
              ],
            ),
            child: const Icon(Icons.shield_rounded,
                color: _primaryWhite, size: 26),
          ),
          const SizedBox(height: 14),
          const Text(
            "Peraturan ini dibuat untuk menjaga keamanan, kenyamanan, dan kestabilan ekosistem FIXCH App. Dengan menggunakan aplikasi ini, pengguna dianggap telah menyetujui seluruh peraturan di atas.",
            style: TextStyle(
              color: _softGrey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Container(
            height: 4,
            width: 80,
            decoration: BoxDecoration(
              gradient: _redGradient,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                    color: _accentRed.withOpacity(0.4), blurRadius: 6)
              ],
            ),
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
