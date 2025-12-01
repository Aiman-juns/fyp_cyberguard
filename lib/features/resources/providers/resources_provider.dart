import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../config/supabase_config.dart';

/// Cyber Attack Type Model
class CyberAttackType {
  final String id;
  final String title;
  final String description;
  final String? mediaUrl;

  CyberAttackType({
    required this.id,
    required this.title,
    required this.description,
    this.mediaUrl,
  });
}

/// Resource Model
class Resource {
  final String id;
  final String title;
  final String category;
  final String content;
  final String? mediaUrl;
  final String? description;
  final List<String>? learningObjectives;
  final List<CyberAttackType>?
  attackTypes; // For Types of Cyber Attack resource
  final DateTime createdAt;
  final DateTime updatedAt;

  Resource({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    this.mediaUrl,
    this.description,
    this.learningObjectives,
    this.attackTypes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      content: json['content'] as String,
      mediaUrl: json['media_url'] as String?,
      description: json['description'] as String?,
      learningObjectives: json['learning_objectives'] != null
          ? List<String>.from(json['learning_objectives'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Local hardcoded resources
final _localResources = [
  Resource(
    id: '1',
    title: 'What is Cyber Security?',
    category: 'Introduction',
    content:
        '''In an era where our reliance on technology is higher than ever, Cybersecurity has emerged as a critical practice for protecting our digital way of life. 
    
It is the practice of defending computers, servers, mobile devices, electronic systems, networks, and data from malicious attacks.''',
    mediaUrl: 'https://www.youtube.com/watch?v=shQEXpUwaIY',
    description:
        'Learn Flutter development from scratch and build beautiful mobile apps',
    learningObjectives: [
      'Concept of Cybersecurity: Understand the core definition of protecting systems.',
      'The Rise of Cybercrime: How the internet\'s growth fueled digital threats.',
      'Core Responsibilities: Developing secure software and analyzing evidence.',
      'Career Pathways: Roles like Ethical Hackers and Forensic Investigators.',
    ],
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  Resource(
    id: '2',
    title: 'Types of Cyber Attack',
    category: 'Cyber Attacks',
    content:
        '''Learn about different types of cyber attacks and how to identify them.''',
    mediaUrl: null,
    description:
        'Explore various cyber attack methods and understand how they work',
    learningObjectives: [
      'Identify different types of cyber attacks',
      'Understand attack vectors and methods',
      'Learn prevention strategies for each attack type',
      'Recognize signs of potential attacks',
    ],
    attackTypes: [
      CyberAttackType(
        id: '1',
        title: 'Clickjacking',
        description:
            'A malicious technique where users are tricked into clicking on something different from what they perceive.',
        mediaUrl: null,
      ),
      CyberAttackType(
        id: '2',
        title: 'Phishing Email',
        description:
            'Fraudulent emails designed to trick recipients into revealing sensitive information or installing malware.',
        mediaUrl: null,
      ),
      CyberAttackType(
        id: '3',
        title: 'Brute Force Attack',
        description:
            'An attack method that uses trial and error to crack passwords, login credentials, and encryption keys.',
        mediaUrl: null,
      ),
      CyberAttackType(
        id: '4',
        title: 'DNS Poisoning',
        description:
            'A cyber attack that redirects users to malicious websites by corrupting DNS cache data.',
        mediaUrl: null,
      ),
      CyberAttackType(
        id: '5',
        title: 'Credential Stuffing',
        description:
            'An attack where stolen account credentials are used to gain unauthorized access to user accounts.',
        mediaUrl: null,
      ),
    ],
    createdAt: DateTime.now().subtract(const Duration(days: 8)),
    updatedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  Resource(
    id: '3',
    title: 'How to Prevent It',
    category: 'Prevention',
    content: '''Understand malware threats and how to protect your systems.
    
Topics covered:
- Types of malware: viruses, trojans, ransomware, spyware
- How malware spreads
- Signs of infection
- Prevention strategies
- Removal and recovery
- Best practices for security''',
    mediaUrl: null,
    description:
        'Learn effective strategies to prevent cyber attacks and protect your digital assets',
    learningObjectives: [
      'Implement strong security measures',
      'Recognize and avoid common attack vectors',
      'Use security tools and best practices',
      'Develop a comprehensive security strategy',
    ],
    createdAt: DateTime.now().subtract(const Duration(days: 6)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

/// Fetch all resources (simulated with local data)
Future<List<Resource>> fetchResources() async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 500));
  return _localResources;
}

/// Fetch single resource by ID (from local data)
Future<Resource> fetchResourceById(String id) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 300));

  try {
    return _localResources.firstWhere((resource) => resource.id == id);
  } catch (e) {
    throw Exception('Resource with ID $id not found');
  }
}

/// Riverpod provider for resources list
final resourcesProvider = FutureProvider<List<Resource>>((ref) async {
  return fetchResources();
});

/// Riverpod provider for single resource
final resourceProvider = FutureProvider.family<Resource, String>((
  ref,
  id,
) async {
  return fetchResourceById(id);
});
