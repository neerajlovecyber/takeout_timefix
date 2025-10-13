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
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? AppColors.info,
        duration: duration ?? AppConstants.snackBarDuration,
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: AppColors.success,
    );
  }

  static void showWarningSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: AppColors.warning,
      duration: AppConstants.shortSnackBarDuration,
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message.length > 100 ? '${message.substring(0, min(100, message.length))}...' : message,
      backgroundColor: AppColors.error,
      duration: AppConstants.snackBarDuration,
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