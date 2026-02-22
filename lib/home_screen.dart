import 'dart:math';
import 'package:flutter/material.dart';
import 'models/preset.dart';
import 'services/timer_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'services/dnd_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final SettingsService settings;

  const HomeScreen({super.key, required this.settings});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TimerService _timer;
  int _selectedPresetIndex = 0;
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    _timer = TimerService();
    _timer.setDurations(
      focusMinutes: widget.settings.defaultDuration,
      breakMinutes: widget.settings.breakDuration,
    );
    _timer.onSessionComplete = _onSessionComplete;
    _timer.addListener(_onTimerTick);
  }

  void _onTimerTick() {
    if (mounted) setState(() {});
  }

  void _onSessionComplete() {
    if (!mounted) return;

    // The session type has already switched by the time this callback fires,
    // so shortBreak means we just finished a focus session.
    final justFinishedFocus = _timer.sessionType == SessionType.shortBreak;

    // Show local notification
    if (widget.settings.soundEnabled) {
      NotificationService.instance
          .showTimerComplete(isFocusComplete: justFinishedFocus);
    }

    // Turn off DND now that the session ended
    if (widget.settings.dndEnabled) {
      DndService.instance.setDnd(false);
    }

    // Still show a snackbar for in-app feedback
    final msg = justFinishedFocus
        ? 'Focus complete! Take a break 🎉'
        : 'Break over — time to focus! 💪';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _selectPreset(int index) {
    final preset = TimerPreset.defaults[index];
    _timer.setDurations(
      focusMinutes: preset.focusMinutes,
      breakMinutes: preset.breakMinutes,
    );
    setState(() {
      _selectedPresetIndex = index;
      _isCustom = false;
    });
  }

  void _showCustomDurationPicker() async {
    int minutes = widget.settings.defaultDuration;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int selected = minutes;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Custom Duration'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$selected min',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Slider(
                    value: selected.toDouble(),
                    min: 1,
                    max: 120,
                    divisions: 119,
                    label: '$selected min',
                    onChanged: (v) =>
                        setDialogState(() => selected = v.round()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, selected),
                    child: const Text('Set')),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      _timer.setDurations(focusMinutes: result, breakMinutes: 5);
      setState(() => _isCustom = true);
    }
  }

  @override
  void dispose() {
    _timer.removeListener(_onTimerTick);
    _timer.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.timer, color: colorScheme.primary, size: 28),
            const SizedBox(width: 8),
            Text('MoTimer',
                style: TextStyle(
                    color: colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(settings: widget.settings),
                ),
              );
              // After returning, apply new defaults if timer is idle
              if (_timer.isIdle && !_isCustom) {
                _timer.setDurations(
                  focusMinutes: widget.settings.defaultDuration,
                  breakMinutes: widget.settings.breakDuration,
                );
              }
              setState(() {});
            },
          ),

        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Welcome ──────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Ready to focus!',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 4),

            // ── Session type label ───────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Chip(
                key: ValueKey(_timer.sessionType),
                label: Text(
                  _timer.sessionType == SessionType.focus
                      ? '🎯 Focus'
                      : '☕ Break',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                backgroundColor: _timer.sessionType == SessionType.focus
                    ? colorScheme.primaryContainer
                    : colorScheme.tertiaryContainer,
              ),
            ),

            // ── Timer ring ───────────────────────────
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background ring
                      SizedBox.expand(
                        child: CustomPaint(
                          painter: _TimerRingPainter(
                            progress: _timer.progress,
                            trackColor:
                                colorScheme.surfaceContainerHighest,
                            progressColor: _timer.isRunning
                                ? colorScheme.primary
                                : colorScheme.outline,
                            strokeWidth: 12,
                          ),
                        ),
                      ),
                      // Time display
                      Semantics(
                        label: '${_timer.displayMinutes} minutes and ${_timer.displaySeconds} seconds remaining.',
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_timer.displayMinutes}:${_timer.displaySeconds}',
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w300,
                                letterSpacing: 4,
                                color: colorScheme.onSurface,
                                fontFeatures: [
                                  const FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            if (_timer.completedSessions > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${_timer.completedSessions} session${_timer.completedSessions > 1 ? 's' : ''} done',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Controls ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reset
                  _ControlButton(
                    icon: Icons.stop_rounded,
                    label: 'Reset',
                    onPressed:
                        _timer.isIdle
                            ? null
                            : () {
                                if (widget.settings.dndEnabled) {
                                  DndService.instance.setDnd(false);
                                }
                                _timer.reset();
                              },
                    color: colorScheme.error,
                  ),
                  // Start / Pause
                  _ControlButton(
                    icon: _timer.isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    label: _timer.isRunning ? 'Pause' : 'Start',
                    onPressed: () {
                      if (_timer.isRunning) {
                        _timer.pause();
                      } else if (_timer.isPaused) {
                        _timer.resume();
                      } else {
                        // Starting a new session
                        if (widget.settings.dndEnabled) {
                          DndService.instance.setDnd(true);
                        }
                        _timer.start();
                      }
                    },
                    color: colorScheme.primary,
                    isPrimary: true,
                  ),
                  // Skip (to break or next focus)
                  _ControlButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Skip',
                    onPressed: _timer.isIdle
                        ? null
                        : () {
                            _timer.reset();
                            _onSessionComplete();
                          },
                    color: colorScheme.tertiary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Presets ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(TimerPreset.defaults.length, (i) {
                    final preset = TimerPreset.defaults[i];
                    final isSelected = !_isCustom && _selectedPresetIndex == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('${preset.focusMinutes}/${preset.breakMinutes}'),
                        selected: isSelected,
                        onSelected: _timer.isIdle
                            ? (_) => _selectPreset(i)
                            : null,
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      label: Text(_isCustom ? 'Custom ✓' : 'Custom'),
                      avatar: const Icon(Icons.tune, size: 18),
                      onPressed:
                          _timer.isIdle ? _showCustomDurationPicker : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Control Button ─────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool isPrimary;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isPrimary ? 72.0 : 56.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Material(
            color: onPressed != null
                ? (isPrimary ? color : color.withValues(alpha: 0.12))
                : Colors.grey.withValues(alpha: 0.1),
            shape: const CircleBorder(),
            elevation: isPrimary ? 4 : 0,
            child: Tooltip(
              message: label,
              child: InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: Icon(
                  icon,
                  size: isPrimary ? 36 : 28,
                  color: onPressed != null
                      ? (isPrimary ? Colors.white : color)
                      : Colors.grey,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: onPressed != null
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Colors.grey,
              ),
        ),
      ],
    );
  }
}

// ── Timer Ring Painter ─────────────────────────────────

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _TimerRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // start from top
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
