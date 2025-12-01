import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'custom_bottom_nav.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final int currentTabIndex;
  final Function(int) onTabChanged;

  const AppShell({
    Key? key,
    required this.child,
    required this.currentTabIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CyberGuard'), elevation: 0),
      drawer: const CustomDrawer(),
      body: widget.child,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: widget.currentTabIndex,
        onTabChanged: widget.onTabChanged,
      ),
    );
  }
}
