import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// A frosted glass header with the LunaRae logo on the left
class FrostedHeader extends StatelessWidget {
  final String? title;
  final bool showBranding;
  final Widget? trailing;

  const FrostedHeader({
    super.key,
    this.title,
    this.showBranding = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: LunaTheme.cardColor(context).withOpacity(0.6),
            border: Border(
              bottom: BorderSide(
                color: LunaTheme.primary(context).withOpacity(0.15),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              if (showBranding) ...[
                // Logo on the left
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: LunaTheme.primary(context).withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/lunarae_icon_1024x1024.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title text (optional)
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: LunaTheme.appTitle(context).copyWith(
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              if (!showBranding) const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
