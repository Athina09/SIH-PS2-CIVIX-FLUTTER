// Ported from src/features/project/LiveProjectRecord.tsx
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../state/persona_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/panel.dart';
import '../../widgets/status_chip.dart';

String _fmtDate(String iso, [String pattern = 'd MMM yyyy']) {
  try {
    return DateFormat(pattern).format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

const _tabKeys = ['Overview', 'Timeline', 'Funds', 'Documents', 'Risks', 'Pilot results', 'Council', 'Community', 'Audit'];

const _seatIcon = {
  'reporter': Icons.person_outline,
  'panchayat': Icons.account_balance_outlined,
  'beneficiary': Icons.groups_outlined,
  'expert': Icons.school_outlined,
  'official': Icons.verified_user_outlined,
};

const _severityIcon = {'low': Icons.info_outline, 'medium': Icons.warning_amber_outlined, 'high': Icons.report_gmailerrorred_outlined};
const _severityTone = {'low': ChipTone.neutral, 'medium': ChipTone.risk, 'high': ChipTone.failed};
const _severityColor = {'low': CivixColors.neelSoft, 'medium': CivixColors.tasar, 'high': CivixColors.ember};

bool _isWeatherRisk(String label) => RegExp(r'monsoon|rain|cloud|weather|flood|drought', caseSensitive: false).hasMatch(label);

class LiveProjectRecordScreen extends ConsumerStatefulWidget {
  final String projectId;
  const LiveProjectRecordScreen({super.key, required this.projectId});

  @override
  ConsumerState<LiveProjectRecordScreen> createState() => _LiveProjectRecordScreenState();
}

class _LiveProjectRecordScreenState extends ConsumerState<LiveProjectRecordScreen> {
  String _tab = 'Overview';
  String? _uploadingMilestoneId;
  bool _checkingFundsDoc = false;

  final _riskLabelController = TextEditingController();
  String _riskSeverity = 'medium';

  final _metricLabelController = TextEditingController();
  final _metricValueController = TextEditingController();
  final _metricUnitController = TextEditingController();
  final _metricTargetController = TextEditingController();

  @override
  void dispose() {
    _riskLabelController.dispose();
    _metricLabelController.dispose();
    _metricValueController.dispose();
    _metricUnitController.dispose();
    _metricTargetController.dispose();
    super.dispose();
  }

  Future<String?> _pickFileAndHash() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return null;
    final contentHash = sha256.convert(bytes).toString();
    return jsonEncode({'name': file.name, 'contentHash': contentHash});
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(dictionaryProvider);
    final persona = ref.watch(personaProvider);
    final store = ref.watch(civixStoreProvider);
    final notifier = ref.read(civixStoreProvider.notifier);

    final project = store.projects.where((p) => p.id == widget.projectId).firstOrNull;
    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('liveProjectRecord.notFound'))),
        body: Center(child: Text(t('liveProjectRecord.notFound'))),
      );
    }

    final owner = store.institutions.where((i) => i.id == project.ownerId).firstOrNull;
    final district = store.districts.where((d) => d.id == project.districtId).firstOrNull;
    final issue = store.masterIssues.where((mi) => mi.id == project.issueId).firstOrNull;
    final isGovernment = persona.role == 'government';
    final isUniversity = persona.role == 'university';

    String? sourceIssueHref;
    if (issue != null) {
      if (isGovernment) {
        sourceIssueHref = '/gov/issues/${issue.id}';
      } else if (isUniversity) {
        sourceIssueHref = '/uni/challenges/${issue.id}';
      } else if (persona.role == 'citizen') {
        sourceIssueHref = '/citizen/wall/${issue.id}';
      }
    }

    final totalReleased = project.pledges.where((p) => p.status == 'released').fold<double>(0, (s, p) => s + (p.amount ?? 0));
    final totalPledged = project.pledges.fold<double>(0, (s, p) => s + (p.amount ?? 0));
    final fundsDocs = project.documents.where((d) => d.kind == 'funds-allocation').toList();
    final releasedBudget = project.milestones.where((m) => m.status == 'released').fold<double>(0, (s, m) => s + m.budget);

    return Scaffold(
      appBar: AppBar(
        title: Text(project.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (owner != null || district != null)
                      Text('${owner?.name ?? ''} · ${district?.name ?? ''}', style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
                  ],
                ),
              ),
              StatusChip(
                label: project.stage.replaceAll('-', ' '),
                tone: project.stage == 'failed' ? ChipTone.failed : ChipTone.progress,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isGovernment)
            Wrap(
              spacing: 8,
              children: [
                if (project.stage != 'failed' && project.stage != 'scaled')
                  CivixButton(
                    label: t('liveProjectRecord.advanceStage'),
                    variant: CivixButtonVariant.secondary,
                    size: CivixButtonSize.sm,
                    onPressed: () => _record(notifier.advanceProjectStage(project.id, persona.name)),
                  ),
                if (project.stage != 'failed')
                  CivixButton(
                    label: t('liveProjectRecord.markFailed'),
                    variant: CivixButtonVariant.danger,
                    size: CivixButtonSize.sm,
                    onPressed: () => _record(notifier.markProjectFailed(
                      project.id,
                      persona.name,
                      category: 'other',
                      type: 'technical',
                      lesson: t('liveProjectRecord.markedFailed', {'title': project.title}),
                      designWarning: t('liveProjectRecord.investigateRootCause'),
                    )),
                  ),
              ],
            )
          else
            Text(t('liveProjectRecord.onlyControlRoom'), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _tabKeys.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(t('liveProjectRecord.tabs.$i')),
                      selected: _tab == _tabKeys[i],
                      onSelected: (_) => setState(() => _tab = _tabKeys[i]),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: CivixColors.rule),
          const SizedBox(height: 12),

          if (_tab == 'Overview') ..._overview(t, project, issue, sourceIssueHref),
          if (_tab == 'Timeline') ..._timeline(t, project, notifier, persona, isGovernment, isUniversity, releasedBudget),
          if (_tab == 'Funds') ..._funds(t, project, notifier, persona, isGovernment, totalPledged, totalReleased, fundsDocs),
          if (_tab == 'Documents') ..._documents(t, project),
          if (_tab == 'Risks') ..._risks(t, project, notifier, persona, isGovernment),
          if (_tab == 'Pilot results') ..._pilotResults(t, project, notifier, persona, isUniversity),
          if (_tab == 'Council') ..._council(t, project),
          if (_tab == 'Community') ..._community(t, project),
          if (_tab == 'Audit') ..._audit(t, store, project),
        ],
      ),
    );
  }

  void _record(String? message) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<Widget> _overview(AppDictionary t, Project project, MasterIssue? issue, String? sourceIssueHref) {
    return [
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv(t('liveProjectRecord.budget'), formatCurrency(project.budget)),
            const SizedBox(height: 6),
            _kv(t('liveProjectRecord.maintenancePlanLabel'), project.maintenancePlan),
            const SizedBox(height: 12),
            if (issue?.problemStatement != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('liveProjectRecord.generatedProblemStatement'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(issue!.problemStatement!.summary, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('${t('liveProjectRecord.scope')} ${issue.problemStatement!.scope}', style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                    Text('${t('liveProjectRecord.successCriteria')} ${issue.problemStatement!.successCriteria.join('; ')}',
                        style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                    Text('${t('liveProjectRecord.disciplinesNeeded')} ${issue.problemStatement!.disciplinesNeeded.join(', ')}',
                        style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                    if (sourceIssueHref != null) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => context.push(sourceIssueHref),
                        child: Text(t('liveProjectRecord.viewSourceIssue'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CivixColors.neel, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ],
                ),
              ),
            ] else
              Text(t('liveProjectRecord.noProblemStatement'), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
            const SizedBox(height: 12),
            Text(t('liveProjectRecord.updates'), style: const TextStyle(fontWeight: FontWeight.w600)),
            for (final u in project.updates)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${_fmtDate(u.at)} — ${u.text}', style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _timeline(AppDictionary t, Project project, CivixNotifier notifier, Persona persona, bool isGovernment, bool isUniversity, double releasedBudget) {
    final pct = project.budget == 0 ? 0.0 : (releasedBudget / project.budget).clamp(0, 1).toDouble();
    return [
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t('liveProjectRecord.budgetReleased'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CivixColors.neelSoft)),
                Text('${formatCurrency(releasedBudget)} ${t('liveProjectRecord.of')} ${formatCurrency(project.budget)}',
                    style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: pct, minHeight: 10, backgroundColor: CivixColors.rule, color: CivixColors.sal),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      for (final m in project.milestones) ...[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600, color: CivixColors.neel)),
                        Text('${t('liveProjectRecord.due')} ${_fmtDate(m.due)}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatCurrency(m.budget), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CivixColors.neel)),
                      const SizedBox(height: 4),
                      StatusChip(
                        label: t('projectBriefModal.milestoneStatus.${m.status}'),
                        tone: m.status == 'released' ? ChipTone.success : m.status == 'pending' ? ChipTone.neutral : ChipTone.progress,
                      ),
                    ],
                  ),
                ],
              ),
              if (m.proof != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showDoc(m.proof!),
                  child: Text('📄 ${m.proof!.title}', style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft, decoration: TextDecoration.underline)),
                ),
              ],
              const SizedBox(height: 8),
              const Divider(color: CivixColors.rule, height: 1),
              const SizedBox(height: 8),
              if (m.status == 'pending' && isUniversity)
                _uploadingMilestoneId == m.id
                    ? Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          CivixButton(
                            label: t('liveProjectRecord.upload'),
                            size: CivixButtonSize.sm,
                            onPressed: () async {
                              final picked = await _pickFileAndHash();
                              if (picked == null) return;
                              final data = jsonDecode(picked) as Map<String, dynamic>;
                              final msg = notifier.submitMilestoneProof(
                                project.id,
                                m.id,
                                Doc(id: '', title: data['name'], kind: 'proof', addedAt: '', contentHash: data['contentHash']),
                                persona.name,
                              );
                              setState(() => _uploadingMilestoneId = null);
                              _record(msg);
                            },
                          ),
                          CivixButton(
                            label: t('liveProjectRecord.cancel'),
                            variant: CivixButtonVariant.ghost,
                            size: CivixButtonSize.sm,
                            onPressed: () => setState(() => _uploadingMilestoneId = null),
                          ),
                        ],
                      )
                    : CivixButton(
                        label: t('liveProjectRecord.submitProof'),
                        variant: CivixButtonVariant.secondary,
                        size: CivixButtonSize.sm,
                        onPressed: () => setState(() => _uploadingMilestoneId = m.id),
                      ),
              if (m.status == 'pending' && !isUniversity)
                Text(t('liveProjectRecord.awaitingUniversityProof'), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
              if (m.status == 'submitted' && isGovernment)
                CivixButton(
                  label: t('liveProjectRecord.approveAndRelease'),
                  size: CivixButtonSize.sm,
                  onPressed: () => _record(notifier.approveMilestone(project.id, m.id, persona.name)),
                ),
              if (m.status == 'submitted' && !isGovernment)
                Text(t('liveProjectRecord.awaitingControlRoomApproval'), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _funds(AppDictionary t, Project project, CivixNotifier notifier, Persona persona, bool isGovernment, double totalPledged, double totalReleased,
      List<Doc> fundsDocs) {
    return [
      Row(
        children: [
          Expanded(
            child: Panel(
              child: Column(
                children: [
                  Text(formatCurrency(totalPledged), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: CivixColors.neel)),
                  Text(t('liveProjectRecord.pledged'), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Panel(
              child: Column(
                children: [
                  Text(formatCurrency(totalReleased), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: CivixColors.sal)),
                  Text(t('liveProjectRecord.released'), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      for (final p in project.pledges) ...[
        Panel(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.description, style: const TextStyle(fontWeight: FontWeight.w600, color: CivixColors.neel)),
                    Text(t('opportunities.typeLabels.${p.type}'), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                  ],
                ),
              ),
              if (p.amount != null) Text(formatCurrency(p.amount!), style: const TextStyle(fontWeight: FontWeight.bold, color: CivixColors.neel)),
              const SizedBox(width: 8),
              StatusChip(label: t('industryPortfolio.pledgeStatus.${p.status}'), tone: p.status == 'released' ? ChipTone.success : ChipTone.neutral),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('liveProjectRecord.govFundsDocsHeading'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (fundsDocs.isEmpty) Text(t('liveProjectRecord.noFundsDoc'), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
            for (final d in fundsDocs)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => _showDoc(d),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(border: Border.all(color: CivixColors.rule), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('📄 ${d.title}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, decoration: TextDecoration.underline))),
                        Text(
                          d.duplicateStatus == 'duplicate' ? '⚠ ${t('liveProjectRecord.possibleDuplicate')}' : '✓ ${t('liveProjectRecord.aiVerifiedUnique')}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: d.duplicateStatus == 'duplicate' ? CivixColors.ember : CivixColors.sal),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (isGovernment) ...[
              const Divider(color: CivixColors.rule),
              CivixButton(
                label: _checkingFundsDoc ? t('liveProjectRecord.checking') : t('liveProjectRecord.uploadAndVerify'),
                size: CivixButtonSize.sm,
                onPressed: _checkingFundsDoc
                    ? null
                    : () async {
                        final picked = await _pickFileAndHash();
                        if (picked == null) return;
                        setState(() => _checkingFundsDoc = true);
                        final data = jsonDecode(picked) as Map<String, dynamic>;
                        final msg = notifier.uploadFundsAllocationDoc(project.id, persona.name, title: data['name'], contentHash: data['contentHash']);
                        setState(() => _checkingFundsDoc = false);
                        _record(msg);
                      },
              ),
            ] else if (fundsDocs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(t('liveProjectRecord.onlyGovCanUpload'), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _documents(AppDictionary t, Project project) {
    return [
      for (final d in project.documents) ...[
        InkWell(
          onTap: () => _showDoc(d),
          child: Panel(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: CivixColors.chuna, borderRadius: BorderRadius.circular(8)),
                      alignment: Alignment.center,
                      child: const Text('📄'),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.title, style: const TextStyle(fontWeight: FontWeight.w600, color: CivixColors.neel)),
                        Text('${d.kind.replaceAll('-', ' ')} · ${_fmtDate(d.addedAt)}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                      ],
                    ),
                  ],
                ),
                const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
      if (project.documents.isEmpty) Panel(child: Text(t('liveProjectRecord.noDocumentsYet'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft))),
    ];
  }

  List<Widget> _risks(AppDictionary t, Project project, CivixNotifier notifier, Persona persona, bool isGovernment) {
    return [
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final r in project.risks) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: r.severity == 'high' ? CivixColors.ember.withValues(alpha: 0.4) : CivixColors.rule),
                  color: r.severity == 'high' ? CivixColors.ember.withValues(alpha: 0.06) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(_isWeatherRisk(r.label) ? Icons.cloud_outlined : _severityIcon[r.severity], size: 20, color: _severityColor[r.severity]),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r.label, style: const TextStyle(fontWeight: FontWeight.w600, color: CivixColors.neel))),
                    StatusChip(label: t('liveProjectRecord.severity.${r.severity}'), tone: _severityTone[r.severity]!),
                  ],
                ),
              ),
            ],
            if (project.risks.isEmpty) Text(t('liveProjectRecord.noRisksLogged'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
            const SizedBox(height: 8),
            if (isGovernment) ...[
              const Divider(color: CivixColors.rule),
              const SizedBox(height: 8),
              TextField(
                controller: _riskLabelController,
                decoration: InputDecoration(hintText: t('liveProjectRecord.describeRisk'), isDense: true, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _riskSeverity,
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 'low', child: Text(t('liveProjectRecord.severity.low'))),
                        DropdownMenuItem(value: 'medium', child: Text(t('liveProjectRecord.severity.medium'))),
                        DropdownMenuItem(value: 'high', child: Text(t('liveProjectRecord.severity.high'))),
                      ],
                      onChanged: (v) => setState(() => _riskSeverity = v ?? 'medium'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CivixButton(
                    label: t('liveProjectRecord.logRisk'),
                    size: CivixButtonSize.sm,
                    onPressed: _riskLabelController.text.trim().isEmpty
                        ? null
                        : () {
                            _record(notifier.logRisk(project.id, persona.name, label: _riskLabelController.text.trim(), severity: _riskSeverity));
                            _riskLabelController.clear();
                            setState(() {});
                          },
                  ),
                ],
              ),
            ] else
              Text(t('liveProjectRecord.onlyGovCanLogRisk'), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
          ],
        ),
      ),
    ];
  }

  List<Widget> _pilotResults(AppDictionary t, Project project, CivixNotifier notifier, Persona persona, bool isUniversity) {
    return [
      for (final m in project.pilotResults) ...[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600, color: CivixColors.neel))),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: CivixColors.neel),
                      children: [
                        TextSpan(text: m.value.toStringAsFixed(m.value == m.value.roundToDouble() ? 0 : 1)),
                        TextSpan(text: m.unit, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CivixColors.neelSoft)),
                      ],
                    ),
                  ),
                ],
              ),
              if (m.target != null) ...[
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final pct = (m.value / m.target!).clamp(0, 1).toDouble();
                  final met = m.value >= m.target!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 10,
                          backgroundColor: CivixColors.rule,
                          color: met ? CivixColors.sal : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t('liveProjectRecord.targetLabel')} ${m.target}${m.unit} · ${met ? t('liveProjectRecord.targetMet') : t('liveProjectRecord.pctOfTarget', {'pct': (pct * 100).toStringAsFixed(0)})}',
                        style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft),
                      ),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
      if (project.pilotResults.isEmpty)
        Panel(child: Text(t('liveProjectRecord.noPilotData'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft))),
      const SizedBox(height: 8),
      if (isUniversity)
        Panel(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 160,
                child: TextField(controller: _metricLabelController, decoration: InputDecoration(hintText: t('liveProjectRecord.metricLabelPlaceholder'), isDense: true, border: const OutlineInputBorder())),
              ),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _metricValueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: t('liveProjectRecord.valuePlaceholder'), isDense: true, border: const OutlineInputBorder()),
                ),
              ),
              SizedBox(
                width: 90,
                child: TextField(controller: _metricUnitController, decoration: InputDecoration(hintText: t('liveProjectRecord.unitPlaceholder'), isDense: true, border: const OutlineInputBorder())),
              ),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _metricTargetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: t('liveProjectRecord.targetPlaceholder'), isDense: true, border: const OutlineInputBorder()),
                ),
              ),
              CivixButton(
                label: t('liveProjectRecord.logResult'),
                size: CivixButtonSize.sm,
                onPressed: (_metricLabelController.text.trim().isEmpty || _metricValueController.text.trim().isEmpty)
                    ? null
                    : () {
                        final msg = notifier.logPilotMetric(
                          project.id,
                          persona.name,
                          label: _metricLabelController.text.trim(),
                          value: double.tryParse(_metricValueController.text.trim()) ?? 0,
                          unit: _metricUnitController.text.trim(),
                          target: _metricTargetController.text.trim().isEmpty ? null : double.tryParse(_metricTargetController.text.trim()),
                        );
                        _metricLabelController.clear();
                        _metricValueController.clear();
                        _metricUnitController.clear();
                        _metricTargetController.clear();
                        _record(msg);
                        setState(() {});
                      },
              ),
            ],
          ),
        )
      else
        Panel(child: Text(t('liveProjectRecord.onlyUniversityCanLogPilot'), style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft))),
    ];
  }

  List<Widget> _council(AppDictionary t, Project project) {
    const stages = ['problem', 'prototype', 'pilot', 'final'];
    final grouped = [
      for (final stage in stages) (stage: stage, votes: project.councilVotes.where((v) => v.stage == stage).toList()),
    ].where((g) => g.votes.isNotEmpty).toList();

    return [
      for (final g in grouped) ...[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('liveProjectRecord.stageLabel', {'stage': t('council.stageLabels.${g.stage}')}),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CivixColors.neelSoft, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              for (final v in g.votes) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_seatIcon[v.seat] ?? Icons.person_outline, size: 16, color: CivixColors.neelSoft),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('council.seats.${v.seat}'), style: const TextStyle(fontSize: 13, color: CivixColors.neel)),
                            if (v.comment != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('"${v.comment}"', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                              ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: t('council.votes.${v.vote}'),
                        tone: v.vote == 'yes' ? ChipTone.success : v.vote == 'no' ? ChipTone.risk : ChipTone.progress,
                      ),
                    ],
                  ),
                ),
                const Divider(color: CivixColors.ruleHairline, height: 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
      if (project.councilVotes.isEmpty)
        Panel(child: Text(t('liveProjectRecord.noCouncilVotes'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft))),
      const SizedBox(height: 8),
      InkWell(
        onTap: () => context.push('/council'),
        child: Text(t('liveProjectRecord.goToCouncil'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CivixColors.neel, decoration: TextDecoration.underline)),
      ),
    ];
  }

  List<Widget> _community(AppDictionary t, Project project) {
    final url = 'https://civix.app/p/${project.id}';
    return [
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QrImageView(data: url, size: 96),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => context.push('/p/${project.id}'),
                        child: Text(t('liveProjectRecord.openPublicPage'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CivixColors.neel, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final f in project.qrFeedback) Text('${f.outcome} — ${f.note ?? ''}', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ];
  }

  List<Widget> _audit(AppDictionary t, CivixState store, Project project) {
    final entries = store.auditLog.where((a) => a.target == project.id).toList();
    return [
      Panel(
        child: Column(
          children: [
            for (final a in entries) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(a.action, style: const TextStyle(fontWeight: FontWeight.w600, color: CivixColors.neel))),
                        Text(_fmtDate(a.at), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                      ],
                    ),
                    Text('${a.actor} · ${a.role}', style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                    if (a.detail != null) Text(a.detail!, style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
                  ],
                ),
              ),
              const Divider(color: CivixColors.ruleHairline, height: 1),
            ],
            if (entries.isEmpty) Text(t('liveProjectRecord.noAuditEntries'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
          ],
        ),
      ),
    ];
  }

  void _showDoc(Doc doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${doc.kind.replaceAll('-', ' ')} · ${_fmtDate(doc.addedAt)}', style: const TextStyle(fontSize: 12, color: CivixColors.neelSoft)),
            if (doc.duplicateStatus != null) ...[
              const SizedBox(height: 8),
              Text(
                doc.duplicateStatus == 'duplicate' ? '⚠ Possible duplicate' : '✓ AI-verified unique',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: doc.duplicateStatus == 'duplicate' ? CivixColors.ember : CivixColors.sal),
              ),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  Widget _kv(String k, String v) => RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: CivixColors.neel),
          children: [
            TextSpan(text: '$k ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: v),
          ],
        ),
      );
}
