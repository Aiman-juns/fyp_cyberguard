import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({Key? key}) : super(key: key);

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _urlController = TextEditingController();
  bool _isChecking = false;
  String? _resultStatus; // 'safe', 'danger', 'unknown'
  String? _resultMessage;
  Map<String, dynamic>? _scanStats;
  final String _apiKey = 'b50efe0b052eee3b3981452808bae7aec0fbde0acb8e9baf103597e7e6d301bf';

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

  Future<void> _checkUrl() async {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a URL')),
      );
      return;
    }

    setState(() {
      _isChecking = true;
      _resultStatus = null;
      _resultMessage = null;
      _scanStats = null;
    });

    try {
      final urlId = _encodeUrlToId(_urlController.text);
      final url = Uri.parse('https://www.virustotal.com/api/v3/urls/$urlId');
      
      final response = await http.get(
        url,
        headers: {'x-apikey': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final lastAnalysisStats = data['data']?['attributes']?['last_analysis_stats'] as Map<String, dynamic>?;
        
        if (lastAnalysisStats != null) {
          final malicious = (lastAnalysisStats['malicious'] ?? 0) as int;
          final suspicious = (lastAnalysisStats['suspicious'] ?? 0) as int;
          final harmless = (lastAnalysisStats['harmless'] ?? 0) as int;
          
          setState(() {
            _scanStats = lastAnalysisStats;
            
            if (malicious + suspicious > 0) {
              _resultStatus = 'danger';
              _resultMessage = 'Warning! ${malicious + suspicious} security vendor(s) flagged this site as dangerous. Do not visit.';
            } else if (harmless > 0) {
              _resultStatus = 'safe';
              _resultMessage = 'Good news! This website appears safe to visit according to our security scan.';
            } else {
              _resultStatus = 'unknown';
              _resultMessage = 'This is a new or unknown link. We have no security data for it yet. Be careful.';
            }
          });
        } else {
          setState(() {
            _resultStatus = 'unknown';
            _resultMessage = 'This is a new or unknown link. We have no security data for it yet. Be careful.';
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _resultStatus = 'unknown';
          _resultMessage = 'This is a new or unknown link. We have no security data for it yet. Be careful.';
        });
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultStatus = 'unknown';
        _resultMessage = 'Unable to check this URL. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Digital Assistant',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Check if a URL is safe',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24.0),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'Enter URL (e.g., https://example.com)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              prefixIcon: const Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isChecking ? null : _checkUrl,
              child: _isChecking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Check URL'),
            ),
          ),
          if (_resultStatus != null) ...[
            const SizedBox(height: 24.0),
            Card(
              color: _resultStatus == 'safe'
                  ? Colors.green.shade50
                  : _resultStatus == 'danger'
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _resultStatus == 'safe'
                          ? Icons.check_circle
                          : _resultStatus == 'danger'
                              ? Icons.error
                              : Icons.help,
                      color: _resultStatus == 'safe'
                          ? Colors.green
                          : _resultStatus == 'danger'
                              ? Colors.red
                              : Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      _resultStatus == 'safe'
                          ? 'Safe Website'
                          : _resultStatus == 'danger'
                              ? 'Dangerous Website'
                              : 'Unknown Website',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _resultStatus == 'safe'
                            ? Colors.green
                            : _resultStatus == 'danger'
                                ? Colors.red
                                : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _resultMessage ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_scanStats != null) ...[
                      const SizedBox(height: 16.0),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security Scan Results:',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  'Malicious',
                                  (_scanStats!['malicious'] ?? 0).toString(),
                                  Colors.red,
                                ),
                                _buildStatItem(
                                  'Suspicious',
                                  (_scanStats!['suspicious'] ?? 0).toString(),
                                  Colors.orange,
                                ),
                                _buildStatItem(
                                  'Harmless',
                                  (_scanStats!['harmless'] ?? 0).toString(),
                                  Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
