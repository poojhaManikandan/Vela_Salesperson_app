/// GST Calculator utilities — Dart port of the Python reference implementation.
///
/// Mirrors the exact rounding behaviour of Python's:
///   Decimal(str(value)) * Decimal(str(rate)) / Decimal("100")
///   .quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
library gst_calculator;

class GSTCalculator {
  GSTCalculator._();

  /// CGST = taxable_value * cgst_rate / 100, rounded half-up to 2 dp.
  static double cgst(double taxableValue, {double rate = 2.5}) {
    if (taxableValue < 0 || rate < 0) {
      throw ArgumentError('Taxable value and rate must be non-negative');
    }
    return _roundHalfUp(taxableValue * rate / 100.0);
  }

  /// SGST = taxable_value * sgst_rate / 100, rounded half-up to 2 dp.
  static double sgst(double taxableValue, {double rate = 2.5}) {
    if (taxableValue < 0 || rate < 0) {
      throw ArgumentError('Taxable value and rate must be non-negative');
    }
    return _roundHalfUp(taxableValue * rate / 100.0);
  }

  /// Total GST (CGST + SGST). Both are calculated independently then summed.
  static double totalGst(double taxableValue,
      {double cgstRate = 2.5, double sgstRate = 2.5}) {
    return cgst(taxableValue, rate: cgstRate) +
        sgst(taxableValue, rate: sgstRate);
  }

  /// Rounds [value] to 2 decimal places using ROUND_HALF_UP semantics,
  /// matching Python's Decimal(…).quantize(Decimal("0.01"), ROUND_HALF_UP).
  static double _roundHalfUp(double value) {
    // Multiply by 100, add 0.5, floor, divide back — gives ROUND_HALF_UP.
    return (value * 100 + 0.5).floor() / 100.0;
  }
}
