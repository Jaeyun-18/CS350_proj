import 'package:flutter/material.dart';

class AuthVisuals {
  static const Color pageTop = Color(0xFFF7FFF9);
  static const Color pageBottom = Color(0xFFE1F6E8);
  static const Color cardBorder = Color(0xFFE2F0E6);
  static const Color fieldFill = Color(0xFFF4FAF5);
  static const Color fieldHint = Color(0xFFAABCAA);
  static const Color label = Color(0xFF6B7B6B);
  static const Color text = Color(0xFF0F1A0F);
  static const Color subtleText = Color(0xFF647B6A);
  static const Color muted = Color(0xFF9BB89E);
  static const Color success = Color(0xFF22C55E);
  static const Color divider = Color(0xFFE8F0E8);
  static const Color accentLight = Color(0xFFF0FAF4);
  static const Color accentDark = Color(0xFF22C55E);
  static const Color accentDeep = Color(0xFF16A34A);

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pageTop, pageBottom],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accentDark],
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: cardBorder),
    boxShadow: const [
      BoxShadow(
        color: Color(0x12000000),
        blurRadius: 30,
        offset: Offset(0, 16),
      ),
    ],
  );

  static BoxDecoration fieldDecoration = BoxDecoration(
    color: fieldFill,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: cardBorder, width: 1.4),
  );

  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      helperMaxLines: 2,
      filled: true,
      fillColor: fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      prefixIcon: prefixIcon == null
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(start: 14, end: 10),
              child: prefixIcon,
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cardBorder, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cardBorder, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: success, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.8),
      ),
      labelStyle: const TextStyle(
        color: label,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      ),
      hintStyle: const TextStyle(color: fieldHint),
      helperStyle: const TextStyle(color: muted),
    );
  }

  static TextStyle sectionLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
      color: label,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.9,
    );
  }

  static TextStyle titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
      color: text,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    );
  }

  static TextStyle subtitleStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: subtleText, height: 1.45);
  }
}

class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingIcon = Icons.diversity_3_outlined,
    this.small = false,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final badgeSize = small ? 42.0 : 50.0;
    final iconSize = small ? 22.0 : 26.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(small ? 14 : 18),
            gradient: AuthVisuals.primaryGradient,
          ),
          child: Icon(leadingIcon, color: Colors.white, size: iconSize),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AuthVisuals.text,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                fontSize: small ? 24 : 30,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AuthVisuals.label,
                height: 1.35,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AuthGradientButton extends StatelessWidget {
  const AuthGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? AuthVisuals.primaryGradient
              : LinearGradient(
                  colors: [
                    AuthVisuals.accentDark.withValues(alpha: 0.4),
                    AuthVisuals.accentDeep.withValues(alpha: 0.35),
                  ],
                ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x2222C55E),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AuthVisuals.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AuthVisuals.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AuthVisuals.divider, height: 1)),
      ],
    );
  }
}
