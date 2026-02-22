import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/settings_service.dart';
import 'services/dnd_service.dart';
import 'env.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _focusDuration;
  late int _breakDuration;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _focusDuration = widget.settings.defaultDuration;
    _breakDuration = widget.settings.breakDuration;
  }

  /// Handle enabling DND — checks access and shows consent dialog if needed.
  Future<void> _handleDndEnable() async {
    final dnd = DndService.instance;

    // Check if we already have access
    final hasAccess = await dnd.hasAccess();

    if (hasAccess) {
      await widget.settings.setDndEnabled(true);
      setState(() {});
      return;
    }

    // Otherwise, show a consent dialog
    if (!mounted) return;
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.do_not_disturb_on_outlined, size: 48),
        title: const Text('DND Permission Required'),
        content: const Text(
          'MoTimer needs access to your Do Not Disturb settings to '
          'silence notifications while the timer is running.\n\n'
          'You will be taken to your system settings to grant this permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    if (shouldRequest == true) {
      await dnd.requestAccess();
      // After returning from settings, check again
      await Future.delayed(const Duration(seconds: 1));
      final nowGranted = await dnd.hasAccess();
      if (nowGranted) {
        await widget.settings.setDndEnabled(true);
      }
    }

    if (mounted) setState(() {});
  }

  /// Check if a user is currently signed in.
  bool get _isSignedIn {
    if (!SettingsService.isSupabaseReady) return false;
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Get the current user's email, if signed in.
  String? get _userEmail {
    if (!_isSignedIn) return null;
    try {
      return Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  /// Sign in with Google via Supabase.
  Future<void> _signIn() async {
    setState(() => _isSyncing = true);
    try {
      // Initialize Supabase if not yet done
      if (!SettingsService.isSupabaseReady) {
        await Supabase.initialize(
          url: Env.supabaseUrl,
          anonKey: Env.supabaseAnonKey,
        );
        await SettingsService.markSupabaseReady();
      }

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.motimer://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      // Listen for auth state change to sync settings
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        if (data.session?.user != null) {
          // Pull remote settings, then push any locally-newer ones
          await widget.settings.syncFromSupabase();
          await widget.settings.pushAllToSupabase();
          if (mounted) setState(() {});
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  /// Sign out.
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-out failed: $e')),
        );
      }
    }
  }

  /// Trigger a manual bidirectional sync.
  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      await widget.settings.syncNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings synced successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  /// Format a relative time string like "2 min ago".
  String _formatLastSynced(DateTime? dt) {
    if (dt == null) return 'Never synced';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Theme Color ────────────────────────────
          _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme Color', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ThemeOption.values.map((option) {
                      final isSelected =
                          widget.settings.themeOption == option;
                      return GestureDetector(
                        onTap: () async {
                          await widget.settings.setThemeOption(option);
                          setState(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: option.color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: colorScheme.onSurface,
                                    width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: option.color.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 28)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      widget.settings.themeOption.label,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Timer Defaults ─────────────────────────
          _SectionHeader(
              title: 'Timer Defaults', icon: Icons.timer_outlined),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Focus duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Focus Duration',
                          style: theme.textTheme.titleSmall),
                      Text('$_focusDuration min',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary)),
                    ],
                  ),
                  Slider(
                    value: _focusDuration.toDouble(),
                    min: 1,
                    max: 120,
                    divisions: 119,
                    label: '$_focusDuration min',
                    onChanged: (v) {
                      setState(() => _focusDuration = v.round());
                    },
                    onChangeEnd: (v) {
                      widget.settings.setDefaultDuration(v.round());
                    },
                  ),

                  const Divider(),

                  // Break duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Break Duration',
                          style: theme.textTheme.titleSmall),
                      Text('$_breakDuration min',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.tertiary)),
                    ],
                  ),
                  Slider(
                    value: _breakDuration.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '$_breakDuration min',
                    onChanged: (v) {
                      setState(() => _breakDuration = v.round());
                    },
                    onChangeEnd: (v) {
                      widget.settings.setBreakDuration(v.round());
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Notifications ──────────────────────────
          _SectionHeader(
              title: 'Notifications', icon: Icons.notifications_outlined),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Sound'),
                  subtitle: const Text('Play sound when timer ends'),
                  secondary: const Icon(Icons.volume_up_outlined),
                  value: widget.settings.soundEnabled,
                  onChanged: (v) async {
                    await widget.settings.setSoundEnabled(v);
                    setState(() {});
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrate when timer ends'),
                  secondary: const Icon(Icons.vibration),
                  value: widget.settings.vibrationEnabled,
                  onChanged: (v) async {
                    await widget.settings.setVibrationEnabled(v);
                    setState(() {});
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Do Not Disturb'),
                  subtitle: Text(
                    DndService.instance.isSupported
                        ? 'Silence device while timer runs'
                        : 'Not supported on this platform',
                  ),
                  secondary: const Icon(Icons.do_not_disturb_on_outlined),
                  value: widget.settings.dndEnabled,
                  onChanged: DndService.instance.isSupported
                      ? (v) async {
                          if (v) {
                            await _handleDndEnable();
                          } else {
                            await widget.settings.setDndEnabled(false);
                            setState(() {});
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Account & Sync ─────────────────────────
          _SectionHeader(
              title: 'Account & Sync', icon: Icons.cloud_outlined),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isSignedIn
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Signed in as ${_userEmail ?? 'unknown'}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.sync,
                                color: colorScheme.onSurfaceVariant,
                                size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Last synced: ${_formatLastSynced(widget.settings.lastSyncedAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isSyncing)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: _syncNow,
                                icon: const Icon(Icons.sync, size: 18),
                                label: const Text('Sync Now'),
                              ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _isSyncing ? null : _signOut,
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('Sign out'),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Text(
                          'Sign in to sync your timer presets and settings '
                          'across devices (e.g. Linux ↔ Android).',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        if (_isSyncing)
                          const CircularProgressIndicator()
                        else
                          FilledButton.icon(
                            onPressed: _signIn,
                            icon: const Icon(Icons.login, size: 18),
                            label: const Text('Sign in with Google'),
                          ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 20,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
