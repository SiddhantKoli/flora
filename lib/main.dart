import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'data/app_preferences.dart';
import 'data/game_store.dart';
import 'data/observation.dart';
import 'data/personal_plant.dart';
import 'data/species.dart';
import 'features/camera/add_plant_camera_screen.dart';
import 'features/camera/camera_look.dart';
import 'features/identification/plant_suggestion_service.dart';
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
                        const Text('FIELD NOTES / 001',
                            style: FloraType.caption),
                        const SizedBox(height: 8),
                        const Text('Go outside.\nLook closer.',
                            style: FloraType.display),
                        const SizedBox(height: 12),
                        const Text(
                            'A little field journal for plants you notice.',
                            style: FloraType.body),
                        const SizedBox(height: 20),
                        const ListTile(
                            leading: Icon(Icons.photo_camera_outlined),
                            title: Text('Take a photo in FLORA'),
                            subtitle: Text(
                                'Photos are captured in the app; gallery imports are unavailable.')),
                        const ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title:
                                Text('Check a suggestion, or choose Unknown'),
                            subtitle: Text(
                                'When connected, the model can suggest names. You choose what to save and can correct it later.')),
                        const ListTile(
                            leading: Icon(Icons.phone_android_outlined),
                            title: Text('Keep your finds on this phone'),
                            subtitle: Text(
                                'Your journal stays on this device. A photo is sent for suggestions only when you ask. Export a backup before changing phones.')),
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
                                  color: FloraPalette.mint,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Center(child: _speciesArt(species))),
                          const SizedBox(height: 20),
                          Text('NEW DISCOVERY  ·  +${result.xpEarned} XP',
                              style: FloraType.caption),
                          const SizedBox(height: 6),
                          Text(species?.commonName ?? 'Plant',
                              style: FloraType.display),
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
                              style: FloraType.display.copyWith(fontSize: 31)),
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

  Widget _speciesArt(Species? species) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.spa_rounded, size: 64, color: FloraPalette.night),
          const SizedBox(height: 10),
          Text(species?.commonName.toUpperCase() ?? 'NEW FIND',
              style: FloraType.caption.copyWith(color: FloraPalette.night)),
        ],
      );

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
  final suggestionService = const PlantSuggestionService();
  bool suggestionLoading = false;
  String? suggestionError;
  List<PlantSuggestion> suggestions = const [];
  String? chosenSuggestion;
  int photoEpoch = 0;
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
      photoEpoch++;
      showOriginal = false;
      saveError = null;
      suggestions = const [];
      chosenSuggestion = null;
      suggestionError = null;
      suggestionLoading = false;
    });
  }

  Future<void> findSuggestions() async {
    if (suggestionLoading) return;
    final epoch = photoEpoch;
    setState(() {
      suggestionLoading = true;
      suggestionError = null;
      suggestions = const [];
    });
    try {
      final found = await suggestionService.suggest(photo.originalPath);
      if (!mounted || epoch != photoEpoch) return;
      setState(() {
        suggestions = found;
        if (found.isEmpty)
          suggestionError =
              'No useful suggestions came back. You can name this plant yourself.';
      });
    } on PlantSuggestionException catch (error) {
      if (mounted && epoch == photoEpoch) {
        setState(() => suggestionError = error.message);
      }
    } finally {
      if (mounted && epoch == photoEpoch) {
        setState(() => suggestionLoading = false);
      }
    }
  }

  void chooseSuggestion(PlantSuggestion suggestion) {
    Species? catalogMatch;
    for (final species in seedSpecies) {
      if (species.scientificName.toLowerCase() ==
          suggestion.scientificName.toLowerCase()) {
        catalogMatch = species;
        break;
      }
    }
    setState(() {
      selectedId = catalogMatch?.id;
      chosenSuggestion = suggestion.scientificName;
      customName.text = catalogMatch == null
          ? suggestion.displayName
              .substring(0, suggestion.displayName.length.clamp(0, 80))
          : '';
      suggestionError = null;
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
          title: Text(
              widget.existingPlant == null ? 'Review your find' : 'New visit',
              style: FloraType.title.copyWith(fontSize: 21))),
      body: SafeArea(
          child: Column(children: [
        Expanded(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
              const Text('01 / PHOTO', style: FloraType.caption),
              const SizedBox(height: 10),
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                      File(showOriginal
                          ? photo.originalPath
                          : photo.displayPath),
                      height: 285,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 1000,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          height: 285,
                          child: Center(
                              child: Text('Photo preview unavailable'))))),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: saving ? null : retake,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Retake photo')),
              const SizedBox(height: 24),
              if (saveError != null) ...[
                Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: FloraPalette.coral.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(8)),
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
                    style: FloraType.display.copyWith(fontSize: 32)),
                const SizedBox(height: 6),
                Text(
                    widget.existingPlant!.placeLabel.isEmpty
                        ? 'Add another dated photo to this plant.'
                        : '${widget.existingPlant!.placeLabel} · Add another dated photo.',
                    style: const TextStyle(color: FloraPalette.muted)),
                const SizedBox(height: 18),
              ] else ...[
                const Text('02 / NAME YOUR FIND', style: FloraType.caption),
                const SizedBox(height: 7),
                const Text('Look familiar?', style: FloraType.display),
                const SizedBox(height: 6),
                Text(
                    'Get a possible match, then check it yourself. You can always name the plant or save it as unknown.',
                    style: FloraType.body.copyWith(color: FloraPalette.muted)),
                const SizedBox(height: 18),
                if (suggestionService.isConfigured) ...[
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: FloraPalette.mint,
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ASK THE PLANT MODEL',
                                style: FloraType.caption),
                            const SizedBox(height: 6),
                            Text('Possible matches from your photo',
                                style: FloraType.title.copyWith(fontSize: 21)),
                            const SizedBox(height: 6),
                            const Text(
                                'Only if you tap below, FLORA sends the original photo to Pl@ntNet for suggestions. Your journal copy stays on this phone.',
                                style: FloraType.body),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                                onPressed:
                                    suggestionLoading ? null : findSuggestions,
                                icon: suggestionLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.auto_awesome_rounded),
                                label: Text(suggestionLoading
                                    ? 'Looking for matches…'
                                    : 'Find plant suggestions')),
                            const SizedBox(height: 4),
                            const Text(
                                'Powered by Pl@ntNet · Requires internet',
                                style: FloraType.caption),
                          ])),
                  const SizedBox(height: 14),
                ],
                if (suggestionError != null) ...[
                  Text(suggestionError!,
                      style:
                          FloraType.body.copyWith(color: FloraPalette.muted)),
                  const SizedBox(height: 14),
                ],
                if (suggestions.isNotEmpty) ...[
                  const Text('POSSIBLE MATCHES', style: FloraType.caption),
                  const SizedBox(height: 7),
                  ...suggestions.map((suggestion) => ListTile(
                        selected: chosenSuggestion == suggestion.scientificName,
                        selectedTileColor: FloraPalette.mint,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        title: Text(suggestion.displayName),
                        subtitle: Text(suggestion.scientificName),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${(suggestion.score * 100).round()}%',
                                style: FloraType.caption
                                    .copyWith(color: FloraPalette.signal)),
                            if (chosenSuggestion == suggestion.scientificName)
                              const Icon(Icons.check_circle,
                                  color: FloraPalette.signal, size: 18),
                          ],
                        ),
                        onTap: () => chooseSuggestion(suggestion),
                      )),
                  const Text(
                      'Scores rank model guesses; they are not proof. Check the plant before relying on a name.',
                      style: FloraType.caption),
                  TextButton(
                    onPressed: () => setState(() {
                      suggestions = const [];
                      if (chosenSuggestion != null) {
                        selectedId = null;
                        customName.clear();
                      }
                      chosenSuggestion = null;
                    }),
                    child: const Text('None of these'),
                  ),
                  const Divider(),
                ],
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
                    onChanged: (_) => setState(() {
                          selectedId = null;
                          chosenSuggestion = null;
                        }),
                    decoration: const InputDecoration(
                        labelText: 'Or write your own plant name',
                        hintText: 'Your unverified label')),
                const SizedBox(height: 4),
                const Text(
                    'Names outside the sample catalog stay personal labels, even when a model suggested them.',
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
              const SizedBox(height: 16),
              const Text('03 / FIELD NOTE', style: FloraType.caption),
              const SizedBox(height: 10),
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
            decoration: const BoxDecoration(
                color: FloraPalette.surface,
                border: Border(top: BorderSide(color: FloraPalette.line))),
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
                      backgroundColor: FloraPalette.signal,
                      foregroundColor: Colors.white,
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
          onTap: () => setState(() {
            selectedId = species.id;
            chosenSuggestion = null;
            customName.clear();
          }),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: selected
                    ? FloraPalette.mint.withValues(alpha: 0.65)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: selected ? FloraPalette.signal : FloraPalette.line,
                    width: selected ? 2 : 1)),
            child: Row(children: [
              Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Color(species.color),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(species.commonName.substring(0, 1).toUpperCase(),
                      style:
                          FloraType.title.copyWith(color: FloraPalette.night))),
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
                  color: selected ? FloraPalette.signal : FloraPalette.muted),
            ]),
          ),
        ));
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
            title: Text('Field note',
                style: FloraType.title.copyWith(fontSize: 21)),
            actions: [
              IconButton(
                  onPressed: delete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete observation')
            ]),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('YOUR FIELD RECORD', style: FloraType.caption),
          const SizedBox(height: 10),
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
                      borderRadius: BorderRadius.circular(8),
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
                                            ? FloraPalette.signal
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
              style: FloraType.caption),
          const SizedBox(height: 12),
          Text(
              widget.observation.speciesId == null
                  ? 'PERSONAL PLANT'
                  : 'SELECTED BY YOU',
              style: FloraType.caption),
          const SizedBox(height: 6),
          Text(
              widget.plantName ??
                  speciesById(widget.observation.speciesId)?.commonName ??
                  'Unknown plant',
              style: FloraType.display.copyWith(fontSize: 32)),
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
          const Text('Your field note', style: FloraType.title),
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
                  backgroundColor: FloraPalette.signal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52)),
              child: Text(saving ? 'Saving...' : 'Save changes',
                  style: TextStyle(fontWeight: FontWeight.w900))),
        ]));
  }
}
