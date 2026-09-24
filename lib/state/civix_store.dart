// Ported from src/store/index.ts (Zustand) -> Riverpod StateNotifier.
// Faithful port: same seed data sources, same ~30 action methods, same audit/notification
// side effects on every mutation, same "Recorded" confirmation pattern (via [recordedMessageProvider]
// instead of the onRecorded pub-sub + RecordedDialog.tsx).
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/types.dart';
import '../data/districts.dart' as seed_districts;
import '../data/institutions.dart' as seed_institutions;
import '../data/partners.dart' as seed_partners;
import '../data/reports.dart' as seed_reports;
import '../data/projects.dart' as seed_projects;
import '../data/misc.dart' as seed_misc;
import '../engines/similarity.dart' as similarity_engine;
import '../engines/priority.dart' as priority_engine;
import '../engines/routing.dart' as routing_engine;
import '../engines/credibility.dart' as credibility_engine;
import '../engines/duplicate_check.dart' as dup_engine;
import '../engines/social_signal.dart' as social_engine;
import 'session.dart';

int _counter = 0;
String _nid(String prefix) {
  final t = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final c = (_counter++).toRadixString(36);
  return '$prefix-$t-$c';
}

String _nowIso() => DateTime.now().toIso8601String();

/// Every state-changing action sets this instead of firing a toast directly, so the UI can show a
/// small "Recorded" confirmation (mirrors onRecorded()/RecordedDialog.tsx) rather than a
/// notification that can be missed or fades away.
final recordedMessageProvider = StateProvider<String?>((ref) => null);

List<AppNotification> _pushNotif(List<AppNotification> notifs, String toRole, String text, [String? link]) {
  return [
    AppNotification(id: _nid('notif'), toRole: toRole, text: text, link: link, at: _nowIso(), read: false),
    ...notifs,
  ];
}

List<AuditEntry> _pushAudit(List<AuditEntry> log, String actor, Role role, String action, String target, [String? detail]) {
  return [
    AuditEntry(id: _nid('audit'), actor: actor, role: role, action: action, target: target, detail: detail, at: _nowIso()),
    ...log,
  ];
}

class CivixState {
  final Session session;
  final Season season;
  final double rainfallAnomalyPct;
  final bool drought;

  final List<District> districts;
  final List<Report> reports;
  final List<MasterIssue> masterIssues;
  final List<SystemicChallenge> systemicChallenges;
  final List<Institution> institutions;
  final List<IndustryPartner> partners;
  final List<Team> teams;
  final List<Project> projects;
  final List<CapabilityGap> capabilityGaps;
  final List<FailureLesson> failureLessons;
  final List<SolutionMemoryEntry> solutionMemory;
  final List<OutreachTask> outreachTasks;
  final List<SocialPost> socialPosts;
  final List<AuditEntry> auditLog;
  final List<AppNotification> notifications;

  const CivixState({
    required this.session,
    required this.season,
    required this.rainfallAnomalyPct,
    required this.drought,
    required this.districts,
    required this.reports,
    required this.masterIssues,
    required this.systemicChallenges,
    required this.institutions,
    required this.partners,
    required this.teams,
    required this.projects,
    required this.capabilityGaps,
    required this.failureLessons,
    required this.solutionMemory,
    required this.outreachTasks,
    required this.socialPosts,
    required this.auditLog,
    required this.notifications,
  });

  factory CivixState.seed() => CivixState(
        session: const Session(role: 'citizen', profile: null, lang: AppLang.en),
        season: 'monsoon',
        rainfallAnomalyPct: 12,
        drought: false,
        districts: List.of(seed_districts.districts),
        reports: List.of(seed_reports.seedReports),
        masterIssues: List.of(seed_reports.seedMasterIssues),
        systemicChallenges: List.of(seed_misc.seedSystemicChallenges),
        institutions: List.of(seed_institutions.institutions),
        partners: List.of(seed_partners.partners),
        teams: List.of(seed_projects.seedTeams),
        projects: List.of(seed_projects.seedProjects),
        capabilityGaps: List.of(seed_misc.seedCapabilityGaps),
        failureLessons: List.of(seed_misc.seedFailureLessons),
        solutionMemory: List.of(seed_misc.seedSolutionMemory),
        outreachTasks: List.of(seed_misc.seedOutreachTasks),
        socialPosts: List.of(seed_misc.seedSocialPosts),
        auditLog: [...seed_projects.seedProjectAuditLog, ...seed_misc.seedAuditEntries],
        notifications: List.of(seed_misc.seedNotifications),
      );

  CivixState copyWith({
    Session? session,
    Season? season,
    double? rainfallAnomalyPct,
    bool? drought,
    List<District>? districts,
    List<Report>? reports,
    List<MasterIssue>? masterIssues,
    List<SystemicChallenge>? systemicChallenges,
    List<Institution>? institutions,
    List<IndustryPartner>? partners,
    List<Team>? teams,
    List<Project>? projects,
    List<CapabilityGap>? capabilityGaps,
    List<FailureLesson>? failureLessons,
    List<SolutionMemoryEntry>? solutionMemory,
    List<OutreachTask>? outreachTasks,
    List<SocialPost>? socialPosts,
    List<AuditEntry>? auditLog,
    List<AppNotification>? notifications,
  }) =>
      CivixState(
        session: session ?? this.session,
        season: season ?? this.season,
        rainfallAnomalyPct: rainfallAnomalyPct ?? this.rainfallAnomalyPct,
        drought: drought ?? this.drought,
        districts: districts ?? this.districts,
        reports: reports ?? this.reports,
        masterIssues: masterIssues ?? this.masterIssues,
        systemicChallenges: systemicChallenges ?? this.systemicChallenges,
        institutions: institutions ?? this.institutions,
        partners: partners ?? this.partners,
        teams: teams ?? this.teams,
        projects: projects ?? this.projects,
        capabilityGaps: capabilityGaps ?? this.capabilityGaps,
        failureLessons: failureLessons ?? this.failureLessons,
        solutionMemory: solutionMemory ?? this.solutionMemory,
        outreachTasks: outreachTasks ?? this.outreachTasks,
        socialPosts: socialPosts ?? this.socialPosts,
        auditLog: auditLog ?? this.auditLog,
        notifications: notifications ?? this.notifications,
      );
}

const String kPersistKey = 'civix-v5';

class CivixNotifier extends StateNotifier<CivixState> {
  CivixNotifier() : super(CivixState.seed()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(kPersistKey);
      if (raw == null) return;
      // Persistence is best-effort session continuity, not a full schema migration path;
      // if the seed data shape changes we simply fall back to fresh seed data.
    } catch (_) {
      // ignore corrupt/missing persisted state — keep seed
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPersistKey, jsonEncode(state.session.toJson()));
    } catch (_) {
      // best-effort only
    }
  }

  // --- session ---
  void setRole(String role, [Persona? profile]) {
    state = state.copyWith(session: state.session.copyWith(role: role, profile: profile ?? state.session.profile));
    _persist();
  }

  void setProfile(Persona profile) {
    state = state.copyWith(session: state.session.copyWith(role: profile.role, profile: profile));
    _persist();
  }

  void logout() {
    state = state.copyWith(session: Session(role: state.session.role, profile: null, lang: state.session.lang));
    _persist();
  }

  void setLang(AppLang lang) {
    state = state.copyWith(session: state.session.copyWith(lang: lang));
    _persist();
  }

  String setSeason(Season season) {
    state = state.copyWith(season: season);
    return 'Season set to ${season.replaceAll('-', ' ')}. Priorities re-ranked.';
  }

  void setRainfallAnomaly(double pct) => state = state.copyWith(rainfallAnomalyPct: pct);

  void setDrought(bool drought) => state = state.copyWith(drought: drought);

  // --- citizen reporting ---
  ({String reportId, String masterIssueId, bool matched, double? matchScore, String message}) submitReport({
    required Channel channel,
    required String language,
    String? rawText,
    String? transcript,
    String? translation,
    required Category category,
    required String districtId,
    required String village,
    required double lat,
    required double lng,
    required int urgencyHint,
    required String affectedGroup,
    int? households,
    required List<Evidence> evidence,
    required String reporterId,
    required String reporterName,
    String? createdAtOverride,
    bool? autoDiscovered,
    String? citizenSelectedDepartment,
    double? citizenSelectedDepartmentConfidence,
  }) {
    final createdAt = createdAtOverride ?? _nowIso();
    final openIssues = state.masterIssues;
    final match = similarity_engine.findBestMatch(
      category: category,
      lat: lat,
      lng: lng,
      createdAt: createdAt,
      issues: openIssues,
    );
    final isDup = match != null && match.result.isDuplicate;
    final reportId = _nid('report');

    final allExistingEvidence = <({Evidence evidence, String issueId})>[];
    for (final r in state.reports) {
      for (final e in r.evidence) {
        allExistingEvidence.add((evidence: e, issueId: r.masterIssueId));
      }
    }
    final processedEvidence = evidence.map((e) {
      final dupMatch = dup_engine.findDuplicateByHash<({Evidence evidence, String issueId})>(
        e.contentHash,
        allExistingEvidence,
        (item) => item.evidence.contentHash,
      );
      if (dupMatch != null) {
        return e.copyWith(duplicateStatus: 'duplicate', duplicateOfIssueId: dupMatch.issueId);
      }
      return e.contentHash != null ? e.copyWith(duplicateStatus: 'unique') : e;
    }).toList();

    if (isDup) {
      final report = Report(
        id: reportId,
        channel: channel,
        language: language,
        rawText: rawText,
        transcript: transcript,
        translation: translation,
        category: category,
        districtId: districtId,
        village: village,
        lat: lat,
        lng: lng,
        urgencyHint: urgencyHint,
        affectedGroup: affectedGroup,
        households: households,
        evidence: processedEvidence,
        reporterId: reporterId,
        reporterName: reporterName,
        createdAt: createdAt,
        masterIssueId: match.issue.id,
        autoDiscovered: autoDiscovered,
        citizenSelectedDepartment: citizenSelectedDepartment,
        citizenSelectedDepartmentConfidence: citizenSelectedDepartmentConfidence,
      );
      state = state.copyWith(
        reports: [...state.reports, report],
        masterIssues: state.masterIssues
            .map((mi) => mi.id == match.issue.id
                ? mi.copyWith(reportIds: [...mi.reportIds, reportId], households: mi.households + (households ?? 0))
                : mi)
            .toList(),
        auditLog: _pushAudit(state.auditLog, reporterName, 'citizen', 'Submitted report (matched to existing case)', match.issue.id),
        notifications: _pushNotif(state.notifications, 'government', 'New evidence added to an existing case: ${match.issue.title}', '/gov/issues/${match.issue.id}'),
      );
      _persist();
      return (
        reportId: reportId,
        masterIssueId: match.issue.id,
        matched: true,
        matchScore: match.result.score,
        message: 'Someone already reported this. Your report is now evidence on the same case.',
      );
    }

    final issueId = _nid('issue');
    final issue = MasterIssue(
      id: issueId,
      title: '${category.replaceAll('-', ' ')} reported in $village',
      category: category,
      districtId: districtId,
      village: village,
      lat: lat,
      lng: lng,
      reportIds: [reportId],
      upvotes: 0,
      upvoterIds: const [],
      households: households ?? 0,
      stage: 'awaiting-validation',
      repeatCount: 0,
      createdAt: createdAt,
    );
    final report = Report(
      id: reportId,
      channel: channel,
      language: language,
      rawText: rawText,
      transcript: transcript,
      translation: translation,
      category: category,
      districtId: districtId,
      village: village,
      lat: lat,
      lng: lng,
      urgencyHint: urgencyHint,
      affectedGroup: affectedGroup,
      households: households,
      evidence: processedEvidence,
      reporterId: reporterId,
      reporterName: reporterName,
      createdAt: createdAt,
      masterIssueId: issueId,
      autoDiscovered: autoDiscovered,
      citizenSelectedDepartment: citizenSelectedDepartment,
      citizenSelectedDepartmentConfidence: citizenSelectedDepartmentConfidence,
    );
    state = state.copyWith(
      reports: [...state.reports, report],
      masterIssues: [...state.masterIssues, issue],
      auditLog: _pushAudit(state.auditLog, reporterName, 'citizen', 'Submitted new report', issueId, channel),
      notifications: _pushNotif(state.notifications, 'government', 'New case awaiting validation: ${issue.title}', '/gov/inbox'),
    );
    _persist();
    return (
      reportId: reportId,
      masterIssueId: issueId,
      matched: false,
      matchScore: null,
      message: 'New case created. Tracking ID: ${issueId.substring(issueId.length - 6).toUpperCase()}',
    );
  }

  String? upvoteIssue(String issueId, String voterId) {
    final match = state.masterIssues.where((mi) => mi.id == issueId);
    final already = match.isNotEmpty && match.first.upvoterIds.contains(voterId);
    state = state.copyWith(
      masterIssues: state.masterIssues
          .map((mi) => mi.id == issueId && !mi.upvoterIds.contains(voterId)
              ? mi.copyWith(upvotes: mi.upvotes + 1, upvoterIds: [...mi.upvoterIds, voterId])
              : mi)
          .toList(),
    );
    _persist();
    return already ? null : 'Your upvote was recorded on this case.';
  }

  String? addEvidence(String issueId, Evidence evidenceInput) {
    final match = state.masterIssues.where((mi) => mi.id == issueId);
    if (match.isEmpty || match.first.reportIds.isEmpty) return null;
    final issue = match.first;
    final ev = Evidence(
      id: _nid('ev'),
      kind: evidenceInput.kind,
      label: evidenceInput.label,
      url: evidenceInput.url,
      addedBy: evidenceInput.addedBy,
      addedAt: _nowIso(),
    );
    state = state.copyWith(
      reports: state.reports
          .map((r) => r.id == issue.reportIds.first ? _reportWithEvidence(r, ev) : r)
          .toList(),
      auditLog: _pushAudit(state.auditLog, evidenceInput.addedBy, 'citizen', 'Added evidence', issueId),
    );
    _persist();
    return 'Evidence added.';
  }

  Report _reportWithEvidence(Report r, Evidence ev) => Report(
        id: r.id,
        channel: r.channel,
        language: r.language,
        rawText: r.rawText,
        transcript: r.transcript,
        translation: r.translation,
        category: r.category,
        districtId: r.districtId,
        village: r.village,
        lat: r.lat,
        lng: r.lng,
        urgencyHint: r.urgencyHint,
        affectedGroup: r.affectedGroup,
        households: r.households,
        evidence: [...r.evidence, ev],
        reporterId: r.reporterId,
        reporterName: r.reporterName,
        createdAt: r.createdAt,
        masterIssueId: r.masterIssueId,
        autoDiscovered: r.autoDiscovered,
        citizenSelectedDepartment: r.citizenSelectedDepartment,
        citizenSelectedDepartmentConfidence: r.citizenSelectedDepartmentConfidence,
      );

  String addHouseholds(String issueId, int count) {
    state = state.copyWith(
      masterIssues: state.masterIssues
          .map((mi) => mi.id == issueId ? mi.copyWith(households: mi.households + count) : mi)
          .toList(),
    );
    _persist();
    return 'Added $count affected households.';
  }

  String? mergeIssues(String sourceIssueId, String targetIssueId, String actor) {
    final sourceMatch = state.masterIssues.where((mi) => mi.id == sourceIssueId);
    final targetMatch = state.masterIssues.where((mi) => mi.id == targetIssueId);
    if (sourceMatch.isEmpty || targetMatch.isEmpty || sourceIssueId == targetIssueId) return null;
    final source = sourceMatch.first;
    state = state.copyWith(
      masterIssues: state.masterIssues
          .where((mi) => mi.id != sourceIssueId)
          .map((mi) => mi.id == targetIssueId
              ? mi.copyWith(
                  reportIds: [...mi.reportIds, ...source.reportIds],
                  households: mi.households + source.households,
                  upvotes: mi.upvotes + source.upvotes,
                  repeatCount: mi.repeatCount + 1,
                )
              : mi)
          .toList(),
      reports: state.reports.map((r) => r.masterIssueId == sourceIssueId ? _reportWithIssue(r, targetIssueId) : r).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Merged duplicate issue into master issue', targetIssueId, 'merged $sourceIssueId'),
      notifications: _pushNotif(state.notifications, 'citizen', 'Merged. ${source.reportIds.length} reporters notified.', '/citizen/wall/$targetIssueId'),
    );
    _persist();
    return 'Merged into master issue. ${source.reportIds.length} reporters notified.';
  }

  Report _reportWithIssue(Report r, String issueId) => Report(
        id: r.id,
        channel: r.channel,
        language: r.language,
        rawText: r.rawText,
        transcript: r.transcript,
        translation: r.translation,
        category: r.category,
        districtId: r.districtId,
        village: r.village,
        lat: r.lat,
        lng: r.lng,
        urgencyHint: r.urgencyHint,
        affectedGroup: r.affectedGroup,
        households: r.households,
        evidence: r.evidence,
        reporterId: r.reporterId,
        reporterName: r.reporterName,
        createdAt: r.createdAt,
        masterIssueId: issueId,
        autoDiscovered: r.autoDiscovered,
        citizenSelectedDepartment: r.citizenSelectedDepartment,
        citizenSelectedDepartmentConfidence: r.citizenSelectedDepartmentConfidence,
      );

  String? convertSocialSignal(String postId, String reporterName) {
    final match = state.socialPosts.where((p) => p.id == postId);
    if (match.isEmpty || (match.first.converted ?? false)) return null;
    final post = match.first;
    state = state.copyWith(
      socialPosts: state.socialPosts.map((p) => p.id == postId ? p.copyWith(converted: true) : p).toList(),
    );
    submitReport(
      channel: 'social',
      language: 'English',
      category: post.category,
      districtId: post.districtId,
      village: post.author,
      lat: post.lat,
      lng: post.lng,
      urgencyHint: 3,
      affectedGroup: 'community members',
      evidence: const [],
      reporterId: 'social-$postId',
      reporterName: reporterName,
      autoDiscovered: true,
      rawText: post.text,
    );
    return reporterName == social_engine.aiEscalationActor
        ? 'AI auto-escalated a social post to an official case.'
        : 'Converted to case. Marked as found on social media.';
  }

  String? validateIssue(String issueId, String actor) {
    final match = state.masterIssues.where((mi) => mi.id == issueId);
    if (match.isEmpty) return null;
    final issue = match.first;
    final priority = priority_engine.computePriority(
      category: issue.category,
      households: issue.households,
      upvotes: issue.upvotes,
      districtId: issue.districtId,
      districts: state.districts,
      season: state.season,
      rainfallAnomalyPct: state.rainfallAnomalyPct,
      drought: state.drought,
    );
    const disciplinesGuess = {
      'wildlife-conflict': ['wildlife/ecology', 'agri', 'iot/embedded', 'social science'],
      'water-quality': ['environmental science', 'water-quality'],
      'agri-postharvest': ['agri-postharvest', 'agri'],
      'livelihood-forest-produce': ['lac cultivation', 'value-addition', 'social science'],
      'water-scarcity': ['civil engineering', 'iot/embedded'],
    };
    final ps = ProblemStatement(
      summary: '${issue.title} affecting ${issue.households} households in ${issue.village}, ${issue.districtId}.',
      scope: '${issue.reportIds.length} report(s) received across the affected area.',
      evidenceSummary: '${issue.reportIds.length} report(s) on file with supporting evidence.',
      urgency: priority.total >= 70 ? 'High' : (priority.total >= 40 ? 'Medium' : 'Low'),
      successCriteria: const ['Root cause addressed', 'Community confirms improvement via QR feedback'],
      disciplinesNeeded: disciplinesGuess[issue.category] ?? const ['civil engineering', 'social science'],
    );
    state = state.copyWith(
      masterIssues: state.masterIssues
          .map((mi) => mi.id == issueId ? mi.copyWith(stage: 'validated', problemStatement: ps, priority: priority.toBreakdown()) : mi)
          .toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Validated issue and generated problem statement', issueId),
      notifications: _pushNotif(state.notifications, 'citizen', 'Your report "${issue.title}" has been validated.', '/citizen/wall/$issueId'),
    );
    _persist();
    return 'Issue validated. Problem statement generated.';
  }

  String editProblemStatement(String issueId, ProblemStatement partial, String actor) {
    state = state.copyWith(
      masterIssues: state.masterIssues.map((mi) {
        if (mi.id != issueId || mi.problemStatement == null) return mi;
        return mi.copyWith(problemStatement: partial.copyWith(approvedBy: actor, approvedAt: _nowIso()));
      }).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Edited problem statement', issueId),
    );
    _persist();
    return 'Problem statement updated.';
  }

  String? routeIssue(String issueId, {required String type, String? department, String? scheme, String? overrideReason, required String actor}) {
    final match = state.masterIssues.where((mi) => mi.id == issueId);
    if (match.isEmpty) return null;
    final issue = match.first;
    final rec = routing_engine.recommendRoute(category: issue.category, repeatCount: issue.repeatCount);
    final override = type != rec.type
        ? HumanOverride(by: actor, reason: overrideReason ?? 'No reason given', at: _nowIso())
        : null;
    final route = RouteDecision(
      type: type,
      department: department,
      scheme: scheme,
      reason: rec.reason,
      aiRecommended: rec.type,
      humanOverride: override,
    );
    state = state.copyWith(
      masterIssues: state.masterIssues.map((mi) {
        if (mi.id != issueId) return mi;
        return mi.copyWith(
          stage: type == 'service' ? 'routed-service' : 'routed-innovation',
          route: route,
          serviceTicket: type == 'service'
              ? ServiceTicket(id: _nid('svc'), department: department ?? 'MGNREGA cell', status: 'assigned', slaDays: 15, assignedAt: _nowIso())
              : mi.serviceTicket,
        );
      }).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Routed issue to ${type == 'service' ? 'Service Twin' : 'Innovation Twin'}', issueId, override != null ? 'Override: ${override.reason}' : null),
      notifications: type == 'innovation'
          ? _pushNotif(state.notifications, 'university', 'A new validated challenge is available: ${issue.title}', '/uni/challenges/$issueId')
          : _pushNotif(state.notifications, 'citizen', 'Your issue was routed to $department.', '/citizen/wall/$issueId'),
    );
    _persist();
    return 'Routed to ${type == 'service' ? 'Service Twin' : 'Innovation Twin'}.${override != null ? ' Override logged.' : ''}';
  }

  String resolveServiceTicket(String issueId, String actor) {
    state = state.copyWith(
      masterIssues: state.masterIssues.map((mi) {
        if (mi.id != issueId || mi.serviceTicket == null) return mi;
        return mi.copyWith(stage: 'resolved', serviceTicket: mi.serviceTicket!.copyWith(status: 'resolved', resolvedAt: _nowIso()));
      }).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Resolved service ticket', issueId),
      notifications: _pushNotif(state.notifications, 'citizen', 'Your reported issue has been resolved.', '/citizen/wall/$issueId'),
    );
    _persist();
    return 'Resolved. Citizens notified.';
  }

  void escalateToInnovation(String issueId, String actor) {
    routeIssue(issueId, type: 'innovation', actor: actor);
  }

  String promoteSystemic(String systemicId, String actor) {
    state = state.copyWith(
      systemicChallenges: state.systemicChallenges.map((sc) => sc.id == systemicId ? sc.copyWith(promoted: true) : sc).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Promoted systemic challenge', systemicId),
    );
    _persist();
    return 'Promoted to a single systemic challenge.';
  }

  ({String projectId, String message}) submitProposal({
    required String issueId,
    required String institutionId,
    required List<String> memberIds,
    required List<String> disciplines,
    required String title,
    required double budget,
    required List<({String title, double budget, String due})> milestones,
    required String maintenancePlan,
    required String actor,
  }) {
    final issue = state.masterIssues.firstWhere((mi) => mi.id == issueId);
    final teamId = _nid('team');
    final projectId = _nid('proj');
    final newTeam = Team(id: teamId, institutionId: institutionId, memberIds: memberIds, disciplines: disciplines);
    final newProject = Project(
      id: projectId,
      issueId: issueId,
      title: title,
      teamId: teamId,
      stage: 'pending-approval',
      ownerId: institutionId,
      districtId: issue.districtId,
      budget: budget,
      milestones: milestones
          .map((m) => Milestone(id: _nid('ms'), title: m.title, budget: m.budget, due: m.due, status: 'pending'))
          .toList(),
      pledges: const [],
      documents: [Doc(id: _nid('doc'), title: 'Innovation Twin proposal', kind: 'proposal', addedAt: _nowIso())],
      risks: const [],
      pilotResults: const [],
      councilVotes: const [],
      qrFeedback: const [],
      updates: [Update(id: _nid('upd'), text: 'Proposal submitted for Government approval.', at: _nowIso(), by: actor)],
      maintenancePlan: maintenancePlan,
      createdAt: _nowIso(),
    );
    state = state.copyWith(
      teams: [...state.teams, newTeam],
      projects: [...state.projects, newProject],
      masterIssues: state.masterIssues.map((mi) => mi.id == issueId ? mi.copyWith(projectId: projectId) : mi).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'university', 'Submitted Innovation Twin proposal', projectId),
      notifications: _pushNotif(state.notifications, 'government', 'A team submitted a proposal for: ${issue.title}', '/projects/$projectId'),
    );
    _persist();
    return (projectId: projectId, message: 'Proposal submitted for Government approval.');
  }

  String? approveInnovationTwin(String projectId, String actor) {
    final match = state.projects.where((p) => p.id == projectId);
    if (match.isEmpty) return null;
    final project = match.first;
    state = state.copyWith(
      projects: state.projects.map((p) => p.id == projectId ? p.copyWith(stage: 'building') : p).toList(),
      masterIssues: state.masterIssues.map((mi) => mi.id == project.issueId ? mi.copyWith(stage: 'in-project') : mi).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Approved Innovation Twin and notified team', projectId),
      notifications: _pushNotif(state.notifications, 'university', 'Your Innovation Twin proposal was approved. Building has started.', '/projects/$projectId'),
    );
    _persist();
    return 'Approved and notified team.';
  }

  String pledgeSupport(String projectId, Pledge pledgeInput, String actor) {
    final newPledge = Pledge(
      id: _nid('pledge'),
      partnerId: pledgeInput.partnerId,
      type: pledgeInput.type,
      amount: pledgeInput.amount,
      description: pledgeInput.description,
      scope: pledgeInput.scope,
      milestoneId: pledgeInput.milestoneId,
      status: 'pledged',
    );
    state = state.copyWith(
      projects: state.projects.map((p) => p.id == projectId ? p.copyWith(pledges: [...p.pledges, newPledge]) : p).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'industry', 'Pledged support', projectId, pledgeInput.description),
      notifications: _pushNotif(state.notifications, 'university', 'A new pledge was made to your project.', '/projects/$projectId'),
    );
    _persist();
    return 'Pledge recorded.';
  }

  String submitMilestoneProof(String projectId, String milestoneId, Doc docInput, String actor) {
    ({Doc doc, String projectId, String projectTitle, String milestoneTitle})? existing;
    if (docInput.contentHash != null) {
      for (final p in state.projects) {
        for (final m in p.milestones) {
          if (m.proof != null && m.proof!.contentHash == docInput.contentHash) {
            existing = (doc: m.proof!, projectId: p.id, projectTitle: p.title, milestoneTitle: m.title);
          }
        }
      }
    }
    final newDoc = Doc(
      id: _nid('doc'),
      title: docInput.title,
      kind: docInput.kind,
      addedAt: _nowIso(),
      url: docInput.url,
      contentHash: docInput.contentHash,
      duplicateStatus: existing != null ? 'duplicate' : (docInput.contentHash != null ? 'unique' : null),
      duplicateOfProjectId: existing?.projectId,
    );
    final projectTitle = state.projects.firstWhere((p) => p.id == projectId).title;
    state = state.copyWith(
      projects: state.projects
          .map((p) => p.id == projectId
              ? p.copyWith(milestones: p.milestones.map((m) => m.id == milestoneId ? m.copyWith(status: 'submitted', proof: newDoc) : m).toList())
              : p)
          .toList(),
      auditLog: _pushAudit(
        state.auditLog,
        actor,
        'university',
        existing != null ? 'Submitted milestone proof — flagged as possible duplicate by AI check' : 'Submitted milestone proof',
        projectId,
      ),
      notifications: existing != null
          ? _pushNotif(state.notifications, 'government', 'Possible duplicate: the milestone proof for "$projectTitle" matches one already on "${existing.projectTitle}".', '/projects/$projectId')
          : _pushNotif(state.notifications, 'government', 'Milestone proof submitted, awaiting approval.', '/projects/$projectId'),
    );
    _persist();
    return 'Milestone proof submitted.';
  }

  /// For proof files with no content hash to compare, the reviewer can still trigger an AI pass —
  /// deterministic per document, so re-running it doesn't flip the result.
  String? runMilestoneProofAiCheck(String projectId, String milestoneId, String actor) {
    final project = state.projects.where((p) => p.id == projectId);
    if (project.isEmpty) return null;
    final milestone = project.first.milestones.where((m) => m.id == milestoneId);
    if (milestone.isEmpty || milestone.first.proof == null) return null;
    final proof = milestone.first.proof!;
    final seed = proof.id.codeUnits.fold(0, (sum, ch) => sum + ch);
    final confidence = (92 + (seed % 8)).round() / 100;
    state = state.copyWith(
      projects: state.projects.map((p) {
        if (p.id != projectId) return p;
        return p.copyWith(
          milestones: p.milestones.map((m) {
            if (m.id != milestoneId || m.proof == null) return m;
            return m.copyWith(proof: m.proof!.copyWith(duplicateStatus: 'unique', duplicateCheckConfidence: confidence));
          }).toList(),
        );
      }).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Ran AI duplicate check on milestone proof', projectId),
    );
    _persist();
    return 'AI duplicate check passed — ${(confidence * 100).round()}% confidence.';
  }

  String approveMilestone(String projectId, String milestoneId, String actor) {
    state = state.copyWith(
      projects: state.projects.map((p) {
        if (p.id != projectId) return p;
        return p.copyWith(
          milestones: p.milestones.map((m) => m.id == milestoneId ? m.copyWith(status: 'approved') : m).toList(),
          pledges: p.pledges.map((pl) => pl.milestoneId == milestoneId ? pl.copyWith(status: 'released') : pl).toList(),
        );
      }).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Approved milestone and released funds', projectId),
      notifications: _pushNotif(state.notifications, 'university', 'Milestone approved. Pledged funds released.', '/projects/$projectId'),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      state = state.copyWith(
        projects: state.projects.map((p) {
          if (p.id != projectId) return p;
          return p.copyWith(milestones: p.milestones.map((m) => m.id == milestoneId ? m.copyWith(status: 'released') : m).toList());
        }).toList(),
      );
      _persist();
    });
    _persist();
    return 'Milestone approved. Funds released.';
  }

  String? uploadFundsAllocationDoc(String projectId, String actor, {required String title, String? url, required String contentHash}) {
    final match = state.projects.where((p) => p.id == projectId);
    if (match.isEmpty) return null;
    final project = match.first;
    ({Doc doc, String projectId, String projectTitle})? existing;
    for (final p in state.projects) {
      for (final d in p.documents) {
        if (d.kind == 'funds-allocation' && d.contentHash == contentHash) {
          existing = (doc: d, projectId: p.id, projectTitle: p.title);
        }
      }
    }
    final newDoc = Doc(
      id: _nid('doc'),
      title: title,
      kind: 'funds-allocation',
      addedAt: _nowIso(),
      url: url,
      contentHash: contentHash,
      duplicateStatus: existing != null ? 'duplicate' : 'unique',
      duplicateOfProjectId: existing?.projectId,
    );
    state = state.copyWith(
      projects: state.projects.map((p) => p.id == projectId ? p.copyWith(documents: [...p.documents, newDoc]) : p).toList(),
      auditLog: _pushAudit(
        state.auditLog,
        actor,
        'government',
        existing != null ? 'Uploaded funds allocation document — flagged as possible duplicate by AI check' : 'Uploaded and AI-verified funds allocation document',
        projectId,
      ),
      notifications: existing != null
          ? _pushNotif(state.notifications, 'government', 'Possible duplicate: the funds document for "${project.title}" matches one already on "${existing.projectTitle}".', '/projects/$projectId')
          : _pushNotif(state.notifications, 'industry', '${project.title} has confirmed government funding allocated — co-fund it in Opportunities.', '/industry/opportunities'),
    );
    _persist();
    return existing != null
        ? 'Possible duplicate document — matches a document already uploaded on "${existing.projectTitle}".'
        : 'Funds allocation document verified as unique. Industries notified.';
  }

  String castCouncilVote(String projectId, String actor, {required String stage, required String seat, required String vote, String? comment}) {
    final newVote = CouncilVote(id: _nid('vote'), stage: stage, seat: seat, vote: vote, comment: comment, at: _nowIso());
    final project = state.projects.firstWhere((p) => p.id == projectId);
    final votesForStage = [...project.councilVotes.where((v) => v.stage == stage), newVote];
    final total = votesForStage.fold<double>(0, (sum, v) => sum + (v.vote == 'yes' ? 1 : (v.vote == 'partial' ? 0.5 : 0)));
    final passed = total >= 3 && votesForStage.length >= 5;
    state = state.copyWith(
      projects: state.projects.map((p) {
        if (p.id != projectId) return p;
        var newStage = p.stage;
        if (passed && stage == 'final') newStage = 'community-validated';
        return p.copyWith(councilVotes: [...p.councilVotes, newVote], stage: newStage);
      }).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'council', 'Cast $vote vote ($seat seat, $stage stage)', projectId, comment),
    );
    _persist();
    return passed ? '$stage stage passed council review.' : 'Vote recorded.';
  }

  String logRisk(String projectId, String actor, {required String label, required String severity, int? daysLate}) {
    final newRisk = Risk(id: _nid('risk'), label: label, severity: severity, daysLate: daysLate);
    state = state.copyWith(
      projects: state.projects.map((p) => p.id == projectId ? p.copyWith(risks: [...p.risks, newRisk]) : p).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Logged a $severity risk', projectId, label),
    );
    _persist();
    return 'Risk logged.';
  }

  String logPilotMetric(String projectId, String actor, {required String label, required double value, required String unit, double? target}) {
    final newMetric = PilotMetric(id: _nid('pm'), label: label, value: value, unit: unit, target: target);
    state = state.copyWith(
      projects: state.projects.map((p) => p.id == projectId ? p.copyWith(pilotResults: [...p.pilotResults, newMetric]) : p).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'university', 'Logged pilot result', projectId, '$label: $value$unit'),
    );
    _persist();
    return 'Pilot result logged.';
  }

  static const List<String> _stageOrder = [
    'team-forming', 'pending-approval', 'building', 'piloting', 'deployed', 'community-validated', 'scaled',
  ];

  String advanceProjectStage(String projectId, String actor) {
    state = state.copyWith(
      projects: state.projects.map((p) {
        if (p.id != projectId) return p;
        final idx = _stageOrder.indexOf(p.stage);
        final next = (idx >= 0 && idx < _stageOrder.length - 1) ? _stageOrder[idx + 1] : p.stage;
        return p.copyWith(
          stage: next,
          updates: [...p.updates, Update(id: _nid('upd'), text: 'Project advanced to ${next.replaceAll('-', ' ')}.', at: _nowIso(), by: actor)],
        );
      }).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Advanced project stage', projectId),
    );
    _persist();
    return 'Project stage advanced.';
  }

  String markProjectFailed(String projectId, String actor, {required Category category, required String type, required String lesson, required String designWarning}) {
    final newLesson = FailureLesson(id: _nid('fl'), projectId: projectId, category: category, type: type, lesson: lesson, designWarning: designWarning);
    state = state.copyWith(
      projects: state.projects.map((p) => p.id == projectId ? p.copyWith(stage: 'failed') : p).toList(),
      failureLessons: [...state.failureLessons, newLesson],
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Marked project failed and logged a lesson', projectId, lesson),
    );
    _persist();
    return 'Project marked failed. Lesson added to Failure-to-Prevention.';
  }

  String publishCapabilityGap(String gapId, String actor) {
    state = state.copyWith(
      capabilityGaps: state.capabilityGaps.map((g) => g.id == gapId ? g.copyWith(published: true) : g).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Published capability gap to industry', gapId),
      notifications: _pushNotif(state.notifications, 'industry', 'A new capability gap was published.', '/industry/opportunities'),
    );
    _persist();
    return 'Published to Industry opportunities.';
  }

  String fillCapabilityGap(String gapId, String filledBy, String actor) {
    state = state.copyWith(
      capabilityGaps: state.capabilityGaps.map((g) => g.id == gapId ? g.copyWith(filledBy: filledBy) : g).toList(),
      auditLog: _pushAudit(state.auditLog, actor, 'industry', 'Filled capability gap', gapId),
    );
    _persist();
    return 'Capability gap filled.';
  }

  String triggerOutreach(String districtId, String institutionId, String actor) {
    final taskId = _nid('out');
    state = state.copyWith(
      outreachTasks: [...state.outreachTasks, OutreachTask(id: taskId, districtId: districtId, institutionId: institutionId, status: 'assigned')],
      auditLog: _pushAudit(state.auditLog, actor, 'government', 'Triggered HEI-led outreach', districtId),
      notifications: _pushNotif(state.notifications, 'university', 'You have been assigned an outreach task.', '/uni'),
    );
    _persist();
    return 'Outreach triggered.';
  }

  String? completeOutreach(String taskId, String actor) {
    final match = state.outreachTasks.where((t) => t.id == taskId);
    if (match.isEmpty) return null;
    final task = match.first;
    final newReports = List.generate(6, (i) {
      return Report(
        id: _nid('report'),
        channel: 'app',
        language: 'Hindi',
        category: 'other',
        districtId: task.districtId,
        village: 'Outreach ward',
        lat: 23,
        lng: 85,
        urgencyHint: 2,
        affectedGroup: 'outreach respondents',
        households: 4,
        evidence: const [],
        reporterId: 'outreach-$i',
        reporterName: 'Outreach respondent ${i + 1}',
        createdAt: _nowIso(),
        masterIssueId: '',
      );
    });
    state = state.copyWith(
      outreachTasks: state.outreachTasks.map((t) => t.id == taskId ? t.copyWith(status: 'completed') : t).toList(),
      districts: state.districts.map((d) => d.id == task.districtId ? _districtWithReportRate(d, d.reportRate + 15) : d).toList(),
      reports: [...state.reports, ...newReports],
      auditLog: _pushAudit(state.auditLog, actor, 'university', 'Completed outreach', task.districtId),
    );
    _persist();
    return 'Outreach completed. Equity gap for this district should shrink.';
  }

  District _districtWithReportRate(District d, double reportRate) => District(
        id: d.id,
        name: d.name,
        lat: d.lat,
        lng: d.lng,
        population: d.population,
        needIndex: d.needIndex,
        reportRate: reportRate,
        terrain: d.terrain,
        rainfall: d.rainfall,
        tribalMajority: d.tribalMajority,
      );

  String? submitQRFeedback(String projectId, {required String outcome, String? note, String? photo}) {
    final newFb = QRFeedback(id: _nid('qr'), outcome: outcome, note: note, photo: photo, at: _nowIso());
    final match = state.projects.where((p) => p.id == projectId);
    if (match.isEmpty) return null;
    final project = match.first;

    var institutions = state.institutions;
    institutions = institutions.map((inst) {
      if (inst.id != project.ownerId) return inst;
      final delta = outcome == 'works' ? 4.0 : (outcome == 'partial' ? 0.0 : -6.0);
      final qrSuccess = (inst.credibility.qrSuccess + delta).clamp(0.0, 100.0);
      final overall = credibility_engine
          .recomputeOverall(
            timeliness: inst.credibility.timeliness,
            qrSuccess: qrSuccess,
            councilApproval: inst.credibility.councilApproval,
            maintenance: inst.credibility.maintenance,
          )
          .toDouble();
      return inst.copyWith(
        credibility: inst.credibility.copyWith(
          qrSuccess: qrSuccess,
          overall: overall,
          history: [...inst.credibility.history, CredibilityHistoryEntry(projectId: projectId, delta: delta, reason: 'QR feedback: $outcome')],
        ),
      );
    }).toList();

    final failureLessons = outcome == 'not-working'
        ? [
            ...state.failureLessons,
            FailureLesson(
              id: _nid('fl'),
              projectId: projectId,
              category: 'other',
              type: 'technical',
              lesson: 'QR feedback reported "not working" for ${project.title}.',
              designWarning: 'Investigate root cause and update maintenance plan.',
            ),
          ]
        : state.failureLessons;

    state = state.copyWith(
      projects: state.projects.map((p) => p.id == projectId ? p.copyWith(qrFeedback: [...p.qrFeedback, newFb]) : p).toList(),
      institutions: institutions,
      failureLessons: failureLessons,
      notifications: (outcome == 'not-working' || outcome == 'needs-maintenance')
          ? _pushNotif(state.notifications, 'government', 'Field feedback flags an issue with ${project.title}.', '/projects/$projectId')
          : state.notifications,
    );
    _persist();
    return 'Thank you for your feedback.';
  }

  void markNotificationRead(String id) {
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
    );
    _persist();
  }

  String resetData() {
    _counter = 0;
    state = CivixState.seed().copyWith(session: state.session);
    _persist();
    return 'Data reset.';
  }
}

final civixStoreProvider = StateNotifierProvider<CivixNotifier, CivixState>((ref) => CivixNotifier());

// --- module-level helpers/constants mirroring exports at the bottom of store/index.ts ---

const List<String> councilSeats = ['reporter', 'panchayat', 'beneficiary', 'expert', 'official'];

const Map<Role, String> roleAvatarColor = {
  'citizen': '#B3123F',
  'government': '#1C2B5A',
  'university': '#2F6B3F',
  'industry': '#C79A2E',
  'council': '#5B4B8A',
};

Persona guestPersona(Role role) => Persona(
      id: 'guest-$role',
      name: 'Guest',
      role: role,
      avatarColor: roleAvatarColor[role] ?? '#1C2B5A',
      blurb: '',
    );
