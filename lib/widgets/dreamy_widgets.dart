import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// A dreamy gradient background that adapts to light/dark mode
class DreamyBackground extends StatelessWidget {
  final Widget child;
  
  const DreamyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LunaTheme.backgroundGradient(context),
      child: child,
    );
  }
}

/// Story card with dreamy styling, glow shadow, and rounded corners
class DreamyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  
  const DreamyCard({
    super.key, 
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(LunaTheme.cardPadding),
      decoration: BoxDecoration(
        color: LunaTheme.cardColor(context),
        borderRadius: BorderRadius.circular(LunaTheme.radiusCard),
        boxShadow: LunaTheme.cardShadow(context),
      ),
      child: child,
    );
  }
}

/// Primary button with gradient and scale animation
class DreamyPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool compact;
  
  const DreamyPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.compact = false,
  });

  @override
  State<DreamyPrimaryButton> createState() => _DreamyPrimaryButtonState();
}

class _DreamyPrimaryButtonState extends State<DreamyPrimaryButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = LunaTheme.isDarkMode(context);
    
    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading 
          ? (_) => _controller.forward() 
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading 
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            } 
          : null,
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: widget.compact ? 12 : 18, 
            horizontal: widget.compact ? 16 : 24,
          ),
          decoration: BoxDecoration(
            gradient: LunaTheme.buttonGradient(context),
            borderRadius: BorderRadius.circular(LunaTheme.radiusButton),
            boxShadow: [
              BoxShadow(
                color: LunaTheme.primary(context).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? _MoonLoadingIndicator(isDark: isDark)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: isDark ? LunaTheme.darkCard : LunaTheme.lightCard,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.text,
                          style: LunaTheme.buttonText(context),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Secondary button with softer styling
class DreamySecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  
  const DreamySecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  @override
  State<DreamySecondaryButton> createState() => _DreamySecondaryButtonState();
}

class _DreamySecondaryButtonState extends State<DreamySecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = LunaTheme.isDarkMode(context);
    
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LunaTheme.secondaryButtonGradient(context),
            borderRadius: BorderRadius.circular(LunaTheme.radiusButton),
            border: Border.all(
              color: LunaTheme.secondary(context).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: LunaTheme.textPrimary(context),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: LunaTheme.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: LunaTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dreamy pill-shaped input field
class DreamyInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final VoidCallback? onSubmitted;
  
  const DreamyInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLines = 3,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LunaTheme.inputBackground(context),
        borderRadius: BorderRadius.circular(
          maxLines > 1 ? 20 : LunaTheme.radiusInput,
        ),
        border: Border.all(
          color: LunaTheme.primary(context).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textInputAction:
            onSubmitted != null ? TextInputAction.done : TextInputAction.newline,
        keyboardType:
            onSubmitted != null ? TextInputType.text : TextInputType.multiline,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
        style: LunaTheme.body(context).copyWith(
          color: LunaTheme.textPrimary(context),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: LunaTheme.hintText(context),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, 
            vertical: 16,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

/// Slow spinning moon/star loading indicator
class _MoonLoadingIndicator extends StatefulWidget {
  final bool isDark;
  
  const _MoonLoadingIndicator({required this.isDark});

  @override
  State<_MoonLoadingIndicator> createState() => _MoonLoadingIndicatorState();
}

class _MoonLoadingIndicatorState extends State<_MoonLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.nightlight_round,
        color: widget.isDark ? LunaTheme.darkCard : LunaTheme.lightCard,
        size: 24,
      ),
    );
  }
}

/// Standalone moon loading indicator for use elsewhere
class MoonLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  
  const MoonLoadingIndicator({
    super.key, 
    this.size = 40,
    this.color,
  });

  @override
  State<MoonLoadingIndicator> createState() => _MoonLoadingIndicatorPublicState();
}

class _MoonLoadingIndicatorPublicState extends State<MoonLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.nightlight_round,
        color: widget.color ?? LunaTheme.primary(context),
        size: widget.size,
      ),
    );
  }
}

/// App title with optional moon/star icon and glow effect
class LunaRaeTitle extends StatelessWidget {
  const LunaRaeTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = LunaTheme.isDarkMode(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Moon icon with glow in dark mode
        Container(
          padding: const EdgeInsets.all(8),
          decoration: isDark
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: LunaTheme.darkPrimary.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                )
              : null,
          child: Icon(
            isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
            color: LunaTheme.primary(context),
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        // Title text with glow in dark mode
        Text(
          'LunaRae',
          style: LunaTheme.appTitle(context).copyWith(
            shadows: isDark
                ? [
                    Shadow(
                      color: LunaTheme.darkPrimary.withOpacity(0.6),
                      blurRadius: 20,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

/// Fade and slide transition for page navigation
class DreamyPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  
  DreamyPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.05);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            var fadeTween = Tween(begin: 0.0, end: 1.0);

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: SlideTransition(
                position: animation.drive(tween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}
