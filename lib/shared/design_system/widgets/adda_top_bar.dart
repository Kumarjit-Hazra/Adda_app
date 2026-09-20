import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/profile/presentation/widgets/adda_identity_sheet.dart';
import '../../../../features/room/presentation/providers/room_provider.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';
import 'app_avatar.dart';

/// Reusable top navigation bar providing branding, guest identity pill,
/// and live presence indicator across ADDA primary shells.
class AddaTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? contextTitle;
  final String? contextBadge;
  final Color? badgeColor;
  final List<Widget>? actions;
  final bool showIdentityPill;
  final VoidCallback? onIdentityTap;
  final PreferredSizeWidget? bottom;

  const AddaTopBar({
    super.key,
    this.contextTitle,
    this.contextBadge,
    this.badgeColor,
    this.actions,
    this.showIdentityPill = true,
    this.onIdentityTap,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  void _handleIdentityTap(BuildContext context) {
    if (onIdentityTap != null) {
      onIdentityTap!();
    } else {
      AddaIdentitySheet.show(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);
    final activeRoom = ref.watch(roomProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget? leadingContent;
    if (showIdentityPill) {
      leadingContent = userAsync.maybeWhen(
        data: (user) => GestureDetector(
          onTap: () => _handleIdentityTap(context),
          child: Container(
            margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? AddaColors.surfaceElevatedDark.withAlpha(200)
                  : AddaColors.surfaceLight,
              borderRadius: AddaRadius.radiusFull,
              border: Border.all(
                color: isDark ? AddaColors.borderDark : AddaColors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppAvatar(
                  name: user.name,
                  avatarSeed: user.avatarSeed,
                  size: 24,
                  isOnline: true,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AddaColors.amber.withAlpha(35),
                    borderRadius: AddaRadius.radiusXs,
                  ),
                  child: const Text(
                    'GUEST',
                    style: TextStyle(
                      color: AddaColors.amber,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        orElse: () => const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Center/Title Content
    Widget titleContent;
    if (contextTitle != null) {
      titleContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (contextBadge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: (badgeColor ?? AddaColors.coral).withAlpha(35),
                borderRadius: AddaRadius.radiusSm,
              ),
              child: Text(
                contextBadge!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: badgeColor ?? AddaColors.coral,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            contextTitle!,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      );
    } else {
      // Default ADDA Branding
      titleContent = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AddaColors.coral.withAlpha(20),
          borderRadius: AddaRadius.radiusFull,
          border: Border.all(color: AddaColors.coral.withAlpha(60), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('☕️', style: TextStyle(fontSize: 12)),
            SizedBox(width: 5),
            Text(
              'ADDA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AddaColors.coral,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Action items
    final List<Widget> actionItems = [];

    // Active Room floating pill if in voice session
    if (activeRoom != null) {
      actionItems.add(
        GestureDetector(
          onTap: () => context.push(
            '/space/${activeRoom.spaceId}/room',
            extra: activeRoom.spaceName,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AddaColors.emerald.withAlpha(35),
              borderRadius: AddaRadius.radiusFull,
              border: Border.all(color: AddaColors.emerald.withAlpha(120)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AddaColors.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(
                    activeRoom.spaceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AddaColors.emerald,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (actions != null) {
      actionItems.addAll(actions!);
    } else {
      // Default identity sheet / settings trigger
      actionItems.add(
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 20),
          tooltip: 'Identity & Preferences',
          onPressed: () => _handleIdentityTap(context),
        ),
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      titleSpacing: showIdentityPill ? 4 : NavigationToolbar.kMiddleSpacing,
      leadingWidth: showIdentityPill ? 140 : null,
      leading: leadingContent,
      title: titleContent,
      centerTitle: true,
      actions: actionItems,
      bottom: bottom,
    );
  }
}
