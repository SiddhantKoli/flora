import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'data/game_rules.dart';
import 'data/game_store.dart';
import 'data/observation.dart';
import 'data/species.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FloraApp());
}

const forest = Color(0xFF173D30);
const sage = Color(0xFF7F9E83);
const canvas = Color(0xFFF7F7F1);
const ink = Color(0xFF1B2922);

class FloraApp extends StatefulWidget {
  const FloraApp({super.key});

  @override
  State<FloraApp> createState() => _FloraAppState();
}

class _FloraAppState extends State<FloraApp> {
  GameSnapshot? snapshot;
  Object? loadError;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final next = await GameStore.instance.snapshot();
      if (mounted) setState(() { snapshot = next; loadError = null; });
    } catch (error) {
      if (mounted) setState(() => loadError = error);
    }
  }

  Future<void> scan({ImageSource source = ImageSource.camera}) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (picked == null || !mounted) return;
      final result = await Navigator.of(context).push<SaveResult>(MaterialPageRoute(builder: (_) => ReviewPage(photo: File(picked.path))));
      if (result == null || !mounted) return;
      await refresh();
      if (!mounted) return;
      if (result.duplicateImage) {
        message('This photo is already in your journal. No XP was added.');
      } else if (result.firstDiscovery) {
        final species = speciesById(result.observation?.speciesId);
        await showDialog<void>(context: context, builder: (context) => AlertDialog(
          title: const Text('New discovery'),
          content: Text('${species?.commonName ?? 'Plant'} was added to your Plantdex. +${result.xpEarned} XP\n\nThis is your selection, not an expert identification.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Continue'))],
        ));
      } else {
        message(result.xpEarned > 0 ? 'Observation saved. +${result.xpEarned} XP' : 'Observation saved.');
      }
    } catch (_) {
      if (mounted) message('Could not open or save the photo. Check camera access and try again.');
    }
  }

  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> claim(String kind) async {
    final xp = await GameStore.instance.claimQuest(kind);
    await refresh();
    if (mounted) message(xp > 0 ? 'Quest claimed. +$xp XP' : 'Quest is not ready to claim.');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: forest, primary: forest, surface: canvas);
    return MaterialApp(
      title: 'FLORA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: canvas,
        appBarTheme: const AppBarTheme(backgroundColor: canvas, foregroundColor: ink),
        cardTheme: CardThemeData(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      ),
      home: Builder(builder: (context) {
        if (loadError != null) return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Could not open your local collection.'), const SizedBox(height: 12), FilledButton(onPressed: refresh, child: const Text('Retry'))])));
        if (snapshot == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final state = snapshot!;
        final pages = <Widget>[
          HomePage(state: state, onScan: () => scan(), onLibrary: () => scan(source: ImageSource.gallery), onTab: (value) => setState(() => tab = value)),
          PlantdexPage(state: state),
          QuestPage(state: state, onClaim: claim),
          JournalPage(state: state, onChanged: refresh),
          ProfilePage(state: state),
        ];
        return Scaffold(
          body: SafeArea(child: IndexedStack(index: tab, children: pages)),
          floatingActionButton: tab == 0 ? null : FloatingActionButton.extended(onPressed: () => scan(), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Scan')),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (value) => setState(() => tab = value),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Plantdex'),
              NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Quests'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Journal'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      }),
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: forest)),
    if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54))],
  ]);
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.state, required this.onScan, required this.onLibrary, required this.onTab});
  final GameSnapshot state;
  final VoidCallback onScan;
  final VoidCallback onLibrary;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final level = levelForXp(state.xp);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 32), children: [
      Row(children: [const Expanded(child: PageHeading('Good to see you', subtitle: 'Your field notes start here.')), CircleAvatar(backgroundColor: forest, child: Text('$level', style: const TextStyle(color: Colors.white)))]),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: forest, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LEVEL $level', style: const TextStyle(color: Color(0xFFBFD6BE), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Text('${state.unlockedIds.length} plants discovered', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        LinearProgressIndicator(value: xpIntoLevel(state.xp) / 250, color: const Color(0xFFD1E5B7), backgroundColor: Colors.white24, minHeight: 7, borderRadius: BorderRadius.circular(7)),
        const SizedBox(height: 8),
        Text('${xpIntoLevel(state.xp)} / 250 XP to level ${level + 1}', style: const TextStyle(color: Colors.white70)),
      ])),
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: onScan, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Take a plant photo'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58))),
      const SizedBox(height: 8),
      Center(child: TextButton(onPressed: onLibrary, child: const Text('Choose an existing photo'))),
      const SizedBox(height: 22),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Today’s quest', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)), TextButton(onPressed: () => onTab(2), child: const Text('All quests'))]),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const Icon(Icons.flag_outlined, color: forest), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Record one plant', style: TextStyle(fontWeight: FontWeight.w600)), Text('${state.dailyProgress}/1 observation · +50 XP', style: const TextStyle(color: Colors.black54))])), Icon(state.dailyClaimed ? Icons.check_circle : Icons.chevron_right, color: forest)]))),
      const SizedBox(height: 20),
      Text('Recent discoveries', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      if (state.observations.isEmpty) const Text('Your journal is empty. Take a photo to begin.', style: TextStyle(color: Colors.black54)),
      ...state.observations.take(3).map((observation) => ObservationTile(observation: observation, onTap: () => onTab(3))),
      const SizedBox(height: 16),
      const Text('Plant suggestions are not available in this prototype. You choose a catalog entry or save the photo as unknown.', style: TextStyle(color: Colors.black54, fontSize: 12)),
    ]);
  }
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.photo});
  final File photo;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  String? selectedId;
  bool saving = false;
  String search = '';
  final notes = TextEditingController();

  @override
  void dispose() { notes.dispose(); super.dispose(); }

  Future<void> save(String? speciesId) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final result = await GameStore.instance.saveObservation(source: widget.photo, speciesId: speciesId, notes: notes.text);
      if (mounted) Navigator.of(context).pop(result);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save this observation. Try another photo.')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = seedSpecies.where((species) => '${species.commonName} ${species.scientificName}'.toLowerCase().contains(search.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Review photo')),
      body: SafeArea(child: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
          ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(widget.photo, height: 220, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 220, child: Center(child: Text('Photo preview unavailable'))))),
          const SizedBox(height: 18),
          const PageHeading('What did you find?', subtitle: 'Select a plant only if you recognize it. No automatic identification is available yet.'),
          const SizedBox(height: 18),
          TextField(onChanged: (value) => setState(() => search = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search the draft catalog', labelText: 'Search plants')),
          const SizedBox(height: 10),
          if (matches.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No plants match. You can save this as unknown.')),
          ...matches.map((species) => Card(child: RadioListTile<String>(
            value: species.id, groupValue: selectedId, onChanged: (value) => setState(() => selectedId = value),
            title: Text(species.commonName), subtitle: Text(species.scientificName),
            secondary: CircleAvatar(backgroundColor: Color(species.color), child: Text(species.glyph, style: const TextStyle(color: forest, fontSize: 24))),
          ))),
          const SizedBox(height: 14),
          TextField(controller: notes, minLines: 2, maxLines: 4, maxLength: 500, decoration: const InputDecoration(labelText: 'Field note (optional)', hintText: 'What did you notice?')),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16), child: Column(children: [
          FilledButton(onPressed: selectedId == null || saving ? null : () => save(selectedId), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)), child: Text(saving ? 'Saving…' : 'Save selected plant')),
          TextButton(onPressed: saving ? null : () => save(null), child: const Text('Not sure — save as unknown')),
        ])),
      ])),
    );
  }
}

class PlantdexPage extends StatefulWidget {
  const PlantdexPage({super.key, required this.state});
  final GameSnapshot state;

  @override
  State<PlantdexPage> createState() => _PlantdexPageState();
}

class _PlantdexPageState extends State<PlantdexPage> {
  String search = '';
  bool unlockedOnly = false;

  @override
  Widget build(BuildContext context) {
    final entries = seedSpecies.where((species) {
      if (unlockedOnly && !widget.state.unlockedIds.contains(species.id)) return false;
      return '${species.commonName} ${species.scientificName} ${species.family}'.toLowerCase().contains(search.toLowerCase());
    }).toList();
    return CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 16), sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeading('Plantdex', subtitle: '${widget.state.unlockedIds.length} of ${seedSpecies.length} draft entries discovered'),
        const SizedBox(height: 18),
        TextField(onChanged: (value) => setState(() => search = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search plants', hintText: 'Name or family')),
        const SizedBox(height: 8),
        FilterChip(label: const Text('Discovered'), selected: unlockedOnly, onSelected: (value) => setState(() => unlockedOnly = value)),
      ]))),
      if (entries.isEmpty) const SliverFillRemaining(child: Center(child: Text('No plants match this search.'))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), sliver: SliverLayoutBuilder(builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        return SliverGrid.builder(
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: width >= 620 ? 3 : 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.83),
          itemBuilder: (context, index) {
            final species = entries[index];
            final unlocked = widget.state.unlockedIds.contains(species.id);
            return Semantics(button: true, label: '${species.commonName}, ${unlocked ? 'discovered' : 'not discovered'}', child: InkWell(
              onTap: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => SpeciesDetail(species: species, unlocked: unlocked)),
              borderRadius: BorderRadius.circular(18),
              child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: Color(species.color), borderRadius: const BorderRadius.vertical(top: Radius.circular(18))), child: Center(child: Text(unlocked ? species.glyph : '?', style: TextStyle(color: forest.withValues(alpha: unlocked ? 0.85 : 0.4), fontSize: 64))))),
                Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(species.commonName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(unlocked ? species.scientificName : 'Not discovered', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 12))])),
              ])),
            ));
          },
        );
      })),
    ]);
  }
}

class SpeciesDetail extends StatelessWidget {
  const SpeciesDetail({super.key, required this.species, required this.unlocked});
  final Species species;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 30), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: Color(species.color), borderRadius: BorderRadius.circular(16)), child: Center(child: Text(unlocked ? species.glyph : '?', style: const TextStyle(fontSize: 80, color: forest)))),
    const SizedBox(height: 20),
    Text(species.commonName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
    const SizedBox(height: 3),
    Text(species.scientificName, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
    const SizedBox(height: 18),
    Text('Family: ${species.family}', style: const TextStyle(fontWeight: FontWeight.w600)),
    const SizedBox(height: 10),
    Text(unlocked ? species.description : 'Take a photo and select this plant to add it to your collection.'),
    const SizedBox(height: 18),
    const Text('Draft catalog entry. Identity and content require botanical review before release.', style: TextStyle(fontSize: 12, color: Colors.black54)),
  ])));
}

class QuestPage extends StatelessWidget {
  const QuestPage({super.key, required this.state, required this.onClaim});
  final GameSnapshot state;
  final ValueChanged<String> onClaim;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 24), children: [
    const PageHeading('Quests', subtitle: 'A little reason to look closer today.'),
    const SizedBox(height: 24),
    QuestCard(title: 'Daily field note', description: 'Record one selected plant today.', progress: state.dailyProgress, target: 1, xp: dailyQuestXp, claimed: state.dailyClaimed, onClaim: () => onClaim('daily')),
    const SizedBox(height: 12),
    QuestCard(title: 'Weekly explorer', description: 'Record three different plants this week.', progress: state.weeklyProgress, target: 3, xp: weeklyQuestXp, claimed: state.weeklyClaimed, onClaim: () => onClaim('weekly')),
    const SizedBox(height: 14),
    const Text('Quest progress counts your own selections. New daily and weekly quests begin with your device’s local calendar.', style: TextStyle(color: Colors.black54, fontSize: 12)),
  ]);
}

class QuestCard extends StatelessWidget {
  const QuestCard({super.key, required this.title, required this.description, required this.progress, required this.target, required this.xp, required this.claimed, required this.onClaim});
  final String title;
  final String description;
  final int progress;
  final int target;
  final int xp;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))), Text('+$xp XP', style: const TextStyle(color: forest, fontWeight: FontWeight.w700))]),
    const SizedBox(height: 5), Text(description, style: const TextStyle(color: Colors.black54)),
    const SizedBox(height: 16), LinearProgressIndicator(value: (progress / target).clamp(0.0, 1.0), color: forest, backgroundColor: const Color(0xFFE5EBE3), minHeight: 6, borderRadius: BorderRadius.circular(6)),
    const SizedBox(height: 8), Text('${progress.clamp(0, target)} / $target complete'),
    const SizedBox(height: 12), Align(alignment: Alignment.centerRight, child: FilledButton.tonal(onPressed: claimed || progress < target ? null : onClaim, child: Text(claimed ? 'Claimed' : 'Claim reward'))),
  ])));
}

class JournalPage extends StatelessWidget {
  const JournalPage({super.key, required this.state, required this.onChanged});
  final GameSnapshot state;
  final Future<void> Function() onChanged;

  Future<void> openObservation(BuildContext context, Observation observation) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ObservationDetail(observation: observation, onChanged: onChanged)));
    await onChanged();
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 24), children: [
    PageHeading('Field journal', subtitle: '${state.observations.length} observations saved on this device'),
    const SizedBox(height: 18),
    if (state.observations.isEmpty) const Padding(padding: EdgeInsets.only(top: 50), child: Center(child: Text('Your photos and notes will appear here.'))),
    ...state.observations.map((observation) => ObservationTile(observation: observation, onTap: () => openObservation(context, observation))),
  ]);
}

class ObservationTile extends StatelessWidget {
  const ObservationTile({super.key, required this.observation, required this.onTap});
  final Observation observation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final species = speciesById(observation.speciesId);
    return Card(child: ListTile(
      onTap: onTap,
      leading: ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.file(File(observation.imagePath), width: 54, height: 54, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 54, height: 54, child: Icon(Icons.image_not_supported_outlined)))),
      title: Text(species?.commonName ?? 'Unknown plant'),
      subtitle: Text('${observation.createdAt.toLocal().day}/${observation.createdAt.toLocal().month}/${observation.createdAt.toLocal().year} · ${species == null ? 'Not identified' : 'Selected by you'}'),
      trailing: const Icon(Icons.chevron_right),
    ));
  }
}

class ObservationDetail extends StatefulWidget {
  const ObservationDetail({super.key, required this.observation, required this.onChanged});
  final Observation observation;
  final Future<void> Function() onChanged;

  @override
  State<ObservationDetail> createState() => _ObservationDetailState();
}

class _ObservationDetailState extends State<ObservationDetail> {
  late final TextEditingController notes;

  @override
  void initState() { super.initState(); notes = TextEditingController(text: widget.observation.notes); }
  @override
  void dispose() { notes.dispose(); super.dispose(); }

  Future<void> delete() async {
    final approved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete observation?'),
      content: const Text('The photo and note will be removed from this device. Earned XP and Plantdex discoveries stay in your collection.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
    ));
    if (approved != true) return;
    await GameStore.instance.deleteObservation(widget.observation);
    await widget.onChanged();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final species = speciesById(widget.observation.speciesId);
    return Scaffold(appBar: AppBar(title: const Text('Observation'), actions: [IconButton(onPressed: delete, icon: const Icon(Icons.delete_outline), tooltip: 'Delete observation')]), body: ListView(padding: const EdgeInsets.all(20), children: [
      ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(File(widget.observation.imagePath), height: 280, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 280, child: Center(child: Text('Photo unavailable'))))),
      const SizedBox(height: 20),
      PageHeading(species?.commonName ?? 'Unknown plant', subtitle: species == null ? 'Saved without an identification' : '${species.scientificName} · selected by you'),
      const SizedBox(height: 18),
      TextField(controller: notes, maxLines: 5, maxLength: 500, decoration: const InputDecoration(labelText: 'Field note')),
      const SizedBox(height: 12),
      FilledButton(onPressed: () async { await GameStore.instance.updateNotes(widget.observation.id, notes.text); await widget.onChanged(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved.'))); }, child: const Text('Save note')),
    ]));
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.state});
  final GameSnapshot state;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 24), children: [
    const PageHeading('Your profile', subtitle: 'Playing as a guest on this device'),
    const SizedBox(height: 22),
    Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Level ${levelForXp(state.xp)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: forest)),
      Text('${state.xp} total XP · ${state.unlockedIds.length} discoveries'),
    ]))),
    const SizedBox(height: 20),
    Text('Achievements', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    ListTile(leading: Icon(state.achievements.contains('first_discovery') ? Icons.emoji_events : Icons.lock_outline, color: forest), title: const Text('First find'), subtitle: const Text('Discover your first plant'), trailing: Text(state.achievements.contains('first_discovery') ? 'Unlocked' : 'Locked')),
    ListTile(leading: Icon(state.achievements.contains('five_species') ? Icons.emoji_events : Icons.lock_outline, color: forest), title: const Text('Field collector'), subtitle: const Text('Discover five different plants'), trailing: Text(state.achievements.contains('five_species') ? 'Unlocked' : 'Locked')),
    const Divider(height: 32),
    const Text('About this build', style: TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    const Text('Photos and progress stay on this device. There is no account, cloud backup, or automatic plant identification yet. Catalog content is a draft and should not be used for safety, edibility, or medical decisions.', style: TextStyle(color: Colors.black54)),
  ]);
}
