import 'package:intl/intl.dart';

/// Immutable representation of money in integer Paise (1 INR = 100 Paise).
/// Strictly eliminates IEEE 754 floating-point inaccuracies in financial transactions.
final class Money implements Comparable<Money> {
  /// Amount in integer Paise (e.g. 1050 for ₹10.50)
  final int paise;

  const Money._(this.paise);

  /// Creates a [Money] instance from integer paise.
  const Money.fromPaise(int paise) : this._(paise);

  /// Creates a [Money] instance from rupees (converts to paise using exact rounding).
  factory Money.fromRupees(num rupees) {
    return Money._((rupees * 100).round());
  }

  /// Zero amount instance.
  static const Money zero = Money._(0);

  /// Converts paise to rupees as a double for presentation/calculations.
  double get inRupees => paise / 100.0;

  Money operator +(Money other) => Money._(paise + other.paise);
  Money operator -(Money other) => Money._(paise - other.paise);
  Money operator *(num multiplier) => Money._((paise * multiplier).round());
  Money operator /(num divisor) {
    if (divisor == 0) throw ArgumentError('Cannot divide money by zero.');
    return Money._((paise / divisor).round());
  }

  bool operator <(Money other) => paise < other.paise;
  bool operator <=(Money other) => paise <= other.paise;
  bool operator >(Money other) => paise > other.paise;
  bool operator >=(Money other) => paise >= other.paise;

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && runtimeType == other.runtimeType && paise == other.paise;

  @override
  int get hashCode => paise.hashCode;

  /// Formats the money into standard Indian Rupee notation (e.g., ₹1,450.50 or ₹14.00).
  String format({bool includeSymbol = true}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: includeSymbol ? '₹' : '',
      decimalDigits: 2,
    );
    return formatter.format(inRupees).trim();
  }

  @override
  String toString() => format();
}
