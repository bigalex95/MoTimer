import 'dart:async';
import 'package:flutter/foundation.dart';

/// Possible states of the timer.
enum TimerState { idle, running, paused }

/// Possible session types.
enum SessionType { focus, shortBreak }

/// A ChangeNotifier-based timer service.
///
/// Manages countdown logic with 1-second ticks, supports start/pause/resume/reset,
/// and tracks focus vs break sessions.
class TimerService extends ChangeNotifier {
  Timer? _timer;
  TimerState _state = TimerState.idle;
  SessionType _sessionType = SessionType.focus;

  int _totalSeconds = 25 * 60; // default 25 min
  int _remainingSeconds = 25 * 60;
  int _completedSessions = 0;

  // Original durations stored for session transitions
  int _focusSeconds = 25 * 60;
  int _breakSeconds = 5 * 60;

  // ── Getters ──────────────────────────────────────────

  TimerState get state => _state;
  SessionType get sessionType => _sessionType;
  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;
  int get completedSessions => _completedSessions;

  double get progress =>
      _totalSeconds > 0 ? 1.0 - (_remainingSeconds / _totalSeconds) : 0.0;

  String get displayMinutes =>
      (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
  String get displaySeconds =>
      (_remainingSeconds % 60).toString().padLeft(2, '0');

  bool get isIdle => _state == TimerState.idle;
  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;

  // ── Configuration ────────────────────────────────────

  /// Sets the focus and break duration (in minutes). Resets the timer.
  void setDurations({required int focusMinutes, required int breakMinutes}) {
    _totalSeconds = focusMinutes * 60;
    _focusSeconds = _totalSeconds;
    _breakSeconds = breakMinutes * 60;
    reset();
  }

  /// Quick-set from preset index or custom value.
  void setFocusDuration(int minutes) {
    _totalSeconds = minutes * 60;
    _focusSeconds = _totalSeconds;
    reset();
  }

  // ── Controls ─────────────────────────────────────────

  void start() {
    if (_state == TimerState.running) return;
    _state = TimerState.running;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  void pause() {
    if (_state != TimerState.running) return;
    _timer?.cancel();
    _state = TimerState.paused;
    notifyListeners();
  }

  void resume() {
    if (_state != TimerState.paused) return;
    start();
  }

  void reset() {
    _timer?.cancel();
    _state = TimerState.idle;
    _sessionType = SessionType.focus;
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  // ── Callbacks ────────────────────────────────────────

  /// Called when a session (focus or break) finishes.
  VoidCallback? onSessionComplete;

  // ── Internals ────────────────────────────────────────

  void _tick(Timer timer) {
    if (_remainingSeconds <= 0) {
      _timer?.cancel();
      _state = TimerState.idle;

      if (_sessionType == SessionType.focus) {
        _completedSessions++;
        // Switch to break
        _sessionType = SessionType.shortBreak;
        _totalSeconds = _breakSeconds;
        _remainingSeconds = _breakSeconds;
      } else {
        // Break finished → back to focus
        _sessionType = SessionType.focus;
        _totalSeconds = _focusSeconds;
        _remainingSeconds = _totalSeconds;
      }

      onSessionComplete?.call();
      notifyListeners();
      return;
    }

    _remainingSeconds--;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
