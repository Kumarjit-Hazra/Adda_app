import 'package:flutter/material.dart';
import '../../../../core/haptics/haptics_service.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

/// Tactile button with micro-animation and haptic feedback.
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 48,
    this.padding,
  });

  const AppButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 48,
    this.padding,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 44,
    this.padding,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.destructive({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height = 48,
    this.padding,
  }) : variant = AppButtonVariant.destructive;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
      HapticsService.lightTap();
    }
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color textColor;
    BoxDecoration decoration;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        textColor = Colors.white;
        decoration = BoxDecoration(
          gradient: isEnabled ? AddaColors.primaryGradient : null,
          color: isEnabled
              ? null
              : (isDark
                    ? AddaColors.surfaceElevatedDark
                    : AddaColors.surfaceElevatedLight),
          borderRadius: AddaRadius.radiusLg,
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AddaColors.coral.withAlpha(90),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        );
        break;
      case AppButtonVariant.secondary:
        textColor = isDark
            ? AddaColors.textPrimaryDark
            : AddaColors.textPrimaryLight;
        decoration = BoxDecoration(
          color: isDark
              ? AddaColors.surfaceVariantDark
              : AddaColors.surfaceVariantLight,
          borderRadius: AddaRadius.radiusLg,
          border: Border.all(
            color: isDark
                ? AddaColors.borderLuminousDark
                : AddaColors.borderLuminousLight,
            width: 1.2,
          ),
        );
        break;
      case AppButtonVariant.ghost:
        textColor = isDark
            ? AddaColors.textSecondaryDark
            : AddaColors.textSecondaryLight;
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: AddaRadius.radiusMd,
        );
        break;
      case AppButtonVariant.destructive:
        textColor = Colors.white;
        decoration = BoxDecoration(
          color: isEnabled
              ? AddaColors.rose
              : (isDark
                    ? AddaColors.surfaceElevatedDark
                    : AddaColors.surfaceElevatedLight),
          borderRadius: AddaRadius.radiusLg,
        );
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            widget.icon!,
            const SizedBox(width: AddaSpacing.sm),
          ],
          Text(
            widget.text,
            style: TextStyle(
              color: isEnabled
                  ? textColor
                  : (isDark
                        ? AddaColors.textMutedDark
                        : AddaColors.textMutedLight),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ],
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: isEnabled ? _onTapDown : null,
        onTapUp: isEnabled ? _onTapUp : null,
        onTapCancel: isEnabled ? _onTapCancel : null,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.isFullWidth ? double.infinity : widget.width,
          height: widget.height,
          padding:
              widget.padding ??
              const EdgeInsets.symmetric(horizontal: AddaSpacing.xl),
          decoration: decoration,
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.borderColor,
    this.size = 44,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        backgroundColor ??
        (isDark
            ? AddaColors.surfaceVariantDark
            : AddaColors.surfaceVariantLight);
    final border =
        borderColor ??
        (isDark ? AddaColors.borderDark : AddaColors.borderLight);

    Widget button = InkWell(
      onTap: () {
        if (onPressed != null) {
          HapticsService.lightTap();
          onPressed!();
        }
      },
      borderRadius: AddaRadius.radiusFull,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 1),
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
