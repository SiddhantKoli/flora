import 'package:flutter/material.dart';

import '../../data/app_preferences.dart';
import '../../data/game_store.dart';
import '../../ui/flora_design.dart';
import '../backup/backup_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage(
      {super.key,
      required this.state,
      required this.preferences,
      required this.onPreferencesChanged,
      required this.onDataChanged,
      required this.onClearData});
  final GameSnapshot state;
  final AppPreferences preferences;
  final Future<void> Function(AppPreferences) onPreferencesChanged;
  final Future<void> Function() onDataChanged;
  final Future<void> Function() onClearData;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppPreferences preferences = widget.preferences;
  bool busy = false;
  String? error;

  Future<void> change(AppPreferences next) async {
    setState(() {
      preferences = next;
      error = null;
    });
    try {
      await widget.onPreferencesChanged(next);
    } catch (_) {
      if (mounted)
        setState(() {
          preferences = widget.preferences;
          error = 'Could not save this setting.';
        });
    }
  }

  Future<void> clear() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Delete local FLORA data?'),
              content: Text(
                  'This removes ${widget.state.plants.length} plants, '
                  '${widget.state.observations.length} visits, saved photos, XP, badges, and your profile on this phone. '
                  'Export a backup first if you want to keep them. This cannot be undone.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Delete everything')),
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onClearData();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        setState(() => error = 'Could not clear all local data. Try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              const _Heading('Make it comfortable'),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Larger text'),
                  subtitle: const Text('Use at least 118% text size in FLORA.'),
                  value: preferences.largeText,
                  onChanged: busy
                      ? null
                      : (value) =>
                          change(preferences.copyWith(largeText: value))),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduce motion'),
                  subtitle: const Text('Skip optional entrance animations.'),
                  value: preferences.reducedMotion,
                  onChanged: busy
                      ? null
                      : (value) =>
                          change(preferences.copyWith(reducedMotion: value))),
              const Divider(height: 34),
              const _Heading('Photos & privacy'),
              const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.camera_alt_outlined),
                  title: Text('Camera access'),
                  subtitle: Text(
                      'FLORA asks for camera access when you add a plant or visit. If denied, allow it in Android Settings → Apps → FLORA → Permissions. Gallery imports are off.')),
              const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_outline_rounded),
                  title: Text('Stored on this phone'),
                  subtitle: Text(
                      'Your photos, plant names, notes, and progress stay in local app storage. FLORA has no account or cloud sync. Uninstalling can remove this data.')),
              const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.location_off_outlined),
                  title: Text('Place notes'),
                  subtitle: Text(
                      'Places are labels you type. FLORA does not record GPS for plant visits.')),
              const Divider(height: 34),
              const _Heading('Your data'),
              OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BackupPage(
                                  onRestored: widget.onDataChanged))),
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Export or restore journal')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: busy ? null : clear,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade800),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete local data')),
              if (error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(error!,
                        style: TextStyle(color: Colors.red.shade800))),
            ]),
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label,
          style: const TextStyle(
              color: FloraPalette.forest,
              fontSize: 20,
              fontWeight: FontWeight.w900)));
}
