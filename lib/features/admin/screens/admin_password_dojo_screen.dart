import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminPasswordDojoScreen extends ConsumerStatefulWidget {
  const AdminPasswordDojoScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminPasswordDojoScreen> createState() =>
      _AdminPasswordDojoScreenState();
}

class _AdminPasswordDojoScreenState
    extends ConsumerState<AdminPasswordDojoScreen> {
  final Map<int, int> _requirementsPerLevel = {1: 2, 2: 4, 3: 6};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Password Dojo Requirements',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure password requirements for each difficulty level',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ..._buildLevelCards(),
            const SizedBox(height: 24),
            _buildSuggestionGuide(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLevelCards() {
    return List.generate(3, (index) {
      final level = index + 1;
      final requirements = _requirementsPerLevel[level] ?? 0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level $level',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getLevelColor(level),
                      ),
                    ),
                    Chip(
                      label: Text('$requirements requirements'),
                      backgroundColor: _getLevelColor(level).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _getLevelColor(level),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _getLevelDescription(level),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _buildRequirementsList(level, requirements),
                const SizedBox(height: 16),
                _buildUseCaseBox(level),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showEditRequirementsDialog(context, level),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Requirements'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLevelDescription(int level) {
    switch (level) {
      case 1:
        return 'Basic security level - For everyday websites';
      case 2:
        return 'Strong security level - For important accounts';
      case 3:
        return 'Maximum security level - For sensitive accounts';
      default:
        return '';
    }
  }

  Widget _buildRequirementsList(int level, int requirementCount) {
    final requirements = [
      'At least 8 characters long',
      'Contains uppercase letters (A-Z)',
      'Contains lowercase letters (a-z)',
      'Contains numbers (0-9)',
      'Contains special characters (!@#\$%^&*)',
      'At least 12 characters long',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requirements to meet:',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...requirements
            .take(requirementCount)
            .map(
              (req) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: _getLevelColor(level),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        req,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildUseCaseBox(int level) {
    final useCase = _getUseCase(level);
    return Container(
      decoration: BoxDecoration(
        color: _getLevelColor(level).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getLevelColor(level).withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: _getLevelColor(level), size: 18),
              const SizedBox(width: 8),
              Text(
                'Suitable for:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(level),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            useCase,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: _getLevelColor(level)),
          ),
        ],
      ),
    );
  }

  String _getUseCase(int level) {
    switch (level) {
      case 1:
        return 'Websites that don\'t involve personal information (forums, blogs, news sites)';
      case 2:
        return 'Important accounts (email, social media, shopping sites with payment info)';
      case 3:
        return 'Highly sensitive accounts (banking, cryptocurrency, company systems)';
      default:
        return '';
    }
  }

  Widget _buildSuggestionGuide() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Password Strength Guidelines',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideline(
              'Level 1 (Basic)',
              'Good for non-critical websites where account compromise is low risk',
            ),
            const SizedBox(height: 8),
            _buildGuideline(
              'Level 2 (Strong)',
              'Recommended for most online accounts to prevent unauthorized access',
            ),
            const SizedBox(height: 8),
            _buildGuideline(
              'Level 3 (Maximum)',
              'Essential for financial and sensitive work accounts to prevent identity theft and fraud',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideline(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.blue.shade600),
        ),
      ],
    );
  }

  void _showEditRequirementsDialog(BuildContext context, int level) {
    int currentRequirements = _requirementsPerLevel[level] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Level $level Requirements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select number of requirements to enforce:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
                ButtonSegment(value: 5, label: Text('5')),
                ButtonSegment(value: 6, label: Text('6')),
              ],
              selected: {currentRequirements},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _requirementsPerLevel[level] = newSelection.first;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Level $level updated to ${newSelection.first} requirements',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
