import 'package:flutter/material.dart';

class PasscodeIndicator extends StatelessWidget {
  final int passcodeLength;
  const PasscodeIndicator({super.key, required this.passcodeLength});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < passcodeLength
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.primary, width: 2),
          ),
        );
      }),
    );
  }
}

class NumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDeletePressed;

  const NumericKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
      ),
      itemCount: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        if (index == 9) return const SizedBox.shrink(); // Empty space
        if (index == 11) {
          return KeypadButton(
            child: Icon(Icons.backspace_outlined,
                color: theme.textTheme.bodyLarge?.color),
            onPressed: onDeletePressed,
          );
        }
        final number = index == 10 ? '0' : (index + 1).toString();
        return KeypadButton(
          child: Text(
            number,
            style: theme.textTheme.headlineMedium,
          ),
          onPressed: () => onNumberPressed(number),
        );
      },
    );
  }
}

class KeypadButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const KeypadButton({super.key, required this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40),
      child: Center(child: child),
    );
  }
}
