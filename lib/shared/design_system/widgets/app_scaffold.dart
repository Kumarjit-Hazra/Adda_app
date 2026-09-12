import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Base scaffold ensuring consistent background ambience and safe area handling.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final Widget? floatingOverlay;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.floatingOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: isDark ? AddaColors.bgDark : AddaColors.bgLight,
      body: Stack(
        children: [
          // Ambient lighting glow in dark mode
          if (isDark)
            Positioned(
              top: -120,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AddaColors.coral.withAlpha(20),
                ),
              ),
            ),
          if (isDark)
            Positioned(
              top: 200,
              left: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AddaColors.violet.withAlpha(15),
                ),
              ),
            ),
          SafeArea(child: body),
          if (floatingOverlay != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(child: floatingOverlay!),
            ),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
