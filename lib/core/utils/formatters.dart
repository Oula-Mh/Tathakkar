import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Locale-aware formatting (Arabic digits in Arabic, Latin in English).
abstract final class Fmt {
  static String minutesToTime(BuildContext context, int minutes) {
    final locale = Localizations.localeOf(context).languageCode;
    final dt = DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60);
    return DateFormat.jm(locale).format(dt);
  }

  static String time(BuildContext context, DateTime dt) =>
      DateFormat.jm(Localizations.localeOf(context).languageCode).format(dt);

  static String date(BuildContext context, DateTime dt) =>
      DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(dt);

  static String dayHeader(BuildContext context, DateTime dt) =>
      DateFormat.MMMMEEEEd(Localizations.localeOf(context).languageCode)
          .format(dt);

  static String monthYear(BuildContext context, DateTime dt) =>
      DateFormat.yMMMM(Localizations.localeOf(context).languageCode).format(dt);

  static String number(BuildContext context, num n) =>
      NumberFormat.decimalPattern(Localizations.localeOf(context).languageCode)
          .format(n);
}

extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);
  bool isSameDay(DateTime o) => year == o.year && month == o.month && day == o.day;
}

extension MinutesX on int {
  /// minutes-of-day -> DateTime on [day].
  DateTime onDay(DateTime day) =>
      DateTime(day.year, day.month, day.day, this ~/ 60, this % 60);
}
