import 'package:flutter/material.dart';

import '../domain/jelara_event.dart';

sealed class EventEditorResult {
  const EventEditorResult();
}

class EventSavedResult extends EventEditorResult {
  const EventSavedResult(this.event);

  final JelaraEvent event;
}

class EventDeletedResult extends EventEditorResult {
  const EventDeletedResult(this.eventId);

  final String eventId;
}

class EventEditorPage extends StatefulWidget {
  const EventEditorPage({super.key, this.initialEvent});

  final JelaraEvent? initialEvent;

  static Future<EventEditorResult?> show(
    BuildContext context, {
    JelaraEvent? event,
  }) {
    return Navigator.of(context).push<EventEditorResult>(
      MaterialPageRoute(builder: (_) => EventEditorPage(initialEvent: event)),
    );
  }

  @override
  State<EventEditorPage> createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
  late final TextEditingController _titleController;
  late DateTime _start;
  late bool _allDay;
  late Set<ReminderOffset> _reminders;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  bool get _isEditing => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    _titleController = TextEditingController(text: event?.title ?? '');
    _start = event?.localStart ?? _nextHalfHour(DateTime.now());
    _allDay = event?.allDay ?? false;
    _reminders = {...event?.reminders ?? const <ReminderOffset>{}};
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit mark' : 'New mark'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              Text(
                _isEditing
                    ? 'Keep the moment clear.'
                    : 'Give the moment a name.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Jelara keeps this event on your device and counts from the local time shown below.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurface.withValues(alpha: 0.62)),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Flight to Tokyo',
                  prefixIcon: Icon(Icons.bookmark_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Add a title so this mark is easy to find.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _SectionLabel(label: 'WHEN', icon: Icons.schedule_outlined),
              const SizedBox(height: 10),
              _PickerTile(
                icon: Icons.calendar_month_outlined,
                label: 'Date',
                value: _formatDate(_start),
                onTap: _pickDate,
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _allDay
                    ? const SizedBox.shrink(key: ValueKey('all-day'))
                    : _PickerTile(
                        key: const ValueKey('timed'),
                        icon: Icons.access_time_outlined,
                        label: 'Time',
                        value: _formatTime(_start),
                        onTap: _pickTime,
                      ),
              ),
              const SizedBox(height: 10),
              _ToggleTile(
                icon: Icons.wb_sunny_outlined,
                title: 'All day',
                subtitle: 'Use the start of this local calendar day',
                value: _allDay,
                onChanged: (value) {
                  setState(() {
                    _allDay = value;
                    if (!value && _start.hour == 0 && _start.minute == 0) {
                      _start = DateTime(
                        _start.year,
                        _start.month,
                        _start.day,
                        9,
                      );
                    }
                  });
                },
              ),
              const SizedBox(height: 28),
              _SectionLabel(
                label: 'REMIND ME',
                icon: Icons.notifications_none_outlined,
              ),
              const SizedBox(height: 6),
              Text(
                'Choose any moments before the mark. Notifications are scheduled only after you save.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurface.withValues(alpha: 0.62)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final offset in ReminderOffset.values)
                    Semantics(
                      label: '${offset.label}, ${offset.description}',
                      child: FilterChip(
                        label: Text(offset.label),
                        selected: _reminders.contains(offset),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _reminders.add(offset);
                            } else {
                              _reminders.remove(offset);
                            }
                          });
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 34),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(_isEditing ? 'Save changes' : 'Create mark'),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete mark'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                    side: BorderSide(
                      color: colors.error.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Choose mark date',
    );
    if (!mounted || selected == null) return;
    setState(() {
      _start = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _start.hour,
        _start.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
      helpText: 'Choose mark time',
    );
    if (!mounted || selected == null) return;
    setState(() {
      _start = DateTime(
        _start.year,
        _start.month,
        _start.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final title = _titleController.text.trim();
    final start = _allDay
        ? DateTime(_start.year, _start.month, _start.day)
        : _start;
    final event = JelaraEvent(
      id:
          widget.initialEvent?.id ??
          'event-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      start: start,
      allDay: _allDay,
      reminders: _reminders,
      source: widget.initialEvent?.source ?? EventSource.manual,
    );
    if (mounted) {
      Navigator.of(context).pop(EventSavedResult(event));
    }
  }

  Future<void> _delete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this mark?'),
        content: Text(
          '“${widget.initialEvent!.title}” will be removed from Jelara.',
        ),
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
    if (!mounted || shouldDelete != true) return;
    Navigator.of(context).pop(EventDeletedResult(widget.initialEvent!.id));
  }

  static DateTime _nextHalfHour(DateTime now) {
    final roundedMinute = now.minute < 30 ? 30 : 0;
    final addHour = now.minute < 30 ? 0 : 1;
    return DateTime(
      now.year,
      now.month,
      now.day,
      now.hour + addHour,
      roundedMinute,
    );
  }

  static String _formatDate(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              label: title,
              child: Switch(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}
