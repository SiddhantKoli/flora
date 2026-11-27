import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/app_preferences.dart';
import '../../data/game_rules.dart';
import '../../data/game_store.dart';
import '../../ui/flora_design.dart';
import '../backup/backup_page.dart';

class FieldProfilePage extends StatelessWidget {
  const FieldProfilePage(
      {super.key,
      required this.state,
      required this.preferences,
      required this.onPreferencesChanged,
      required this.onRestored,
      required this.onJournal,
      required this.onSettings});
  final GameSnapshot state;
  final AppPreferences preferences;
  final Future<void> Function(AppPreferences) onPreferencesChanged;
  final Future<void> Function() onRestored;
  final VoidCallback onJournal;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Widget record = _RecordPanel(state: state);
    if (!reduceMotion) record = record.animate().fadeIn(duration: 280.ms);
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 38),
        children: [
          Text('Your\nnotebook.', style: FloraType.display),
          const SizedBox(height: 25),
          Row(children: [
            Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                    color: FloraPalette.coral,
                    borderRadius: BorderRadius.circular(17)),
                child: Icon(_avatarIcon(preferences.avatar),
                    size: 33, color: FloraPalette.ink)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      preferences.displayName.isEmpty
                          ? 'Guest explorer'
                          : preferences.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FloraType.title.copyWith(fontSize: 22)),
                  Text('Saved on this device', style: FloraType.caption),
                ])),
            IconButton(
                onPressed: () => _editProfile(context),
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit_outlined)),
          ]),
          const SizedBox(height: 25),
          record,
          const SizedBox(height: 30),
          Row(children: [
            Expanded(child: Text('Recent pages', style: FloraType.title)),
            TextButton(onPressed: onJournal, child: const Text('Open journal')),
          ]),
          if (state.plants.isEmpty)
            Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                child: Text('Your first plant will start your story here.',
                    style: FloraType.body.copyWith(color: FloraPalette.muted)))
          else
            ...state.plants.take(3).map((plant) => Material(
                color: Colors.transparent,
                child: InkWell(
                    onTap: onJournal,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Row(children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: plant.latestVisit == null
                                  ? const SizedBox(
                                      width: 54,
                                      height: 54,
                                      child: ColoredBox(
                                          color: FloraPalette.mint,
                                          child: Icon(Icons.spa_outlined)))
                                  : Image.file(
                                      File(plant.latestVisit!.imagePath),
                                      width: 54,
                                      height: 54,
                                      fit: BoxFit.cover,
                                      cacheWidth: 180,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox(
                                              width: 54,
                                              height: 54,
                                              child: Icon(Icons
                                                  .broken_image_outlined)))),
                          const SizedBox(width: 13),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(plant.displayName,
                                    style: FloraType.body
                                        .copyWith(fontWeight: FontWeight.w800)),
                                Text(
                                    '${plant.visits.length} ${plant.visits.length == 1 ? 'visit' : 'visits'}',
                                    style: FloraType.caption),
                              ])),
                          const Icon(Icons.arrow_outward_rounded,
                              color: FloraPalette.signal, size: 21),
                        ]))))),
          const SizedBox(height: 16),
          Text('Small wins', style: FloraType.title),
          const SizedBox(height: 13),
          _BadgeLine(
              label: 'First find',
              unlocked: state.achievements.contains('first_discovery'),
              description: 'One catalog plant discovered'),
          _BadgeLine(
              label: 'Field collector',
              unlocked: state.achievements.contains('five_species'),
              description: 'Five catalog plants discovered'),
          const SizedBox(height: 28),
          Text('Your space', style: FloraType.title),
          const SizedBox(height: 12),
          _ActionLine(
              icon: Icons.settings_outlined,
              title: 'Settings & privacy',
              onTap: onSettings),
          _ActionLine(
              icon: Icons.save_alt_rounded,
              title: 'Export or restore',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BackupPage(onRestored: onRestored)))),
          const SizedBox(height: 15),
          Text(
              'This guest profile has no account or cloud sync. Export a backup before changing phones.',
              style: FloraType.caption),
        ]);
  }

  Future<void> _editProfile(BuildContext context) async {
    final name = TextEditingController(text: preferences.displayName);
    var avatar = preferences.avatar;
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: FloraPalette.background,
        builder: (sheetContext) => StatefulBuilder(
            builder: (context, setState) => SafeArea(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20,
                        MediaQuery.viewInsetsOf(context).bottom + 22),
                    child: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Make it yours', style: FloraType.title),
                          const SizedBox(height: 18),
                          TextField(
                              controller: name,
                              maxLength: 40,
                              decoration: const InputDecoration(
                                  labelText: 'Display name',
                                  hintText: 'Guest explorer')),
                          const SizedBox(height: 10),
                          Text('Choose an icon',
                              style: FloraType.body
                                  .copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          Wrap(
                              spacing: 10,
                              children: ['leaf', 'flower', 'sun', 'spark']
                                  .map((option) => ChoiceChip(
                                      label: Icon(_avatarIcon(option),
                                          semanticLabel: option),
                                      selected: avatar == option,
                                      onSelected: (_) =>
                                          setState(() => avatar = option)))
                                  .toList()),
                          const SizedBox(height: 20),
                          FilledButton(
                              onPressed: () async {
                                try {
                                  await onPreferencesChanged(
                                      preferences.copyWith(
                                          displayName: name.text.trim(),
                                          avatar: avatar));
                                  if (sheetContext.mounted)
                                    Navigator.pop(sheetContext);
                                } catch (_) {
                                  if (sheetContext.mounted)
                                    ScaffoldMessenger.of(sheetContext)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Could not save your profile. Try again.')));
                                }
                              },
                              child: const Text('Save profile')),
                        ]))))));
    name.dispose();
  }
}

IconData _avatarIcon(String name) => switch (name) {
      'flower' => Icons.local_florist_outlined,
      'sun' => Icons.wb_sunny_outlined,
      'spark' => Icons.auto_awesome_outlined,
      _ => Icons.spa_outlined,
    };

class _RecordPanel extends StatelessWidget {
  const _RecordPanel({required this.state});
  final GameSnapshot state;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: FloraPalette.night, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Field record',
            style: FloraType.caption.copyWith(color: FloraPalette.mint)),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
              child: Text('Level ${levelForXp(state.xp)}',
                  style: FloraType.display
                      .copyWith(fontSize: 38, color: Colors.white))),
          Text('${state.xp} XP',
              style: FloraType.body
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 22),
        const Divider(color: Color(0xFF41605D)),
        const SizedBox(height: 13),
        Row(children: [
          Expanded(child: _RecordStat('${state.plants.length}', 'plants kept')),
          Expanded(
              child: _RecordStat('${state.observations.length}', 'visits')),
          Expanded(
              child:
                  _RecordStat('${state.unlockedIds.length}', 'catalog seen')),
        ]),
      ]));
}

class _RecordStat extends StatelessWidget {
  const _RecordStat(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: FloraType.title.copyWith(color: Colors.white, fontSize: 23)),
        Text(label,
            style: FloraType.caption.copyWith(color: const Color(0xFFD3E3DD))),
      ]);
}

class _BadgeLine extends StatelessWidget {
  const _BadgeLine(
      {required this.label, required this.description, required this.unlocked});
  final String label;
  final String description;
  final bool unlocked;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: unlocked ? FloraPalette.mint : FloraPalette.line,
                borderRadius: BorderRadius.circular(11)),
            child: Icon(
                unlocked ? Icons.stars_rounded : Icons.lock_outline_rounded,
                color: FloraPalette.ink)),
        const SizedBox(width: 13),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: FloraType.body.copyWith(fontWeight: FontWeight.w800)),
          Text(description, style: FloraType.caption),
        ])),
        Text(unlocked ? 'Earned' : 'Locked',
            style: FloraType.caption.copyWith(
                color: unlocked ? FloraPalette.signal : FloraPalette.muted)),
      ]));
}

class _ActionLine extends StatelessWidget {
  const _ActionLine(
      {required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: FloraPalette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(children: [
                Icon(icon, size: 22, color: FloraPalette.signal),
                const SizedBox(width: 13),
                Expanded(
                    child: Text(title,
                        style: FloraType.body
                            .copyWith(fontWeight: FontWeight.w800))),
                const Icon(Icons.arrow_outward_rounded, size: 20),
              ]))));
}
