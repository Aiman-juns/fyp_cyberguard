class BreachModel {
  final String name;
  final String description;
  final String riskLevel; // 'high', 'medium', 'low'

  BreachModel({
    required this.name,
    required this.description,
    required this.riskLevel,
  });

  factory BreachModel.fromName(String name) {
    // Generate a generic description based on the breach name
    return BreachModel(
      name: name,
      description: _generateDescription(name),
      riskLevel: 'high', // Most breaches are high risk by default
    );
  }

  static String _generateDescription(String name) {
    // Common breach types and their descriptions
    final lowerName = name.toLowerCase();

    if (lowerName.contains('linkedin') || lowerName.contains('professional')) {
      return 'Professional data including email, name, and job information may be exposed.';
    } else if (lowerName.contains('adobe') || lowerName.contains('creative')) {
      return 'Account credentials and personal information likely compromised.';
    } else if (lowerName.contains('dropbox') || lowerName.contains('cloud')) {
      return 'Cloud storage credentials and potentially stored files exposed.';
    } else if (lowerName.contains('yahoo') || lowerName.contains('mail')) {
      return 'Email account credentials and personal communications at risk.';
    } else if (lowerName.contains('facebook') || lowerName.contains('social')) {
      return 'Social media profile data and contact information exposed.';
    } else if (lowerName.contains('twitter') || lowerName.contains('x.com')) {
      return 'Username, email, and social connections may be compromised.';
    } else {
      return 'Password, email, and personal information likely exposed in this breach.';
    }
  }

  factory BreachModel.fromJson(Map<String, dynamic> json) {
    return BreachModel(
      name: json['name'] as String,
      description: json['description'] as String? ?? 'Data breach detected',
      riskLevel: json['riskLevel'] as String? ?? 'high',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description, 'riskLevel': riskLevel};
  }
}
