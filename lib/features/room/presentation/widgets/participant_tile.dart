import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/widgets/app_avatar.dart';
import '../../../../shared/design_system/widgets/speaking_indicator.dart';
import '../../domain/models/participant.dart';

class ParticipantTile extends StatelessWidget {
  final Participant participant;
  final bool isLocal;
  final VoidCallback? onTap;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.isLocal = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: participant.isSpeaking
              ? AddaColors.emerald.withAlpha(25)
              : (isDark
                    ? AddaColors.surfaceVariantDark
                    : AddaColors.surfaceVariantLight),
          borderRadius: AddaRadius.radiusLg,
          border: Border.all(
            color: participant.isSpeaking
                ? AddaColors.emerald
                : (isDark ? AddaColors.borderDark : AddaColors.borderLight),
            width: participant.isSpeaking ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(
              name: participant.name,
              avatarUrl: participant.avatarUrl,
              size: 34,
              isSpeaking: participant.isSpeaking,
              isOnline: true,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLocal ? 'You' : participant.name.split(' ')[0],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AddaColors.textPrimaryDark
                            : AddaColors.textPrimaryLight,
                      ),
                    ),
                    if (participant.isHost) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AddaColors.amber,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (participant.isMuted)
                      const Icon(
                        Icons.mic_off_rounded,
                        size: 12,
                        color: AddaColors.rose,
                      )
                    else if (participant.isSpeaking)
                      SpeakingIndicator(isSpeaking: true, height: 10)
                    else
                      Text(
                        '${participant.pingMs}ms',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AddaColors.textMutedDark
                              : AddaColors.textMutedLight,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
