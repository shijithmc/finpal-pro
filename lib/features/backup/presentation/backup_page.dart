import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/backup_service.dart';

/// Settings > Data Management page — backup, restore, and TSV export.
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _loading = false;
  String? _statusMessage;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _statusMessage = null;
    });
    try {
      await action();
      if (mounted) {
        setState(() => _statusMessage = 'Done.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.read(backupServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Data Management')),
      body: ListView(
        children: [
          // ── Export ────────────────────────────────────────────────────────
          _SectionHeader(title: 'Export'),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Export Transactions (TSV)'),
            subtitle: const Text(
              'Share all transactions as a tab-separated spreadsheet.',
            ),
            trailing: _loading
                ? const _LoadingIndicator()
                : const Icon(Icons.chevron_right),
            onTap: _loading
                ? null
                : () => _run(() async {
                    await svc.exportTransactionsTsv();
                  }),
          ),
          const Divider(indent: 72),

          // ── Backup ────────────────────────────────────────────────────────
          _SectionHeader(title: 'Backup'),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Create Backup'),
            subtitle: const Text(
              'Export a full JSON backup of all data (accounts, transactions, budgets).',
            ),
            trailing: _loading
                ? const _LoadingIndicator()
                : const Icon(Icons.chevron_right),
            onTap: _loading
                ? null
                : () => _run(() async {
                    await svc.createJsonBackup();
                  }),
          ),
          const Divider(indent: 72),

          // ── Restore ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Restore'),
          ListTile(
            leading: Icon(
              Icons.restore_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Restore from Backup',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text(
              'Replaces ALL current data with backup contents. This cannot be undone.',
            ),
            trailing: _loading
                ? const _LoadingIndicator()
                : Icon(Icons.chevron_right, color: theme.colorScheme.error),
            onTap: _loading ? null : () => _confirmRestore(context, svc),
          ),
          const Divider(indent: 72),

          // ── Status ────────────────────────────────────────────────────────
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _statusMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _statusMessage!.startsWith('Error')
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Backups are stored locally and shared via the system share sheet. '
              'To keep a permanent copy, save to Google Drive, email, or another cloud service.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context, BackupService svc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text(
          'This will replace ALL current data (accounts, transactions, budgets) '
          'with the contents of the backup file.\n\n'
          'This action cannot be undone. Make sure you have a recent backup before proceeding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // In production, open a file picker to let the user select the backup file.
    // share_plus does not provide a file picker; use file_picker package in Sprint 3.
    // For Sprint 2, prompt user to enter file path (developer mode fallback).
    final pathController = TextEditingController();
    final filePath = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Backup File Path'),
        content: TextField(
          controller: pathController,
          decoration: const InputDecoration(
            hintText: '/storage/emulated/0/Download/finpal_backup_*.json',
            labelText: 'File path',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, pathController.text.trim()),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (filePath == null || filePath.isEmpty) return;

    await _run(() => svc.restoreFromJson(filePath));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
