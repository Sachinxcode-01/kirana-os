import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  static StockStatus fromQuantities(double current, double minAlert) {
    if (current <= 0) {
      return StockStatus.outOfStock;
    } else if (current <= minAlert) {
      return StockStatus.lowStock;
    }
    return StockStatus.inStock;
  }

  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'IN STOCK';
      case StockStatus.lowStock:
        return 'LOW STOCK';
      case StockStatus.outOfStock:
        return 'OUT OF STOCK';
    }
  }

  Color get badgeColor {
    switch (this) {
      case StockStatus.inStock:
        return KiranaColors.secondary;
      case StockStatus.lowStock:
        return KiranaColors.warning;
      case StockStatus.outOfStock:
        return KiranaColors.error;
    }
  }

  Color get containerColor {
    switch (this) {
      case StockStatus.inStock:
        return KiranaColors.secondaryContainer;
      case StockStatus.lowStock:
        return KiranaColors.warningContainer;
      case StockStatus.outOfStock:
        return KiranaColors.errorContainer;
    }
  }

  IconData get icon {
    switch (this) {
      case StockStatus.inStock:
        return Icons.check_circle_outline;
      case StockStatus.lowStock:
        return Icons.warning_amber_rounded;
      case StockStatus.outOfStock:
        return Icons.error_outline;
    }
  }
}
