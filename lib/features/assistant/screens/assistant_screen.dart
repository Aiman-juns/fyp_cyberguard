import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({Key? key}) : super(key: key);

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with SingleTickerProviderStateMixin {
  final _urlController = TextEditingController();
  bool _isChecking = false;
  String? _resultStatus; // 'safe', 'danger', 'unknown'
  String? _resultMessage;
  Map<String, dynamic>? _scanStats;
  List<Map<String, String>>? _threatDetails;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final String _apiKey =
      'b50efe0b052eee3b3981452808bae7aec0fbde0acb8e9baf103597e7e6d301bf';

  String _encodeUrlToId(String url) {
    // Ensure URL has a scheme
    String encodedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      encodedUrl = 'https://$url';
    }

    // Base64url encode
    final bytes = utf8.encode(encodedUrl);
    final encoded = base64Url.encode(bytes).toString();

    // Remove padding '='
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
    if (_urlController.text.isEmpty) {
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
      final urlId = _encodeUrlToId(_urlController.text);
      final url = Uri.parse('https://www.virustotal.com/api/v3/urls/$urlId');

      final response = await http
          .get(url, headers: {'x-apikey': _apiKey})
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

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

              // Extract threat details
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

          // Start animation
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
      setState(() {
        _resultStatus = 'unknown';
        _resultMessage = '⚠️ Unable to check this URL. Please try again.';
      });
      _animationController.forward(from: 0);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
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
    _urlController.dispose();
    _animationController.dispose();
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Container(
              padding: const EdgeInsets.all(20.0),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
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
                          'Digital Assistant',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Check if a URL is safe before clicking',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Input Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
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
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
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
            ),

            // Results
            if (_resultStatus != null) ...[
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
                          colors: _resultStatus == 'safe'
                              ? [Colors.green.shade50, Colors.green.shade100]
                              : _resultStatus == 'danger'
                              ? [Colors.red.shade50, Colors.red.shade100]
                              : [Colors.orange.shade50, Colors.orange.shade100],
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Icon with animation
                            TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.8, end: 1.0),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.elasticOut,
                              builder: (context, double scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: _resultStatus == 'safe'
                                          ? Colors.green
                                          : _resultStatus == 'danger'
                                          ? Colors.red
                                          : Colors.orange,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (_resultStatus == 'safe'
                                                      ? Colors.green
                                                      : _resultStatus ==
                                                            'danger'
                                                      ? Colors.red
                                                      : Colors.orange)
                                                  .withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _resultStatus == 'safe'
                                          ? Icons.check_circle
                                          : _resultStatus == 'danger'
                                          ? Icons.error
                                          : Icons.help,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              _resultStatus == 'safe'
                                  ? 'Safe Website'
                                  : _resultStatus == 'danger'
                                  ? 'Dangerous Website'
                                  : 'Unknown Website',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: _resultStatus == 'safe'
                                        ? Colors.green.shade800
                                        : _resultStatus == 'danger'
                                        ? Colors.red.shade800
                                        : Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              _resultMessage ?? '',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade800,
                                  ),
                            ),

                            // Scan stats
                            if (_scanStats != null) ...[
                              const SizedBox(height: 20.0),
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800.withOpacity(0.5)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.analytics_outlined,
                                          size: 20,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Security Scan Results:',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16.0),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatItem(
                                          'Malicious',
                                          (_scanStats!['malicious'] ?? 0)
                                              .toString(),
                                          Colors.red,
                                          Icons.dangerous,
                                        ),
                                        _buildStatItem(
                                          'Suspicious',
                                          (_scanStats!['suspicious'] ?? 0)
                                              .toString(),
                                          Colors.orange,
                                          Icons.warning_amber,
                                        ),
                                        _buildStatItem(
                                          'Harmless',
                                          (_scanStats!['harmless'] ?? 0)
                                              .toString(),
                                          Colors.green,
                                          Icons.check_circle_outline,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Threat details section
                            if (_threatDetails != null &&
                                _threatDetails!.isNotEmpty) ...[
                              const SizedBox(height: 20.0),
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey.shade800.withOpacity(0.5)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.red.shade700
                                        : Colors.red.shade200,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.report_problem,
                                          color: Colors.red.shade700,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Detected Threats',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red.shade900,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12.0),
                                    Text(
                                      'The following security vendors identified threats:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade700,
                                          ),
                                    ),
                                    const SizedBox(height: 12.0),
                                    ...(_threatDetails!.take(5).map((threat) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12.0,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(12.0),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? (threat['category'] ==
                                                          'malicious'
                                                      ? Colors.red.shade900
                                                            .withOpacity(0.3)
                                                      : Colors.orange.shade900
                                                            .withOpacity(0.3))
                                                : (threat['category'] ==
                                                          'malicious'
                                                      ? Colors.red.shade50
                                                      : Colors.orange.shade50),
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? (threat['category'] ==
                                                            'malicious'
                                                        ? Colors.red.shade700
                                                        : Colors
                                                              .orange
                                                              .shade700)
                                                  : (threat['category'] ==
                                                            'malicious'
                                                        ? Colors.red.shade200
                                                        : Colors
                                                              .orange
                                                              .shade200),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                threat['category'] ==
                                                        'malicious'
                                                    ? Icons.cancel
                                                    : Icons.warning,
                                                color:
                                                    threat['category'] ==
                                                        'malicious'
                                                    ? Colors.red
                                                    : Colors.orange,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      threat['vendor'] ??
                                                          'Unknown',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Category: ${threat['category']?.toUpperCase()}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            threat['category'] ==
                                                                'malicious'
                                                            ? Colors
                                                                  .red
                                                                  .shade700
                                                            : Colors
                                                                  .orange
                                                                  .shade700,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      threat['result'] ??
                                                          'No details available',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isDark
                                                            ? Colors
                                                                  .grey
                                                                  .shade400
                                                            : Colors
                                                                  .grey
                                                                  .shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList()),
                                    if (_threatDetails!.length > 5) ...[
                                      const SizedBox(height: 8),
                                      Center(
                                        child: Text(
                                          '+ ${_threatDetails!.length - 5} more threats detected',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
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

  Widget _buildStatItem(
    String label,
    String count,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
