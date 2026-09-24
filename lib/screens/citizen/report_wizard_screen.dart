// Ported from src/features/citizen/ReportWizard.tsx
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../data/districts.dart' as district_data;
import '../../engines/ai_pipeline.dart';
import '../../engines/duplicate_check.dart';
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/a11y_store.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/civix_top_bar.dart';
import '../../widgets/department_seal.dart';
import '../../widgets/panel.dart';
import '../../widgets/speak_button.dart';

enum _Mode { voice, text, photo }

class _ConfidenceTier {
  final String label;
  final Color color;
  final int dots;
  const _ConfidenceTier(this.label, this.color, this.dots);
}

_ConfidenceTier _confidenceTier(int pct, dynamic confidence) {
  if (pct >= 50) return _ConfidenceTier(confidence('strong') as String, const Color(0xFF2E7D46), 3);
  if (pct >= 30) return _ConfidenceTier(confidence('possible') as String, const Color(0xFFB58900), 2);
  return _ConfidenceTier(confidence('lessLikely') as String, const Color(0xFF8A8A8A), 1);
}

const List<String> kReportLanguages = [
  'Hindi', 'English', 'Santali', 'Mundari', 'Ho', 'Kurukh', 'Khortha', 'Nagpuri', 'Kurmali', 'Panchpargania',
];

const Map<String, String> _speechRecognitionLang = {'Hindi': 'hi_IN', 'English': 'en_IN'};

class ReportWizardScreen extends ConsumerStatefulWidget {
  const ReportWizardScreen({super.key});

  @override
  ConsumerState<ReportWizardScreen> createState() => _ReportWizardScreenState();
}

class _ReportWizardScreenState extends ConsumerState<ReportWizardScreen> {
  double step = 1;
  _Mode mode = _Mode.voice;
  String language = 'Hindi';
  final TextEditingController textCtrl = TextEditingController();
  String? photoPath;
  String? photoHash;
  bool videoAdded = false;
  bool weakConnectivity = false;
  int? households;
  String districtId = 'ranchi';
  final TextEditingController villageCtrl = TextEditingController();
  double lat = 23.34;
  double lng = 85.31;
  int stageIndex = 0;
  AIPipelineResult? result;
  ({bool matched, double? matchScore, String? issueTitle, String? department})? finalResult;
  String? selectedDept;
  bool recording = false;
  String? voiceError;
  bool locating = false;
  String? locationError;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;

  @override
  void dispose() {
    textCtrl.dispose();
    villageCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    final t = ref.read(dictionaryProvider);
    setState(() {
      locating = true;
      locationError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('service disabled');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          locationError = t('reportWizard.locationPermissionDenied');
          locating = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      var nearest = district_data.districts.first;
      var bestDist = double.infinity;
      for (final d in district_data.districts) {
        final dist = (d.lat - pos.latitude) * (d.lat - pos.latitude) + (d.lng - pos.longitude) * (d.lng - pos.longitude);
        if (dist < bestDist) {
          bestDist = dist;
          nearest = d;
        }
      }
      setState(() {
        lat = pos.latitude;
        lng = pos.longitude;
        districtId = nearest.id;
        locating = false;
      });
    } catch (_) {
      setState(() {
        locationError = t('reportWizard.locationFailed');
        locating = false;
      });
    }
  }

  Future<void> _toggleRecording() async {
    final t = ref.read(dictionaryProvider);
    if (recording) {
      await _speech.stop();
      setState(() => recording = false);
      return;
    }
    if (!_speechReady) {
      _speechReady = await _speech.initialize(onError: (_) => setState(() => voiceError = t('reportWizard.speechCaptureError')));
    }
    if (!_speechReady) {
      setState(() => voiceError = t('reportWizard.speechUnsupported'));
      return;
    }
    setState(() {
      voiceError = null;
      recording = true;
    });
    await _speech.listen(
      onResult: (r) => setState(() => textCtrl.text = r.recognizedWords),
      localeId: _speechRecognitionLang[language],
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      String? hash;
      if (!kIsWeb) {
        hash = hashBytes(await File(file.path).readAsBytes());
      }
      setState(() {
        photoPath = file.path;
        photoHash = hash;
      });
    } catch (_) {
      // best-effort — evidence attachment is optional to the flow beyond marking hasContent
      setState(() => photoPath = 'attached');
    }
  }

  void _runPipeline() {
    setState(() => stageIndex = 0);
    var i = 0;
    Timer.periodic(const Duration(milliseconds: 350), (timer) {
      i++;
      setState(() => stageIndex = i);
      if (i >= aiPipelineStages.length) {
        timer.cancel();
        final r = runAiPipeline(
          rawText: textCtrl.text,
          village: villageCtrl.text.isEmpty ? 'your village' : villageCtrl.text,
          households: households,
        );
        setState(() {
          result = r;
          selectedDept = r.departmentSuggestions.isNotEmpty ? r.departmentSuggestions.first.department : null;
          step = 3.5;
        });
      }
    });
  }

  bool get _hasContent => mode == _Mode.photo ? (photoPath != null || videoAdded) : textCtrl.text.trim().isNotEmpty;
  bool get _canContinue => _hasContent && villageCtrl.text.trim().isNotEmpty;

  void _finish() {
    final r = result;
    if (r == null) return;
    final persona = ref.read(personaProvider);
    final notifier = ref.read(civixStoreProvider.notifier);
    DepartmentSuggestion? chosenDept;
    for (final d in r.departmentSuggestions) {
      if (d.department == selectedDept) chosenDept = d;
    }
    final evidence = <Evidence>[
      if (photoPath != null)
        Evidence(
          id: 'ev-${DateTime.now().millisecondsSinceEpoch}-photo',
          kind: 'photo',
          label: 'Citizen-submitted photo',
          addedBy: persona.name,
          addedAt: DateTime.now().toIso8601String(),
          contentHash: photoHash,
        ),
      if (videoAdded)
        Evidence(
          id: 'ev-${DateTime.now().millisecondsSinceEpoch}-video',
          kind: 'video',
          label: 'Citizen-submitted video clip',
          addedBy: persona.name,
          addedAt: DateTime.now().toIso8601String(),
        ),
    ];
    final res = notifier.submitReport(
      channel: 'app',
      language: language,
      rawText: textCtrl.text.isEmpty ? null : textCtrl.text,
      transcript: r.transcript.isEmpty ? null : r.transcript,
      translation: r.translation.isEmpty ? null : r.translation,
      category: r.category,
      districtId: districtId,
      village: villageCtrl.text.isEmpty ? 'Unnamed village' : villageCtrl.text,
      lat: lat,
      lng: lng,
      urgencyHint: r.extractedFields.urgency,
      affectedGroup: r.extractedFields.affectedGroup,
      households: households,
      citizenSelectedDepartment: chosenDept?.department,
      citizenSelectedDepartmentConfidence: chosenDept?.confidence,
      evidence: evidence,
      reporterId: persona.id,
      reporterName: persona.name,
    );
    final issue = ref.read(civixStoreProvider).masterIssues.where((mi) => mi.id == res.masterIssueId);
    setState(() {
      finalResult = (
        matched: res.matched,
        matchScore: res.matchScore,
        issueTitle: issue.isNotEmpty ? issue.first.title : null,
        department: chosenDept?.department,
      );
      step = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final dataSaver = ref.watch(a11yStoreProvider.select((s) => s.dataSaver));
    final role = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: const CivixTopBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('reportWizard.heading'), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: List.generate(t.list('reportWizard.steps').length, (i) {
              final labels = t.list('reportWizard.steps');
              final active = step.floor() == i + 1 || (i == 3 && step == 4);
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('${i + 1}. ${labels[i]}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: active ? role : CivixColors.neelSoft)),
              );
            }),
          ),
          const SizedBox(height: 16),
          if (step == 1) _buildStep1(t, role),
          if (step == 2) _buildStep2(t, role, dataSaver),
          if (step == 3) _buildStep3(t, role),
          if (step == 3.5 && result != null) _buildStep35(t),
          if (step == 4 && finalResult != null) _buildStep4(t),
        ],
      ),
    );
  }

  Widget _buildStep1(AppDictionary t, Color role) {
    final modes = [
      (_Mode.voice, t('reportWizard.voice'), Icons.mic),
      (_Mode.text, t('reportWizard.text'), Icons.text_fields),
      (_Mode.photo, t('reportWizard.photoVideo'), Icons.camera_alt_outlined),
    ];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(t('reportWizard.howToReport'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              SpeakButton(text: t('reportWizard.howToReport')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: modes
                .map((m) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => setState(() => mode = m.$1),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: mode == m.$1 ? role : CivixColors.rule, width: mode == m.$1 ? 2 : 1),
                              borderRadius: BorderRadius.circular(8),
                              color: mode == m.$1 ? role.withValues(alpha: 0.08) : null,
                            ),
                            child: Column(
                              children: [Icon(m.$3, size: 20), const SizedBox(height: 4), Text(m.$2, style: const TextStyle(fontSize: 11))],
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(t('reportWizard.language'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: language,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(10)),
            items: kReportLanguages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) => setState(() => language = v ?? language),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CivixButton(label: t('reportWizard.continue'), onPressed: () => setState(() => step = 2)),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(AppDictionary t, Color role, bool dataSaver) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mode == _Mode.voice) _buildVoiceCapture(t, role),
          if (mode == _Mode.text) _buildTextCapture(t),
          if (mode == _Mode.photo) _buildPhotoCapture(t),
          const SizedBox(height: 16),
          Text(t('reportWizard.location'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: districtId,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(10)),
                  items: district_data.districts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => districtId = v ?? districtId),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: villageCtrl,
                  decoration: InputDecoration(hintText: t('reportWizard.village'), border: const OutlineInputBorder(), isDense: true, contentPadding: const EdgeInsets.all(10)),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CivixButton(
            label: locating ? t('reportWizard.locating') : t('reportWizard.useMyLocation'),
            variant: CivixButtonVariant.secondary,
            size: CivixButtonSize.sm,
            onPressed: locating ? null : _useMyLocation,
          ),
          if (locationError != null)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text(locationError!, style: const TextStyle(fontSize: 12, color: CivixColors.ember))),
          if (dataSaver)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                color: CivixColors.chuna,
                child: Text(t('reportWizard.mapHiddenDataSaver'), style: const TextStyle(fontSize: 12)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}', style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
            ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: weakConnectivity,
            onChanged: (v) => setState(() => weakConnectivity = v ?? false),
            title: Text(t('reportWizard.lowConnectivity'), style: const TextStyle(fontSize: 13)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          if (weakConnectivity)
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFFFF3CD),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, size: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t('reportWizard.offlineDraft'), style: const TextStyle(fontSize: 12))),
                  TextButton(onPressed: () => setState(() => weakConnectivity = false), child: Text(t('reportWizard.syncNow'))),
                ],
              ),
            ),
          if (!_canContinue)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${mode == _Mode.photo ? t('reportWizard.addPhotoOrVideo') : t('reportWizard.recordOrType')}'
                '${villageCtrl.text.trim().isEmpty ? ' ${t('reportWizard.villageRequired')}' : ''}',
                style: const TextStyle(fontSize: 12, color: CivixColors.ember),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              CivixButton(label: t('reportWizard.back'), variant: CivixButtonVariant.secondary, onPressed: () => setState(() => step = 1)),
              const SizedBox(width: 8),
              CivixButton(
                label: t('reportWizard.continue'),
                onPressed: (weakConnectivity || !_canContinue)
                    ? null
                    : () {
                        setState(() => step = 3);
                        _runPipeline();
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCapture(AppDictionary t, Color role) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(20, (i) => Container(
                  width: 3,
                  height: (8 + (i % 5) * 6).toDouble(),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  color: role.withValues(alpha: recording ? 1 : 0.4),
                )),
          ),
          const SizedBox(height: 8),
          CivixButton(
            label: recording ? t('reportWizard.stopRecording') : t('reportWizard.startRecording'),
            variant: recording ? CivixButtonVariant.secondary : CivixButtonVariant.primary,
            size: CivixButtonSize.sm,
            icon: recording ? Icons.stop : Icons.mic,
            onPressed: _toggleRecording,
          ),
          const SizedBox(height: 8),
          Text(
            recording ? '${t('reportWizard.recordingIn')} $language…' : t('reportWizard.recordingHint'),
            style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft),
          ),
          if (voiceError != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(voiceError!, style: const TextStyle(fontSize: 12, color: Colors.red))),
          const SizedBox(height: 8),
          TextField(
            controller: textCtrl,
            maxLines: 3,
            decoration: InputDecoration(hintText: t('reportWizard.voiceTranscriptPlaceholder'), border: const OutlineInputBorder(), isDense: true, contentPadding: const EdgeInsets.all(10)),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCapture(AppDictionary t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('reportWizard.describeProblem'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: textCtrl,
          maxLines: 4,
          decoration: InputDecoration(hintText: t('reportWizard.describePlaceholder'), border: const OutlineInputBorder(), isDense: true, contentPadding: const EdgeInsets.all(10)),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildPhotoCapture(AppDictionary t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('reportWizard.photo'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CivixColors.neelSoft)),
        const SizedBox(height: 6),
        CivixButton(label: t('reportWizard.attachPhoto'), variant: CivixButtonVariant.secondary, size: CivixButtonSize.sm, onPressed: _pickPhoto),
        if (photoPath != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: kIsWeb || photoPath == 'attached'
                ? Container(
                    height: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.image, size: 32, color: CivixColors.neelSoft),
                  )
                : ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(photoPath!), height: 100, fit: BoxFit.cover)),
          ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Text(t('reportWizard.video'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CivixColors.neelSoft)),
        const SizedBox(height: 6),
        if (videoAdded)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), color: CivixColors.chuna, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.videocam_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(t('reportWizard.videoAttached'), style: const TextStyle(fontSize: 12))),
                TextButton(onPressed: () => setState(() => videoAdded = false), child: Text(t('reportWizard.remove'))),
              ],
            ),
          )
        else
          CivixButton(label: t('reportWizard.attachVideo'), variant: CivixButtonVariant.secondary, size: CivixButtonSize.sm, onPressed: () => setState(() => videoAdded = true)),
      ],
    );
  }

  Widget _buildStep3(AppDictionary t, Color role) {
    return Panel(
      child: Column(
        children: [
          Text(t('reportWizard.aiPreparing'), style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          for (var i = 0; i < aiPipelineStages.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${i < stageIndex ? '✓ ' : i == stageIndex ? '… ' : '  '}${aiPipelineStages[i]}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: i == stageIndex ? FontWeight.w600 : FontWeight.w400,
                  color: i < stageIndex ? CivixColors.lac : (i == stageIndex ? role : CivixColors.neelSoft.withValues(alpha: 0.5)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep35(AppDictionary t) {
    final r = result!;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('reportWizard.original'), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
          Text(r.transcript.isNotEmpty ? r.transcript : (textCtrl.text.isNotEmpty ? textCtrl.text : t('reportWizard.noTextCaptured')), style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('reportWizard.translation'), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                    Text(r.translation.isNotEmpty ? r.translation : textCtrl.text, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              SpeakButton(text: r.translation.isNotEmpty ? r.translation : textCtrl.text),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('reportWizard.category'), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                    Text(r.category.replaceAll('-', ' ')),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('reportWizard.place'), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                    Text(r.extractedFields.place),
                  ],
                ),
              ),
            ],
          ),
          if (r.missingDetails.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(t('reportWizard.missingDetail'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: CivixColors.neelSoft)),
            for (final m in r.missingDetails)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(m, style: const TextStyle(fontSize: 13))),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                        onChanged: (v) => setState(() => households = int.tryParse(v)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (r.departmentSuggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(t('reportWizard.whoShouldGet'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: CivixColors.neelSoft)),
                SpeakButton(text: t('reportWizard.whoShouldGet')),
              ],
            ),
            const SizedBox(height: 8),
            for (final d in r.departmentSuggestions) _buildDeptOption(t, d),
          ],
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: CivixButton(label: t('reportWizard.submitReport'), onPressed: _finish)),
        ],
      ),
    );
  }

  Widget _buildDeptOption(AppDictionary t, DepartmentSuggestion d) {
    final checked = selectedDept == d.department;
    final pct = (d.confidence * 100).round();
    final tier = _confidenceTier(pct, (String key) => t('reportWizard.confidence.$key'));
    final role = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => selectedDept = d.department),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: checked ? role : CivixColors.rule, width: checked ? 2 : 1),
            borderRadius: BorderRadius.circular(8),
            color: checked ? role.withValues(alpha: 0.08) : null,
          ),
          child: Row(
            children: [
              Radio<String>(value: d.department, groupValue: selectedDept, onChanged: (v) => setState(() => selectedDept = v)),
              DepartmentSeal(department: d.department, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.department, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: i < tier.dots ? tier.color : CivixColors.chuna),
                          ),
                        Text(tier.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tier.color)),
                        Text(' ($pct%)', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                      ],
                    ),
                    if (d.scheme != null)
                      Text('${t('reportWizard.scheme')}: ${d.scheme}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                  ],
                ),
              ),
              SpeakButton(text: '${d.department}. ${tier.label}, $pct percent.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep4(AppDictionary t) {
    final f = finalResult!;
    final role = Theme.of(context).colorScheme.primary;
    return Panel(
      child: Column(
        children: [
          if (f.matched) ...[
            Text(t('reportWizard.alreadyReported'), style: TextStyle(fontWeight: FontWeight.w600, color: role)),
            const SizedBox(height: 4),
            Text('${t('reportWizard.similarityMatch')} (${((f.matchScore ?? 0) * 100).round()}% ${t('reportWizard.similarityMatchSuffix')}).', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(f.issueTitle ?? '', style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ] else ...[
            Text(t('reportWizard.newCaseCreated'), style: const TextStyle(fontWeight: FontWeight.w600, color: CivixColors.lac)),
            const SizedBox(height: 4),
            Text(f.issueTitle ?? '', style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
          ],
          if (f.department != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DepartmentSeal(department: f.department!, size: 36),
                const SizedBox(width: 8),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft),
                    children: [
                      TextSpan(text: '${t('reportWizard.routedTo')}: '),
                      TextSpan(text: f.department, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CivixButton(label: t('reportWizard.goToVillageWall'), variant: CivixButtonVariant.secondary, onPressed: () => context.go('/citizen/wall')),
              const SizedBox(width: 8),
              CivixButton(label: t('reportWizard.myReports'), onPressed: () => context.go('/citizen/my-reports')),
            ],
          ),
        ],
      ),
    );
  }
}
