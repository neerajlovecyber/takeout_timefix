import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'app_constants.dart';

class UIHelpers {
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration? duration,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: Theme.of(context).colorScheme.onInverseSurface,
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.inverseSurface,
        duration: duration ?? AppConstants.snackBarDuration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.primary,
      icon: Icons.check_circle,
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      duration: AppConstants.shortSnackBarDuration,
      icon: Icons.warning,
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    final truncatedMessage = message.length > 100 
      ? '${message.substring(0, min(100, message.length))}...' 
      : message;
    
    showSnackBar(
      context,
      truncatedMessage,
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: AppConstants.snackBarDuration,
      icon: Icons.error,
    );
  }

  static String truncateMessage(String message, {int maxLength = 100}) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, min(maxLength, message.length))}...';
  }

  static IconData getStatusIcon(bool isValid, bool hasPermissions) {
    if (isValid && hasPermissions) {
      return Icons.check_circle;
    } else if (isValid && !hasPermissions) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  static Color getStatusColor(bool isValid, bool hasPermissions) {
    if (isValid && hasPermissions) {
      return AppColors.success;
    } else if (isValid && !hasPermissions) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  static String getStatusText(bool isValid, bool hasPermissions) {
    if (isValid && hasPermissions) {
      return '✅ Ready for processing';
    } else if (isValid && !hasPermissions) {
      return '⚠️ No write permissions';
    } else {
      return '❌ Invalid folder';
    }
  }
}

class PathUtils {
  static String getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  static String getParentDirectory(String path) {
    final parts = path.split(Platform.pathSeparator);
    if (parts.length <= 1) return '';
    return parts.sublist(0, parts.length - 1).join(Platform.pathSeparator);
  }

  static bool isValidPath(String path) {
    try {
      return path.isNotEmpty && Directory(path).existsSync();
    } catch (e) {
      return false;
    }
  }
}