import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class CompletionCheckbox extends StatelessWidget {
  const CompletionCheckbox({
    required this.checked,
    required this.onTap,
    this.color,
    this.size = 24,
    super.key,
  });

  final bool checked;
  final VoidCallback onTap;

  final Color? color;

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return Semantics(
      checked: checked,
      label: checked ? 'Mark as not done' : 'Mark as done',
      child: InkResponse(
        onTap: onTap,
        radius: size,
        containedInkWell: false,
        child: AnimatedContainer(
          duration: AppMotion.strike,
          curve: AppMotion.strikeCurve,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: checked ? accent : Colors.transparent,
            border: Border.all(
              color: checked ? accent : scheme.outline,
              width: 2,
            ),
          ),
          child: AnimatedScale(
            duration: AppMotion.strike,
            curve: checked ? Curves.easeOutBack : Curves.easeIn,
            scale: checked ? 1 : 0,
            child: AnimatedOpacity(
              duration: AppMotion.quick,
              opacity: checked ? 1 : 0,
              child: Icon(
                Icons.check_rounded,
                size: size * 0.68,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
