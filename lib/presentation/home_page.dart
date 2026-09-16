import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/countdown.dart';
import '../domain/jelara_event.dart';
import '../platform/platform_interfaces.dart';
import 'calendar_import_page.dart';
import 'jelara_controller.dart';
import 'jelara_theme.dart';
import 'event_editor_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final JelaraController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _ticker;
  bool _working = false;

  JelaraController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // This timer exists only while the foreground page is mounted. Persistent
    // reminders use the notification scheduler rather than a background loop.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _controller.refreshCountdown();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final selected = _controller.selectedEvent;
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth >= 700 ? 36.0 : 20.0;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            18,
                            horizontal,
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _Header(
                              onImport: _openCalendarImport,
                              onAdd: () => _openEditor(),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            28,
                            horizontal,
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: selected == null
                                ? _EmptyFocus(onAdd: () => _openEditor())
                                : _FocalEventCard(
                                    event: selected,
                                    snapshot: _controller.countdownFor(
                                      selected,
                                    ),
                                    onEdit: () => _openEditor(selected),
                                  ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            34,
                            horizontal,
                            20,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _SectionHeading(
                              title: 'All marks',
                              detail: _controller.events.length == 1
                                  ? '1 saved moment'
                                  : '${_controller.events.length} saved moments',
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: horizontal),
                          sliver: SliverList.separated(
                            itemCount: _controller.events.length,
                            itemBuilder: (context, index) {
                              final event = _controller.events[index];
                              return _EventListTile(
                                event: event,
                                snapshot: _controller.countdownFor(event),
                                selected: event.id == _controller.selectedId,
                                onTap: () => _selectEvent(event),
                                onEdit: () => _openEditor(event),
                                onDelete: () => _deleteEvent(event),
                              );
                            },
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            22,
                            horizontal,
                            34,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: OutlinedButton.icon(
                              onPressed: _working ? null : () => _openEditor(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add another mark'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectEvent(JelaraEvent event) async {
    if (_working) return;
    setState(() => _working = true);
    await _controller.selectEvent(event.id);
    if (mounted) setState(() => _working = false);
  }

  Future<void> _openEditor([JelaraEvent? event]) async {
    if (_working) return;
    final result = await EventEditorPage.show(context, event: event);
    if (!mounted || result == null) return;

    setState(() => _working = true);
    if (result is EventSavedResult) {
      final saveResult = await _controller.saveEvent(result.event);
      if (mounted) _showSaveFeedback(result.event, saveResult);
    } else if (result is EventDeletedResult) {
      await _controller.deleteEvent(result.eventId);
    }
    if (mounted) setState(() => _working = false);
  }

  Future<void> _deleteEvent(JelaraEvent event) async {
    if (_working) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this mark?'),
        content: Text('“${event.title}” will be removed from Jelara.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _working = true);
    try {
      await _controller.deleteEvent(event.id);
    } on Object {
      if (mounted) {
        _showMessage('Could not delete the mark. Try again.');
      }
    }
    if (mounted) setState(() => _working = false);
  }

  Future<void> _openCalendarImport() async {
    if (_working) return;
    final imported = await Navigator.of(context).push<ImportedCalendarEvent>(
      MaterialPageRoute(
        builder: (_) => CalendarImportPage(
          calendar: _controller.calendarGateway,
          googleCalendar: _controller.googleCalendarGateway,
        ),
      ),
    );
    if (!mounted || imported == null) return;
    setState(() => _working = true);
    final event = imported.toJelaraEvent();
    final result = await _controller.saveEvent(event);
    if (mounted) {
      _showSaveFeedback(event, result);
      setState(() => _working = false);
    }
  }

  void _showSaveFeedback(JelaraEvent event, SaveEventResult result) {
    if (result.warning != null) {
      _showMessage('Saved, but ${result.warning}');
    } else if (event.reminders.isNotEmpty &&
        result.notificationPermission == NotificationPermissionStatus.denied) {
      _showMessage(
        'Saved. Notifications are off for Jelara in system settings.',
      );
    } else if (event.reminders.isNotEmpty && !result.notificationsSynced) {
      _showMessage('Saved. Reminders will be available on Android.');
    } else {
      _showMessage('${event.title} is now your focus.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onImport, required this.onAdd});

  final VoidCallback onImport;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'JELARA',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Make time visible.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Import or connect a calendar',
          child: IconButton(
            onPressed: onImport,
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Import or connect a calendar',
          ),
        ),
        const SizedBox(width: 2),
        Semantics(
          button: true,
          label: 'Add a new mark',
          child: IconButton.filled(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            tooltip: 'Add a new mark',
          ),
        ),
      ],
    );
  }
}

class _FocalEventCard extends StatelessWidget {
  const _FocalEventCard({
    required this.event,
    required this.snapshot,
    required this.onEdit,
  });

  final JelaraEvent event;
  final CountdownSnapshot snapshot;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context, snapshot.status);
    final onAccent = _onAccent(snapshot.status);
    final surface = Theme.of(context).colorScheme.surface;
    return Semantics(
      container: true,
      label: snapshot.accessibleLabel,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(status: snapshot.status, color: accent),
                const SizedBox(width: 10),
                if (event.source != EventSource.manual)
                  Text(
                    event.source == EventSource.google
                        ? 'GOOGLE CALENDAR'
                        : 'DEVICE CALENDAR',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit ${event.title}',
                  icon: const Icon(Icons.edit_outlined),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                snapshot.displayText,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: accent,
                  fontSize: snapshot.isAllDay ? 72 : 58,
                  letterSpacing: snapshot.isAllDay ? -2.8 : -1.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _eventDateLine(event),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 18),
            Divider(color: onAccent.withValues(alpha: 0.14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  event.reminders.isEmpty
                      ? Icons.notifications_none_outlined
                      : Icons.notifications_active_outlined,
                  size: 18,
                  color: onAccent.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.reminders.isEmpty
                        ? 'No reminders set'
                        : '${event.reminders.length} reminder${event.reminders.length == 1 ? '' : 's'} set',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.62),
                    ),
                  ),
                ),
                Text(
                  'FOCUS',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: accent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventListTile extends StatelessWidget {
  const _EventListTile({
    required this.event,
    required this.snapshot,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final JelaraEvent event;
  final CountdownSnapshot snapshot;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = _accent(context, snapshot.status);
    return Semantics(
      button: true,
      selected: selected,
      label: '${event.title}, ${snapshot.accessibleLabel}',
      child: Material(
        color: selected ? colors.surfaceContainerHighest : colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _eventDateLine(event),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.58),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      snapshot.displayText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      snapshot.statusLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.46),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  tooltip: 'Actions for ${event.title}',
                  onSelected: (action) {
                    if (action == 'edit') onEdit();
                    if (action == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit mark')),
                    PopupMenuItem(value: 'delete', child: Text('Delete mark')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final CountdownStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      CountdownStatus.upcoming => 'UPCOMING',
      CountdownStatus.today => 'TODAY',
      CountdownStatus.overdue => 'OVERDUE',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 10),
        Text(
          detail,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _EmptyFocus extends StatelessWidget {
  const _EmptyFocus({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.push_pin_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(height: 18),
          Text(
            'Nothing pinned yet.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add one moment to make it the calm center of your day.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.64),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add your first mark'),
          ),
        ],
      ),
    );
  }
}

Color _accent(BuildContext context, CountdownStatus status) {
  switch (status) {
    case CountdownStatus.upcoming:
      return Theme.of(context).brightness == Brightness.dark
          ? JelaraPalette.mint
          : const Color(0xFF087A5C);
    case CountdownStatus.today:
      return Theme.of(context).brightness == Brightness.dark
          ? JelaraPalette.amber
          : const Color(0xFF9A5B00);
    case CountdownStatus.overdue:
      return Theme.of(context).brightness == Brightness.dark
          ? JelaraPalette.coral
          : const Color(0xFFBA1A1A);
  }
}

Color _onAccent(CountdownStatus status) {
  switch (status) {
    case CountdownStatus.upcoming:
      return JelaraPalette.mint;
    case CountdownStatus.today:
      return JelaraPalette.amber;
    case CountdownStatus.overdue:
      return JelaraPalette.coral;
  }
}

String _eventDateLine(JelaraEvent event) {
  final local = event.localStart;
  final date = DateFormat('EEE, d MMM yyyy').format(local);
  return event.allDay
      ? '$date · All day'
      : '$date · ${DateFormat('HH:mm').format(local)}';
}
