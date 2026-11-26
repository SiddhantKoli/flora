import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/backup_service.dart';
import '../../data/game_store.dart';
import '../../ui/flora_design.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key, required this.onRestored});
  final Future<void> Function() onRestored;

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  static const channel = MethodChannel('flora/backup_document');
  bool busy = false;

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> export() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final bytes = await BackupService.instance.createBackup();
      if (!mounted) return;
      final saved = await channel.invokeMethod<bool>('save', {'bytes': bytes});
      if (saved == true)
        message('FLORA backup saved. Keep the file somewhere safe.');
    } catch (error) {
      message(error is StateError
          ? error.message
          : 'Could not export the journal. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> restore() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final bytes = await channel.invokeMethod<Uint8List>('open');
      if (bytes == null || !mounted) return;
      final preview = BackupService.instance.inspect(bytes);
      final currentCount =
          (await GameStore.instance.snapshot()).observations.length;
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                title: const Text('Replace your current journal?'),
                content: Text(
                    'This backup has ${preview.observationCount} entries and ${preview.photoCount} photos. Your $currentCount current entries, photos, and progress will be replaced. Export your current journal first if you want to keep it.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Replace journal')),
                ],
              ));
      if (confirmed != true) return;
      await BackupService.instance.restore(bytes);
      try {
        await widget.onRestored();
        message('Journal restored from backup.');
      } catch (_) {
        message('Backup restored. Reopen FLORA to refresh the screen.');
      }
    } on FormatException catch (error) {
      message(error.message);
    } catch (_) {
      message('Could not restore this backup. Your journal was kept.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Your data')),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Keep your finds.',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
              'FLORA keeps your photos and progress on this phone. Save a backup before reinstalling or changing devices.',
              style: TextStyle(color: FloraPalette.muted, height: 1.45)),
          const SizedBox(height: 24),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.save_alt_rounded,
                            size: 30, color: FloraPalette.forest),
                        const SizedBox(height: 12),
                        const Text('Export journal',
                            style: TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        const Text(
                            'Save one FLORA backup file with your entries, photos, and progress.'),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: busy ? null : export,
                            child: const Text('Save backup file')),
                      ]))),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.restore_rounded,
                            size: 30, color: FloraPalette.forest),
                        const SizedBox(height: 12),
                        const Text('Restore journal',
                            style: TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        const Text(
                            'Choose a FLORA backup. You can review its contents before replacing this phone’s journal.'),
                        const SizedBox(height: 16),
                        OutlinedButton(
                            onPressed: busy ? null : restore,
                            child: const Text('Choose backup file')),
                      ]))),
          if (busy) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 20),
          const Text(
              'Backups are not uploaded by FLORA. Anyone with the file can view its photos and notes, so store it privately.',
              style: TextStyle(color: FloraPalette.muted, fontSize: 13)),
        ])),
      );
}
