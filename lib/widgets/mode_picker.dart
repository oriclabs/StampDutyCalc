import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/user_mode_provider.dart';

class ModePicker extends StatelessWidget {
  final UserMode selected;
  final ValueChanged<UserMode> onChanged;

  const ModePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: UserMode.values.map((mode) {
        return _ModeCard(
          mode: mode,
          isSelected: selected == mode,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(mode);
          },
        );
      }).toList(),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final UserMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    mode.icon,
                    size: 40,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mode.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8)
                          : theme.colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
