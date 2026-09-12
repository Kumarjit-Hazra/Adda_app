import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';
import '../../domain/models/space_model.dart';
import '../providers/space_provider.dart';

class JoinSpaceDialog extends ConsumerStatefulWidget {
  const JoinSpaceDialog({super.key});

  static Future<SpaceModel?> show(BuildContext context) {
    return showDialog<SpaceModel>(
      context: context,
      builder: (ctx) => const JoinSpaceDialog(),
    );
  }

  @override
  ConsumerState<JoinSpaceDialog> createState() => _JoinSpaceDialogState();
}

class _JoinSpaceDialogState extends ConsumerState<JoinSpaceDialog> {
  final _codeController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(spaceRepositoryProvider);
    final space = await repo.getSpaceByInviteCode(code);

    if (mounted) {
      if (space != null) {
        Navigator.of(context).pop(space);
      } else {
        setState(() {
          _errorMessage =
              'No Space found with code "$code". Please check and try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark
          ? AddaColors.surfaceDark
          : AddaColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: AddaRadius.radiusXl),
      child: Padding(
        padding: const EdgeInsets.all(AddaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AddaColors.coral.withAlpha(25),
                    borderRadius: AddaRadius.radiusMd,
                  ),
                  child: const Icon(
                    Icons.group_add_rounded,
                    color: AddaColors.coral,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AddaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Space',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        'Enter 6-character code',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AddaSpacing.lg),
            AppTextField(
              controller: _codeController,
              hintText: 'e.g. CHAI29',
              autofocus: true,
              onSubmitted: (_) => _handleJoin(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AddaSpacing.sm),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AddaColors.rose, fontSize: 12),
              ),
            ],
            const SizedBox(height: AddaSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.ghost(
                  text: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AddaSpacing.sm),
                AppButton(
                  text: 'Join',
                  isLoading: _isLoading,
                  onPressed: _handleJoin,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
