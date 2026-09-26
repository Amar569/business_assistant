import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final IconData? icon;
  final Size? size;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.icon,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: color ?? theme.primaryColor,
            side: BorderSide(color: color ?? theme.primaryColor),
            minimumSize: size ?? const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color ?? theme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: size ?? const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );

    return isLoading
        ? ElevatedButton(
            onPressed: null,
            style: buttonStyle,
            child: const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          )
        : isOutlined
            ? OutlinedButton(
                onPressed: onPressed,
                style: buttonStyle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(text),
                  ],
                ),
              )
            : ElevatedButton(
                onPressed: onPressed,
                style: buttonStyle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(text),
                  ],
                ),
              );
  }
}
