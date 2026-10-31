import '../../../medications/domain/entities/medication.dart';

enum StockLevel { ok, low, out }

StockLevel stockLevelOf(Medication m) =>
    m.isOutOfStock ? StockLevel.out : (m.isLowStock ? StockLevel.low : StockLevel.ok);

/// Pure rule: which alert (if any) is due now?
///  - ok            -> never
///  - same as last  -> never (no repeats)
///  - out           -> always (escalation from low is important)
///  - low after out -> never (partial refill, not worth another alert)
///  - low           -> alert
StockLevel? stockAlertDue({required StockLevel current, required StockLevel? lastAlerted}) {
  if (current == StockLevel.ok) return null;
  if (lastAlerted == current) return null;
  if (current == StockLevel.out) return StockLevel.out;
  if (lastAlerted == StockLevel.out) return null;
  return StockLevel.low;
}
