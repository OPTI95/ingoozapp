import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// AppBar back button using the Figma `ic-back` arrow instead of the
/// default Material chevron.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: SvgPicture.asset('assets/svg/ic-back.svg', width: 24, height: 24),
      onPressed: () => Navigator.of(context).maybePop(),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}
