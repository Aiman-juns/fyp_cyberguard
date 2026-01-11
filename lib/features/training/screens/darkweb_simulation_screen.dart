import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class DarkWebSimulationScreen extends StatefulWidget {
  const DarkWebSimulationScreen({Key? key}) : super(key: key);

  @override
  State<DarkWebSimulationScreen> createState() =>
      _DarkWebSimulationScreenState();
}

class _DarkWebSimulationScreenState extends State<DarkWebSimulationScreen>
    with TickerProviderStateMixin {
  int _phase = 0; // 0: Warning, 1: Loading, 2: Captcha, 3: Marketplace, 4: Hacked
  String _loadingText = 'Initializing Tor...';
  bool _isHacked = false;
  bool _canGoBack = false;
  bool _acceptedWarning = false;
  String _typedUrl = '';
  final String _targetUrl = 'darkmarket3xzy2onion';
  bool _showCursor = true;
  Timer? _cursorTimer;
  Timer? _flashTimer;
  bool _flashRed = false;
  List<String> _terminalLines = [];
  final ScrollController _scrollController = ScrollController();
  int _captchaAnswer = 0;
  final TextEditingController _captchaController = TextEditingController();
  final AudioPlayer _backgroundAudioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startCursorBlink();
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _flashTimer?.cancel();
    _scrollController.dispose();
    _captchaController.dispose();
    _backgroundAudioPlayer.dispose();
    super.dispose();
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() => _showCursor = !_showCursor);
      }
    });
  }

  // Phase 0: Initial Warning
  void _startWarning() {
    setState(() => _phase = 0);
  }

  void _acceptWarningAndProceed() {
    setState(() {
      _acceptedWarning = true;
      _phase = 1;
    });
    _startBackgroundMusic(); // Start music when entering simulation
    _startPhase1Connection();
  }

  // Phase 1: Connection Simulation with Terminal-like output
  void _startPhase1Connection() async {
    _addTerminalLine('[TOR] Starting Tor Browser...');
    await Future.delayed(const Duration(milliseconds: 800));
    
    _addTerminalLine('[TOR] Connecting to Tor network...');
    await Future.delayed(const Duration(milliseconds: 600));
    
    _addTerminalLine('[RELAY] Found 3 entry guards');
    await Future.delayed(const Duration(milliseconds: 500));
    
    _addTerminalLine('[RELAY] Circuit established: USA > Germany > Netherlands');
    await Future.delayed(const Duration(milliseconds: 700));
    
    _addTerminalLine('[TOR] Establishing encrypted connection...');
    await Future.delayed(const Duration(milliseconds: 600));
    
    _addTerminalLine('[HANDSHAKE] Key exchange successful');
    await Future.delayed(const Duration(milliseconds: 500));
    
    _addTerminalLine('[TOR] Connected to Tor network');
    _addTerminalLine('[WARNING] Your activity is NOT fully anonymous');
    await Future.delayed(const Duration(milliseconds: 800));
    
    _addTerminalLine('[BROWSER] Loading .onion directory...');
    await Future.delayed(const Duration(milliseconds: 1000));
    
    _addTerminalLine('[SUCCESS] Ready to browse hidden services');
    await Future.delayed(const Duration(milliseconds: 500));

    // Auto-type the dark web URL
    _startTypingUrl();
  }

  void _addTerminalLine(String line) {
    if (mounted) {
      setState(() => _terminalLines.add(line));
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _startTypingUrl() async {
    await Future.delayed(const Duration(milliseconds: 800));
    for (int i = 0; i < _targetUrl.length; i++) {
      if (mounted && _phase == 1) {
        setState(() => _typedUrl += _targetUrl[i]);
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      _addTerminalLine('[BROWSER] Navigating to ${_typedUrl}.onion...');
      await Future.delayed(const Duration(milliseconds: 1200));
      _addTerminalLine('[SECURITY] WARNING: Unverified hidden service');
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Generate random captcha
      final random1 = (DateTime.now().millisecondsSinceEpoch % 10) + 1;
      final random2 = (DateTime.now().second % 10) + 1;
      _captchaAnswer = random1 + random2;
      
      setState(() => _phase = 2);
    }
  }

  // Phase 3: The Trap
  void _triggerHack() async {
    HapticFeedback.heavyImpact();
    
    setState(() {
      _phase = 4;
      _isHacked = true;
    });

    // Start red/black flashing
    _flashTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted && _phase == 4) {
        setState(() => _flashRed = !_flashRed);
      }
    });

    // Simulate freeze for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    
    _flashTimer?.cancel();
    
    if (mounted) {
      setState(() {
        _flashRed = true;
        _canGoBack = true;
      });
    }
  }
  
  Future<void> _startBackgroundMusic() async {
    debugPrint('🎵 Attempting to start background music...');
    try {
      await _backgroundAudioPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _backgroundAudioPlayer.setReleaseMode(ReleaseMode.loop);
      await _backgroundAudioPlayer.setVolume(0.5);
      
      // Try to play the audio file
      debugPrint('🎵 Loading: sounds/dark_web_bg.mp3');
      final source = AssetSource('sounds/dark_web_bg.mp3');
      await _backgroundAudioPlayer.play(source);
      
      debugPrint('🎵 Background music started successfully!');
    } catch (e) {
      debugPrint('❌ Error playing background music: $e');
      // If MP3 fails, it might be a web compatibility issue
      // The music will just not play, but won't crash the app
    }
  }

  Future<void> _stopBackgroundMusic() async {
    debugPrint('🎵 Stopping background music...');
    try {
      await _backgroundAudioPlayer.stop();
      debugPrint('🎵 Background music stopped');
    } catch (e) {
      debugPrint('❌ Error stopping background music: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 0) {
      return _buildPhase0Warning();
    } else if (_phase == 1) {
      return _buildPhase1Terminal();
    } else if (_phase == 2) {
      return _buildPhase2Captcha();
    } else if (_phase == 3) {
      return _buildPhase3Marketplace();
    } else {
      return _buildPhase4Hacked();
    }
  }

  // Phase 0: Warning Screen
  Widget _buildPhase0Warning() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.red),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 3),
                  color: Colors.red.withOpacity(0.1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '⚠️ WARNING ⚠️',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 20,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'YOU ARE ABOUT TO ENTER A SIMULATED DARK WEB ENVIRONMENT',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• This is an EDUCATIONAL simulation\n'
                      '• Real dark web contains ILLEGAL content\n'
                      '• Accessing real dark web is DANGEROUS\n'
                      '• Your data can be STOLEN\n'
                      '• You may witness HARMFUL material\n'
                      '• Law enforcement MONITORS dark web',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: Colors.greenAccent,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'NEVER ACCESS THE REAL DARK WEB',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _acceptWarningAndProceed,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 2),
                      color: Colors.black,
                    ),
                    child: const Text(
                      '[I UNDERSTAND - PROCEED TO SIMULATION]',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Phase 1: Terminal-style Connection
  Widget _buildPhase1Terminal() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fake browser header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                border: const Border(
                  bottom: BorderSide(color: Colors.green, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _typedUrl.isEmpty ? 'about:tor' : '$_typedUrl.onion',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              color: Colors.greenAccent,
                            ),
                          ),
                          if (_showCursor && _typedUrl.isNotEmpty)
                            Container(
                              width: 8,
                              height: 14,
                              color: Colors.greenAccent,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Terminal output
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _terminalLines.length,
                itemBuilder: (context, index) {
                  final line = _terminalLines[index];
                  Color color = Colors.greenAccent;
                  if (line.contains('[WARNING]') || line.contains('[SECURITY]')) {
                    color = Colors.red;
                  } else if (line.contains('[SUCCESS]')) {
                    color = Colors.green;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        color: color,
                        height: 1.4,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Phase 2: Captcha Verification
  Widget _buildPhase2Captcha() {
    final random1 = (_captchaAnswer - (DateTime.now().second % 10)) > 0 
        ? (_captchaAnswer - (DateTime.now().second % 10))
        : _captchaAnswer - 1;
    final random2 = _captchaAnswer - random1;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  color: Colors.red.withOpacity(0.1),
                ),
                child: const Text(
                  'SECURITY VERIFICATION REQUIRED',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'To access this hidden service, prove you are human:',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: Colors.greenAccent,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Ugly captcha
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  color: Colors.grey.shade900,
                ),
                child: Column(
                  children: [
                    const Text(
                      'CAPTCHA:',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Text(
                        '$random1  +  $random2  = ?',
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 24,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 1),
                        color: Colors.black,
                      ),
                      child: TextField(
                        controller: _captchaController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 16,
                          color: Colors.greenAccent,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter answer...',
                          hintStyle: TextStyle(
                            fontFamily: 'Courier',
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    if (_captchaController.text == _captchaAnswer.toString()) {
                      HapticFeedback.mediumImpact();
                      setState(() => _phase = 3);
                    } else {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'INCORRECT - TRY AGAIN',
                            style: TextStyle(fontFamily: 'Courier'),
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 1),
                        ),
                      );
                      _captchaController.clear();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 2),
                      color: Colors.black,
                    ),
                    child: const Text(
                      '[SUBMIT]',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 14,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  _stopBackgroundMusic();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: const Text(
                    '[EXIT]',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Phase 2: The "Marketplace"
  Widget _buildPhase3Marketplace() {
    final items = [
      {
        'id': '883',
        'name': 'Item #883 [REDACTED]',
        'desc': 'Data dump from hospital. No refunds.',
        'price': '0.0032 BTC',
        'seller': 'Anonymous',
        'rating': '★★★☆☆',
      },
      {
        'id': '442',
        'name': 'Mystery Box - Tier 1',
        'desc': 'Contains random compromised accounts.',
        'price': '0.0015 BTC',
        'seller': 'DarkSeller92',
        'rating': '★★★★☆',
      },
      {
        'id': '751',
        'name': 'User Logs (Unfiltered)',
        'desc': 'Raw session cookies from 2024. Buyer beware.',
        'price': '0.0050 BTC',
        'seller': 'CookieMonster',
        'rating': '★★☆☆☆',
      },
      {
        'id': '293',
        'name': 'Database Access [LIMITED]',
        'desc': 'Corporate credentials. Expires in 48hrs.',
        'price': '0.0120 BTC',
        'seller': 'DBHunter',
        'rating': '★★★★★',
      },
      {
        'id': '619',
        'name': '[CLASSIFIED] Package',
        'desc': 'Identity bundle with credit history. Clean record.',
        'price': '0.0200 BTC',
        'seller': 'GhostID',
        'rating': '★★★★☆',
      },
      {
        'id': '104',
        'name': 'Phishing Kit v2.8',
        'desc': 'Pre-configured templates. Instant deployment.',
        'price': '0.0080 BTC',
        'seller': 'PhishMaster',
        'rating': '★★★☆☆',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Fake browser header with .onion URL
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                border: const Border(
                  bottom: BorderSide(color: Colors.green, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.red, size: 18),
                    onPressed: () {
                      _stopBackgroundMusic();
                      Navigator.pop(context);
                    },
                  ),
                  const Icon(Icons.lock, color: Colors.green, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Text(
                        '$_targetUrl.onion',
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Marketplace header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                color: Colors.red.withOpacity(0.05),
              ),
              child: Column(
                children: [
                  const Text(
                    'UNVERIFIED MARKET - v3.0',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '⚠️ NO ESCROW | NO REFUNDS | NO SUPPORT ⚠️',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      color: Colors.yellow,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'ACTIVE USERS: 1,247',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 8,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'LISTINGS: 8,392',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 8,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Items list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['name']!,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 13,
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.yellow, width: 1),
                              ),
                              child: Text(
                                item['price']!,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10,
                                  color: Colors.yellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['desc']!,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11,
                            color: Colors.green,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'ID: ${item['id']}',
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Seller: ${item['seller']}',
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item['rating']!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.yellow,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _triggerHack,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.red, width: 1),
                                    color: Colors.black,
                                  ),
                                  child: const Text(
                                    '[EXECUTE CONTRACT]',
                                    style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 11,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _triggerHack,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey, width: 1),
                                ),
                                child: const Text(
                                  '[VIEW]',
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom warning bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 1),
                color: Colors.red.withOpacity(0.1),
              ),
              child: const Text(
                '⚠️ WARNING: All transactions are irreversible. Use at your own risk.',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Phase 3: The Hack/Trap
  Widget _buildPhase4Hacked() {
    return Scaffold(
      backgroundColor: _flashRed ? Colors.red : Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.warning,
                size: 100,
                color: _flashRed ? Colors.black : Colors.red,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _flashRed ? Colors.black : Colors.red,
                    width: 3,
                  ),
                  color: _flashRed ? Colors.red : Colors.black,
                ),
                child: Column(
                  children: [
                    Text(
                      '⚠️ CRITICAL ERROR ⚠️',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 22,
                        color: _flashRed ? Colors.black : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'MALICIOUS SCRIPT EXECUTED',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 16,
                        color: _flashRed ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  color: Colors.black,
                ),
                child: const Text(
                  'SYSTEM COMPROMISED:\n\n'
                  '✗ Session cookies: STOLEN\n'
                  '✗ Browser fingerprint: CAPTURED\n'
                  '✗ IP address: LOGGED\n'
                  '✗ Keystroke logger: INSTALLED\n'
                  '✗ Wallet addresses: MONITORED\n'
                  '✗ Personal data: EXFILTRATED\n\n'
                  'In a REAL scenario:\n'
                  '• Your accounts would be hijacked\n'
                  '• Your identity would be stolen\n'
                  '• Your money would be drained\n'
                  '• Your device would be infected\n'
                  '• Law enforcement might investigate YOU',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    color: Colors.greenAccent,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.yellow, width: 2),
                  color: Colors.yellow.withOpacity(0.1),
                ),
                child: const Text(
                  '📚 LESSON LEARNED:\n\n'
                  'The Dark Web is NOT anonymous.\n'
                  'Every click can be tracked.\n'
                  'Never trust .onion sites.\n'
                  'NEVER visit the real Dark Web.',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    color: Colors.yellow,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              if (_canGoBack)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    color: Colors.black,
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '[RETURN TO SAFETY]',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 14,
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: const [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'System frozen...',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
