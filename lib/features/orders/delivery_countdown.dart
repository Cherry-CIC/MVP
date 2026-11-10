/// Both delivery reminders show the same wall-clock deadline, rounded up to
/// the next whole second while the buyer still has time left.
extension DeliveryCountdown on Duration {
  int get _secondsLeft =>
      isNegative ? 0 : (inMicroseconds + Duration.microsecondsPerSecond - 1) ~/ Duration.microsecondsPerSecond;

  String get countdownText {
    final seconds = _secondsLeft;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(seconds ~/ 3600)}:${two(seconds ~/ 60 % 60)}:${two(seconds % 60)}';
  }

  String get spokenCountdown {
    final seconds = _secondsLeft;
    final hours = seconds ~/ 3600;
    final minutes = seconds ~/ 60 % 60;
    final units = [
      if (hours > 0) hours == 1 ? '1 hour' : '$hours hours',
      if (minutes > 0) minutes == 1 ? '1 minute' : '$minutes minutes',
    ];
    return units.isEmpty ? 'less than a minute' : units.join(' and ');
  }
}
