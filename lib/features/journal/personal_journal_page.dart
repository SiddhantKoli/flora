import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/game_store.dart';
import '../../data/observation.dart';
import '../../data/personal_plant.dart';
import '../../data/species.dart';
import '../../ui/flora_design.dart';

class PersonalJournalPage extends StatefulWidget {
  const PersonalJournalPage(
      {super.key,
      required this.state,
      required this.onChanged,
      required this.onAddPlant,
      required this.onAddVisit,
      required this.onOpenVisit});
  final GameSnapshot state;
  final Future<void> Function() onChanged;
  final Future<void> Function() onAddPlant;
  final Future<void> Function(PersonalPlant) onAddVisit;
  final Future<dynamic> Function(Observation) onOpenVisit;

  @override
  State<PersonalJournalPage> createState() => _PersonalJournalPageState();
}

class _PersonalJournalPageState extends State<PersonalJournalPage> {
  String search = '';
  bool unknownOnly = false;

  @override
  Widget build(BuildContext context) {
    final plants = widget.state.plants.where((plant) {
      if (unknownOnly &&
          (plant.speciesId != null || plant.customName.isNotEmpty))
        return false;
      final query = search.trim().toLowerCase();
      return '${plant.displayName} ${plant.plantLabel} ${plant.placeLabel} ${plant.visits.map((v) => v.notes).join(' ')}'
          .toLowerCase()
          .contains(query);
    }).toList();
    return CustomScrollView(slivers: [
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverList(
              delegate: SliverChildListDelegate([
            const Text('Your plants.',
                style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.7)),
            const SizedBox(height: 5),
            Text(
                '${widget.state.plants.length} plants · ${widget.state.observations.length} visits on this device',
                style: const TextStyle(color: FloraPalette.muted)),
            const SizedBox(height: 20),
            if (widget.state.plants.isEmpty)
              _EmptyJournal(onAddPlant: widget.onAddPlant)
            else ...[
              TextField(
                  onChanged: (value) => setState(() => search = value),
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search your plants',
                      hintText: 'Name, place, or note')),
              const SizedBox(height: 10),
              Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                      label: const Text('Unknown'),
                      selected: unknownOnly,
                      onSelected: (value) =>
                          setState(() => unknownOnly = value))),
              const SizedBox(height: 14),
              if (plants.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child: Text('No plants match. Try another search.'))),
            ],
          ]))),
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          sliver: SliverList.builder(
              itemCount: plants.length,
              itemBuilder: (context, index) {
                final plant = plants[index];
                return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _PlantCard(
                        plant: plant,
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => PersonalPlantPage(
                                  plantId: plant.id,
                                  onChanged: widget.onChanged,
                                  onAddVisit: widget.onAddVisit,
                                  onOpenVisit: widget.onOpenVisit)));
                          await widget.onChanged();
                        }));
              })),
    ]);
  }
}

class _EmptyJournal extends StatelessWidget {
  const _EmptyJournal({required this.onAddPlant});
  final Future<void> Function() onAddPlant;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: FloraPalette.blue, borderRadius: BorderRadius.circular(26)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.local_florist_rounded,
            size: 64, color: FloraPalette.forest),
        const SizedBox(height: 16),
        const Text('Start with one plant.',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text(
            'Take a photo, give it a name if you know it, and come back to see how it changes.'),
        const SizedBox(height: 18),
        FilledButton.icon(
            onPressed: onAddPlant,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Add your first plant')),
      ]));
}

class _PlantCard extends StatelessWidget {
  const _PlantCard({required this.plant, required this.onTap});
  final PersonalPlant plant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(
                aspectRatio: 1.85,
                child: plant.latestVisit == null
                    ? const ColoredBox(
                        color: FloraPalette.lime,
                        child: Icon(Icons.spa_rounded, size: 70))
                    : Image.file(File(plant.latestVisit!.imagePath),
                        fit: BoxFit.cover,
                        cacheWidth: 900,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                            color: FloraPalette.lime,
                            child: Center(
                                child: Icon(Icons.broken_image_outlined,
                                    size: 50))))),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(plant.displayName,
                            style: const TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w900)),
                        if (plant.nickname.isNotEmpty)
                          Text(plant.plantLabel,
                              style:
                                  const TextStyle(color: FloraPalette.muted)),
                        const SizedBox(height: 4),
                        Text(
                            '${plant.visits.length} ${plant.visits.length == 1 ? 'visit' : 'visits'}${plant.placeLabel.isEmpty ? '' : ' · ${plant.placeLabel}'}',
                            style: const TextStyle(color: FloraPalette.muted)),
                      ])),
                  const Icon(Icons.arrow_forward_rounded,
                      color: FloraPalette.forest),
                ])),
          ])));
}

class PersonalPlantPage extends StatefulWidget {
  const PersonalPlantPage(
      {super.key,
      required this.plantId,
      required this.onChanged,
      required this.onAddVisit,
      required this.onOpenVisit});
  final String plantId;
  final Future<void> Function() onChanged;
  final Future<void> Function(PersonalPlant) onAddVisit;
  final Future<dynamic> Function(Observation) onOpenVisit;

  @override
  State<PersonalPlantPage> createState() => _PersonalPlantPageState();
}

class _PersonalPlantPageState extends State<PersonalPlantPage> {
  PersonalPlant? plant;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final next =
        (await GameStore.instance.snapshot()).plantById(widget.plantId);
    if (mounted)
      setState(() {
        plant = next;
        loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final current = plant;
    if (current == null)
      return Scaffold(
          appBar: AppBar(),
          body: const Center(
              child: Text('This plant is no longer in your journal.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Plant journal'), actions: [
        IconButton(
            tooltip: 'Edit plant details',
            onPressed: () async {
              await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => _EditPlantSheet(
                      plant: current,
                      onSaved: () async {
                        await widget.onChanged();
                        await reload();
                      }));
            },
            icon: const Icon(Icons.edit_outlined)),
      ]),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (current.latestVisit != null)
            AspectRatio(
                aspectRatio: 1.1,
                child: Image.file(File(current.latestVisit!.imagePath),
                    fit: BoxFit.cover,
                    cacheWidth: 1200,
                    errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined)))),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(current.displayName,
                        style: const TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1)),
                    if (current.nickname.isNotEmpty)
                      Text(current.plantLabel,
                          style: const TextStyle(
                              fontSize: 16, color: FloraPalette.muted)),
                    if (current.placeLabel.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(children: [
                            const Icon(Icons.place_outlined, size: 18),
                            const SizedBox(width: 4),
                            Flexible(child: Text(current.placeLabel))
                          ])),
                    const SizedBox(height: 10),
                    Text(
                        '${current.visits.length} ${current.visits.length == 1 ? 'visit' : 'visits'} · Named by you',
                        style: const TextStyle(color: FloraPalette.muted)),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                        onPressed: () async {
                          await widget.onAddVisit(current);
                          await reload();
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Add a visit'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54))),
                    const SizedBox(height: 26),
                    const Text('VISIT HISTORY',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: FloraPalette.forest,
                            letterSpacing: 1)),
                  ])),
        ])),
        SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            sliver: SliverList.builder(
                itemCount: current.visits.length,
                itemBuilder: (context, index) {
                  final visit = current.visits[index];
                  final date = visit.createdAt.toLocal();
                  return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () async {
                                await widget.onOpenVisit(visit);
                                await reload();
                              },
                              child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(children: [
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(File(visit.imagePath),
                                            width: 74,
                                            height: 74,
                                            fit: BoxFit.cover,
                                            cacheWidth: 222,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox(
                                                    width: 74,
                                                    height: 74,
                                                    child: Icon(Icons
                                                        .broken_image_outlined)))),
                                    const SizedBox(width: 14),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(
                                              '${date.day}/${date.month}/${date.year}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16)),
                                          Text(
                                              visit.notes.isEmpty
                                                  ? '${visit.allImagePaths.length} photo'
                                                  : visit.notes,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: FloraPalette.muted)),
                                        ])),
                                    const Icon(Icons.chevron_right_rounded),
                                  ])))));
                })),
      ]),
    );
  }
}

class _EditPlantSheet extends StatefulWidget {
  const _EditPlantSheet({required this.plant, required this.onSaved});
  final PersonalPlant plant;
  final Future<void> Function() onSaved;
  @override
  State<_EditPlantSheet> createState() => _EditPlantSheetState();
}

class _EditPlantSheetState extends State<_EditPlantSheet> {
  late final TextEditingController custom =
      TextEditingController(text: widget.plant.customName);
  late final TextEditingController nickname =
      TextEditingController(text: widget.plant.nickname);
  late final TextEditingController place =
      TextEditingController(text: widget.plant.placeLabel);
  String? speciesId;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    speciesId = widget.plant.speciesId;
  }

  @override
  void dispose() {
    custom.dispose();
    nickname.dispose();
    place.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await GameStore.instance.updatePersonalPlant(widget.plant.id,
          speciesId: speciesId,
          customName: custom.text,
          nickname: nickname.text,
          placeLabel: place.text);
      await widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        setState(() => error = 'Could not save these details. Try again.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
          child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Edit plant',
                    style:
                        TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text(
                    'Names are chosen by you. FLORA does not identify plants.',
                    style: TextStyle(color: FloraPalette.muted)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                    initialValue: speciesId ?? '',
                    decoration:
                        const InputDecoration(labelText: 'Sample catalog name'),
                    items: [
                      const DropdownMenuItem(
                          value: '', child: Text('None / personal name')),
                      ...seedSpecies.map((s) => DropdownMenuItem(
                          value: s.id, child: Text(s.commonName)))
                    ],
                    onChanged: (value) =>
                        setState(() => speciesId = value == '' ? null : value)),
                const SizedBox(height: 10),
                if (speciesId == null)
                  TextField(
                      controller: custom,
                      maxLength: 80,
                      decoration: const InputDecoration(
                          labelText: 'Your plant name',
                          hintText: 'Unknown plant')),
                TextField(
                    controller: nickname,
                    maxLength: 60,
                    decoration: const InputDecoration(
                        labelText: 'Nickname (optional)')),
                TextField(
                    controller: place,
                    maxLength: 80,
                    decoration: const InputDecoration(
                        labelText: 'Place note (optional)')),
                const Text(
                    'Place is written by you; FLORA does not record GPS.',
                    style: TextStyle(color: FloraPalette.muted, fontSize: 13)),
                if (error != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(error!,
                          style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: saving ? null : save,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: Text(saving ? 'Saving…' : 'Save details')),
              ]))));
}
