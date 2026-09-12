import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/radius.dart';
import '../../../../shared/design_system/tokens/spacing.dart';
import '../../../../shared/design_system/widgets/app_button.dart';
import '../../../../shared/design_system/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/space_model.dart';
import '../providers/space_provider.dart';

class CreateSpaceSheet extends ConsumerStatefulWidget {
  const CreateSpaceSheet({super.key});

  static Future<SpaceModel?> show(BuildContext context) {
    return showModalBottomSheet<SpaceModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreateSpaceSheet(),
    );
  }

  @override
  ConsumerState<CreateSpaceSheet> createState() => _CreateSpaceSheetState();
}

class _CreateSpaceSheetState extends ConsumerState<CreateSpaceSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  SpaceType _selectedType = SpaceType.friends;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final space = await ref
          .read(spacesProvider.notifier)
          .createSpace(
            name: name,
            type: _selectedType,
            description: _descController.text.trim(),
            ownerId: user.id,
          );
      if (mounted) {
        Navigator.of(context).pop(space);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AddaSpacing.xl,
        right: AddaSpacing.xl,
        top: AddaSpacing.lg,
        bottom: bottomInset + AddaSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: isDark ? AddaColors.surfaceDark : AddaColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AddaRadius.xl),
        ),
        border: Border.all(
          color: isDark
              ? AddaColors.borderLuminousDark
              : AddaColors.borderLuminousLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AddaColors.borderLuminousDark
                    : AddaColors.borderLuminousLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AddaSpacing.lg),
          Text(
            'Create New Space',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'A persistent hangout for your circle to talk, play, and stay connected.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AddaSpacing.lg),
          AppTextField(
            controller: _nameController,
            labelText: 'Space Name',
            hintText: 'e.g. Chai & Chill ☕️',
            autofocus: true,
          ),
          const SizedBox(height: AddaSpacing.md),
          AppTextField(
            controller: _descController,
            labelText: 'Description (optional)',
            hintText: 'What is this space for?',
          ),
          const SizedBox(height: AddaSpacing.lg),
          Text(
            'Room Type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AddaColors.textSecondaryDark
                  : AddaColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AddaSpacing.sm),
          Row(
            children: SpaceType.values.map((type) {
              final isSelected = type == _selectedType;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? type.color.withAlpha(35)
                          : (isDark
                                ? AddaColors.surfaceVariantDark
                                : AddaColors.surfaceVariantLight),
                      borderRadius: AddaRadius.radiusMd,
                      border: Border.all(
                        color: isSelected ? type.color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          type.icon,
                          color: isSelected
                              ? type.color
                              : (isDark ? Colors.white60 : Colors.black54),
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.displayName.split(' ')[0],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? type.color
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AddaSpacing.xxl),
          AppButton(
            text: 'Launch Space',
            isFullWidth: true,
            isLoading: _isLoading,
            onPressed: _handleCreate,
          ),
        ],
      ),
    );
  }
}
