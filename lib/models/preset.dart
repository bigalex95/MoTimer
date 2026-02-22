/// A timer preset with focus and break durations.
class TimerPreset {
  final String label;
  final int focusMinutes;
  final int breakMinutes;

  const TimerPreset({
    required this.label,
    required this.focusMinutes,
    required this.breakMinutes,
  });

  /// Built-in presets.
  static const List<TimerPreset> defaults = [
    TimerPreset(label: 'Pomodoro', focusMinutes: 25, breakMinutes: 5),
    TimerPreset(label: 'Long Focus', focusMinutes: 50, breakMinutes: 10),
  ];
}
