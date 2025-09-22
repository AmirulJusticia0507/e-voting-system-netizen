import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isLoading;
  final bool useGradient;
  final List<Color>? gradientColors;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.isLoading = false,
    this.useGradient = false,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? const SizedBox(
              key: ValueKey("loading"),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              text,
              key: ValueKey("text"),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor ?? Colors.white,
              ),
            ),
    );

    if (useGradient) {
      // 🔹 Tombol dengan Gradient
      return SizedBox(
        width: width ?? double.infinity,
        height: height ?? 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors ??
                  [Theme.of(context).primaryColor, Colors.deepPurple],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
            child: buttonChild,
          ),
        ),
      );
    } else {
      // 🔹 Tombol Normal dengan warna solid
      return SizedBox(
        width: width ?? double.infinity,
        height: height ?? 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Theme.of(context).primaryColor,
            foregroundColor: textColor ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: 4, // ada shadow
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
          onPressed: isLoading ? null : onPressed,
          child: buttonChild,
        ),
      );
    }
  }
}
