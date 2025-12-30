import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/admin_provider.dart';
import '../../training/providers/training_provider.dart';
import '../../../config/supabase_config.dart';

class AdminQuestionsScreen extends ConsumerStatefulWidget {
  const AdminQuestionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminQuestionsScreen> createState() =>
      _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends ConsumerState<AdminQuestionsScreen> {
  String _selectedModule = 'phishing';

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(adminQuestionsProvider(_selectedModule));

    return questionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.refresh(adminQuestionsProvider(_selectedModule)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (questions) {
        return Column(
          children: [
            // Module selector
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade700, Colors.indigo.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.quiz,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Question Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Module',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'phishing', label: Text('Phishing')),
                      ButtonSegment(value: 'password', label: Text('Password')),
                      ButtonSegment(value: 'attack', label: Text('Attack')),
                    ],
                    selected: {_selectedModule},
                    onSelectionChanged: (newSelection) {
                      setState(() => _selectedModule = newSelection.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return Colors.white.withOpacity(0.3);
                      }),
                    ),
                  ),
                ],
              ),
            ),
            // Questions list
            Expanded(
              child: questions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No questions yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showCreateQuestionDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Question'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        return _QuestionCard(
                          question: question,
                          onEdit: () =>
                              _showEditQuestionDialog(context, question),
                          onDelete: () =>
                              _showDeleteConfirmDialog(context, question.id),
                        );
                      },
                    ),
            ),
            // Add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateQuestionDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Question'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateQuestionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialogContent(
        moduleType: _selectedModule,
        onSave: (question) {
          ref.invalidate(adminQuestionsProvider(_selectedModule));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditQuestionDialog(BuildContext context, Question question) {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialogContent(
        moduleType: question.moduleType,
        question: question,
        onSave: (updated) {
          ref.invalidate(adminQuestionsProvider(_selectedModule));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, String questionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(adminProvider.notifier)
                    .deleteQuestion(questionId);
                ref.invalidate(adminQuestionsProvider(_selectedModule));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Question deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final difficultyColor = question.difficulty == 1
        ? Colors.green
        : question.difficulty == 2
        ? Colors.orange
        : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: difficultyColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: difficultyColor.withOpacity(0.15),
            blurRadius: 8,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        difficultyColor,
                        difficultyColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: difficultyColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    question.difficulty == 1
                        ? Icons.sentiment_satisfied
                        : question.difficulty == 2
                        ? Icons.sentiment_neutral
                        : Icons.sentiment_very_dissatisfied,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: difficultyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Difficulty ${question.difficulty}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: difficultyColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildQuestionPreview(context, question),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: onEdit,
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: onDelete,
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Answer: ${question.correctAnswer}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildQuestionPreview(BuildContext context, Question question) {
    // For phishing module, parse and display email data nicely
    if (question.moduleType == 'phishing') {
      try {
        final emailData = json.decode(question.content);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'From: ${emailData['senderName'] ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    emailData['senderEmail'] ?? 'no-email',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.subject, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Subject: ${emailData['subject'] ?? 'No subject'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        );
      } catch (e) {
        // Fallback if not JSON
        return Text(
          question.content.length > 100
              ? '${question.content.substring(0, 100)}...'
              : question.content,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      }
    } else if (question.moduleType == 'password') {
      // For password module, parse and display requirements nicely
      try {
        final passwordData = json.decode(question.content);
        final requirements = <String>[];

        if (passwordData['minLength'] != null) {
          requirements.add('Min ${passwordData['minLength']} characters');
        }
        if (passwordData['uppercase'] == true) requirements.add('Uppercase');
        if (passwordData['lowercase'] == true) requirements.add('Lowercase');
        if (passwordData['numbers'] == true) requirements.add('Numbers');
        if (passwordData['special'] == true) requirements.add('Special chars');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Password Requirements',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: requirements
                  .map(
                    (req) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        req,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      } catch (e) {
        // Fallback if not JSON
        return Row(
          children: [
            Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                question.content.length > 80
                    ? '${question.content.substring(0, 80)}...'
                    : question.content,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }
    } else if (question.moduleType == 'attack') {
      // For attack module, parse and display scenario nicely
      try {
        final attackData = json.decode(question.content);
        final description = attackData['description'] ?? '';
        final options = attackData['options'] as List<dynamic>? ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    description.length > 80
                        ? '${description.substring(0, 80)}...'
                        : description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (options.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${options.length} answer options',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        );
      } catch (e) {
        // Fallback if not JSON
        return Row(
          children: [
            Icon(Icons.security, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                question.content.length > 80
                    ? '${question.content.substring(0, 80)}...'
                    : question.content,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }
    }

    // For other modules, show content normally
    return Text(
      question.content.length > 100
          ? '${question.content.substring(0, 100)}...'
          : question.content,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _QuestionDialogContent extends ConsumerStatefulWidget {
  final String moduleType;
  final Question? question;
  final Function(Question) onSave;

  const _QuestionDialogContent({
    required this.moduleType,
    this.question,
    required this.onSave,
  });

  @override
  ConsumerState<_QuestionDialogContent> createState() =>
      _QuestionDialogContentState();
}

class _QuestionDialogContentState
    extends ConsumerState<_QuestionDialogContent> {
  late TextEditingController
  contentController; // Used for body in phishing, content in others
  late TextEditingController senderNameController;
  late TextEditingController senderEmailController;
  late TextEditingController subjectController;
  late TextEditingController answerController;
  late TextEditingController explanationController;
  late TextEditingController mediaUrlController;
  int difficulty = 1;
  String? selectedPhishingAnswer; // 'phishing' or 'safe'

  // Password module specific
  int minLength = 8;
  bool requireUppercase = true;
  bool requireLowercase = true;
  bool requireNumbers = true;
  bool requireSpecial = true;

  bool get isPhishingModule => widget.moduleType == 'phishing';
  bool get isPasswordModule => widget.moduleType == 'password';
  bool get isAttackModule => widget.moduleType == 'attack';

  // Attack module specific
  late TextEditingController descriptionController;
  late TextEditingController optionAController;
  late TextEditingController optionBController;
  late TextEditingController optionCController;
  late TextEditingController optionDController;
  String mediaType = 'none'; // 'none', 'image', 'youtube', 'video'
  String? selectedCorrectOption; // 'A', 'B', 'C', or 'D'

  // File upload state
  String? _selectedMediaFileName;
  String? _uploadedMediaUrl;
  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();

    // Initialize answer, explanation, and mediaUrl controllers (same for all modules)
    answerController = TextEditingController(
      text: widget.question?.correctAnswer ?? '',
    );

    // For phishing module, extract the answer (phishing/safe) from correctAnswer
    if (isPhishingModule && widget.question != null) {
      selectedPhishingAnswer = widget.question!.correctAnswer.toLowerCase();
    }

    explanationController = TextEditingController(
      text: widget.question?.explanation ?? '',
    );
    mediaUrlController = TextEditingController(
      text: widget.question?.mediaUrl ?? '',
    );
    difficulty = widget.question?.difficulty ?? 1;

    // Handle content field based on module type
    if (isPhishingModule) {
      // For phishing: parse JSON and populate separate fields
      Map<String, dynamic> emailData = {};
      if (widget.question?.content != null &&
          widget.question!.content.isNotEmpty) {
        try {
          emailData =
              jsonDecode(widget.question!.content) as Map<String, dynamic>;
        } catch (e) {
          // If parsing fails, use empty values
        }
      }

      senderNameController = TextEditingController(
        text: emailData['senderName'] ?? '',
      );
      senderEmailController = TextEditingController(
        text: emailData['senderEmail'] ?? '',
      );
      subjectController = TextEditingController(
        text: emailData['subject'] ?? '',
      );
      contentController = TextEditingController(text: emailData['body'] ?? '');
    } else if (isPasswordModule) {
      // For password module: parse JSON requirements
      Map<String, dynamic> passwordData = {};
      if (widget.question?.content != null &&
          widget.question!.content.isNotEmpty) {
        try {
          passwordData =
              jsonDecode(widget.question!.content) as Map<String, dynamic>;
        } catch (e) {
          // If parsing fails, use defaults
        }
      }

      minLength = passwordData['minLength'] ?? 8;
      requireUppercase = passwordData['uppercase'] ?? true;
      requireLowercase = passwordData['lowercase'] ?? true;
      requireNumbers = passwordData['numbers'] ?? true;
      requireSpecial = passwordData['special'] ?? true;

      // These controllers aren't used for password module but initialize them anyway
      contentController = TextEditingController();
      senderNameController = TextEditingController();
      senderEmailController = TextEditingController();
      subjectController = TextEditingController();
    } else if (isAttackModule) {
      // For attack module: parse JSON with description and options
      Map<String, dynamic> attackData = {};
      if (widget.question?.content != null &&
          widget.question!.content.isNotEmpty) {
        try {
          attackData =
              jsonDecode(widget.question!.content) as Map<String, dynamic>;
        } catch (e) {
          // If parsing fails, use defaults
        }
      }

      descriptionController = TextEditingController(
        text: attackData['description'] ?? '',
      );
      mediaType = attackData['mediaType'] ?? 'none';

      final options = attackData['options'] as List<dynamic>? ?? [];
      optionAController = TextEditingController(
        text: options.isNotEmpty ? options[0] ?? '' : '',
      );
      optionBController = TextEditingController(
        text: options.length > 1 ? options[1] ?? '' : '',
      );
      optionCController = TextEditingController(
        text: options.length > 2 ? options[2] ?? '' : '',
      );
      optionDController = TextEditingController(
        text: options.length > 3 ? options[3] ?? '' : '',
      );

      // Derive selected correct option from correctAnswer field
      if (widget.question != null) {
        final answer = widget.question!.correctAnswer.toLowerCase();
        if (answer.contains('a') ||
            options.isNotEmpty && options[0] == widget.question!.correctAnswer)
          selectedCorrectOption = 'A';
        else if (answer.contains('b') ||
            options.length > 1 && options[1] == widget.question!.correctAnswer)
          selectedCorrectOption = 'B';
        else if (answer.contains('c') ||
            options.length > 2 && options[2] == widget.question!.correctAnswer)
          selectedCorrectOption = 'C';
        else if (answer.contains('d') ||
            options.length > 3 && options[3] == widget.question!.correctAnswer)
          selectedCorrectOption = 'D';
      }

      // Initialize unused controllers
      contentController = TextEditingController();
      senderNameController = TextEditingController();
      senderEmailController = TextEditingController();
      subjectController = TextEditingController();
    } else {
      // For other modules: use content as plain text
      contentController = TextEditingController(
        text: widget.question?.content ?? '',
      );
      senderNameController = TextEditingController();
      senderEmailController = TextEditingController();
      subjectController = TextEditingController();

      // Initialize attack controllers
      descriptionController = TextEditingController();
      optionAController = TextEditingController();
      optionBController = TextEditingController();
      optionCController = TextEditingController();
      optionDController = TextEditingController();
    }
  }

  // File picker method
  Future<void> _pickMediaFile() async {
    try {
      FilePickerResult? result;

      if (mediaType == 'image') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
      } else if (mediaType == 'video') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: false,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final fileBytes = result.files.single.bytes;
        final fileName = result.files.single.name;
        
        if (fileBytes != null) {
          setState(() {
            _selectedMediaFileName = fileName;
            _uploadedMediaUrl = null;
          });

          // Automatically upload the file
          await _uploadMediaFile(fileBytes, fileName);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  // Upload file to Supabase storage
  Future<void> _uploadMediaFile(List<int> fileBytes, String fileName) async {
    setState(() => _isUploadingFile = true);

    try {
      final fileExtension = fileName.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folder = mediaType == 'image' ? 'images' : 'videos';
      final uniqueFileName = '${widget.moduleType}_${timestamp}.$fileExtension';
      final path = '$folder/$uniqueFileName';

      // Convert List<int> to Uint8List for web compatibility
      final uint8ListBytes = Uint8List.fromList(fileBytes);

      // Upload to Supabase storage
      final bucket = SupabaseConfig.client.storage.from('question-media');
      await bucket.uploadBinary(path, uint8ListBytes);

      // Get public URL
      final url = bucket.getPublicUrl(path);

      setState(() {
        _uploadedMediaUrl = url;
        mediaUrlController.text = url;
        _isUploadingFile = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isUploadingFile = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    contentController.dispose();
    senderNameController.dispose();
    senderEmailController.dispose();
    subjectController.dispose();
    answerController.dispose();
    explanationController.dispose();
    mediaUrlController.dispose();
    descriptionController.dispose();
    optionAController.dispose();
    optionBController.dispose();
    optionCController.dispose();
    optionDController.dispose();
    super.dispose();
  }

  String _getContentValue() {
    if (isPhishingModule) {
      // Combine phishing fields into JSON
      final emailData = {
        'senderName': senderNameController.text,
        'senderEmail': senderEmailController.text,
        'subject': subjectController.text,
        'body': contentController.text,
      };
      return jsonEncode(emailData);
    } else if (isPasswordModule) {
      // Combine password requirements into JSON
      final passwordData = {
        'minLength': minLength,
        'uppercase': requireUppercase,
        'lowercase': requireLowercase,
        'numbers': requireNumbers,
        'special': requireSpecial,
      };
      return jsonEncode(passwordData);
    } else if (isAttackModule) {
      // Combine attack module fields into JSON
      final attackData = {
        'description': descriptionController.text,
        'mediaType': mediaType,
        'options': [
          optionAController.text,
          optionBController.text,
          optionCController.text,
          optionDController.text,
        ],
      };
      return jsonEncode(attackData);
    } else {
      return contentController.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.question == null ? 'Create Question' : 'Edit Question',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Conditional fields based on module type
            if (isPhishingModule) ...[
              // Phishing module: 4 separate fields
              TextField(
                controller: senderNameController,
                decoration: const InputDecoration(
                  labelText: 'Sender Name',
                  hintText: 'e.g., IT Support',
                ),
                onChanged: (_) => setState(() {}), // Trigger preview update
              ),
              const SizedBox(height: 16),
              TextField(
                controller: senderEmailController,
                decoration: const InputDecoration(
                  labelText: 'Sender Email',
                  hintText: 'e.g., support@company-security.com',
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}), // Trigger preview update
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g., Urgent: Password Expiry',
                ),
                onChanged: (_) => setState(() {}), // Trigger preview update
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Email Body',
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                minLines: 4,
                onChanged: (_) => setState(() {}), // Trigger preview update
              ),
              const SizedBox(height: 16),
              // Preview Card
              _EmailPreviewCard(
                senderName: senderNameController.text,
                senderEmail: senderEmailController.text,
                subject: subjectController.text,
                body: contentController.text,
                mediaUrl: mediaUrlController.text.isNotEmpty
                    ? mediaUrlController.text
                    : null,
              ),
            ] else if (isPasswordModule) ...[
              // Password module: configuration form
              Text(
                'Password Requirements Configuration',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Text(
                'Minimum Length: $minLength',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Slider(
                value: minLength.toDouble(),
                min: 6,
                max: 20,
                divisions: 14,
                label: minLength.toString(),
                onChanged: (value) {
                  setState(() => minLength = value.toInt());
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Require Uppercase (A-Z)'),
                value: requireUppercase,
                onChanged: (value) {
                  setState(() => requireUppercase = value ?? true);
                },
                dense: true,
              ),
              CheckboxListTile(
                title: const Text('Require Lowercase (a-z)'),
                value: requireLowercase,
                onChanged: (value) {
                  setState(() => requireLowercase = value ?? true);
                },
                dense: true,
              ),
              CheckboxListTile(
                title: const Text('Require Numbers (0-9)'),
                value: requireNumbers,
                onChanged: (value) {
                  setState(() => requireNumbers = value ?? true);
                },
                dense: true,
              ),
              CheckboxListTile(
                title: const Text('Require Special Characters (!@#...)'),
                value: requireSpecial,
                onChanged: (value) {
                  setState(() => requireSpecial = value ?? true);
                },
                dense: true,
              ),
            ] else if (isAttackModule) ...[
              // Attack module: multimedia quiz configuration
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Scenario Description',
                  hintText: 'Describe the cyberattack scenario',
                ),
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Media Type',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: mediaType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'none',
                    child: Text('None (Text Only)'),
                  ),
                  DropdownMenuItem(value: 'image', child: Text('Image')),
                  DropdownMenuItem(
                    value: 'youtube',
                    child: Text('YouTube Video'),
                  ),
                  DropdownMenuItem(value: 'video', child: Text('MP4 Video')),
                ],
                onChanged: (value) {
                  setState(() => mediaType = value ?? 'none');
                },
              ),
              if (mediaType != 'none') ...[
                const SizedBox(height: 16),
                if (mediaType == 'image' || mediaType == 'video') ...[
                  // File upload option for images and videos
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploadingFile ? null : _pickMediaFile,
                          icon: _isUploadingFile
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file),
                          label: Text(
                            _isUploadingFile
                                ? 'Uploading...'
                                : 'Upload ${mediaType == 'image' ? 'Image' : 'Video'} File',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedMediaFileName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'File selected: $_selectedMediaFileName',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'OR enter URL directly:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: mediaUrlController,
                  decoration: InputDecoration(
                    labelText: mediaType == 'youtube'
                        ? 'YouTube Video URL or ID'
                        : mediaType == 'video'
                        ? 'MP4 Video URL'
                        : 'Image URL',
                    hintText: mediaType == 'youtube'
                        ? 'e.g., https://youtube.com/watch?v=...'
                        : 'e.g., https://...',
                    suffixIcon:
                        mediaType != 'youtube' && _uploadedMediaUrl != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Answer Options',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: optionAController,
                decoration: const InputDecoration(
                  labelText: 'Option A',
                  prefixText: 'A) ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: optionBController,
                decoration: const InputDecoration(
                  labelText: 'Option B',
                  prefixText: 'B) ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: optionCController,
                decoration: const InputDecoration(
                  labelText: 'Option C',
                  prefixText: 'C) ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: optionDController,
                decoration: const InputDecoration(
                  labelText: 'Option D',
                  prefixText: 'D) ',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Correct Answer',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ['A', 'B', 'C', 'D'].map((option) {
                  return ChoiceChip(
                    label: Text(option),
                    selected: selectedCorrectOption == option,
                    onSelected: (selected) {
                      setState(() => selectedCorrectOption = option);
                    },
                  );
                }).toList(),
              ),
            ] else ...[
              // Other modules: single content field
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Question Content',
                ),
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 16),
            // Answer field - different for phishing vs other modules
            if (isPhishingModule) ...[
              Text(
                'Correct Answer',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.warning),
                      label: const Text('Phishing'),
                      onPressed: () {
                        setState(() => selectedPhishingAnswer = 'phishing');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedPhishingAnswer == 'phishing'
                            ? Colors.red.shade600
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shield),
                      label: const Text('Safe'),
                      onPressed: () {
                        setState(() => selectedPhishingAnswer = 'safe');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedPhishingAnswer == 'safe'
                            ? Colors.green.shade600
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (!isPasswordModule) ...[
              TextField(
                controller: answerController,
                decoration: const InputDecoration(labelText: 'Correct Answer'),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: explanationController,
              decoration: const InputDecoration(labelText: 'Explanation'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: mediaUrlController,
              decoration: const InputDecoration(
                labelText: 'Media URL (optional)',
              ),
              onChanged: (_) {
                if (isPhishingModule) setState(() {}); // Trigger preview update
              },
            ),
            const SizedBox(height: 16),
            Slider(
              value: difficulty.toDouble(),
              min: 1,
              max: 3,
              divisions: 2,
              label: 'Difficulty: $difficulty',
              onChanged: (value) => setState(() => difficulty = value.toInt()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Validate that phishing answer is selected for phishing module
            if (isPhishingModule && selectedPhishingAnswer == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select Phishing or Safe')),
              );
              return;
            }

            if (isAttackModule) {
              if (descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a description')),
                );
                return;
              }
              if (optionAController.text.isEmpty ||
                  optionBController.text.isEmpty ||
                  optionCController.text.isEmpty ||
                  optionDController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all 4 options')),
                );
                return;
              }
              if (selectedCorrectOption == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select correct answer')),
                );
                return;
              }
            }

            try {
              final content = _getContentValue();

              // Determine correct answer based on module type
              String correctAnswer;
              if (isPhishingModule) {
                correctAnswer = selectedPhishingAnswer!;
              } else if (isPasswordModule) {
                correctAnswer = 'valid_password';
              } else if (isAttackModule) {
                // Get the selected option text as correct answer
                correctAnswer = selectedCorrectOption == 'A'
                    ? optionAController.text
                    : selectedCorrectOption == 'B'
                    ? optionBController.text
                    : selectedCorrectOption == 'C'
                    ? optionCController.text
                    : optionDController.text;
              } else {
                correctAnswer = answerController.text;
              }

              if (widget.question == null) {
                await ref
                    .read(adminProvider.notifier)
                    .createQuestion(
                      moduleType: widget.moduleType,
                      difficulty: difficulty,
                      content: content,
                      correctAnswer: correctAnswer,
                      explanation: isAttackModule
                          ? ''
                          : explanationController.text,
                      mediaUrl:
                          (mediaType == 'none' ||
                              mediaUrlController.text.isEmpty)
                          ? null
                          : mediaUrlController.text,
                    );
              } else {
                await ref
                    .read(adminProvider.notifier)
                    .updateQuestion(
                      questionId: widget.question!.id,
                      difficulty: difficulty,
                      content: content,
                      correctAnswer: correctAnswer,
                      explanation: isAttackModule
                          ? ''
                          : explanationController.text,
                      mediaUrl:
                          (mediaType == 'none' ||
                              mediaUrlController.text.isEmpty)
                          ? null
                          : mediaUrlController.text,
                    );
              }

              // Invalidate the cache to refresh the questions list
              if (mounted) {
                ref.invalidate(adminQuestionsProvider(widget.moduleType));

                // Invalidate all training providers for this module (including family providers for all difficulties)
                if (widget.moduleType == 'phishing') {
                  ref.invalidate(phishingQuestionsProvider);
                  ref.invalidate(phishingQuestionsByDifficultyProvider);
                } else if (widget.moduleType == 'password') {
                  ref.invalidate(passwordQuestionsProvider);
                  ref.invalidate(passwordQuestionsByDifficultyProvider);
                } else if (widget.moduleType == 'attack') {
                  ref.invalidate(attackQuestionsProvider);
                  ref.invalidate(attackQuestionsByDifficultyProvider);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.question == null
                          ? 'Question created'
                          : 'Question updated',
                    ),
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Preview card widget for phishing email questions
class _EmailPreviewCard extends StatelessWidget {
  final String senderName;
  final String senderEmail;
  final String subject;
  final String body;
  final String? mediaUrl;

  const _EmailPreviewCard({
    required this.senderName,
    required this.senderEmail,
    required this.subject,
    required this.body,
    this.mediaUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            // Email Header
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade600,
                  child: Text(
                    senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName.isNotEmpty ? senderName : 'Sender Name',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        senderEmail.isNotEmpty
                            ? senderEmail
                            : 'sender@email.com',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            // Subject
            if (subject.isNotEmpty)
              Text(
                subject,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            if (subject.isEmpty)
              Text(
                'Subject',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                ),
              ),
            const SizedBox(height: 8),
            // Body
            Text(
              body.isNotEmpty ? body : 'Email body content...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: body.isEmpty ? Colors.grey.shade400 : null,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Media preview
            if (mediaUrl != null && mediaUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
