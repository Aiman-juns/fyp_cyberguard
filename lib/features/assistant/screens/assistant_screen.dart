import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/ai_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({Key? key}) : super(key: key);

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [const Color(0xFFF8F9FA), const Color(0xFFE9ECEF)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Header
          Container(
            padding: const EdgeInsets.all(20.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.security_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Assistant',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'AI-powered protection tools',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar - Pill Style
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return Row(
                  children: [
                    Expanded(
                      child: _PillTab(
                        icon: Icons.link,
                        label: 'URL Scanner',
                        isSelected: _tabController.index == 0,
                        onTap: () => _tabController.animateTo(0),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _PillTab(
                        icon: Icons.message,
                        label: 'Smish Detector',
                        isSelected: _tabController.index == 1,
                        onTap: () => _tabController.animateTo(1),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [UrlScannerTab(), SmishDetectorTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// URL Scanner Tab (existing VirusTotal logic)
class UrlScannerTab extends StatefulWidget {
  const UrlScannerTab({Key? key}) : super(key: key);

  @override
  State<UrlScannerTab> createState() => _UrlScannerTabState();
}

class _UrlScannerTabState extends State<UrlScannerTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final _urlController = TextEditingController();
  bool _isChecking = false;
  String? _resultStatus;
  String? _resultMessage;
  Map<String, dynamic>? _scanStats;
  List<Map<String, String>>? _threatDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late final String _apiKey;

  @override
  bool get wantKeepAlive => true;

  String _encodeUrlToId(String url) {
    String encodedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      encodedUrl = 'https://$url';
    }
    final bytes = utf8.encode(encodedUrl);
    final encoded = base64Url.encode(bytes).toString();
    return encoded.replaceAll('=', '');
  }

  List<Map<String, String>> _extractThreatDetails(
    Map<String, dynamic> analysisResults,
  ) {
    List<Map<String, String>> threats = [];
    analysisResults.forEach((vendor, result) {
      if (result is Map<String, dynamic>) {
        final category = result['category'] as String?;
        final resultText = result['result'] as String?;
        if (category == 'malicious' || category == 'suspicious') {
          threats.add({
            'vendor': vendor,
            'category': category ?? 'unknown',
            'result': resultText ?? 'Flagged as potentially harmful',
          });
        }
      }
    });
    return threats;
  }

  Future<void> _checkUrl() async {
    final inputUrl = _urlController.text.trim();

    if (inputUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a URL')));
      return;
    }

    setState(() {
      _isChecking = true;
      _resultStatus = null;
      _resultMessage = null;
      _scanStats = null;
      _threatDetails = null;
    });

    try {
      // Encode URL for VirusTotal API
      final urlId = _encodeUrlToId(inputUrl);
      final apiUrl = Uri.parse('https://www.virustotal.com/api/v3/urls/$urlId');

      print('Checking URL: $inputUrl');
      print('Encoded ID: $urlId');

      final response = await http
          .get(apiUrl, headers: {'x-apikey': _apiKey})
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      print('Response status: ${response.statusCode}');
      print(
        'Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final attributes = data['data']?['attributes'] as Map<String, dynamic>?;
        final lastAnalysisStats =
            attributes?['last_analysis_stats'] as Map<String, dynamic>?;
        final lastAnalysisResults =
            attributes?['last_analysis_results'] as Map<String, dynamic>?;

        if (lastAnalysisStats != null) {
          final malicious = (lastAnalysisStats['malicious'] ?? 0) as int;
          final suspicious = (lastAnalysisStats['suspicious'] ?? 0) as int;
          final harmless = (lastAnalysisStats['harmless'] ?? 0) as int;

          setState(() {
            _scanStats = lastAnalysisStats;

            if (malicious + suspicious > 0) {
              _resultStatus = 'danger';
              _resultMessage =
                  '⚠️ Warning! ${malicious + suspicious} security vendor(s) flagged this site as dangerous. Do not visit.';
              if (lastAnalysisResults != null) {
                _threatDetails = _extractThreatDetails(lastAnalysisResults);
              }
            } else if (harmless > 0) {
              _resultStatus = 'safe';
              _resultMessage =
                  '✅ Good news! This website appears safe to visit according to our security scan.';
            } else {
              _resultStatus = 'unknown';
              _resultMessage =
                  '❓ This is a new or unknown link. We have no security data for it yet. Be careful.';
            }
          });
          _animationController.forward(from: 0);
        } else {
          setState(() {
            _resultStatus = 'unknown';
            _resultMessage =
                '❓ This is a new or unknown link. We have no security data for it yet. Be careful.';
          });
          _animationController.forward(from: 0);
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _resultStatus = 'unknown';
          _resultMessage =
              '❓ This is a new or unknown link. We have no security data for it yet. Be careful.';
        });
        _animationController.forward(from: 0);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      print('Error checking URL: $e');

      setState(() {
        _resultStatus = 'unknown';
        _resultMessage = '⚠️ Unable to check this URL. Error: ${e.toString()}';
      });
      _animationController.forward(from: 0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Load VirusTotal API key from .env
    final virusTotalKey = dotenv.env['VIRUSTOTAL_KEY'];
    if (virusTotalKey == null || virusTotalKey.isEmpty) {
      throw Exception(
        'VIRUSTOTAL_KEY not found in .env file!\n'
        'Add VIRUSTOTAL_KEY=your_api_key to your .env file',
      );
    }
    _apiKey = virusTotalKey;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFAFAFA), const Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Check if a URL is safe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.science,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  tooltip: 'Test Data',
                  onSelected: (String url) {
                    _urlController.text = url;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Test URL loaded: ${url.length > 40 ? url.substring(0, 40) + '...' : url}',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          child: Text(
                            'Safe URLs',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          enabled: false,
                        ),
                        const PopupMenuItem<String>(
                          value: 'https://www.youtube.com/',
                          child: Text('YouTube'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'https://myguru.upsi.edu.my/users/auth/login',
                          child: Text('MyGuru UPSI'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'https://www.sara.gov.my/',
                          child: Text('SARA Malaysia'),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          child: Text(
                            'Unsafe URLs',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                          enabled: false,
                        ),
                        const PopupMenuItem<String>(
                          value: 'https://ww4.site/bflix/',
                          child: Text(
                            'Suspicious Streaming Site',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'https://pencurivids.blogspot.com/',
                          child: Text(
                            'Suspicious Blog Site',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Instructions Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.blue.shade200, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How to use this tool:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Check suspicious links before clicking them\n'
                    '• Verify links from emails, SMS, or social media\n'
                    '• Look for misspelled domains or unusual URLs\n'
                    '• Never click links marked as dangerous',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Input Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'Enter URL (e.g., https://example.com)',
                      filled: true,
                      fillColor: isDark
                          ? Colors.grey.shade800.withOpacity(0.5)
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.link,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _checkUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2,
                      ),
                      child: _isChecking
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Scanning...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.search),
                                SizedBox(width: 8),
                                Text(
                                  'Check URL',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Results section
            if (_resultStatus != null) ...[
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _resultStatus == 'danger'
                          ? Colors.red.withOpacity(0.1)
                          : _resultStatus == 'safe'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _resultStatus == 'danger'
                            ? Colors.red
                            : _resultStatus == 'safe'
                            ? Colors.green
                            : Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _resultStatus == 'danger'
                              ? Icons.dangerous
                              : _resultStatus == 'safe'
                              ? Icons.check_circle
                              : Icons.help,
                          color: _resultStatus == 'danger'
                              ? Colors.red
                              : _resultStatus == 'safe'
                              ? Colors.green
                              : Colors.orange,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _resultStatus == 'danger'
                              ? 'DANGEROUS!'
                              : _resultStatus == 'safe'
                              ? 'SAFE'
                              : 'UNKNOWN',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _resultStatus == 'danger'
                                ? Colors.red
                                : _resultStatus == 'safe'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _resultMessage ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                        ),
                        if (_scanStats != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Security Scan Results',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildStatRow(
                                  'Malicious',
                                  _scanStats!['malicious'] ?? 0,
                                  Colors.red,
                                ),
                                _buildStatRow(
                                  'Suspicious',
                                  _scanStats!['suspicious'] ?? 0,
                                  Colors.orange,
                                ),
                                _buildStatRow(
                                  'Harmless',
                                  _scanStats!['harmless'] ?? 0,
                                  Colors.green,
                                ),
                                _buildStatRow(
                                  'Undetected',
                                  _scanStats!['undetected'] ?? 0,
                                  Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_threatDetails != null &&
                            _threatDetails!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Threat Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ..._threatDetails!.take(5).map((threat) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.shield,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${threat['vendor']}: ${threat['result']}',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                if (_threatDetails!.length > 5)
                                  Text(
                                    '+ ${_threatDetails!.length - 5} more threats detected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            count.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

// New Smish Detector Tab
class SmishDetectorTab extends StatefulWidget {
  const SmishDetectorTab({Key? key}) : super(key: key);

  @override
  State<SmishDetectorTab> createState() => _SmishDetectorTabState();
}

class _SmishDetectorTabState extends State<SmishDetectorTab>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  bool _isAnalyzing = false;
  SmishAnalysisResult? _result;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final AiService _aiService = AiService();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Image selected! Click Analyze to scan.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _analyzeMessage() async {
    // Allow analysis if there's either text or an image
    if (_messageController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message or upload an image to analyze'),
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      String messageToAnalyze = _messageController.text;

      // If there's an image but no text, indicate image analysis
      if (_selectedImage != null && messageToAnalyze.trim().isEmpty) {
        messageToAnalyze = '[Screenshot uploaded for analysis]';
      }

      // If there's an image, add note about it
      if (_selectedImage != null) {
        messageToAnalyze +=
            '\n\n[Note: Screenshot/image uploaded - analyzing text content from image]';
      }

      final result = await _aiService.analyzeSmishing(messageToAnalyze);

      if (!mounted) return;

      setState(() {
        _result = result;
      });

      _animationController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error analyzing message: $e')));
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFAFAFA), const Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8.0),
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI-Powered SMS Analyzer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.science,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  tooltip: 'Test Data',
                  onSelected: (String message) {
                    _messageController.text = message;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test message loaded'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      child: Text(
                        'Safe Messages',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                      enabled: false,
                    ),
                    const PopupMenuItem<String>(
                      value:
                          'Hi! Just checking in to see how you\'re doing. Let me know when you\'re free to catch up!',
                      child: Text('Casual Friend Message'),
                    ),
                    const PopupMenuItem<String>(
                      value:
                          'Your appointment at the clinic has been confirmed for tomorrow at 3 PM. Please arrive 10 minutes early. Reply CONFIRM to acknowledge.',
                      child: Text('Appointment Reminder'),
                    ),
                    const PopupMenuItem<String>(
                      value:
                          'Dear customer, your order #12345 has been shipped and will arrive in 2-3 business days. Track your order at our official website.',
                      child: Text('Delivery Notification'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      child: Text(
                        'Scam Messages',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                      enabled: false,
                    ),
                    const PopupMenuItem<String>(
                      value:
                          'URGENT! Your bank account has been suspended due to suspicious activity. Click this link immediately to verify your identity: bit.ly/verify123 or your account will be closed in 24 hours!',
                      child: Text(
                        'Fake Bank Alert',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value:
                          'CONGRATULATIONS! You\'ve won RM50,000 in our lucky draw! To claim your prize, send us your IC number, bank account details, and pay RM500 processing fee to this number.',
                      child: Text(
                        'Prize Scam',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value:
                          'Hi, this is LHDN. You have an outstanding tax payment of RM3,500. Pay now via this link or face legal action: shorturl.at/tax123. Reply with your details urgently!',
                      child: Text(
                        'Tax Fraud',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              'Paste a suspicious SMS message below to detect phishing attempts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12.0),

            // Instructions Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.purple.shade200, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        size: 20,
                        color: Colors.purple.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What to check:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Urgency tactics (\"Act now!\", \"Limited time\")\n'
                    '• Requests for personal/financial information\n'
                    '• Suspicious links or phone numbers\n'
                    '• Claims of account problems or prizes',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.purple.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Input Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF9333EA).withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA).withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (_selectedImage != null) ...[
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.network(
                                    _selectedImage!.path,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    _selectedImage!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _messageController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: _selectedImage != null
                          ? 'Image uploaded! You can add text here or click Analyze to check the image...'
                          : 'Paste your SMS message here or upload a screenshot...\n\nExample: "URGENT! Your bank account has been suspended. Click here to verify: bit.ly/xyz123"',
                      filled: true,
                      fillColor: isDark
                          ? Colors.grey.shade800.withOpacity(0.5)
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 100.0),
                        child: Icon(
                          Icons.message,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16.0),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Image'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isAnalyzing ? null : _analyzeMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2,
                      ),
                      child: _isAnalyzing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Analyzing with AI...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.psychology),
                                SizedBox(width: 8),
                                Text(
                                  'Analyze Message',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Results
            if (_result != null) ...[
              const SizedBox(height: 24.0),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _result!.isScam
                              ? [Colors.red.shade50, Colors.red.shade100]
                              : [Colors.green.shade50, Colors.green.shade100],
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon and Verdict
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: _result!.isScam
                                        ? Colors.red
                                        : Colors.green,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_result!.isScam
                                                    ? Colors.red
                                                    : Colors.green)
                                                .withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _result!.isScam
                                        ? Icons.warning
                                        : Icons.check_circle,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _result!.isScam
                                            ? '🚨 Likely a SCAM!'
                                            : '✅ Looks Safe',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: _result!.isScam
                                                  ? Colors.red.shade900
                                                  : Colors.green.shade900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (_result!.isScam
                                                      ? Colors.red
                                                      : Colors.green)
                                                  .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Confidence: ${_result!.confidenceLevel}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _result!.isScam
                                                ? Colors.red.shade900
                                                : Colors.green.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Verdict
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800.withOpacity(0.5)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.fact_check,
                                        size: 20,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Analysis:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _result!.verdict,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),

                            // Red Flags
                            if (_result!.redFlags.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800.withOpacity(0.5)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: _result!.isScam
                                        ? Colors.red.shade300
                                        : Colors.green.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.flag,
                                          size: 20,
                                          color: _result!.isScam
                                              ? Colors.red.shade700
                                              : Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _result!.isScam
                                              ? 'Red Flags Detected:'
                                              : 'Trust Indicators:',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: _result!.isScam
                                                    ? Colors.red.shade900
                                                    : Colors.green.shade900,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ..._result!.redFlags.map((flag) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              _result!.isScam
                                                  ? Icons.close
                                                  : Icons.check,
                                              size: 16,
                                              color: _result!.isScam
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                flag,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ],

                            // Sarcastic Advice
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Colors.purple.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb,
                                        size: 20,
                                        color: Colors.purple.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Expert Commentary:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple.shade900,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _result!.sarcasticAdvice,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.purple.shade900,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Custom Pill Tab Widget
class _PillTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : isDark
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
