import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

class BugSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const BugSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<BugSenderPage> createState() => _BugSenderPageState();
}

class _BugSenderPageState extends State<BugSenderPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> senderList = [];
  bool isLoading   = false;
  bool isRefreshing = false;
  String? errorMessage;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchSenders();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Network ────────────────────────────────────────────────────────────────

  Future<void> _fetchSenders() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/mySender?key=${widget.sessionKey}"),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          setState(() => senderList = data["connections"] ?? []);
        } else {
          setState(() => errorMessage = data["message"] ?? "Failed to fetch senders");
        }
      } else {
        setState(() => errorMessage = "Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => errorMessage = "Connection failed: $e");
    } finally {
      setState(() { isLoading = false; isRefreshing = false; });
    }
  }

  Future<void> _refreshSenders() async {
    setState(() => isRefreshing = true);
    await _fetchSenders();
    _showSnackBar("List refreshed!", isError: false);
  }

  Future<void> _addSender(String number) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/getPairing?key=${widget.sessionKey}&number=$number"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          _showPairingCodeDialog(number, data['pairingCode']);
          _showSnackBar("Pairing code generated!", isError: false);
        } else {
          _showSnackBar(data['message'] ?? "Failed to generate pairing code", isError: true);
        }
      } else {
        _showSnackBar("Server error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection failed: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
      _fetchSenders();
    }
  }

  Future<void> _deleteSender(String senderId) async {
    final confirmed = await showDialog<bool>(
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
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 22),
            ),
            const SizedBox(width: 12),
            const Text("Confirm Delete",
                style: TextStyle(
                    color: _primaryWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this sender? This action cannot be undone.",
          style: TextStyle(color: _softGrey, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL", style: TextStyle(color: _softGrey)),
          ),
          Container(
            decoration: BoxDecoration(
              color: _accentRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accentRed.withOpacity(0.5)),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("DELETE",
                  style: TextStyle(
                      color: _softRed, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => isLoading = true);
      try {
        final response = await http.delete(
          Uri.parse(
              "$baseUrl/deleteSender?key=${widget.sessionKey}&id=$senderId"),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["valid"] == true) {
            _showSnackBar("Sender deleted successfully!", isError: false);
            _fetchSenders();
          } else {
            _showSnackBar(data["message"] ?? "Failed to delete sender",
                isError: true);
          }
        } else {
          _showSnackBar("Server error: ${response.statusCode}", isError: true);
        }
      } catch (e) {
        _showSnackBar("Connection failed: $e", isError: true);
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showAddSenderDialog() {
    final phoneController = TextEditingController();

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
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: _redGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: _accentRed.withOpacity(0.3), blurRadius: 8)],
              ),
              child: const Icon(Icons.add_rounded, color: _primaryWhite, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Add New Sender",
                style: TextStyle(
                    color: _primaryWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [_glassPrimary, _glassSecond],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryWhite.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: _primaryWhite, fontSize: 15),
            cursorColor: _accentRed,
            decoration: InputDecoration(
              labelText: "Phone Number",
              labelStyle: const TextStyle(color: _softGrey, fontSize: 13),
              hintText: "62xxx",
              hintStyle: TextStyle(color: _softGrey.withOpacity(0.4)),
              prefixIcon: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _redGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_rounded,
                    color: _primaryWhite, size: 16),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 48, minHeight: 40),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: _softGrey)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: _redGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: _accentRed.withOpacity(0.3), blurRadius: 8)],
            ),
            child: TextButton(
              onPressed: () async {
                final number = phoneController.text.trim();
                if (number.isEmpty) {
                  _showSnackBar("Please enter phone number", isError: true);
                  return;
                }
                Navigator.pop(context);
                await _addSender(number);
              },
              child: const Text("ADD SENDER",
                  style: TextStyle(
                      color: _primaryWhite, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPairingCodeDialog(String number, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: _accentRed.withOpacity(0.4), width: 1.5),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: _redGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _accentRed.withOpacity(0.4), blurRadius: 20)
                ],
              ),
              child: const Icon(Icons.qr_code_2_rounded,
                  color: _primaryWhite, size: 36),
            ),
            const SizedBox(height: 14),
            ShaderMask(
              shaderCallback: (b) => _redGradient.createShader(
                  Rect.fromLTWH(0, 0, b.width, b.height)),
              child: const Text(
                "Pairing Required",
                style: TextStyle(
                    color: _primaryWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Number: $number",
                style: const TextStyle(color: _softGrey, fontSize: 13)),
            const SizedBox(height: 20),

            // Pairing code box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accentRed, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: _accentRed.withOpacity(0.4),
                      blurRadius: 18,
                      spreadRadius: 1)
                ],
              ),
              child: Text(
                code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _softRed,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  fontFamily: 'Courier',
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Copy button
            GestureDetector(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: code));
                _showSnackBar("Code copied to clipboard!", isError: false);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_glassPrimary, _glassSecond],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _accentRed.withOpacity(0.4), width: 1),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy_rounded, color: _accentRed, size: 18),
                    SizedBox(width: 10),
                    Text("COPY CODE",
                        style: TextStyle(
                            color: _accentRed,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("CLOSE", style: TextStyle(color: _softGrey)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: _redGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                _fetchSenders();
              },
              child: const Text("REFRESH LIST",
                  style: TextStyle(
                      color: _primaryWhite, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Snackbar ───────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                color: _primaryWhite, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? _softRed : _accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Card ───────────────────────────────────────────────────────────────────

  Widget _buildSenderCard(Map<String, dynamic> sender, int index) {
    final name = sender['sessionName'] ?? 'WhatsApp Sender';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_glassPrimary, _glassSecond],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _primaryWhite.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: _accentRed.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _redGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: _accentRed.withOpacity(0.35), blurRadius: 10)
                    ],
                  ),
                  child: const Icon(Icons.phone_android_rounded,
                      color: _primaryWhite, size: 22),
                ),
                const SizedBox(width: 16),

                // Name
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: _primaryWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.35)),
                  ),
                  child: const Text(
                    "CONNECTED",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _refreshSenders,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [_glassPrimary, _glassSecond],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _primaryWhite.withOpacity(0.1)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded,
                              color: _softGrey, size: 16),
                          SizedBox(width: 8),
                          Text("REFRESH",
                              style: TextStyle(
                                  color: _softGrey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _deleteSender(sender['sessionName']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _accentRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _accentRed.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              color: _softRed, size: 16),
                          SizedBox(width: 8),
                          Text("DELETE",
                              style: TextStyle(
                                  color: _softRed,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty / Error States ───────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [
                      _accentRed.withOpacity(0.15),
                      _darkRed.withOpacity(0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                shape: BoxShape.circle,
                border: Border.all(color: _accentRed.withOpacity(0.3)),
              ),
              child: const Icon(Icons.phone_iphone_rounded,
                  color: _accentRed, size: 70),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (b) => _redGradient.createShader(
                  Rect.fromLTWH(0, 0, b.width, b.height)),
              child: const Text(
                "No Senders Found",
                style: TextStyle(
                    color: _primaryWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Add your first WhatsApp sender to get started",
              style: TextStyle(color: _softGrey, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: _showAddSenderDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: _redGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: _accentRed.withOpacity(0.4), blurRadius: 18)
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: _primaryWhite),
                    SizedBox(width: 10),
                    Text("ADD FIRST SENDER",
                        style: TextStyle(
                            color: _primaryWhite,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _accentRed.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: _accentRed.withOpacity(0.3)),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: _accentRed, size: 60),
            ),
            const SizedBox(height: 24),
            const Text("Failed to Load",
                style: TextStyle(
                    color: _primaryWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Unknown error occurred",
              style: const TextStyle(
                  color: _softGrey, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: _fetchSenders,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: _redGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: _accentRed.withOpacity(0.4), blurRadius: 18)
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: _primaryWhite),
                    SizedBox(width: 10),
                    Text("TRY AGAIN",
                        style: TextStyle(
                            color: _primaryWhite,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ],
                ),
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
            border: Border.all(color: _primaryWhite.withOpacity(0.08)),
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
            "Manage Bug Sender",
            style: TextStyle(
              color: _primaryWhite,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _glassPrimary,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: _primaryWhite.withOpacity(0.08)),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: _accentRed, size: 20),
              onPressed: isLoading ? null : _refreshSenders,
            ),
          ),
        ],
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
            child: isLoading && senderList.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _accentRed, strokeWidth: 2.5))
                : errorMessage != null && senderList.isEmpty
                    ? _buildErrorState()
                    : senderList.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: _accentRed,
                            backgroundColor: _cardBg,
                            onRefresh: _refreshSenders,
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                  top: 12, bottom: 100),
                              itemCount: senderList.length,
                              itemBuilder: (_, i) => _buildSenderCard(
                                Map<String, dynamic>.from(senderList[i]),
                                i,
                              ),
                            ),
                          ),
          ),
        ),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: _redGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _accentRed.withOpacity(0.45),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddSenderDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: _primaryWhite),
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
