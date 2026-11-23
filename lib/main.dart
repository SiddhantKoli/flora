import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'data/game_rules.dart';
import 'data/game_store.dart';
import 'data/observation.dart';
import 'data/species.dart';
import 'ui/flora_design.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FloraApp());
}

const forest = FloraPalette.forest;
const canvas = FloraPalette.background;
const ink = FloraPalette.ink;

class FloraApp extends StatefulWidget {
  const FloraApp({super.key});

  @override
  State<FloraApp> createState() => _FloraAppState();
}

class _FloraAppState extends State<FloraApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
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
      if (mounted) {
        setState(() {
          snapshot = next;
          loadError = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => loadError = error);
    }
  }

  Future<void> scan({ImageSource source = ImageSource.camera}) async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (picked == null || !mounted) return;
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      final result = await navigator.push<SaveResult>(MaterialPageRoute(
          builder: (_) => ReviewPage(photo: File(picked.path))));
      if (result == null || !mounted) return;
      await refresh();
      if (!mounted) return;
      if (result.duplicateImage) {
        message('This photo is already in your journal. No XP was added.');
      } else if (result.firstDiscovery) {
        final species = speciesById(result.observation?.speciesId);
        await showModalBottomSheet<void>(
            context: navigator.context,
            showDragHandle: true,
            backgroundColor: canvas,
            builder: (context) => SafeArea(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              height: 190,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: FloraPalette.lime,
                                  borderRadius: BorderRadius.circular(24)),
                              child: Center(child: _speciesArt(species))),
                          const SizedBox(height: 20),
                          Text('NEW DISCOVERY  ·  +${result.xpEarned} XP',
                              style: const TextStyle(
                                  color: forest,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                          const SizedBox(height: 6),
                          Text(species?.commonName ?? 'Plant',
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1)),
                          const SizedBox(height: 8),
                          const Text(
                              'Added to your Plantdex. This is your selection, not an expert identification.',
                              style: TextStyle(
                                  color: FloraPalette.muted, height: 1.4)),
                          const SizedBox(height: 20),
                          FilledButton(
                              onPressed: () => Navigator.pop(context),
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52)),
                              child: const Text('Keep exploring',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w800))),
                        ]))));
      } else {
        message(result.xpEarned > 0
            ? 'Observation saved. +${result.xpEarned} XP'
            : 'Observation saved.');
      }
    } catch (_) {
      if (mounted) {
        message(
            'Could not open or save the photo. Check camera access and try again.');
      }
    }
  }

  void message(String text) =>
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text(text)));

  Widget _speciesArt(Species? species) => species == null
      ? const Icon(Icons.spa_rounded, size: 90, color: forest)
      : PlantIllustration(species: species, scale: 1.05);

  Future<void> claim(String kind) async {
    final xp = await GameStore.instance.claimQuest(kind);
    await refresh();
    if (mounted) {
      message(
          xp > 0 ? 'Quest claimed. +$xp XP' : 'Quest is not ready to claim.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
        seedColor: forest, primary: forest, surface: canvas);
    return MaterialApp(
      title: 'FLORA',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: canvas,
        textTheme: ThemeData.light()
            .textTheme
            .apply(bodyColor: ink, displayColor: ink),
        appBarTheme: const AppBarTheme(
            backgroundColor: canvas,
            foregroundColor: ink,
            surfaceTintColor: Colors.transparent),
        cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22))),
        inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none)),
      ),
      home: Builder(builder: (context) {
        if (loadError != null) {
          return Scaffold(
              body: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Could not open your local collection.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: refresh, child: const Text('Retry'))
          ])));
        }
        if (snapshot == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final state = snapshot!;
        final pages = <Widget>[
          PlantdexPage(
              state: state,
              onScan: () => scan(),
              onLibrary: () => scan(source: ImageSource.gallery)),
          JournalPage(state: state, onChanged: refresh),
          QuestPage(state: state, onClaim: claim),
          ProfilePage(state: state),
        ];
        return Scaffold(
          body: SafeArea(child: IndexedStack(index: tab, children: pages)),
          bottomNavigationBar: FloraNavBar(
              selected: tab,
              onSelect: (value) => setState(() => tab = value),
              onScan: () => scan()),
        );
      }),
    );
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
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> save(String? speciesId) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final result = await GameStore.instance.saveObservation(
          source: widget.photo, speciesId: speciesId, notes: notes.text);
      if (mounted) Navigator.of(context).pop(result);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Could not save this observation. Try another photo.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = seedSpecies
        .where((species) => '${species.commonName} ${species.scientificName}'
            .toLowerCase()
            .contains(search.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
          title: const Text('New observation',
              style:
                  TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5))),
      body: SafeArea(
          child: Column(children: [
        Expanded(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.file(widget.photo,
                      height: 205,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          height: 205,
                          child: Center(
                              child: Text('Photo preview unavailable'))))),
              const SizedBox(height: 20),
              const Text('YOUR FIND',
                  style: TextStyle(
                      color: forest,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              const SizedBox(height: 5),
              const Text('Look familiar?',
                  style: TextStyle(
                      color: ink,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1)),
              const SizedBox(height: 6),
              const Text(
                  'Pick a plant only if you know it. Suggestions are not available yet.',
                  style: TextStyle(color: FloraPalette.muted, height: 1.35)),
              const SizedBox(height: 18),
              TextField(
                  onChanged: (value) => setState(() => search = value),
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name',
                      labelText: 'Find a plant')),
              const SizedBox(height: 10),
              if (matches.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(16),
                    child:
                        Text('No match. You can still save this as unknown.')),
              ...matches.map((species) => _candidateTile(species)),
              const SizedBox(height: 14),
              TextField(
                  controller: notes,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                      labelText: 'Field note (optional)',
                      hintText: 'What did you notice?')),
            ])),
        Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Column(children: [
              FilledButton(
                  onPressed: selectedId == null || saving
                      ? null
                      : () => save(selectedId),
                  style: FilledButton.styleFrom(
                      backgroundColor: FloraPalette.lime,
                      foregroundColor: ink,
                      minimumSize: const Size.fromHeight(54)),
                  child: Text(saving ? 'Saving…' : 'Add to my Plantdex',
                      style: const TextStyle(fontWeight: FontWeight.w900))),
              TextButton(
                  onPressed: saving ? null : () => save(null),
                  child: const Text('Not sure? Save as unknown',
                      style: TextStyle(fontWeight: FontWeight.w700))),
            ])),
      ])),
    );
  }

  Widget _candidateTile(Species species) {
    final selected = selectedId == species.id;
    return Semantics(
        button: true,
        selected: selected,
        label: species.commonName,
        child: InkWell(
          onTap: () => setState(() => selectedId = species.id),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: selected
                    ? FloraPalette.lime.withValues(alpha: 0.35)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: selected ? forest : FloraPalette.line,
                    width: selected ? 2 : 1)),
            child: Row(children: [
              Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: Color(species.color),
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                      child: PlantIllustration(species: species, scale: 0.3))),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(species.commonName,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(species.scientificName,
                        style: const TextStyle(
                            fontSize: 12, color: FloraPalette.muted))
                  ])),
              Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? forest : FloraPalette.muted),
            ]),
          ),
        ));
  }
}

class PlantdexPage extends StatefulWidget {
  const PlantdexPage(
      {super.key,
      required this.state,
      required this.onScan,
      required this.onLibrary});
  final GameSnapshot state;
  final VoidCallback onScan;
  final VoidCallback onLibrary;

  @override
  State<PlantdexPage> createState() => _PlantdexPageState();
}

class _PlantdexPageState extends State<PlantdexPage> {
  String search = '';
  bool unlockedOnly = false;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final entries = seedSpecies.where((species) {
      if (unlockedOnly && !widget.state.unlockedIds.contains(species.id)) {
        return false;
      }
      return '${species.commonName} ${species.scientificName} ${species.family}'
          .toLowerCase()
          .contains(search.toLowerCase());
    }).toList();
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 640 ? 3 : 2;
      return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Row(children: [
              const Text('FLORA',
                  style: TextStyle(
                      color: ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.3)),
              const Text('✦',
                  style: TextStyle(color: FloraPalette.coral, fontSize: 18)),
              const Spacer(),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('GUEST EXPLORER',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5))),
              const SizedBox(width: 5),
              IconButton(
                  onPressed: widget.onLibrary,
                  tooltip: 'Choose a photo',
                  icon: const Icon(Icons.add_photo_alternate_outlined)),
            ]),
            const SizedBox(height: 25),
            const Text('Plantdex',
                style: TextStyle(
                    fontSize: 40,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.8,
                    color: ink)),
            const SizedBox(height: 7),
            const Text('Your pocket-sized world of green.',
                style: TextStyle(
                    fontSize: 15,
                    color: FloraPalette.muted,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 23),
            Container(
              height: 176,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: forest, borderRadius: BorderRadius.circular(26)),
              child: Stack(children: [
                Positioned(
                    right: -15,
                    top: -28,
                    child: Container(
                        width: 158,
                        height: 158,
                        decoration: const BoxDecoration(
                            color: FloraPalette.lime, shape: BoxShape.circle))),
                Positioned(
                    right: -3,
                    top: -38,
                    child: PlantIllustration(
                        species: seedSpecies.first, scale: 0.94)),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('YOUR COLLECTION',
                          style: TextStyle(
                              color: FloraPalette.lime,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1)),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${widget.state.unlockedIds.length.toString().padLeft(2, '0')} / ${seedSpecies.length.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.2)),
                            const Text('plants in your world',
                                style: TextStyle(
                                    color: Color(0xFFD2E2D8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 11),
                            SizedBox(
                                width: 150,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(
                                      begin: 0,
                                      end: widget.state.unlockedIds.length /
                                          seedSpecies.length),
                                  duration: reducedMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 700),
                                  builder: (_, value, __) =>
                                      LinearProgressIndicator(
                                          value: value,
                                          color: FloraPalette.lime,
                                          backgroundColor: Colors.white30,
                                          minHeight: 5,
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                )),
                          ]),
                    ]),
              ]),
            ),
            const SizedBox(height: 24),
            TextField(
                onChanged: (value) => setState(() => search = value),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search your plant world',
                    labelText: 'Search plants')),
            const SizedBox(height: 17),
            Row(children: [
              _filter('All plants', false),
              const SizedBox(width: 8),
              _filter('Collected', true),
              const Spacer(),
              Text('${entries.length} entries',
                  style: const TextStyle(
                      color: FloraPalette.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 18),
            if (entries.isEmpty)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 55),
                  child: Column(children: [
                    const Icon(Icons.spa_outlined,
                        size: 42, color: FloraPalette.muted),
                    const SizedBox(height: 12),
                    Text(
                        unlockedOnly
                            ? 'Nothing collected yet. Tap the camera to begin.'
                            : 'No plants match your search.',
                        textAlign: TextAlign.center)
                  ])),
            if (entries.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78),
                itemBuilder: (context, index) {
                  final species = entries[index];
                  final unlocked =
                      widget.state.unlockedIds.contains(species.id);
                  const backgrounds = [
                    Color(0xFFDDEFC8),
                    FloraPalette.blue,
                    FloraPalette.lilac,
                    Color(0xFFFFD9CD),
                    Color(0xFFCDE9D9),
                    Color(0xFFF6E8B2),
                    Color(0xFFC9E8DF),
                    Color(0xFFF3D7E7)
                  ];
                  final paletteIndex =
                      seedSpecies.indexWhere((item) => item.id == species.id);
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: reducedMotion
                        ? Duration.zero
                        : Duration(milliseconds: 240 + index * 45),
                    builder: (context, opacity, child) => Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                            offset: Offset(0, (1 - opacity) * 10),
                            child: child)),
                    child: Semantics(
                        button: true,
                        label:
                            '${species.commonName}, ${unlocked ? 'collected' : 'not collected'}',
                        child: InkWell(
                          onTap: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (_) => SpeciesDetail(
                                  species: species, unlocked: unlocked)),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                              decoration: BoxDecoration(
                                  color: backgrounds[paletteIndex],
                                  borderRadius: BorderRadius.circular(22)),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: Stack(children: [
                                      Center(
                                          child: PlantIllustration(
                                              species: species,
                                              muted: !unlocked,
                                              scale: 0.8)),
                                      Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Icon(
                                              unlocked
                                                  ? Icons.check_circle
                                                  : Icons.lock_outline_rounded,
                                              size: 18,
                                              color:
                                                  ink.withValues(alpha: 0.65))),
                                    ])),
                                    Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            14, 0, 14, 14),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(species.commonName,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 15,
                                                      letterSpacing: -0.4)),
                                              const SizedBox(height: 3),
                                              Text(
                                                  unlocked
                                                      ? species.scientificName
                                                      : 'Ready to discover',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      color: FloraPalette.muted,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 11)),
                                            ])),
                                  ])),
                        )),
                  );
                },
              ),
            const SizedBox(height: 20),
            Center(
                child: TextButton.icon(
                    onPressed: widget.onScan,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Find something new'))),
          ]);
    });
  }

  Widget _filter(String label, bool value) {
    final active = unlockedOnly == value;
    return ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => setState(() => unlockedOnly = value),
        selectedColor: FloraPalette.lime,
        backgroundColor: Colors.white,
        side: BorderSide.none,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, color: ink));
  }
}

class SpeciesDetail extends StatelessWidget {
  const SpeciesDetail(
      {super.key, required this.species, required this.unlocked});
  final Species species;
  final bool unlocked;

  @override
  Widget build(BuildContext context) => SafeArea(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 210,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Color(species.color),
                        borderRadius: BorderRadius.circular(24)),
                    child: Center(
                        child: PlantIllustration(
                            species: species, muted: !unlocked, scale: 1.08))),
                const SizedBox(height: 22),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                        color: unlocked ? FloraPalette.lime : FloraPalette.line,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        unlocked ? 'IN YOUR COLLECTION' : 'WAITING TO BE FOUND',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5))),
                const SizedBox(height: 10),
                Text(species.commonName,
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2)),
                const SizedBox(height: 2),
                Text(species.scientificName,
                    style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: FloraPalette.muted)),
                const SizedBox(height: 18),
                Text('THE QUICK TAKE',
                    style: TextStyle(
                        color: forest,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1)),
                const SizedBox(height: 7),
                Text(
                    unlocked
                        ? species.description
                        : 'Spot it in the real world, take a photo, and add it to your collection.',
                    style: const TextStyle(fontSize: 15, height: 1.4)),
                const SizedBox(height: 12),
                Text('Family  /  ${species.family}',
                    style: const TextStyle(
                        fontSize: 13,
                        color: FloraPalette.muted,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                const Text(
                    'Draft catalog entry. A selected plant is not an expert identification.',
                    style: TextStyle(fontSize: 12, color: FloraPalette.muted)),
              ])));
}

class QuestPage extends StatelessWidget {
  const QuestPage({super.key, required this.state, required this.onClaim});
  final GameSnapshot state;
  final ValueChanged<String> onClaim;

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 30), children: [
        const Text('Side quests.',
            style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.7)),
        const SizedBox(height: 6),
        const Text('A little motivation to look closer.',
            style: TextStyle(color: FloraPalette.muted, fontSize: 15)),
        const SizedBox(height: 22),
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: forest, borderRadius: BorderRadius.circular(23)),
            child: Row(children: [
              const Icon(Icons.bolt_rounded,
                  color: FloraPalette.lime, size: 36),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${state.xp} XP',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24)),
                const Text('your total so far',
                    style: TextStyle(color: Color(0xFFC4D9CB)))
              ]),
              const Spacer(),
              Text('LVL ${levelForXp(state.xp)}',
                  style: const TextStyle(
                      color: FloraPalette.lime, fontWeight: FontWeight.w900)),
            ])),
        const SizedBox(height: 25),
        const Text('ON THE BOARD',
            style: TextStyle(
                color: FloraPalette.muted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
        const SizedBox(height: 12),
        QuestCard(
            title: 'A new leaf',
            description: 'Record one plant you recognize today.',
            progress: state.dailyProgress,
            target: 1,
            xp: dailyQuestXp,
            claimed: state.dailyClaimed,
            onClaim: () => onClaim('daily')),
        const SizedBox(height: 14),
        QuestCard(
            title: 'The week in green',
            description: 'Find three different plants this week.',
            progress: state.weeklyProgress,
            target: 3,
            xp: weeklyQuestXp,
            claimed: state.weeklyClaimed,
            onClaim: () => onClaim('weekly')),
        const SizedBox(height: 18),
        const Text(
            'Progress comes from your own plant selections. Quests reset on your device’s local calendar.',
            style: TextStyle(
                color: FloraPalette.muted, fontSize: 12, height: 1.4)),
      ]);
}

class QuestCard extends StatelessWidget {
  const QuestCard(
      {super.key,
      required this.title,
      required this.description,
      required this.progress,
      required this.target,
      required this.xp,
      required this.claimed,
      required this.onClaim});
  final String title;
  final String description;
  final int progress;
  final int target;
  final int xp;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final daily = target == 1;
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: daily ? FloraPalette.lilac : FloraPalette.blue,
            borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(15)),
                child: Icon(
                    daily ? Icons.wb_sunny_outlined : Icons.explore_outlined,
                    color: ink)),
            const Spacer(),
            Text('+$xp XP',
                style: const TextStyle(
                    color: ink, fontWeight: FontWeight.w900, fontSize: 15))
          ]),
          const SizedBox(height: 18),
          Text(title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7)),
          const SizedBox(height: 4),
          Text(description,
              style: const TextStyle(color: FloraPalette.ink, fontSize: 14)),
          const SizedBox(height: 22),
          LinearProgressIndicator(
              value: (progress / target).clamp(0.0, 1.0),
              color: forest,
              backgroundColor: Colors.white70,
              minHeight: 7,
              borderRadius: BorderRadius.circular(7)),
          const SizedBox(height: 9),
          Row(children: [
            Text('${progress.clamp(0, target)} of $target',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            const Spacer(),
            if (claimed) const Icon(Icons.check_circle, color: forest, size: 19)
          ]),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: claimed || progress < target ? null : onClaim,
              style: FilledButton.styleFrom(
                  backgroundColor: forest, foregroundColor: Colors.white),
              child: Text(claimed ? 'Claimed' : 'Claim reward',
                  style: const TextStyle(fontWeight: FontWeight.w800))),
        ]));
  }
}

class JournalPage extends StatelessWidget {
  const JournalPage({super.key, required this.state, required this.onChanged});
  final GameSnapshot state;
  final Future<void> Function() onChanged;

  Future<void> openObservation(
      BuildContext context, Observation observation) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ObservationDetail(observation: observation, onChanged: onChanged)));
    await onChanged();
  }

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 30), children: [
        const Text('Field notes.',
            style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.7)),
        const SizedBox(height: 6),
        Text(
            '${state.observations.length} ${state.observations.length == 1 ? 'moment' : 'moments'} kept on this device',
            style: const TextStyle(color: FloraPalette.muted, fontSize: 15)),
        const SizedBox(height: 22),
        if (state.observations.isEmpty)
          Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: FloraPalette.blue,
                  borderRadius: BorderRadius.circular(26)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: PlantIllustration(
                            species: seedSpecies[2], scale: 1.1)),
                    const SizedBox(height: 8),
                    const Text('Every find has a story.',
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7)),
                    const SizedBox(height: 6),
                    const Text(
                        'Your photos and little details will live here. Start with a plant that catches your eye.',
                        style: TextStyle(fontSize: 14, height: 1.4)),
                  ])),
        if (state.observations.isNotEmpty) ...[
          const Text('YOUR MOMENTS',
              style: TextStyle(
                  color: FloraPalette.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          ...state.observations.map((observation) => ObservationTile(
              observation: observation,
              onTap: () => openObservation(context, observation))),
        ],
      ]);
}

class ObservationTile extends StatelessWidget {
  const ObservationTile(
      {super.key, required this.observation, required this.onTap});
  final Observation observation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final species = speciesById(observation.speciesId);
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(File(observation.imagePath),
                            width: 66,
                            height: 66,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                                width: 66,
                                height: 66,
                                child:
                                    Icon(Icons.image_not_supported_outlined)))),
                    const SizedBox(width: 13),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(species?.commonName ?? 'Unknown plant',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                              '${observation.createdAt.toLocal().day}/${observation.createdAt.toLocal().month}/${observation.createdAt.toLocal().year}  ·  ${species == null ? 'Unidentified' : 'Selected by you'}',
                              style: const TextStyle(
                                  color: FloraPalette.muted, fontSize: 12))
                        ])),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: FloraPalette.muted, size: 15),
                  ])),
            )));
  }
}

class ObservationDetail extends StatefulWidget {
  const ObservationDetail(
      {super.key, required this.observation, required this.onChanged});
  final Observation observation;
  final Future<void> Function() onChanged;

  @override
  State<ObservationDetail> createState() => _ObservationDetailState();
}

class _ObservationDetailState extends State<ObservationDetail> {
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    notes = TextEditingController(text: widget.observation.notes);
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> delete() async {
    final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Delete observation?'),
              content: const Text(
                  'The photo and note will be removed from this device. Earned XP and Plantdex discoveries stay in your collection.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'))
              ],
            ));
    if (approved != true) return;
    await GameStore.instance.deleteObservation(widget.observation);
    await widget.onChanged();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final species = speciesById(widget.observation.speciesId);
    return Scaffold(
        appBar: AppBar(
            title: const Text('Field note',
                style: TextStyle(fontWeight: FontWeight.w900)),
            actions: [
              IconButton(
                  onPressed: delete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete observation')
            ]),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.file(File(widget.observation.imagePath),
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                      height: 260,
                      child: Center(child: Text('Photo unavailable'))))),
          const SizedBox(height: 21),
          Text(species == null ? 'SAVED AS UNKNOWN' : 'SELECTED BY YOU',
              style: const TextStyle(
                  color: forest,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontSize: 11)),
          const SizedBox(height: 6),
          Text(species?.commonName ?? 'Unknown plant',
              style: const TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(species?.scientificName ?? 'A story waiting for a name',
              style: const TextStyle(
                  color: FloraPalette.muted, fontStyle: FontStyle.italic)),
          const SizedBox(height: 21),
          const Text('Your field note',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          TextField(
              controller: notes,
              maxLines: 5,
              maxLength: 500,
              decoration:
                  const InputDecoration(labelText: 'What did you notice?')),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: () async {
                await GameStore.instance
                    .updateNotes(widget.observation.id, notes.text);
                await widget.onChanged();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note saved.')));
                }
              },
              style: FilledButton.styleFrom(
                  backgroundColor: FloraPalette.lime,
                  foregroundColor: ink,
                  minimumSize: const Size.fromHeight(52)),
              child: const Text('Save note',
                  style: TextStyle(fontWeight: FontWeight.w900))),
        ]));
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.state});
  final GameSnapshot state;

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 30), children: [
        const Text('You, in bloom.',
            style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.7)),
        const SizedBox(height: 6),
        const Text('A guest explorer with a growing story.',
            style: TextStyle(color: FloraPalette.muted, fontSize: 15)),
        const SizedBox(height: 23),
        Container(
            height: 190,
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
                color: forest, borderRadius: BorderRadius.circular(26)),
            child: Stack(children: [
              Positioned(
                  right: -16,
                  top: -37,
                  child: Container(
                      width: 165,
                      height: 165,
                      decoration: const BoxDecoration(
                          color: FloraPalette.coral, shape: BoxShape.circle))),
              Positioned(
                  right: 5,
                  top: 1,
                  child: Text('${levelForXp(state.xp)}',
                      style: const TextStyle(
                          fontSize: 116,
                          height: 1,
                          color: ink,
                          fontWeight: FontWeight.w900))),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('YOUR LEVEL',
                        style: TextStyle(
                            color: FloraPalette.lime,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1)),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Keep growing.',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24)),
                          const SizedBox(height: 8),
                          Text('${state.xp} XP earned',
                              style: const TextStyle(color: Color(0xFFCFDFD4)))
                        ])
                  ]),
            ])),
        const SizedBox(height: 13),
        Row(children: [
          Expanded(
              child: _stat('${state.unlockedIds.length}', 'Plants found',
                  FloraPalette.lime)),
          const SizedBox(width: 12),
          Expanded(
              child: _stat('${state.observations.length}', 'Field notes',
                  FloraPalette.blue)),
        ]),
        const SizedBox(height: 28),
        const Text('Badges to earn',
            style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7)),
        const SizedBox(height: 12),
        _badge('First find', 'Discover your first plant',
            state.achievements.contains('first_discovery'), FloraPalette.lilac),
        const SizedBox(height: 10),
        _badge('Field collector', 'Discover five different plants',
            state.achievements.contains('five_species'), FloraPalette.coral),
        const SizedBox(height: 28),
        const Text('Your space, your data',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4)),
        const SizedBox(height: 8),
        const Text(
            'Photos and progress live on this device. There is no account or cloud backup in this build. Plant entries are drafts, and selections are not expert identification.',
            style: TextStyle(color: FloraPalette.muted, height: 1.45)),
      ]);

  Widget _stat(String value, String label, Color color) => Container(
      padding: const EdgeInsets.all(17),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
      ]));

  Widget _badge(
          String title, String description, bool unlocked, Color accent) =>
      Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(19)),
          child: Row(children: [
            Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(15)),
                child: Icon(
                    unlocked ? Icons.stars_rounded : Icons.lock_outline_rounded,
                    color: ink)),
            const SizedBox(width: 13),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15)),
                  Text(description,
                      style: const TextStyle(
                          color: FloraPalette.muted, fontSize: 12))
                ])),
            Text(unlocked ? 'EARNED' : 'LOCKED',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: FloraPalette.muted)),
          ]));
}
