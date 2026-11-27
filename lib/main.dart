import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'data/game_rules.dart';
import 'data/app_preferences.dart';
import 'data/game_store.dart';
import 'data/observation.dart';
import 'data/personal_plant.dart';
import 'data/species.dart';
import 'features/camera/add_plant_camera_screen.dart';
import 'features/camera/camera_look.dart';
import 'features/backup/backup_page.dart';
import 'features/journal/personal_journal_page.dart';
import 'features/plantdex/explore_page.dart';
import 'features/quests/progress_page.dart';
import 'features/profile/field_profile_page.dart';
import 'features/settings/settings_page.dart';
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
  bool firstRunChecked = false;
  AppPreferences preferences = const AppPreferences();

  @override
  void initState() {
    super.initState();
    refresh();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final next = await AppPreferencesStore.instance.load();
    if (mounted) setState(() => preferences = next);
  }

  Future<void> updatePreferences(AppPreferences next) async {
    await AppPreferencesStore.instance.save(next);
    if (mounted) setState(() => preferences = next);
  }

  Future<void> clearLocalData() async {
    await GameStore.instance.clearAllData();
    await AppPreferencesStore.instance.save(const AppPreferences());
    final directory = await getApplicationSupportDirectory();
    final marker = File(p.join(directory.path, 'first_run_seen'));
    if (await marker.exists()) await marker.delete();
    if (mounted) {
      setState(() {
        preferences = const AppPreferences();
        tab = 0;
      });
      await refresh();
      message('Local FLORA data deleted.');
    }
  }

  Future<void> refresh() async {
    try {
      final next = await GameStore.instance.snapshot();
      if (mounted) {
        setState(() {
          snapshot = next;
          loadError = null;
        });
        if (!firstRunChecked) {
          firstRunChecked = true;
          showFirstRunGuide();
        }
      }
    } catch (error) {
      if (mounted) setState(() => loadError = error);
    }
  }

  Future<void> showFirstRunGuide() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final marker = File(p.join(directory.path, 'first_run_seen'));
    if (await marker.exists()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = navigatorKey.currentContext;
      if (!mounted || context == null) return;
      final start = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          backgroundColor: canvas,
          builder: (sheetContext) => SafeArea(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome to FLORA',
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        const Text(
                            'A little field journal for plants you notice.',
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 20),
                        const ListTile(
                            leading: Icon(Icons.photo_camera_outlined),
                            title: Text('Take a photo in FLORA'),
                            subtitle: Text(
                                'Photos are captured in the app; gallery imports are unavailable.')),
                        const ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Choose a name, or Unknown'),
                            subtitle: Text(
                                'FLORA does not identify plants. You can correct a name later.')),
                        const ListTile(
                            leading: Icon(Icons.phone_android_outlined),
                            title: Text('Keep your finds on this phone'),
                            subtitle: Text(
                                'Photos and progress stay on your device. Export a backup before changing phones.')),
                        const SizedBox(height: 18),
                        FilledButton(
                            onPressed: () => Navigator.pop(sheetContext, true),
                            style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52)),
                            child: const Text('Add my first plant')),
                        Center(
                            child: TextButton(
                                onPressed: () =>
                                    Navigator.pop(sheetContext, false),
                                child: const Text('Explore first'))),
                      ]))));
      await marker.writeAsString('1');
      if (start == true && mounted) await scan();
    });
  }

  Future<void> scan() async {
    try {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      final photo = await navigator.push<CapturedPlantPhoto>(MaterialPageRoute(
          builder: (_) => AddPlantCameraScreen(
              onPhotoReady: (photo) => navigator.pop(photo))));
      if (photo == null || !mounted) return;
      final capturedPhoto = photo;
      final result = await navigator.push<SaveResult>(
          MaterialPageRoute(builder: (_) => ReviewPage(photo: capturedPhoto)));
      if (result == null || !mounted) return;
      await refresh();
      if (!mounted) return;
      if (result.duplicateImage) {
        message('This photo is already in your journal. No XP was added.');
      } else if (result.firstDiscovery) {
        final species = speciesById(result.observation?.speciesId);
        await showModalBottomSheet<void>(
            context: navigatorKey.currentContext!,
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
                          const SizedBox(height: 8),
                          Text(
                              '${snapshot?.unlockedIds.length ?? 0} plants in your Plantdex',
                              style:
                                  const TextStyle(color: FloraPalette.muted)),
                          const SizedBox(height: 20),
                          FilledButton(
                              onPressed: () =>
                                  viewSavedEntry(context, result.observation),
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52)),
                              child: const Text('View in Journal',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w800))),
                          Center(
                              child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Keep exploring'))),
                        ]))));
      } else {
        final savedPlant = snapshot?.plantById(result.observation?.plantId);
        await showModalBottomSheet<void>(
            context: navigatorKey.currentContext!,
            showDragHandle: true,
            backgroundColor: canvas,
            builder: (context) => SafeArea(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              savedPlant?.displayName == 'Unknown plant'
                                  ? 'Saved as Unknown'
                                  : 'Saved ${savedPlant?.displayName ?? 'plant'}',
                              style: const TextStyle(
                                  fontSize: 29, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text(
                              result.xpEarned > 0
                                  ? '+${result.xpEarned} XP · ${snapshot?.observations.length ?? 0} moments saved'
                                  : '${snapshot?.observations.length ?? 0} moments saved',
                              style:
                                  const TextStyle(color: FloraPalette.muted)),
                          const SizedBox(height: 8),
                          const Text(
                              'You can add more photos, edit the note, or correct the plant name later.'),
                          const SizedBox(height: 20),
                          FilledButton(
                              onPressed: () =>
                                  viewSavedEntry(context, result.observation),
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52)),
                              child: const Text('View in Journal')),
                          Center(
                              child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Keep exploring'))),
                        ]))));
      }
    } catch (error, stackTrace) {
      debugPrint('Scan flow failed: $error\n$stackTrace');
      if (mounted) {
        message(
            'Could not open or save the photo. Check camera access and try again.');
      }
    }
  }

  Future<void> addVisit(PersonalPlant plant) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    try {
      final photo = await navigator.push<CapturedPlantPhoto>(MaterialPageRoute(
          builder: (_) => AddPlantCameraScreen(
              onPhotoReady: (captured) => navigator.pop(captured))));
      if (photo == null || !mounted) return;
      final result = await navigator.push<SaveResult>(MaterialPageRoute(
          builder: (_) => ReviewPage(photo: photo, existingPlant: plant)));
      if (result == null || !mounted) return;
      await refresh();
      if (mounted)
        message('Visit saved to ${plant.displayName}. +${result.xpEarned} XP');
    } catch (error, stackTrace) {
      debugPrint('Add visit failed: $error\n$stackTrace');
      if (mounted) message('Could not save this visit. Try again.');
    }
  }

  void message(String text) =>
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text(text)));

  void viewSavedEntry(BuildContext sheetContext, Observation? observation) {
    Navigator.pop(sheetContext);
    setState(() => tab = 1);
    if (observation?.plantId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => PersonalPlantPage(
                plantId: observation!.plantId!,
                onChanged: refresh,
                onAddVisit: addVisit,
                onOpenVisit: (visit) => navigatorKey.currentState!.push(
                    MaterialPageRoute(
                        builder: (_) => ObservationDetail(
                            observation: visit,
                            onChanged: refresh,
                            plantName: snapshot
                                ?.plantById(visit.plantId)
                                ?.displayName))),
              )));
    });
  }

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
        seedColor: FloraPalette.signal,
        primary: FloraPalette.signal,
        onPrimary: Colors.white,
        surface: FloraPalette.background,
        onSurface: FloraPalette.ink);
    return MaterialApp(
      title: 'FLORA',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
              textScaler: preferences.largeText
                  ? (media.textScaler.scale(1) < 1.18
                      ? const TextScaler.linear(1.18)
                      : media.textScaler)
                  : media.textScaler,
              disableAnimations:
                  preferences.reducedMotion || media.disableAnimations),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'DMSans',
        colorScheme: scheme,
        scaffoldBackgroundColor: canvas,
        textTheme: ThemeData.light()
            .textTheme
            .apply(fontFamily: 'DMSans', bodyColor: ink, displayColor: ink),
        appBarTheme: const AppBarTheme(
            backgroundColor: canvas,
            foregroundColor: ink,
            centerTitle: false,
            titleTextStyle: FloraType.title,
            surfaceTintColor: Colors.transparent),
        cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18))),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
                backgroundColor: FloraPalette.ink,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size(48, 52))),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                foregroundColor: FloraPalette.ink,
                textStyle: const TextStyle(
                    fontFamily: 'DMSans', fontWeight: FontWeight.w700),
                side: const BorderSide(color: FloraPalette.line),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size(48, 48))),
        inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: FloraPalette.line)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: FloraPalette.line)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: FloraPalette.signal, width: 2))),
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
          ExplorePage(state: state, onAddPlant: () => scan()),
          PersonalJournalPage(
              state: state,
              onChanged: refresh,
              onAddPlant: scan,
              onAddVisit: addVisit,
              onOpenVisit: (observation) => navigatorKey.currentState!.push(
                  MaterialPageRoute(
                      builder: (_) => ObservationDetail(
                          observation: observation,
                          onChanged: refresh,
                          plantName: state
                              .plantById(observation.plantId)
                              ?.displayName)))),
          ProgressPage(state: state, onClaim: claim),
          FieldProfilePage(
              state: state,
              preferences: preferences,
              onPreferencesChanged: updatePreferences,
              onRestored: refresh,
              onJournal: () => setState(() => tab = 1),
              onSettings: () => navigatorKey.currentState!.push(
                  MaterialPageRoute(
                      builder: (_) => SettingsPage(
                          state: state,
                          preferences: preferences,
                          onPreferencesChanged: updatePreferences,
                          onDataChanged: refresh,
                          onClearData: clearLocalData)))),
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
  const ReviewPage({super.key, required this.photo, this.existingPlant});
  final CapturedPlantPhoto photo;
  final PersonalPlant? existingPlant;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late CapturedPlantPhoto photo;
  String? selectedId;
  bool showOriginal = false;
  bool saving = false;
  String? saveError;
  String search = '';
  final notes = TextEditingController();
  final customName = TextEditingController();
  final nickname = TextEditingController();
  final placeLabel = TextEditingController();

  @override
  void initState() {
    super.initState();
    photo = widget.photo;
  }

  @override
  void dispose() {
    notes.dispose();
    customName.dispose();
    nickname.dispose();
    placeLabel.dispose();
    super.dispose();
  }

  Future<void> save(String? speciesId, {bool asUnknown = false}) async {
    if (saving) return;
    setState(() {
      saving = true;
      saveError = null;
    });
    try {
      final result = await GameStore.instance.saveObservation(
          source: File(showOriginal ? photo.originalPath : photo.displayPath),
          plantId: widget.existingPlant?.id,
          speciesId: widget.existingPlant?.speciesId ?? speciesId,
          customName:
              widget.existingPlant == null && !asUnknown ? customName.text : '',
          nickname: widget.existingPlant == null ? nickname.text : '',
          placeLabel: widget.existingPlant == null ? placeLabel.text : '',
          notes: notes.text);
      if (result.duplicateImage) {
        if (mounted) {
          setState(() => saveError =
              'This photo is already in your journal. Retake it to save a new observation.');
        }
        return;
      }
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) {
        setState(() => saveError = error is FileSystemException
            ? 'The photo could not be read or saved. Retake it, then try again.'
            : 'Could not save this observation. Your review is still here; try again or retake the photo.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> retake() async {
    final next = await Navigator.of(context).push<CapturedPlantPhoto>(
        MaterialPageRoute(
            builder: (cameraContext) => AddPlantCameraScreen(
                initialLookId: photo.lookId,
                onPhotoReady: (captured) =>
                    Navigator.pop(cameraContext, captured))));
    if (next == null || !mounted) return;
    setState(() {
      photo = next;
      showOriginal = false;
      saveError = null;
    });
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
          title: Text(widget.existingPlant == null ? 'New plant' : 'New visit',
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
                  child: Image.file(
                      File(showOriginal
                          ? photo.originalPath
                          : photo.displayPath),
                      height: 205,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 1000,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          height: 205,
                          child: Center(
                              child: Text('Photo preview unavailable'))))),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                  onPressed: saving ? null : retake,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Retake photo')),
              const SizedBox(height: 12),
              if (saveError != null) ...[
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: FloraPalette.coral,
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 10),
                      Expanded(child: Text(saveError!)),
                    ])),
                const SizedBox(height: 16),
              ],
              if (photo.hasLook) ...[
                Text(
                    'Look: ${lookById(photo.lookId).name}. ${showOriginal ? 'The original photo is selected for saving.' : 'The edited copy is selected for saving.'}',
                    style: const TextStyle(color: FloraPalette.muted)),
                SwitchListTile(
                    title: const Text('Save original photo instead'),
                    value: showOriginal,
                    onChanged: (value) => setState(() => showOriginal = value)),
              ],
              if (widget.existingPlant != null) ...[
                Text(widget.existingPlant!.displayName,
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                    widget.existingPlant!.placeLabel.isEmpty
                        ? 'Add another dated photo to this plant.'
                        : '${widget.existingPlant!.placeLabel} · Add another dated photo.',
                    style: const TextStyle(color: FloraPalette.muted)),
                const SizedBox(height: 18),
              ] else ...[
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
                    'FLORA does not identify plants yet. Choose one only if you recognize it, or save this photo as unknown.',
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
                      child: Text(
                          'No match. You can still save this as unknown.')),
                ...matches.map((species) => _candidateTile(species)),
                const SizedBox(height: 14),
                TextField(
                    controller: customName,
                    maxLength: 80,
                    onChanged: (_) => setState(() => selectedId = null),
                    decoration: const InputDecoration(
                        labelText: 'Or write your own plant name',
                        hintText: 'Your unverified label')),
                const SizedBox(height: 4),
                const Text(
                    'A name you enter yourself stays a personal label, not a verified identification.',
                    style: TextStyle(color: FloraPalette.muted, fontSize: 13)),
                const SizedBox(height: 14),
                TextField(
                    controller: nickname,
                    maxLength: 60,
                    decoration: const InputDecoration(
                        labelText: 'Nickname for this plant (optional)',
                        hintText: 'The balcony one')),
                const SizedBox(height: 8),
                TextField(
                    controller: placeLabel,
                    maxLength: 80,
                    decoration: const InputDecoration(
                        labelText: 'Where did you see it? (optional)',
                        hintText: 'School garden')),
                const SizedBox(height: 4),
                const Text(
                    'Place is a note you write. FLORA does not record GPS here.',
                    style: TextStyle(color: FloraPalette.muted, fontSize: 13)),
                const SizedBox(height: 14),
              ],
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
                  onPressed: (widget.existingPlant == null &&
                              selectedId == null &&
                              customName.text.trim().isEmpty) ||
                          saving
                      ? null
                      : () =>
                          save(widget.existingPlant?.speciesId ?? selectedId),
                  style: FilledButton.styleFrom(
                      backgroundColor: FloraPalette.lime,
                      foregroundColor: ink,
                      minimumSize: const Size.fromHeight(54)),
                  child: Text(
                      saving
                          ? 'Saving…'
                          : widget.existingPlant == null
                              ? 'Save plant'
                              : 'Save visit',
                      style: const TextStyle(fontWeight: FontWeight.w900))),
              if (widget.existingPlant == null)
                TextButton(
                    onPressed:
                        saving ? null : () => save(null, asUnknown: true),
                    child: const Text('Not sure? Save photo as unknown',
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
          onTap: () => setState(() {
            selectedId = species.id;
            customName.clear();
          }),
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
  const PlantdexPage({super.key, required this.state, required this.onScan});
  final GameSnapshot state;
  final VoidCallback onScan;

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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.bolt_rounded,
                    color: FloraPalette.lime, size: 36),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('${state.xp} XP',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24))),
                Text('LVL ${levelForXp(state.xp)}',
                    style: const TextStyle(
                        color: FloraPalette.lime, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                  value: xpIntoLevel(state.xp) / 250,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(7),
                  color: FloraPalette.lime,
                  backgroundColor: Colors.white24),
              const SizedBox(height: 8),
              Text(
                  '${250 - xpIntoLevel(state.xp)} XP to level ${levelForXp(state.xp) + 1}',
                  style: const TextStyle(color: Color(0xFFC4D9CB))),
            ])),
        const SizedBox(height: 12),
        const Text(
            'First catalog discovery: +100 XP. A new photo of a plant already found: +10 XP at most once per day. Unknown plants can still be part of your journal.',
            style: TextStyle(color: FloraPalette.muted, height: 1.4)),
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
            'Quests are optional. You can keep a journal without claiming them. Progress uses your own catalog selections and resets on your device’s local calendar.',
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

class ObservationDetail extends StatefulWidget {
  const ObservationDetail(
      {super.key,
      required this.observation,
      required this.onChanged,
      this.plantName});
  final Observation observation;
  final Future<void> Function() onChanged;
  final String? plantName;

  @override
  State<ObservationDetail> createState() => _ObservationDetailState();
}

class _ObservationDetailState extends State<ObservationDetail> {
  late final TextEditingController notes;
  late List<String> imagePaths;
  late String selectedPhotoPath;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    notes = TextEditingController(text: widget.observation.notes);
    imagePaths = widget.observation.allImagePaths;
    selectedPhotoPath = imagePaths.first;
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> addPhoto() async {
    final photo = await Navigator.of(context).push<CapturedPlantPhoto>(
        MaterialPageRoute(
            builder: (cameraContext) => AddPlantCameraScreen(
                onPhotoReady: (photo) => Navigator.pop(cameraContext, photo))));
    if (photo == null || !mounted) return;
    final selectedPath = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Add this photo?'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.file(File(photo.displayPath),
                    height: 190, fit: BoxFit.contain, cacheWidth: 700),
                const SizedBox(height: 10),
                const Text('This photo will join the same plant entry.'),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel')),
                if (photo.hasLook)
                  TextButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, photo.originalPath),
                      child: const Text('Use original')),
                FilledButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, photo.displayPath),
                    child: const Text('Add photo')),
              ],
            ));
    if (selectedPath == null || !mounted) return;
    try {
      final path = await GameStore.instance
          .addObservationPhoto(widget.observation.id, File(selectedPath));
      if (!mounted) return;
      setState(() {
        imagePaths = [...imagePaths, path];
        selectedPhotoPath = path;
      });
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo added to this plant.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error is StateError
                ? error.message
                : 'Could not add this photo. Please try again.')));
      }
    }
  }

  Future<void> removeSelectedPhoto() async {
    if (selectedPhotoPath == imagePaths.first) return;
    final path = selectedPhotoPath;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Remove this photo?'),
              content: const Text(
                  'This extra photo will be deleted from this device. The plant entry and its original photo will stay.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Remove photo')),
              ],
            ));
    if (confirmed != true) return;
    try {
      await GameStore.instance
          .deleteObservationPhoto(widget.observation.id, path);
      if (!mounted) return;
      setState(() {
        imagePaths = imagePaths.where((item) => item != path).toList();
        selectedPhotoPath = imagePaths.first;
      });
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Extra photo removed.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not remove this photo. Try again.')));
      }
    }
  }

  Future<void> delete() async {
    final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Delete observation?'),
              content: const Text(
                  'This visit and its photos will be removed from this device. If it is the last visit, the personal plant page will also disappear. Earned XP and Plantdex discoveries stay.'),
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
          Semantics(
              button: true,
              label: 'Open full photo',
              child: InkWell(
                  onTap: () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => Dialog.fullscreen(
                          backgroundColor: ink,
                          child: SafeArea(
                              child: Stack(children: [
                            Center(
                                child: InteractiveViewer(
                                    minScale: 1,
                                    maxScale: 4,
                                    child: Image.file(File(selectedPhotoPath),
                                        fit: BoxFit.contain))),
                            Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    tooltip: 'Close photo',
                                    icon: const Icon(Icons.close,
                                        color: Colors.white)))
                          ])))),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(File(selectedPhotoPath),
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          cacheWidth: 1100,
                          errorBuilder: (_, __, ___) => const SizedBox(
                              height: 260,
                              child:
                                  Center(child: Text('Photo unavailable'))))))),
          const SizedBox(height: 21),
          if (imagePaths.length > 1) ...[
            SizedBox(
                height: 78,
                child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imagePaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => InkWell(
                        onTap: () => setState(
                            () => selectedPhotoPath = imagePaths[index]),
                        child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        selectedPhotoPath == imagePaths[index]
                                            ? forest
                                            : Colors.transparent,
                                    width: 2)),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(imagePaths[index]),
                                    width: 66,
                                    height: 66,
                                    fit: BoxFit.cover,
                                    cacheWidth: 198)))))),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
              onPressed: addPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text('Add another photo (${imagePaths.length})')),
          if (selectedPhotoPath != imagePaths.first)
            TextButton.icon(
                onPressed: removeSelectedPhoto,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove selected photo')),
          const SizedBox(height: 10),
          Text(
              'Observed ${widget.observation.createdAt.toLocal().day}/${widget.observation.createdAt.toLocal().month}/${widget.observation.createdAt.toLocal().year}  ·  Tap photo to inspect',
              style: const TextStyle(color: FloraPalette.muted, fontSize: 13)),
          const SizedBox(height: 12),
          Text(
              widget.observation.speciesId == null
                  ? 'PERSONAL PLANT'
                  : 'SELECTED BY YOU',
              style: const TextStyle(
                  color: forest,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontSize: 11)),
          const SizedBox(height: 6),
          Text(
              widget.plantName ??
                  speciesById(widget.observation.speciesId)?.commonName ??
                  'Unknown plant',
              style: const TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(
              speciesById(widget.observation.speciesId)?.scientificName ??
                  'Your own plant label',
              style: const TextStyle(
                  color: FloraPalette.muted, fontStyle: FontStyle.italic)),
          const SizedBox(height: 21),
          const Text(
              'Edit this plant’s name and place from its journal page. Names are selected by you, not verified by FLORA.',
              style: TextStyle(color: FloraPalette.muted, fontSize: 13)),
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
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      try {
                        await GameStore.instance.updateObservation(
                            widget.observation.id,
                            speciesId: widget.observation.speciesId,
                            notes: notes.text);
                        await widget.onChanged();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Observation updated.')));
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Could not update this observation. Try again.')));
                        }
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
              style: FilledButton.styleFrom(
                  backgroundColor: FloraPalette.lime,
                  foregroundColor: ink,
                  minimumSize: const Size.fromHeight(52)),
              child: Text(saving ? 'Saving...' : 'Save changes',
                  style: TextStyle(fontWeight: FontWeight.w900))),
        ]));
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage(
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

  Future<void> editProfile(BuildContext context) async {
    final name = TextEditingController(text: preferences.displayName);
    var avatar = preferences.avatar;
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) => SafeArea(
                child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20,
                        MediaQuery.viewInsetsOf(context).bottom + 22),
                    child: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('Make it yours',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 14),
                          TextField(
                              controller: name,
                              maxLength: 40,
                              decoration: const InputDecoration(
                                  labelText: 'Display name',
                                  hintText: 'Guest explorer')),
                          const SizedBox(height: 8),
                          const Text('Choose an icon',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Wrap(
                              spacing: 10,
                              children: ['leaf', 'flower', 'sun', 'spark']
                                  .map((option) => ChoiceChip(
                                      label: Icon(_avatarIcon(option),
                                          semanticLabel: option),
                                      selected: avatar == option,
                                      onSelected: (_) =>
                                          setSheetState(() => avatar = option)))
                                  .toList()),
                          const SizedBox(height: 18),
                          FilledButton(
                              onPressed: () async {
                                await onPreferencesChanged(preferences.copyWith(
                                    displayName: name.text.trim(),
                                    avatar: avatar));
                                if (sheetContext.mounted)
                                  Navigator.pop(sheetContext);
                              },
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52)),
                              child: const Text('Save profile')),
                        ]))))));
    name.dispose();
  }

  IconData _avatarIcon(String name) => switch (name) {
        'flower' => Icons.local_florist_rounded,
        'sun' => Icons.wb_sunny_rounded,
        'spark' => Icons.auto_awesome_rounded,
        _ => Icons.spa_rounded,
      };

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 30), children: [
        Text(
            preferences.displayName.isEmpty
                ? 'You, in bloom.'
                : '${preferences.displayName}, in bloom.',
            style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.7)),
        const SizedBox(height: 6),
        const Text('Guest profile · saved on this device',
            style: TextStyle(color: FloraPalette.muted, fontSize: 15)),
        const SizedBox(height: 8),
        const Text('Export a backup before reinstalling or changing phones.',
            style: TextStyle(color: FloraPalette.muted, fontSize: 13)),
        const SizedBox(height: 14),
        Row(children: [
          CircleAvatar(
              radius: 29,
              backgroundColor: FloraPalette.lilac,
              child: Icon(_avatarIcon(preferences.avatar),
                  size: 30, color: forest)),
          const SizedBox(width: 12),
          OutlinedButton.icon(
              onPressed: () => editProfile(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile')),
        ]),
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
        const SizedBox(height: 14),
        OutlinedButton.icon(
            onPressed: onJournal,
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Open your plant journal')),
        if (state.plants.isNotEmpty) ...[
          const SizedBox(height: 26),
          const Text('Recent plants',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...state.plants.take(3).map((plant) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.spa_rounded, color: forest),
                title: Text(plant.displayName),
                subtitle: Text(
                    '${plant.visits.length} ${plant.visits.length == 1 ? 'visit' : 'visits'}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onJournal,
              )),
        ],
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
            'Photos and progress live on this device. Plant entries are drafts, and selections are not expert identification.',
            style: TextStyle(color: FloraPalette.muted, height: 1.45)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BackupPage(onRestored: onRestored))),
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Export or restore journal')),
        const SizedBox(height: 10),
        OutlinedButton.icon(
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Settings & privacy')),
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
