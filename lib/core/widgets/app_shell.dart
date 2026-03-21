// TEMPORARY STUB — replaced in Task 10
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final bool isAdmin;
  const AppShell({super.key, required this.child, this.isAdmin = false});

  @override
  Widget build(BuildContext context) => child;
}
