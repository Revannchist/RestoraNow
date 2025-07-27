import 'package:flutter/material.dart';

class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  String _getPasswordStrength(String password) {
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);

    if (password.length >= 10 && hasLetter && hasDigit) {
      return 'Strong';
    } else if (password.length >= 6 && hasLetter && hasDigit) {
      return 'Medium';
    } else {
      return 'Weak';
    }
  }

  Color _getStrengthColor(String strength) {
    switch (strength) {
      case 'Weak':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Strong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double _getStrengthValue(String strength) {
    switch (strength) {
      case 'Weak':
        return 0.3;
      case 'Medium':
        return 0.6;
      case 'Strong':
        return 1.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _getPasswordStrength(password);
    final color = _getStrengthColor(strength);
    final value = _getStrengthValue(strength);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(width: 12),
          Text(strength, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}