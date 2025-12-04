import 'package:flutter/material.dart';
import 'dart:math';

/// Data class representing a user avatar
class AvatarData {
  final String id;
  final IconData icon;
  final Color color;
  final String name;

  const AvatarData({
    required this.id,
    required this.icon,
    required this.color,
    required this.name,
  });
}

/// Service for managing user avatars
class AvatarService {
  static const List<AvatarData> _avatars = [
    AvatarData(
      id: 'shield',
      icon: Icons.shield,
      color: Colors.blue,
      name: 'Shield',
    ),
    AvatarData(
      id: 'lock_guard',
      icon: Icons.lock,
      color: Colors.green,
      name: 'Lock Guard',
    ),
    AvatarData(
      id: 'cyber_key',
      icon: Icons.vpn_key,
      color: Colors.orange,
      name: 'Cyber Key',
    ),
    AvatarData(
      id: 'net_shield',
      icon: Icons.security,
      color: Colors.purple,
      name: 'Net Shield',
    ),
    AvatarData(
      id: 'safe_link',
      icon: Icons.link,
      color: Colors.teal,
      name: 'Safe Link',
    ),
  ];

  /// Returns a random avatar ID from the available avatars
  static String getRandomAvatarId() {
    final random = Random();
    final index = random.nextInt(_avatars.length);
    return _avatars[index].id;
  }

  /// Returns the AvatarData for a given avatar ID
  /// Falls back to the first avatar if ID is not found
  static AvatarData getAvatarById(String id) {
    try {
      return _avatars.firstWhere((avatar) => avatar.id == id);
    } catch (e) {
      // Return default avatar if ID not found
      return _avatars[0];
    }
  }

  /// Returns all available avatars
  static List<AvatarData> getAllAvatars() {
    return List.unmodifiable(_avatars);
  }
}
