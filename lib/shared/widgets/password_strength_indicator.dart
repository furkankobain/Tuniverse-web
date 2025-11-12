import 'package:flutter/material.dart';
import '../../core/utils/validation_utils.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool show;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!show || password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = ValidationUtils.calculatePasswordStrength(password);
    final label = ValidationUtils.getPasswordStrengthLabel(strength);
    final color = _getStrengthColor(strength);
    final progress = (strength / 4).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _getStrengthHint(strength),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.lightGreen;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStrengthHint(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Add uppercase, lowercase, numbers';
      case 2:
        return 'Good! Add special characters for better security';
      case 3:
        return 'Great! Consider making it longer';
      case 4:
        return 'Excellent! Your password is very strong';
      default:
        return '';
    }
  }
}
