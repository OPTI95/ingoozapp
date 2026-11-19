import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Password-visibility toggle icon using the Figma SVGs:
/// open eye when the field is obscured ("tap to show"), slashed eye when
/// visible ("tap to hide").
class PasswordEyeIcon extends StatelessWidget {
  const PasswordEyeIcon({super.key, required this.obscured, this.size = 21});

  final bool obscured;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      obscured ? 'assets/svg/ic-eye.svg' : 'assets/svg/eye.svg',
      width: size,
      height: size,
    );
  }
}
