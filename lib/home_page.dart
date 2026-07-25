import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'btrapps/.dart';

final baseUrl = Api.api;

// ─── RED THEME CONSTANTS (identik 1:1 dengan dashboard_page.dart) ─────────────
const Color _bgDark       = Color(0xFF0A0E27);
const Color _cardBg       = Color(0xFF111630);
const Color _accentRed    = Color(0xFFF44336);
const Color _darkRed      = Color(0xFFB71C1C);
const Color _softRed      = Color(0xFFEF5350);
const Color _primaryWhite = Color(0xFFFFFFFF);
const Color _softGrey     = Color(0xFF94A3B8);
const Color _glassPrimary = Color(0x1AFFFFFF);
const Color _glassSecond  = Color(0x0DFFFFFF);

// ─── NAVBAR (sama dengan dashboard) ──────────────────────────────────────────
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

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  Set<String> selectedBugIds = {};
  String _selectedBugMode = "number";

  List<Map<String, dynamic>> _channelList = [];
  Map<String, dynamic>? _selectedChannel;
  bool _isLoadingChannels = false;

  bool _isSending = false;
  String? _responseMessage;

  // Video
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    // Durasi animasi identik dengan dashboard (800ms)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoController =
        VideoPlayerController.asset('assets/videos/banner.mp4');
    _videoController.initialize().then((_) {
      setState(() {
        _videoController.setVolume(0.0);
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          showControls: false,
          autoInitialize: true,
        );
        _isVideoInitialized = true;
      });
    }).catchError((e) {
      setState(() => _isVideoInitialized = false);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    targetController.dispose();
    if (_isVideoInitialized) {
      _videoController.dispose();
      _chewieController.dispose();
    }
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length < 8) return null;
    return cleaned;
  }

  bool isValidGroupLink(String input) =>
      input.contains('chat.whatsapp.com') && input.contains('https://');

  // ── Channel ────────────────────────────────────────────────────────────────

  Future<void> _fetchUserChannels() async {
    setState(() {
      _isLoadingChannels = true;
      _channelList = [];
      _selectedChannel = null;
    });
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/mych?key=${widget.sessionKey}"));
      final data = jsonDecode(res.body);
      if (data["valid"] == true &&
          data["sender"] == true &&
          data["channel"] != null) {
        setState(() {
          _channelList =
              List<Map<String, dynamic>>.from(data["channel"]);
        });
      } else {
        _showAlert(
            "❌ Gagal Memuat Channel", "Tidak dapat mengambil daftar channel.");
      }
    } catch (_) {
      _showAlert("❌ Error", "Terjadi kesalahan saat memuat channel.");
    } finally {
      setState(() => _isLoadingChannels = false);
    }
  }

  void _showChannelSelectionPopup() {
    if (_channelList.isEmpty) _fetchUserChannels();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          // Dialog bg identik dengan dashboard _handleInvalidSession
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
                  gradient: _redGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.campaign_rounded,
                    color: _primaryWhite, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "PILIH CHANNEL",
                style: TextStyle(
                    color: _primaryWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: _isLoadingChannels
                  ? const Center(
                      child: CircularProgressIndicator(color: _accentRed))
                  : _channelList.isEmpty
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: _softGrey, size: 48),
                            const SizedBox(height: 16),
                            const Text("Tidak ada channel ditemukan",
                                style: TextStyle(color: _softGrey)),
                            const SizedBox(height: 16),
                            _smallRedButton(
                              label: "Refresh",
                              onTap: () {
                                Navigator.pop(ctx);
                                _fetchUserChannels();
                              },
                            ),
                          ],
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _channelList.length,
                          itemBuilder: (_, i) {
                            final ch = _channelList[i];
                            final sel =
                                _selectedChannel?['id'] == ch['id'];
                            return _dialogListItem(
                              title: ch['title'] ?? 'Unknown Channel',
                              subtitle: 'ID: ${ch['id']}',
                              selected: sel,
                              onTap: () =>
                                  setS(() => _selectedChannel = ch),
                            );
                          },
                        ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL",
                  style: TextStyle(color: _softGrey)),
            ),
            _dialogOkButton(
              enabled: _selectedChannel != null,
              onTap: () {
                setState(() {
                  targetController.text =
                      _selectedChannel!['title'] ?? '';
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      }),
    );
  }

  void _showBugSelectionPopup() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
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
                  gradient: _redGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bug_report_rounded,
                    color: _primaryWhite, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("PILIH BUG",
                  style: TextStyle(
                      color: _primaryWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.listBug.length,
                itemBuilder: (_, i) {
                  final bug = widget.listBug[i];
                  final bugId = bug['bug_id'];
                  final sel = selectedBugIds.contains(bugId);
                  return _dialogListItem(
                    title: bug['bug_name'],
                    subtitle: bug['description'],
                    selected: sel,
                    onTap: () => setS(() {
                      if (sel) {
                        selectedBugIds.remove(bugId);
                      } else {
                        selectedBugIds.add(bugId);
                      }
                    }),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => setS(() => selectedBugIds.clear()),
              child: const Text("RESET",
                  style: TextStyle(color: _softRed)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL",
                  style: TextStyle(color: _softGrey)),
            ),
            _dialogOkButton(
              enabled: selectedBugIds.isNotEmpty,
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        );
      }),
    );
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final key = widget.sessionKey;

    if (_selectedBugMode == "number") {
      if (formatPhoneNumber(rawInput) == null) {
        _showAlert("❌ Invalid Number",
            "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.");
        return;
      }
      if (selectedBugIds.isEmpty) {
        _showAlert("❌ No Bug Selected", "Pilih minimal 1 bug untuk dikirim.");
        return;
      }
    } else if (_selectedBugMode == "group") {
      if (!isValidGroupLink(rawInput)) {
        _showAlert("❌ Invalid Link",
            "Masukkan link group WA yang valid (contoh: https://chat.whatsapp.com/...).");
        return;
      }
      if (selectedBugIds.isEmpty) {
        _showAlert("❌ No Bug Selected", "Pilih minimal 1 bug untuk dikirim.");
        return;
      }
    } else if (_selectedBugMode == "channel" && _selectedChannel == null) {
      _showAlert(
          "❌ No Channel Selected", "Pilih channel tujuan terlebih dahulu.");
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      late http.Response res;
      late Map<String, dynamic> data;

      if (_selectedBugMode == "channel") {
        res = await http.get(Uri.parse(
            "$baseUrl/raidch?key=$key&id=${_selectedChannel!['id']}"));
        data = jsonDecode(res.body);
        if (data["cooldown"] == true) {
          setState(
              () => _responseMessage = "⏳ Cooldown: Tunggu beberapa saat.");
        } else if (data["valid"] == false) {
          setState(() =>
              _responseMessage = "❌ Key Invalid: Silakan login ulang.");
        } else if (data["sender"] == false) {
          setState(() => _responseMessage = "❌ Sender Anda Kosong.");
        } else if (data["sended"] == false) {
          setState(() =>
              _responseMessage = "⚠️ Gagal: Server sedang maintenance.");
        } else {
          setState(() {
            _responseMessage = "✅ Berhasil mengirim bug ke channel!";
            targetController.clear();
            _selectedChannel = null;
          });
        }
      } else {
        final bugsParam = selectedBugIds.join(',');
        final apiType =
            _selectedBugMode == "number" ? "sendBug" : "raidGrouP";
        res = await http.get(Uri.parse(
            "$baseUrl/$apiType?key=$key&target=$rawInput&bug=$bugsParam"));
        data = jsonDecode(res.body);
        if (data["cooldown"] == true) {
          setState(
              () => _responseMessage = "⏳ Cooldown: Tunggu beberapa saat.");
        } else if (data["valid"] == false) {
          setState(() =>
              _responseMessage = "❌ Key Invalid: Silakan login ulang.");
        } else if (data["sender"] == false) {
          setState(() => _responseMessage = "❌ Sender Anda Kosong.");
        } else if (data["sended"] == false) {
          setState(() =>
              _responseMessage = "⚠️ Gagal: Server sedang maintenance.");
        } else {
          setState(() {
            _responseMessage = "✅ Berhasil mengirim bug!";
            targetController.clear();
            selectedBugIds.clear();
          });
        }
      }
    } catch (_) {
      setState(
          () => _responseMessage = "❌ Error: Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() => _isSending = false);
    }
  }

  // ── Alert dialog — identik dengan dashboard _handleInvalidSession ─────────
  void _showAlert(String title, String msg) {
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
                color: _accentRed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: _accentRed, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: _accentRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK",
                  style: TextStyle(
                      color: _primaryWhite, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable dialog widgets ────────────────────────────────────────────────

  Widget _dialogListItem({
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: [
                  _accentRed.withOpacity(0.15),
                  _darkRed.withOpacity(0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? _accentRed : _primaryWhite.withOpacity(0.08),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? _accentRed.withOpacity(0.15) : _glassPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? _accentRed : _softGrey,
            size: 18,
          ),
        ),
        title: Text(title,
            style: TextStyle(
                color: _primaryWhite,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(color: _softGrey, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)
            : null,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }

  Widget _smallRedButton(
      {required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: _redGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _accentRed.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(label,
            style: const TextStyle(
                color: _primaryWhite, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _dialogOkButton(
      {required bool enabled, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        gradient: enabled ? _redGradient : null,
        color: enabled ? null : _softGrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextButton(
        onPressed: enabled ? onTap : null,
        child: Text("OK",
            style: TextStyle(
                color: enabled ? _primaryWhite : _softGrey,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── UI Sections ────────────────────────────────────────────────────────────

  // Header panel — identik dengan _buildUsernameCard di dashboard
  Widget _buildHeaderPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2137),
          borderRadius: BorderRadius.circular(20),
          // Shadow 3-layer identik dengan username card di dashboard
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
        child: Row(
          children: [
            // Avatar — sama dengan avatar di username card
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _accentRed.withOpacity(0.4), width: 2),
                gradient: _secondaryGradient,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset('assets/images/logo.png',
                    fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.username.toUpperCase(),
                    style: const TextStyle(
                      color: _primaryWhite,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Role badge — identik dengan username card
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
                        ),
                        child: Text(
                          "ROLE: ${widget.role.toUpperCase()}",
                          style: const TextStyle(
                            color: _primaryWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Expired badge — identik
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accentRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _accentRed.withOpacity(0.4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.all_inclusive_rounded,
                            color: _accentRed, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          "Expired: ${widget.expiredDate}",
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
      ),
    );
  }

  // Video player — identik dengan _buildFullWidthBanner di dashboard
  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 200,
            color: const Color(0xFF0D2137),
            child: const Center(
              child: CircularProgressIndicator(
                  color: _accentRed, strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AspectRatio(
                aspectRatio: _videoController.value.aspectRatio,
                child: Chewie(controller: _chewieController),
              ),
              // Gradient overlay bawah — sama dengan dashboard banner
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
              // Gradient kiri
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
              // LIVE badge kiri atas — identik dengan dashboard
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
              // Label kiri bawah — identik dengan dashboard
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
                      "WhatsApp Module",
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
              // CONNECT badge kanan bawah — identik dengan dashboard
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
    );
  }

  // Mode tab — style feature card dashboard
  Widget _buildModeTab({
    required String mode,
    required String label,
    required String subtitle,
    required Color bgColor,
    required Color shadowColor,
    required List<_BgIconData> bgIcons,
  }) {
    final active = _selectedBugMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedBugMode = mode;
          targetController.clear();
          if (mode == "channel") selectedBugIds.clear();
          _selectedChannel = null;
        }),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 100,
            decoration: BoxDecoration(
              color: active ? bgColor : bgColor.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withOpacity(active ? 0.45 : 0.12),
                  blurRadius: active ? 18 : 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: active
                    ? shadowColor.withOpacity(0.55)
                    : _primaryWhite.withOpacity(0.06),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Bg icons — identik dengan _buildReferenceCard dashboard
                ...bgIcons.map((d) => Positioned(
                      left: d.left,
                      top: d.top,
                      child: Transform.rotate(
                        angle: d.rotation,
                        child: Icon(
                          d.icon,
                          size: d.size,
                          color: Colors.white.withOpacity(
                              active ? d.opacity : d.opacity * 0.5),
                        ),
                      ),
                    )),

                // Gradient gelap bawah
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black
                              .withOpacity(active ? 0.25 : 0.42),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),

                // Teks kiri bawah — identik dengan feature card
                Positioned(
                  left: 12,
                  bottom: 12,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: _primaryWhite
                              .withOpacity(active ? 1.0 : 0.60),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          shadows: const [
                            Shadow(color: Colors.black45, blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _primaryWhite
                              .withOpacity(active ? 0.80 : 0.40),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Active dot kanan atas
                if (active)
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _primaryWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: shadowColor.withOpacity(0.7),
                              blurRadius: 4),
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

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title — identik dengan "Quick Action" di dashboard
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
              "Pilih Mode",
              style: TextStyle(
                color: _primaryWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            _buildModeTab(
              mode: "number",
              label: "Bug Nomor",
              subtitle: "Via Phone",
              bgColor: const Color(0xFF1A8C4E),
              shadowColor: const Color(0xFF25D366),
              bgIcons: [
                _BgIconData(icon: Icons.phone_android_rounded, left: 62, top: -18, size: 80, opacity: 0.22, rotation: -0.26),
                _BgIconData(icon: Icons.dialpad_rounded,        left: 4,  top: -6,  size: 36, opacity: 0.15, rotation: -0.18),
                _BgIconData(icon: Icons.call_rounded,           left: 4,  top: 56,  size: 28, opacity: 0.13, rotation: -0.32),
              ],
            ),
            const SizedBox(width: 10),
            _buildModeTab(
              mode: "group",
              label: "Bug Group",
              subtitle: "Via Link",
              bgColor: const Color(0xFF1565C0),
              shadowColor: const Color(0xFF42A5F5),
              bgIcons: [
                _BgIconData(icon: Icons.group_add_rounded, left: 62, top: -18, size: 80, opacity: 0.22, rotation: -0.26),
                _BgIconData(icon: Icons.people_rounded,    left: 4,  top: -6,  size: 36, opacity: 0.15, rotation: -0.18),
                _BgIconData(icon: Icons.link_rounded,      left: 4,  top: 56,  size: 28, opacity: 0.13, rotation: -0.32),
              ],
            ),
            const SizedBox(width: 10),
            _buildModeTab(
              mode: "channel",
              label: "Bug Channel",
              subtitle: "Broadcast",
              bgColor: const Color(0xFF6A1B9A),
              shadowColor: const Color(0xFFAB47BC),
              bgIcons: [
                _BgIconData(icon: Icons.campaign_rounded,          left: 62, top: -18, size: 80, opacity: 0.22, rotation: -0.26),
                _BgIconData(icon: Icons.wifi_tethering_rounded,    left: 4,  top: -6,  size: 36, opacity: 0.15, rotation: -0.18),
                _BgIconData(icon: Icons.broadcast_on_home_rounded, left: 4,  top: 56,  size: 28, opacity: 0.13, rotation: -0.32),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildModeSelector(),
        const SizedBox(height: 24),

        // Section label — identik dengan dashboard
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
            Text(
              _selectedBugMode == "number"
                  ? "NOMOR TARGET"
                  : _selectedBugMode == "group"
                      ? "LINK GROUP WA"
                      : "PILIH CHANNEL",
              style: const TextStyle(
                color: _softGrey,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Channel picker / Text field
        if (_selectedBugMode == "channel")
          GestureDetector(
            onTap: _showChannelSelectionPopup,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_glassPrimary, _glassSecond],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: _accentRed.withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _selectedChannel == null
                        ? const Text("Klik untuk memilih channel",
                            style:
                                TextStyle(color: _softGrey, fontSize: 14))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedChannel!['title'] ??
                                    'Unknown Channel',
                                style: const TextStyle(
                                    color: _primaryWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text("ID: ${_selectedChannel!['id']}",
                                  style: const TextStyle(
                                      color: _softGrey, fontSize: 11)),
                            ],
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: _redGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _primaryWhite,
                        size: 20),
                  ),
                ],
              ),
            ),
          )
        else
          // Input field — identik dengan _buildGlassButton dashboard
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [_glassPrimary, _glassSecond],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: _primaryWhite.withOpacity(0.1), width: 1),
            ),
            child: TextField(
              controller: targetController,
              style: const TextStyle(color: _primaryWhite, fontSize: 15),
              cursorColor: _accentRed,
              keyboardType: _selectedBugMode == "number"
                  ? TextInputType.phone
                  : TextInputType.url,
              decoration: InputDecoration(
                hintText: _selectedBugMode == "number"
                    ? "Contoh: +62xxxxxxxxxx"
                    : "Contoh: https://chat.whatsapp.com/...",
                hintStyle: TextStyle(
                    color: _softGrey.withOpacity(0.5), fontSize: 13),
                prefixIcon: Container(
                  margin:
                      const EdgeInsets.only(left: 14, right: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: _redGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedBugMode == "number"
                        ? Icons.phone_android_rounded
                        : Icons.link_rounded,
                    color: _primaryWhite,
                    size: 18,
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 56, minHeight: 48),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      const BorderSide(color: _accentRed, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 18, horizontal: 16),
              ),
            ),
          ),

        // Bug selector
        if (_selectedBugMode != "channel") ...[
          const SizedBox(height: 24),
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
                "PILIH BUG",
                style: TextStyle(
                    color: _softGrey,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1.5),
              ),
              const Spacer(),
              if (selectedBugIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: _redGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: _accentRed.withOpacity(0.35),
                          blurRadius: 6)
                    ],
                  ),
                  child: Text("${selectedBugIds.length} dipilih",
                      style: const TextStyle(
                          color: _primaryWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showBugSelectionPopup,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_glassPrimary, _glassSecond],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: _accentRed.withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: selectedBugIds.isEmpty
                        ? const Text("Klik untuk memilih bug",
                            style: TextStyle(
                                color: _softGrey, fontSize: 14))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children:
                                selectedBugIds.map((bugId) {
                              final bug = widget.listBug.firstWhere(
                                  (b) => b['bug_id'] == bugId,
                                  orElse: () =>
                                      {'bug_name': 'Unknown'});
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    _accentRed.withOpacity(0.2),
                                    _darkRed.withOpacity(0.1)
                                  ]),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  border: Border.all(
                                      color:
                                          _accentRed.withOpacity(0.4)),
                                ),
                                child: Text(bug['bug_name'],
                                    style: const TextStyle(
                                        color: _softRed,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: _redGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _primaryWhite,
                        size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Send button — identik dengan _buildRedButton di dashboard + pulse
  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: _redGradient,
            boxShadow: [
              BoxShadow(
                color: _accentRed
                    .withOpacity(0.35 + _pulseController.value * 0.15),
                blurRadius: 14 + _pulseController.value * 10,
                spreadRadius: _pulseController.value * 1.5,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isSending ? null : _sendBug,
              borderRadius: BorderRadius.circular(20),
              splashColor: _primaryWhite.withOpacity(0.12),
              child: Center(
                child: _isSending
                    ? const SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                            color: _primaryWhite, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch_rounded,
                              color: _primaryWhite, size: 20),
                          SizedBox(width: 10),
                          Text(
                            "SEND BUG ATTACK",
                            style: TextStyle(
                              color: _primaryWhite,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();

    final isSuccess = _responseMessage!.startsWith('✅');
    final isError   = _responseMessage!.startsWith('❌');

    final Color bg = isSuccess
        ? Colors.green.withOpacity(0.12)
        : isError
            ? _accentRed.withOpacity(0.12)
            : _accentRed.withOpacity(0.1);
    final Color border = isSuccess
        ? Colors.greenAccent
        : isError
            ? _accentRed
            : _softRed;
    final Color text    = isSuccess ? Colors.greenAccent : border;
    final IconData icon = isSuccess
        ? Icons.check_circle_outline_rounded
        : isError
            ? Icons.error_outline_rounded
            : Icons.info_outline_rounded;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: border.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(color: border.withOpacity(0.1), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: text, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _responseMessage!,
                style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Scaffold ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // RadialGradient UNGU — identik dengan dashboard body
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderPanel(),
                _buildVideoPlayer(),
                _buildInputPanel(),
                const SizedBox(height: 28),
                _buildSendButton(),
                _buildResponseMessage(),
                const SizedBox(height: 24),
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

    // Accent lines UNGU 0xFF7B1FA2 — identik dengan dashboard
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
