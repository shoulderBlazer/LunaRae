import 'package:flutter/material.dart';

/// Font size options for the app
enum FontSizeOption {
  extraSmall,
  small,
  medium,
  large,
  extraLarge,
}

/// Provider to manage font size state globally
class FontSizeProvider extends ChangeNotifier {
  FontSizeOption _currentSize = FontSizeOption.medium;

  FontSizeOption get currentSize => _currentSize;

  /// Get the font scale factor based on current size
  double get scaleFactor {
    switch (_currentSize) {
      case FontSizeOption.extraSmall:
        return 0.8;
      case FontSizeOption.small:
        return 0.95;
      case FontSizeOption.medium:
        return 1.0;
      case FontSizeOption.large:
        return 1.25;
      case FontSizeOption.extraLarge:
        return 1.55;
    }
  }

  /// Get display name for current size
  String get currentSizeLabel {
    switch (_currentSize) {
      case FontSizeOption.extraSmall:
        return 'XS';
      case FontSizeOption.small:
        return 'Small';
      case FontSizeOption.medium:
        return 'Medium';
      case FontSizeOption.large:
        return 'Large';
      case FontSizeOption.extraLarge:
        return 'XL';
    }
  }

  /// Set the font size
  void setFontSize(FontSizeOption size) {
    if (_currentSize != size) {
      _currentSize = size;
      notifyListeners();
    }
  }

  /// Cycle to next font size
  void cycleNextSize() {
    switch (_currentSize) {
      case FontSizeOption.extraSmall:
        _currentSize = FontSizeOption.small;
        break;
      case FontSizeOption.small:
        _currentSize = FontSizeOption.medium;
        break;
      case FontSizeOption.medium:
        _currentSize = FontSizeOption.large;
        break;
      case FontSizeOption.large:
        _currentSize = FontSizeOption.extraLarge;
        break;
      case FontSizeOption.extraLarge:
        _currentSize = FontSizeOption.extraSmall;
        break;
    }
    notifyListeners();
  }

  /// Get icon for font size button
  static IconData get fontSizeIcon => Icons.text_fields;
}

/// Shows a font size selector popup
void showFontSizeSelector(BuildContext context, FontSizeProvider provider) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _FontSizeSelectorSheet(provider: provider),
  );
}

class _FontSizeSelectorSheet extends StatelessWidget {
  final FontSizeProvider provider;

  const _FontSizeSelectorSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1B3A) : Colors.white;
    final textColor = isDark ? const Color(0xFFF4F1E8) : const Color(0xFF2A2A2A);
    final primaryColor = isDark ? const Color(0xFFEBD9A3) : const Color(0xFFB9A8E5);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Text Size',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: FontSizeOption.values.map((option) {
                final isSelected = provider.currentSize == option;
                return _FontSizeOptionButton(
                  option: option,
                  isSelected: isSelected,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  backgroundColor: backgroundColor,
                  onTap: () {
                    provider.setFontSize(option);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FontSizeOptionButton extends StatelessWidget {
  final FontSizeOption option;
  final bool isSelected;
  final Color primaryColor;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _FontSizeOptionButton({
    required this.option,
    required this.isSelected,
    required this.primaryColor,
    required this.textColor,
    required this.backgroundColor,
    required this.onTap,
  });

  String get label => 'A';

  double get fontSize {
    switch (option) {
      case FontSizeOption.extraSmall:
        return 12;
      case FontSizeOption.small:
        return 16;
      case FontSizeOption.medium:
        return 20;
      case FontSizeOption.large:
        return 24;
      case FontSizeOption.extraLarge:
        return 28;
    }
  }

  String get sizeLabel {
    switch (option) {
      case FontSizeOption.extraSmall:
        return 'XS';
      case FontSizeOption.small:
        return 'S';
      case FontSizeOption.medium:
        return 'M';
      case FontSizeOption.large:
        return 'L';
      case FontSizeOption.extraLarge:
        return 'XL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : textColor.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: isSelected ? backgroundColor : textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sizeLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? backgroundColor : textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
