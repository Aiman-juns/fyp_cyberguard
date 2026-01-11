import 'dart:math';

enum PasswordStrength { veryWeak, weak, medium, strong }

enum AttackMethod {
  bruteForce,
  dictionaryAttack,
  rainbowTables,
  socialEngineering,
  credentialStuffing
}

class PasswordAnalysis {
  final String password;
  final PasswordStrength strength;
  final Duration estimatedCrackTime;
  final int score;
  final List<AttackMethod> vulnerableToAttacks;
  final List<String> vulnerabilities;
  final List<String> improvements;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumbers;
  final bool hasSymbols;
  final int length;
  final double entropy;

  PasswordAnalysis({
    required this.password,
    required this.strength,
    required this.estimatedCrackTime,
    required this.score,
    required this.vulnerableToAttacks,
    required this.vulnerabilities,
    required this.improvements,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumbers,
    required this.hasSymbols,
    required this.length,
    required this.entropy,
  });

  String get strengthText {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 'Very Weak';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  String get crackTimeFormatted {
    final seconds = estimatedCrackTime.inSeconds;
    
    if (seconds < 1) {
      return 'Instant';
    } else if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      final minutes = (seconds / 60).ceil();
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else if (seconds < 86400) {
      final hours = (seconds / 3600).ceil();
      return '$hours hour${hours > 1 ? 's' : ''}';
    } else if (seconds < 2592000) {
      final days = (seconds / 86400).ceil();
      return '$days day${days > 1 ? 's' : ''}';
    } else if (seconds < 31536000) {
      final months = (seconds / 2592000).ceil();
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      final years = (seconds / 31536000).ceil();
      return '$years year${years > 1 ? 's' : ''}';
    }
  }
}

class PasswordAnalyzer {
  // Common weak passwords list
  static const List<String> commonPasswords = [
    '123456', 'password', '12345678', 'qwerty', '123456789',
    '12345', '1234', '111111', '1234567', 'dragon',
    '123123', 'baseball', 'iloveyou', 'trustno1', 'monkey',
    'letmein', 'abc123', 'qwerty123', 'admin', 'welcome',
    'login', 'password1', 'Password1', 'sunshine', 'master',
    'princess', 'starwars', 'freedom', 'whatever', 'batman'
  ];

  // Common patterns
  static const List<String> commonPatterns = [
    '1234', 'abcd', 'qwerty', 'asdf', '0000', '1111'
  ];

  // Assumptions for crack time calculation
  static const int attemptsPerSecond = 1000000; // 1 million/sec (modern GPU)

  /// Main analysis function
  static PasswordAnalysis analyzePassword(String password) {
    if (password.isEmpty) {
      return PasswordAnalysis(
        password: password,
        strength: PasswordStrength.veryWeak,
        estimatedCrackTime: Duration.zero,
        score: 0,
        vulnerableToAttacks: AttackMethod.values,
        vulnerabilities: ['No password entered'],
        improvements: ['Create a password with at least 12 characters'],
        hasUppercase: false,
        hasLowercase: false,
        hasNumbers: false,
        hasSymbols: false,
        length: 0,
        entropy: 0,
      );
    }

    final length = password.length;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    final hasSymbols = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]'));

    // Calculate entropy
    int charsetSize = 0;
    if (hasLowercase) charsetSize += 26;
    if (hasUppercase) charsetSize += 26;
    if (hasNumbers) charsetSize += 10;
    if (hasSymbols) charsetSize += 32;

    if (charsetSize == 0) charsetSize = 26; // Default
    
    final entropy = length * (log(charsetSize) / log(2));
    final combinations = pow(charsetSize, length).toDouble();
    final averageAttempts = combinations / 2;
    final secondsToCrack = averageAttempts / attemptsPerSecond;

    // Check vulnerabilities
    final vulnerabilities = <String>[];
    final improvements = <String>[];
    final vulnerableAttacks = <AttackMethod>[];

    // Check common passwords
    if (commonPasswords.contains(password.toLowerCase())) {
      vulnerabilities.add('This is a commonly used password');
      vulnerableAttacks.add(AttackMethod.credentialStuffing);
      vulnerableAttacks.add(AttackMethod.dictionaryAttack);
    }

    // Check for dictionary words
    if (_containsCommonWords(password)) {
      vulnerabilities.add('Contains common dictionary words');
      vulnerableAttacks.add(AttackMethod.dictionaryAttack);
    }

    // Check patterns
    if (_containsPattern(password)) {
      vulnerabilities.add('Contains sequential or repeated patterns');
      vulnerableAttacks.add(AttackMethod.bruteForce);
    }

    // Check for personal info patterns
    if (_containsPersonalInfoPattern(password)) {
      vulnerabilities.add('May contain personal information');
      vulnerableAttacks.add(AttackMethod.socialEngineering);
    }

    // Length check
    if (length < 8) {
      vulnerabilities.add('Password is too short');
      improvements.add('Use at least 12 characters');
      vulnerableAttacks.add(AttackMethod.bruteForce);
      vulnerableAttacks.add(AttackMethod.rainbowTables);
    } else if (length < 12) {
      improvements.add('Consider using 12+ characters for better security');
    }

    // Character variety checks
    if (!hasUppercase) {
      vulnerabilities.add('No uppercase letters');
      improvements.add('Add uppercase letters (A-Z)');
    }
    if (!hasLowercase) {
      vulnerabilities.add('No lowercase letters');
      improvements.add('Add lowercase letters (a-z)');
    }
    if (!hasNumbers) {
      vulnerabilities.add('No numbers');
      improvements.add('Add numbers (0-9)');
    }
    if (!hasSymbols) {
      vulnerabilities.add('No special symbols');
      improvements.add('Add special symbols (!@#\$%^&*)');
    }

    // Determine strength
    PasswordStrength strength;
    if (secondsToCrack < 60) {
      strength = PasswordStrength.veryWeak;
    } else if (secondsToCrack < 86400) {
      strength = PasswordStrength.weak;
    } else if (secondsToCrack < 31536000) {
      strength = PasswordStrength.medium;
    } else {
      strength = PasswordStrength.strong;
    }

    // If no specific vulnerabilities found but password is simple
    if (vulnerableAttacks.isEmpty) {
      if (strength == PasswordStrength.veryWeak || strength == PasswordStrength.weak) {
        vulnerableAttacks.add(AttackMethod.bruteForce);
      }
    }

    // Calculate score (0-100)
    int score = 0;
    score += min(30, length * 2); // Max 30 points for length
    if (hasUppercase) score += 15;
    if (hasLowercase) score += 15;
    if (hasNumbers) score += 15;
    if (hasSymbols) score += 20;
    score -= vulnerabilities.length * 5;
    score = max(0, min(100, score));

    // Default improvements if strong
    if (improvements.isEmpty && strength == PasswordStrength.strong) {
      improvements.add('Great password! Consider using a password manager');
      improvements.add('Enable two-factor authentication where possible');
    }

    return PasswordAnalysis(
      password: password,
      strength: strength,
      estimatedCrackTime: Duration(seconds: secondsToCrack.toInt()),
      score: score,
      vulnerableToAttacks: vulnerableAttacks.toSet().toList(),
      vulnerabilities: vulnerabilities,
      improvements: improvements,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumbers: hasNumbers,
      hasSymbols: hasSymbols,
      length: length,
      entropy: entropy,
    );
  }

  static bool _containsCommonWords(String password) {
    final lowerPassword = password.toLowerCase();
    const commonWords = [
      'password', 'pass', 'admin', 'user', 'login', 'welcome',
      'hello', 'test', 'guest', 'master', 'super', 'root'
    ];
    return commonWords.any((word) => lowerPassword.contains(word));
  }

  static bool _containsPattern(String password) {
    final lower = password.toLowerCase();
    return commonPatterns.any((pattern) => lower.contains(pattern)) ||
        _hasRepeatingChars(password) ||
        _hasSequentialChars(password);
  }

  static bool _hasRepeatingChars(String password) {
    if (password.length < 3) return false;
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i] == password[i + 2]) {
        return true;
      }
    }
    return false;
  }

  static bool _hasSequentialChars(String password) {
    if (password.length < 3) return false;
    for (int i = 0; i < password.length - 2; i++) {
      final char1 = password.codeUnitAt(i);
      final char2 = password.codeUnitAt(i + 1);
      final char3 = password.codeUnitAt(i + 2);
      if (char2 == char1 + 1 && char3 == char2 + 1) {
        return true;
      }
    }
    return false;
  }

  static bool _containsPersonalInfoPattern(String password) {
    final lower = password.toLowerCase();
    // Check for years
    if (RegExp(r'19\d{2}|20\d{2}').hasMatch(password)) return true;
    // Check for common personal patterns
    const personalPatterns = ['name', 'birthday', 'birth', 'date'];
    return personalPatterns.any((pattern) => lower.contains(pattern));
  }

  /// Get attack method description
  static String getAttackDescription(AttackMethod method) {
    switch (method) {
      case AttackMethod.bruteForce:
        return 'Trying all possible character combinations systematically';
      case AttackMethod.dictionaryAttack:
        return 'Testing words from a dictionary database';
      case AttackMethod.rainbowTables:
        return 'Using pre-computed hash tables for quick lookup';
      case AttackMethod.socialEngineering:
        return 'Attempting passwords based on personal information';
      case AttackMethod.credentialStuffing:
        return 'Testing commonly leaked passwords from data breaches';
    }
  }

  /// Get attack method name
  static String getAttackName(AttackMethod method) {
    switch (method) {
      case AttackMethod.bruteForce:
        return 'Brute Force Attack';
      case AttackMethod.dictionaryAttack:
        return 'Dictionary Attack';
      case AttackMethod.rainbowTables:
        return 'Rainbow Table Attack';
      case AttackMethod.socialEngineering:
        return 'Social Engineering';
      case AttackMethod.credentialStuffing:
        return 'Credential Stuffing';
    }
  }
}
