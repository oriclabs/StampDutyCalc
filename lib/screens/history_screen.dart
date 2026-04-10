import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/user_mode_provider.dart';
import '../services/history_service.dart';
import 'compare_history_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _history = [];
  bool _loading = true;
  bool _compareMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await HistoryService.getHistory();
    if (mounted) setState(() { _history = history; _loading = false; });
  }

  Future<void> _exportCsv() async {
    try {
      final csv = HistoryService.toCsv(_history);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/vehicle_calculator_history.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Vehicle Calculator History',
        subject: 'Calculation History',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _editNote(HistoryEntry entry) async {
    final controller = TextEditingController(text: entry.note ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. Toyota Camry quote from Suttons',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null) {
      await HistoryService.updateNote(entry.id, result.isEmpty ? null : result);
      _load();
    }
  }

  Future<void> _deleteEntry(HistoryEntry entry) async {
    await HistoryService.deleteEntry(entry.id);
    _load();
  }

  void _toggleCompareMode() {
    setState(() {
      _compareMode = !_compareMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else if (_selectedIds.length < 2) {
        _selectedIds.add(id);
      }
    });
  }

  void _openCompare() {
    if (_selectedIds.length != 2) return;
    final ids = _selectedIds.toList();
    final left = _history.firstWhere((e) => e.id == ids[0]);
    final right = _history.firstWhere((e) => e.id == ids[1]);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompareHistoryScreen(left: left, right: right),
      ),
    ).then((_) {
      setState(() {
        _compareMode = false;
        _selectedIds.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = context.watch<UserModeProvider>().mode;
    final canCompare = mode == UserMode.buyer || mode == UserMode.dealer;

    return Scaffold(
      appBar: AppBar(
        title: Text(_compareMode
            ? 'Select 2 to compare (${_selectedIds.length}/2)'
            : 'History'),
        leading: _compareMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleCompareMode,
              )
            : null,
        actions: [
          if (_compareMode && _selectedIds.length == 2)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: 'Compare selected',
              onPressed: _openCompare,
            ),
          if (!_compareMode && _history.isNotEmpty) ...[
            if (canCompare && _history.length >= 2)
              IconButton(
                icon: const Icon(Icons.compare_arrows),
                tooltip: 'Compare two calculations',
                onPressed: _toggleCompareMode,
              ),
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Export as CSV',
              onPressed: _exportCsv,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear history',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear history?'),
                    content: const Text(
                        'This will remove all saved calculations.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Clear')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await HistoryService.clearHistory();
                  _load();
                }
              },
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmpty(theme)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    return _HistoryCard(
                      entry: entry,
                      onEditNote: () => _editNote(entry),
                      onDelete: () => _deleteEntry(entry),
                      compareMode: _compareMode,
                      isSelected: _selectedIds.contains(entry.id),
                      onToggleSelect: () => _toggleSelection(entry.id),
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 48,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No calculations yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your past stamp duty, on-road, and other calculations will appear here for quick access.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_downward,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap "Tools" below to start',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onEditNote;
  final VoidCallback onDelete;
  final bool compareMode;
  final bool isSelected;
  final VoidCallback? onToggleSelect;

  const _HistoryCard({
    required this.entry,
    required this.onEditNote,
    required this.onDelete,
    this.compareMode = false,
    this.isSelected = false,
    this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      symbol: entry.currencySymbol,
      decimalDigits: 2,
    );
    final dateStr =
        DateFormat('d MMM yyyy, h:mm a').format(entry.timestamp);

    return Card(
      color: compareMode && isSelected
          ? theme.colorScheme.primaryContainer
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: compareMode && isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: compareMode ? onToggleSelect : onEditNote,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        entry.stateCode,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.stateName}, ${entry.countryName}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vehicle: ${formatter.format(entry.vehiclePrice)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatter.format(entry.totalPayable),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (entry.isOnRoad)
                        Text(
                          'On-road',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  if (compareMode)
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    )
                  else
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          color: theme.colorScheme.onSurfaceVariant),
                      onSelected: (v) {
                        if (v == 'note') onEditNote();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'note',
                          child: ListTile(
                            leading: Icon(Icons.note_add),
                            title: Text('Add/Edit note'),
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Delete'),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (entry.note != null && entry.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
