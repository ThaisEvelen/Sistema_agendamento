import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// AppBar com gradiente roxo → índigo, reutilizável em todas as telas.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double height;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.height = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.3,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: leading,
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: kPrimaryGradient,
        ),
      ),
    );
  }
}
