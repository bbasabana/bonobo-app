import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static void setupLocales() {
    timeago.setLocaleMessages('fr', ShortFrMessages());
    timeago.setLocaleMessages('fr_short', ShortFrMessages());
  }

  static String relative(DateTime date, {String locale = 'fr_short'}) {
    try {
      return timeago.format(date, locale: locale, allowFromNow: false);
    } catch (_) {
      return timeago.format(date, locale: 'en', allowFromNow: false);
    }
  }

  static String full(DateTime date) {
    return DateFormat('d MMMM yyyy', 'fr').format(date);
  }

  static String short(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr').format(date);
  }

  static String time(DateTime date) {
    return DateFormat('HH:mm', 'fr').format(date);
  }
}

enum TimeGroup {
  lessThanOneHour,
  oneToFourHours,
  fourToEightHours,
  eightHoursToTenDays,
  all,
}

extension TimeGroupLabel on TimeGroup {
  String get label {
    switch (this) {
      case TimeGroup.lessThanOneHour:
        return '< 1h';
      case TimeGroup.oneToFourHours:
        return '1h — 4h';
      case TimeGroup.fourToEightHours:
        return '4h — 8h';
      case TimeGroup.eightHoursToTenDays:
        return '+ ancien';
      case TimeGroup.all:
        return 'Tout';
    }
  }
}

TimeGroup getTimeGroup(DateTime publishedAt) {
  final now = DateTime.now();
  final diff = now.difference(publishedAt);

  if (diff.inMinutes < 60) return TimeGroup.lessThanOneHour;
  if (diff.inHours < 4) return TimeGroup.oneToFourHours;
  if (diff.inHours < 8) return TimeGroup.fourToEightHours;
  if (diff.inHours < 240) return TimeGroup.eightHoursToTenDays;
  return TimeGroup.eightHoursToTenDays;
}

class ShortFrMessages implements timeago.LookupMessages {
  @override String prefixAgo() => '';
  @override String prefixFromNow() => '';
  @override String suffixAgo() => '';
  @override String suffixFromNow() => '';
  @override String lessThanOneMinute(int seconds) => "maintenant";
  @override String aboutAMinute(int minutes) => "1 min";
  @override String minutes(int minutes) => "$minutes min";
  @override String aboutAnHour(int minutes) => "1h";
  @override String hours(int hours) => "${hours}h";
  @override String aDay(int hours) => "1j";
  @override String days(int days) => "${days}j";
  @override String aboutAMonth(int days) => "1m";
  @override String months(int months) => "${months}m";
  @override String aboutAYear(int year) => "1 an";
  @override String years(int years) => "${years} ans";
  @override String wordSeparator() => ' ';
}
