// Ported 1:1 from src/types.ts (the React/TS source of truth).
library;

typedef Role = String; // 'citizen' | 'government' | 'university' | 'industry' | 'council'
typedef Channel = String; // 'app' | 'web' | 'social'
typedef Season = String; // 'summer' | 'monsoon' | 'post-monsoon' | 'winter'
typedef Category = String;
// 'water-quality' | 'water-scarcity' | 'flooding-roads' | 'power-lighting'
// | 'agri-postharvest' | 'agri-irrigation' | 'wildlife-conflict' | 'health-environment'
// | 'livelihood-forest-produce' | 'education-access' | 'sanitation' | 'other'
typedef IssueStage = String;
// 'awaiting-validation' | 'validated' | 'routed-service' | 'routed-innovation'
// | 'in-project' | 'resolved' | 'closed-failed'
typedef ProjectStage = String;
// 'team-forming' | 'pending-approval' | 'building' | 'piloting'
// | 'deployed' | 'community-validated' | 'scaled' | 'failed'

const List<Category> kCategories = [
  'water-quality', 'water-scarcity', 'flooding-roads', 'power-lighting',
  'agri-postharvest', 'agri-irrigation', 'wildlife-conflict', 'health-environment',
  'livelihood-forest-produce', 'education-access', 'sanitation', 'other',
];

const List<IssueStage> kIssueStages = [
  'awaiting-validation', 'validated', 'routed-service', 'routed-innovation',
  'in-project', 'resolved', 'closed-failed',
];

const List<ProjectStage> kProjectStages = [
  'team-forming', 'pending-approval', 'building', 'piloting',
  'deployed', 'community-validated', 'scaled', 'failed',
];

class Evidence {
  final String id;
  final String kind; // photo | video | voice | text | document
  final String label;
  final String? url;
  final String addedBy;
  final String addedAt;
  final String? contentHash;
  final String? duplicateStatus; // unique | duplicate
  final String? duplicateOfIssueId;

  Evidence({
    required this.id,
    required this.kind,
    required this.label,
    this.url,
    required this.addedBy,
    required this.addedAt,
    this.contentHash,
    this.duplicateStatus,
    this.duplicateOfIssueId,
  });

  Evidence copyWith({String? contentHash, String? duplicateStatus, String? duplicateOfIssueId}) => Evidence(
        id: id,
        kind: kind,
        label: label,
        url: url,
        addedBy: addedBy,
        addedAt: addedAt,
        contentHash: contentHash ?? this.contentHash,
        duplicateStatus: duplicateStatus ?? this.duplicateStatus,
        duplicateOfIssueId: duplicateOfIssueId ?? this.duplicateOfIssueId,
      );

  factory Evidence.fromJson(Map<String, dynamic> j) => Evidence(
        id: j['id'],
        kind: j['kind'],
        label: j['label'],
        url: j['url'],
        addedBy: j['addedBy'],
        addedAt: j['addedAt'],
        contentHash: j['contentHash'],
        duplicateStatus: j['duplicateStatus'],
        duplicateOfIssueId: j['duplicateOfIssueId'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'label': label,
        'url': url,
        'addedBy': addedBy,
        'addedAt': addedAt,
        'contentHash': contentHash,
        'duplicateStatus': duplicateStatus,
        'duplicateOfIssueId': duplicateOfIssueId,
      };
}

class Report {
  final String id;
  final Channel channel;
  final String language;
  final String? rawText;
  final String? transcript;
  final String? translation;
  final Category category;
  final String districtId;
  final String village;
  final double lat;
  final double lng;
  final int urgencyHint; // 1..5
  final String affectedGroup;
  final int? households;
  final List<Evidence> evidence;
  final String reporterId;
  final String reporterName;
  final String createdAt;
  final String masterIssueId;
  final bool? autoDiscovered;
  final String? citizenSelectedDepartment;
  final double? citizenSelectedDepartmentConfidence;

  Report({
    required this.id,
    required this.channel,
    required this.language,
    this.rawText,
    this.transcript,
    this.translation,
    required this.category,
    required this.districtId,
    required this.village,
    required this.lat,
    required this.lng,
    required this.urgencyHint,
    required this.affectedGroup,
    this.households,
    required this.evidence,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.masterIssueId,
    this.autoDiscovered,
    this.citizenSelectedDepartment,
    this.citizenSelectedDepartmentConfidence,
  });

  factory Report.fromJson(Map<String, dynamic> j) => Report(
        id: j['id'],
        channel: j['channel'],
        language: j['language'],
        rawText: j['rawText'],
        transcript: j['transcript'],
        translation: j['translation'],
        category: j['category'],
        districtId: j['districtId'],
        village: j['village'],
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        urgencyHint: j['urgencyHint'],
        affectedGroup: j['affectedGroup'],
        households: j['households'],
        evidence: (j['evidence'] as List).map((e) => Evidence.fromJson(e)).toList(),
        reporterId: j['reporterId'],
        reporterName: j['reporterName'],
        createdAt: j['createdAt'],
        masterIssueId: j['masterIssueId'],
        autoDiscovered: j['autoDiscovered'],
        citizenSelectedDepartment: j['citizenSelectedDepartment'],
        citizenSelectedDepartmentConfidence: (j['citizenSelectedDepartmentConfidence'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel': channel,
        'language': language,
        'rawText': rawText,
        'transcript': transcript,
        'translation': translation,
        'category': category,
        'districtId': districtId,
        'village': village,
        'lat': lat,
        'lng': lng,
        'urgencyHint': urgencyHint,
        'affectedGroup': affectedGroup,
        'households': households,
        'evidence': evidence.map((e) => e.toJson()).toList(),
        'reporterId': reporterId,
        'reporterName': reporterName,
        'createdAt': createdAt,
        'masterIssueId': masterIssueId,
        'autoDiscovered': autoDiscovered,
        'citizenSelectedDepartment': citizenSelectedDepartment,
        'citizenSelectedDepartmentConfidence': citizenSelectedDepartmentConfidence,
      };
}

class ProblemStatement {
  final String summary;
  final String scope;
  final String evidenceSummary;
  final String urgency;
  final List<String> successCriteria;
  final List<String> disciplinesNeeded;
  final String? approvedBy;
  final String? approvedAt;

  ProblemStatement({
    required this.summary,
    required this.scope,
    required this.evidenceSummary,
    required this.urgency,
    required this.successCriteria,
    required this.disciplinesNeeded,
    this.approvedBy,
    this.approvedAt,
  });

  ProblemStatement copyWith({String? approvedBy, String? approvedAt}) => ProblemStatement(
        summary: summary,
        scope: scope,
        evidenceSummary: evidenceSummary,
        urgency: urgency,
        successCriteria: successCriteria,
        disciplinesNeeded: disciplinesNeeded,
        approvedBy: approvedBy ?? this.approvedBy,
        approvedAt: approvedAt ?? this.approvedAt,
      );

  factory ProblemStatement.fromJson(Map<String, dynamic> j) => ProblemStatement(
        summary: j['summary'],
        scope: j['scope'],
        evidenceSummary: j['evidenceSummary'],
        urgency: j['urgency'],
        successCriteria: List<String>.from(j['successCriteria']),
        disciplinesNeeded: List<String>.from(j['disciplinesNeeded']),
        approvedBy: j['approvedBy'],
        approvedAt: j['approvedAt'],
      );

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'scope': scope,
        'evidenceSummary': evidenceSummary,
        'urgency': urgency,
        'successCriteria': successCriteria,
        'disciplinesNeeded': disciplinesNeeded,
        'approvedBy': approvedBy,
        'approvedAt': approvedAt,
      };
}

class PriorityBreakdown {
  final double harm;
  final double people;
  final double equityGap;
  final double seasonal;
  final double total;
  final List<String> explanation;

  PriorityBreakdown({
    required this.harm,
    required this.people,
    required this.equityGap,
    required this.seasonal,
    required this.total,
    required this.explanation,
  });

  factory PriorityBreakdown.fromJson(Map<String, dynamic> j) => PriorityBreakdown(
        harm: (j['harm'] as num).toDouble(),
        people: (j['people'] as num).toDouble(),
        equityGap: (j['equityGap'] as num).toDouble(),
        seasonal: (j['seasonal'] as num).toDouble(),
        total: (j['total'] as num).toDouble(),
        explanation: List<String>.from(j['explanation']),
      );

  Map<String, dynamic> toJson() => {
        'harm': harm,
        'people': people,
        'equityGap': equityGap,
        'seasonal': seasonal,
        'total': total,
        'explanation': explanation,
      };
}

class HumanOverride {
  final String by;
  final String reason;
  final String at;
  HumanOverride({required this.by, required this.reason, required this.at});

  factory HumanOverride.fromJson(Map<String, dynamic> j) =>
      HumanOverride(by: j['by'], reason: j['reason'], at: j['at']);

  Map<String, dynamic> toJson() => {'by': by, 'reason': reason, 'at': at};
}

class RouteDecision {
  final String type; // service | innovation
  final String? department;
  final String? scheme;
  final String reason;
  final String aiRecommended; // service | innovation
  final HumanOverride? humanOverride;

  RouteDecision({
    required this.type,
    this.department,
    this.scheme,
    required this.reason,
    required this.aiRecommended,
    this.humanOverride,
  });

  RouteDecision copyWith({String? type, HumanOverride? humanOverride}) => RouteDecision(
        type: type ?? this.type,
        department: department,
        scheme: scheme,
        reason: reason,
        aiRecommended: aiRecommended,
        humanOverride: humanOverride ?? this.humanOverride,
      );

  factory RouteDecision.fromJson(Map<String, dynamic> j) => RouteDecision(
        type: j['type'],
        department: j['department'],
        scheme: j['scheme'],
        reason: j['reason'],
        aiRecommended: j['aiRecommended'],
        humanOverride: j['humanOverride'] != null ? HumanOverride.fromJson(j['humanOverride']) : null,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'department': department,
        'scheme': scheme,
        'reason': reason,
        'aiRecommended': aiRecommended,
        'humanOverride': humanOverride?.toJson(),
      };
}

class ServiceTicket {
  final String id;
  final String department;
  final String status; // assigned | in-progress | resolved
  final int slaDays;
  final String assignedAt;
  final String? resolvedAt;

  ServiceTicket({
    required this.id,
    required this.department,
    required this.status,
    required this.slaDays,
    required this.assignedAt,
    this.resolvedAt,
  });

  ServiceTicket copyWith({String? status, String? resolvedAt}) => ServiceTicket(
        id: id,
        department: department,
        status: status ?? this.status,
        slaDays: slaDays,
        assignedAt: assignedAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );

  factory ServiceTicket.fromJson(Map<String, dynamic> j) => ServiceTicket(
        id: j['id'],
        department: j['department'],
        status: j['status'],
        slaDays: j['slaDays'],
        assignedAt: j['assignedAt'],
        resolvedAt: j['resolvedAt'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'department': department,
        'status': status,
        'slaDays': slaDays,
        'assignedAt': assignedAt,
        'resolvedAt': resolvedAt,
      };
}

class MasterIssue {
  final String id;
  final String title;
  final String? titleHi;
  final Category category;
  final String districtId;
  final String village;
  final double lat;
  final double lng;
  final List<String> reportIds;
  final int upvotes;
  final List<String> upvoterIds;
  final int households;
  final IssueStage stage;
  final ProblemStatement? problemStatement;
  final PriorityBreakdown? priority;
  final RouteDecision? route;
  final String? systemicId;
  final String? projectId;
  final ServiceTicket? serviceTicket;
  final int repeatCount;
  final String createdAt;

  MasterIssue({
    required this.id,
    required this.title,
    this.titleHi,
    required this.category,
    required this.districtId,
    required this.village,
    required this.lat,
    required this.lng,
    required this.reportIds,
    required this.upvotes,
    required this.upvoterIds,
    required this.households,
    required this.stage,
    this.problemStatement,
    this.priority,
    this.route,
    this.systemicId,
    this.projectId,
    this.serviceTicket,
    required this.repeatCount,
    required this.createdAt,
  });

  MasterIssue copyWith({
    List<String>? reportIds,
    int? upvotes,
    List<String>? upvoterIds,
    int? households,
    IssueStage? stage,
    ProblemStatement? problemStatement,
    PriorityBreakdown? priority,
    RouteDecision? route,
    String? systemicId,
    String? projectId,
    ServiceTicket? serviceTicket,
    int? repeatCount,
  }) =>
      MasterIssue(
        id: id,
        title: title,
        titleHi: titleHi,
        category: category,
        districtId: districtId,
        village: village,
        lat: lat,
        lng: lng,
        reportIds: reportIds ?? this.reportIds,
        upvotes: upvotes ?? this.upvotes,
        upvoterIds: upvoterIds ?? this.upvoterIds,
        households: households ?? this.households,
        stage: stage ?? this.stage,
        problemStatement: problemStatement ?? this.problemStatement,
        priority: priority ?? this.priority,
        route: route ?? this.route,
        systemicId: systemicId ?? this.systemicId,
        projectId: projectId ?? this.projectId,
        serviceTicket: serviceTicket ?? this.serviceTicket,
        repeatCount: repeatCount ?? this.repeatCount,
        createdAt: createdAt,
      );

  factory MasterIssue.fromJson(Map<String, dynamic> j) => MasterIssue(
        id: j['id'],
        title: j['title'],
        titleHi: j['titleHi'],
        category: j['category'],
        districtId: j['districtId'],
        village: j['village'],
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        reportIds: List<String>.from(j['reportIds']),
        upvotes: j['upvotes'],
        upvoterIds: List<String>.from(j['upvoterIds']),
        households: j['households'],
        stage: j['stage'],
        problemStatement: j['problemStatement'] != null ? ProblemStatement.fromJson(j['problemStatement']) : null,
        priority: j['priority'] != null ? PriorityBreakdown.fromJson(j['priority']) : null,
        route: j['route'] != null ? RouteDecision.fromJson(j['route']) : null,
        systemicId: j['systemicId'],
        projectId: j['projectId'],
        serviceTicket: j['serviceTicket'] != null ? ServiceTicket.fromJson(j['serviceTicket']) : null,
        repeatCount: j['repeatCount'],
        createdAt: j['createdAt'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'titleHi': titleHi,
        'category': category,
        'districtId': districtId,
        'village': village,
        'lat': lat,
        'lng': lng,
        'reportIds': reportIds,
        'upvotes': upvotes,
        'upvoterIds': upvoterIds,
        'households': households,
        'stage': stage,
        'problemStatement': problemStatement?.toJson(),
        'priority': priority?.toJson(),
        'route': route?.toJson(),
        'systemicId': systemicId,
        'projectId': projectId,
        'serviceTicket': serviceTicket?.toJson(),
        'repeatCount': repeatCount,
        'createdAt': createdAt,
      };
}

class SystemicChallenge {
  final String id;
  final String title;
  final String rootCause;
  final List<String> issueIds;
  final List<String> districtIds;
  final bool promoted;
  final String? projectId;

  SystemicChallenge({
    required this.id,
    required this.title,
    required this.rootCause,
    required this.issueIds,
    required this.districtIds,
    required this.promoted,
    this.projectId,
  });

  SystemicChallenge copyWith({bool? promoted, String? projectId}) => SystemicChallenge(
        id: id,
        title: title,
        rootCause: rootCause,
        issueIds: issueIds,
        districtIds: districtIds,
        promoted: promoted ?? this.promoted,
        projectId: projectId ?? this.projectId,
      );

  factory SystemicChallenge.fromJson(Map<String, dynamic> j) => SystemicChallenge(
        id: j['id'],
        title: j['title'],
        rootCause: j['rootCause'],
        issueIds: List<String>.from(j['issueIds']),
        districtIds: List<String>.from(j['districtIds']),
        promoted: j['promoted'],
        projectId: j['projectId'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'rootCause': rootCause,
        'issueIds': issueIds,
        'districtIds': districtIds,
        'promoted': promoted,
        'projectId': projectId,
      };
}

class CredibilityHistoryEntry {
  final String projectId;
  final double delta;
  final String reason;
  CredibilityHistoryEntry({required this.projectId, required this.delta, required this.reason});

  factory CredibilityHistoryEntry.fromJson(Map<String, dynamic> j) =>
      CredibilityHistoryEntry(projectId: j['projectId'], delta: (j['delta'] as num).toDouble(), reason: j['reason']);

  Map<String, dynamic> toJson() => {'projectId': projectId, 'delta': delta, 'reason': reason};
}

class CredibilityProfile {
  final double timeliness;
  final double qrSuccess;
  final double councilApproval;
  final double maintenance;
  final double overall;
  final List<CredibilityHistoryEntry> history;

  CredibilityProfile({
    required this.timeliness,
    required this.qrSuccess,
    required this.councilApproval,
    required this.maintenance,
    required this.overall,
    required this.history,
  });

  CredibilityProfile copyWith({
    double? timeliness,
    double? qrSuccess,
    double? councilApproval,
    double? maintenance,
    double? overall,
    List<CredibilityHistoryEntry>? history,
  }) =>
      CredibilityProfile(
        timeliness: timeliness ?? this.timeliness,
        qrSuccess: qrSuccess ?? this.qrSuccess,
        councilApproval: councilApproval ?? this.councilApproval,
        maintenance: maintenance ?? this.maintenance,
        overall: overall ?? this.overall,
        history: history ?? this.history,
      );

  factory CredibilityProfile.fromJson(Map<String, dynamic> j) => CredibilityProfile(
        timeliness: (j['timeliness'] as num).toDouble(),
        qrSuccess: (j['qrSuccess'] as num).toDouble(),
        councilApproval: (j['councilApproval'] as num).toDouble(),
        maintenance: (j['maintenance'] as num).toDouble(),
        overall: (j['overall'] as num).toDouble(),
        history: (j['history'] as List).map((e) => CredibilityHistoryEntry.fromJson(e)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'timeliness': timeliness,
        'qrSuccess': qrSuccess,
        'councilApproval': councilApproval,
        'maintenance': maintenance,
        'overall': overall,
        'history': history.map((e) => e.toJson()).toList(),
      };
}

class Institution {
  final String id;
  final String name;
  final String type; // HEI | Lab | Startup | ITI
  final String districtId;
  final double lat;
  final double lng;
  final List<String> disciplines;
  final List<String> labs;
  final List<String> equipment;
  final double availability;
  final CredibilityProfile credibility;

  Institution({
    required this.id,
    required this.name,
    required this.type,
    required this.districtId,
    required this.lat,
    required this.lng,
    required this.disciplines,
    required this.labs,
    required this.equipment,
    required this.availability,
    required this.credibility,
  });

  Institution copyWith({CredibilityProfile? credibility}) => Institution(
        id: id,
        name: name,
        type: type,
        districtId: districtId,
        lat: lat,
        lng: lng,
        disciplines: disciplines,
        labs: labs,
        equipment: equipment,
        availability: availability,
        credibility: credibility ?? this.credibility,
      );

  factory Institution.fromJson(Map<String, dynamic> j) => Institution(
        id: j['id'],
        name: j['name'],
        type: j['type'],
        districtId: j['districtId'],
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        disciplines: List<String>.from(j['disciplines']),
        labs: List<String>.from(j['labs']),
        equipment: List<String>.from(j['equipment']),
        availability: (j['availability'] as num).toDouble(),
        credibility: CredibilityProfile.fromJson(j['credibility']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'districtId': districtId,
        'lat': lat,
        'lng': lng,
        'disciplines': disciplines,
        'labs': labs,
        'equipment': equipment,
        'availability': availability,
        'credibility': credibility.toJson(),
      };
}

class Team {
  final String id;
  final String institutionId;
  final List<String> memberIds;
  final List<String> disciplines;

  Team({required this.id, required this.institutionId, required this.memberIds, required this.disciplines});

  factory Team.fromJson(Map<String, dynamic> j) => Team(
        id: j['id'],
        institutionId: j['institutionId'],
        memberIds: List<String>.from(j['memberIds']),
        disciplines: List<String>.from(j['disciplines']),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'institutionId': institutionId, 'memberIds': memberIds, 'disciplines': disciplines};
}

class Doc {
  final String id;
  final String title;
  final String kind; // proposal | test | approval | proof | other | funds-allocation
  final String addedAt;
  final String? url;
  final String? contentHash;
  final String? duplicateStatus; // unique | duplicate
  final String? duplicateOfProjectId;
  final double? duplicateCheckConfidence;
  final List<DocAttachment>? attachments;

  Doc({
    required this.id,
    required this.title,
    required this.kind,
    required this.addedAt,
    this.url,
    this.contentHash,
    this.duplicateStatus,
    this.duplicateOfProjectId,
    this.duplicateCheckConfidence,
    this.attachments,
  });

  Doc copyWith({String? contentHash, String? duplicateStatus, String? duplicateOfProjectId, double? duplicateCheckConfidence}) =>
      Doc(
        id: id,
        title: title,
        kind: kind,
        addedAt: addedAt,
        url: url,
        contentHash: contentHash ?? this.contentHash,
        duplicateStatus: duplicateStatus ?? this.duplicateStatus,
        duplicateOfProjectId: duplicateOfProjectId ?? this.duplicateOfProjectId,
        duplicateCheckConfidence: duplicateCheckConfidence ?? this.duplicateCheckConfidence,
        attachments: attachments,
      );

  factory Doc.fromJson(Map<String, dynamic> j) => Doc(
        id: j['id'],
        title: j['title'],
        kind: j['kind'],
        addedAt: j['addedAt'],
        url: j['url'],
        contentHash: j['contentHash'],
        duplicateStatus: j['duplicateStatus'],
        duplicateOfProjectId: j['duplicateOfProjectId'],
        duplicateCheckConfidence: (j['duplicateCheckConfidence'] as num?)?.toDouble(),
        attachments: j['attachments'] != null
            ? (j['attachments'] as List).map((e) => DocAttachment.fromJson(e)).toList()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'kind': kind,
        'addedAt': addedAt,
        'url': url,
        'contentHash': contentHash,
        'duplicateStatus': duplicateStatus,
        'duplicateOfProjectId': duplicateOfProjectId,
        'duplicateCheckConfidence': duplicateCheckConfidence,
        'attachments': attachments?.map((e) => e.toJson()).toList(),
      };
}

class DocAttachment {
  final String id;
  final String title;
  final String url;
  DocAttachment({required this.id, required this.title, required this.url});

  factory DocAttachment.fromJson(Map<String, dynamic> j) => DocAttachment(id: j['id'], title: j['title'], url: j['url']);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'url': url};
}

class Milestone {
  final String id;
  final String title;
  final double budget;
  final String due;
  final String status; // pending | submitted | approved | released
  final Doc? proof;

  Milestone({
    required this.id,
    required this.title,
    required this.budget,
    required this.due,
    required this.status,
    this.proof,
  });

  Milestone copyWith({String? title, double? budget, String? due, String? status, Doc? proof}) => Milestone(
        id: id,
        title: title ?? this.title,
        budget: budget ?? this.budget,
        due: due ?? this.due,
        status: status ?? this.status,
        proof: proof ?? this.proof,
      );

  factory Milestone.fromJson(Map<String, dynamic> j) => Milestone(
        id: j['id'],
        title: j['title'],
        budget: (j['budget'] as num).toDouble(),
        due: j['due'],
        status: j['status'],
        proof: j['proof'] != null ? Doc.fromJson(j['proof']) : null,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'budget': budget, 'due': due, 'status': status, 'proof': proof?.toJson()};
}

class Pledge {
  final String id;
  final String partnerId;
  final String type; // funding | mentoring | equipment | manufacturing | testing
  final double? amount;
  final String description;
  final String scope; // project | milestone
  final String? milestoneId;
  final String status; // pledged | released

  Pledge({
    required this.id,
    required this.partnerId,
    required this.type,
    this.amount,
    required this.description,
    required this.scope,
    this.milestoneId,
    required this.status,
  });

  Pledge copyWith({String? status}) => Pledge(
        id: id,
        partnerId: partnerId,
        type: type,
        amount: amount,
        description: description,
        scope: scope,
        milestoneId: milestoneId,
        status: status ?? this.status,
      );

  factory Pledge.fromJson(Map<String, dynamic> j) => Pledge(
        id: j['id'],
        partnerId: j['partnerId'],
        type: j['type'],
        amount: (j['amount'] as num?)?.toDouble(),
        description: j['description'],
        scope: j['scope'],
        milestoneId: j['milestoneId'],
        status: j['status'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'partnerId': partnerId,
        'type': type,
        'amount': amount,
        'description': description,
        'scope': scope,
        'milestoneId': milestoneId,
        'status': status,
      };
}

class Risk {
  final String id;
  final String label;
  final String severity; // low | medium | high
  final int? daysLate;

  Risk({required this.id, required this.label, required this.severity, this.daysLate});

  factory Risk.fromJson(Map<String, dynamic> j) =>
      Risk(id: j['id'], label: j['label'], severity: j['severity'], daysLate: j['daysLate']);

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'severity': severity, 'daysLate': daysLate};
}

class PilotMetric {
  final String id;
  final String label;
  final double value;
  final String unit;
  final double? target;

  PilotMetric({required this.id, required this.label, required this.value, required this.unit, this.target});

  factory PilotMetric.fromJson(Map<String, dynamic> j) => PilotMetric(
        id: j['id'],
        label: j['label'],
        value: (j['value'] as num).toDouble(),
        unit: j['unit'],
        target: (j['target'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'value': value, 'unit': unit, 'target': target};
}

class CouncilVote {
  final String id;
  final String stage; // problem | prototype | pilot | final
  final String seat; // reporter | panchayat | beneficiary | expert | official
  final String vote; // yes | partial | no
  final String? comment;
  final String at;

  CouncilVote({
    required this.id,
    required this.stage,
    required this.seat,
    required this.vote,
    this.comment,
    required this.at,
  });

  factory CouncilVote.fromJson(Map<String, dynamic> j) => CouncilVote(
        id: j['id'],
        stage: j['stage'],
        seat: j['seat'],
        vote: j['vote'],
        comment: j['comment'],
        at: j['at'],
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'stage': stage, 'seat': seat, 'vote': vote, 'comment': comment, 'at': at};
}

class QRFeedback {
  final String id;
  final String outcome; // works | partial | not-working | needs-maintenance
  final String? note;
  final String? photo;
  final String at;

  QRFeedback({required this.id, required this.outcome, this.note, this.photo, required this.at});

  factory QRFeedback.fromJson(Map<String, dynamic> j) =>
      QRFeedback(id: j['id'], outcome: j['outcome'], note: j['note'], photo: j['photo'], at: j['at']);

  Map<String, dynamic> toJson() => {'id': id, 'outcome': outcome, 'note': note, 'photo': photo, 'at': at};
}

class Update {
  final String id;
  final String text;
  final String at;
  final String by;

  Update({required this.id, required this.text, required this.at, required this.by});

  factory Update.fromJson(Map<String, dynamic> j) => Update(id: j['id'], text: j['text'], at: j['at'], by: j['by']);

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'at': at, 'by': by};
}

class Project {
  final String id;
  final String issueId;
  final String title;
  final String? teamId;
  final ProjectStage stage;
  final String ownerId;
  final String districtId;
  final double budget;
  final List<Milestone> milestones;
  final List<Pledge> pledges;
  final List<Doc> documents;
  final List<Risk> risks;
  final List<PilotMetric> pilotResults;
  final List<CouncilVote> councilVotes;
  final List<QRFeedback> qrFeedback;
  final List<Update> updates;
  final String maintenancePlan;
  final String createdAt;

  Project({
    required this.id,
    required this.issueId,
    required this.title,
    this.teamId,
    required this.stage,
    required this.ownerId,
    required this.districtId,
    required this.budget,
    required this.milestones,
    required this.pledges,
    required this.documents,
    required this.risks,
    required this.pilotResults,
    required this.councilVotes,
    required this.qrFeedback,
    required this.updates,
    required this.maintenancePlan,
    required this.createdAt,
  });

  Project copyWith({
    String? teamId,
    ProjectStage? stage,
    List<Milestone>? milestones,
    List<Pledge>? pledges,
    List<Doc>? documents,
    List<Risk>? risks,
    List<PilotMetric>? pilotResults,
    List<CouncilVote>? councilVotes,
    List<QRFeedback>? qrFeedback,
    List<Update>? updates,
    String? maintenancePlan,
  }) =>
      Project(
        id: id,
        issueId: issueId,
        title: title,
        teamId: teamId ?? this.teamId,
        stage: stage ?? this.stage,
        ownerId: ownerId,
        districtId: districtId,
        budget: budget,
        milestones: milestones ?? this.milestones,
        pledges: pledges ?? this.pledges,
        documents: documents ?? this.documents,
        risks: risks ?? this.risks,
        pilotResults: pilotResults ?? this.pilotResults,
        councilVotes: councilVotes ?? this.councilVotes,
        qrFeedback: qrFeedback ?? this.qrFeedback,
        updates: updates ?? this.updates,
        maintenancePlan: maintenancePlan ?? this.maintenancePlan,
        createdAt: createdAt,
      );

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: j['id'],
        issueId: j['issueId'],
        title: j['title'],
        teamId: j['teamId'],
        stage: j['stage'],
        ownerId: j['ownerId'],
        districtId: j['districtId'],
        budget: (j['budget'] as num).toDouble(),
        milestones: (j['milestones'] as List).map((e) => Milestone.fromJson(e)).toList(),
        pledges: (j['pledges'] as List).map((e) => Pledge.fromJson(e)).toList(),
        documents: (j['documents'] as List).map((e) => Doc.fromJson(e)).toList(),
        risks: (j['risks'] as List).map((e) => Risk.fromJson(e)).toList(),
        pilotResults: (j['pilotResults'] as List).map((e) => PilotMetric.fromJson(e)).toList(),
        councilVotes: (j['councilVotes'] as List).map((e) => CouncilVote.fromJson(e)).toList(),
        qrFeedback: (j['qrFeedback'] as List).map((e) => QRFeedback.fromJson(e)).toList(),
        updates: (j['updates'] as List).map((e) => Update.fromJson(e)).toList(),
        maintenancePlan: j['maintenancePlan'],
        createdAt: j['createdAt'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'issueId': issueId,
        'title': title,
        'teamId': teamId,
        'stage': stage,
        'ownerId': ownerId,
        'districtId': districtId,
        'budget': budget,
        'milestones': milestones.map((e) => e.toJson()).toList(),
        'pledges': pledges.map((e) => e.toJson()).toList(),
        'documents': documents.map((e) => e.toJson()).toList(),
        'risks': risks.map((e) => e.toJson()).toList(),
        'pilotResults': pilotResults.map((e) => e.toJson()).toList(),
        'councilVotes': councilVotes.map((e) => e.toJson()).toList(),
        'qrFeedback': qrFeedback.map((e) => e.toJson()).toList(),
        'updates': updates.map((e) => e.toJson()).toList(),
        'maintenancePlan': maintenancePlan,
        'createdAt': createdAt,
      };
}

class CapabilityGap {
  final String id;
  final String? issueId;
  final String kind; // expert | lab | equipment | capacity
  final String label;
  final List<String> districtIds;
  final bool published;
  final String? filledBy;

  CapabilityGap({
    required this.id,
    this.issueId,
    required this.kind,
    required this.label,
    required this.districtIds,
    required this.published,
    this.filledBy,
  });

  CapabilityGap copyWith({bool? published, String? filledBy}) => CapabilityGap(
        id: id,
        issueId: issueId,
        kind: kind,
        label: label,
        districtIds: districtIds,
        published: published ?? this.published,
        filledBy: filledBy ?? this.filledBy,
      );

  factory CapabilityGap.fromJson(Map<String, dynamic> j) => CapabilityGap(
        id: j['id'],
        issueId: j['issueId'],
        kind: j['kind'],
        label: j['label'],
        districtIds: List<String>.from(j['districtIds']),
        published: j['published'],
        filledBy: j['filledBy'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'issueId': issueId,
        'kind': kind,
        'label': label,
        'districtIds': districtIds,
        'published': published,
        'filledBy': filledBy,
      };
}

class FailureLesson {
  final String id;
  final String? projectId;
  final Category category;
  final String type; // technical | cost | maintenance | community
  final String lesson;
  final String designWarning;

  FailureLesson({
    required this.id,
    this.projectId,
    required this.category,
    required this.type,
    required this.lesson,
    required this.designWarning,
  });

  factory FailureLesson.fromJson(Map<String, dynamic> j) => FailureLesson(
        id: j['id'],
        projectId: j['projectId'],
        category: j['category'],
        type: j['type'],
        lesson: j['lesson'],
        designWarning: j['designWarning'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'category': category,
        'type': type,
        'lesson': lesson,
        'designWarning': designWarning,
      };
}

class SolutionMemoryEntry {
  final String id;
  final String projectId;
  final Category category;
  final String title;
  final String districtId;
  final List<String> components;
  final double cost;
  final String pilotResult;
  final List<String> lessons;
  final List<String> researchers;
  final String institutionId;

  SolutionMemoryEntry({
    required this.id,
    required this.projectId,
    required this.category,
    required this.title,
    required this.districtId,
    required this.components,
    required this.cost,
    required this.pilotResult,
    required this.lessons,
    required this.researchers,
    required this.institutionId,
  });

  factory SolutionMemoryEntry.fromJson(Map<String, dynamic> j) => SolutionMemoryEntry(
        id: j['id'],
        projectId: j['projectId'],
        category: j['category'],
        title: j['title'],
        districtId: j['districtId'],
        components: List<String>.from(j['components']),
        cost: (j['cost'] as num).toDouble(),
        pilotResult: j['pilotResult'],
        lessons: List<String>.from(j['lessons']),
        researchers: List<String>.from(j['researchers']),
        institutionId: j['institutionId'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'category': category,
        'title': title,
        'districtId': districtId,
        'components': components,
        'cost': cost,
        'pilotResult': pilotResult,
        'lessons': lessons,
        'researchers': researchers,
        'institutionId': institutionId,
      };
}

class OutreachTask {
  final String id;
  final String districtId;
  final String institutionId;
  final String status; // assigned | completed

  OutreachTask({required this.id, required this.districtId, required this.institutionId, required this.status});

  OutreachTask copyWith({String? status}) =>
      OutreachTask(id: id, districtId: districtId, institutionId: institutionId, status: status ?? this.status);

  factory OutreachTask.fromJson(Map<String, dynamic> j) => OutreachTask(
        id: j['id'],
        districtId: j['districtId'],
        institutionId: j['institutionId'],
        status: j['status'],
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'districtId': districtId, 'institutionId': institutionId, 'status': status};
}

class AppNotification {
  final String id;
  final String toRole; // Role | 'all'
  final String? toUserId;
  final String text;
  final String? link;
  final String at;
  final bool read;

  AppNotification({
    required this.id,
    required this.toRole,
    this.toUserId,
    required this.text,
    this.link,
    required this.at,
    required this.read,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        toRole: toRole,
        toUserId: toUserId,
        text: text,
        link: link,
        at: at,
        read: read ?? this.read,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'],
        toRole: j['toRole'],
        toUserId: j['toUserId'],
        text: j['text'],
        link: j['link'],
        at: j['at'],
        read: j['read'],
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'toRole': toRole, 'toUserId': toUserId, 'text': text, 'link': link, 'at': at, 'read': read};
}

class AuditEntry {
  final String id;
  final String actor;
  final Role role;
  final String action;
  final String target;
  final String? detail;
  final String at;

  AuditEntry({
    required this.id,
    required this.actor,
    required this.role,
    required this.action,
    required this.target,
    this.detail,
    required this.at,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> j) => AuditEntry(
        id: j['id'],
        actor: j['actor'],
        role: j['role'],
        action: j['action'],
        target: j['target'],
        detail: j['detail'],
        at: j['at'],
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'actor': actor, 'role': role, 'action': action, 'target': target, 'detail': detail, 'at': at};
}

class District {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int population;
  final double needIndex;
  final double reportRate;
  final List<String> terrain;
  final String rainfall; // low | medium | high
  final bool? tribalMajority;

  District({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.population,
    required this.needIndex,
    required this.reportRate,
    required this.terrain,
    required this.rainfall,
    this.tribalMajority,
  });

  factory District.fromJson(Map<String, dynamic> j) => District(
        id: j['id'],
        name: j['name'],
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        population: j['population'],
        needIndex: (j['needIndex'] as num).toDouble(),
        reportRate: (j['reportRate'] as num).toDouble(),
        terrain: List<String>.from(j['terrain']),
        rainfall: j['rainfall'],
        tribalMajority: j['tribalMajority'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'population': population,
        'needIndex': needIndex,
        'reportRate': reportRate,
        'terrain': terrain,
        'rainfall': rainfall,
        'tribalMajority': tribalMajority,
      };
}

class IndustryPartner {
  final String id;
  final String name;
  final List<String> expertise;
  final List<String> districtIds;
  final List<String> offerTypes; // funding | mentoring | equipment | manufacturing | testing

  IndustryPartner({
    required this.id,
    required this.name,
    required this.expertise,
    required this.districtIds,
    required this.offerTypes,
  });

  factory IndustryPartner.fromJson(Map<String, dynamic> j) => IndustryPartner(
        id: j['id'],
        name: j['name'],
        expertise: List<String>.from(j['expertise']),
        districtIds: List<String>.from(j['districtIds']),
        offerTypes: List<String>.from(j['offerTypes']),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'expertise': expertise, 'districtIds': districtIds, 'offerTypes': offerTypes};
}

class SocialPost {
  final String id;
  final String platform; // x | instagram | telegram | facebook
  final String author;
  final bool verified;
  final String text;
  final String districtId;
  final Category category;
  final double lat;
  final double lng;
  final String at;
  final bool? converted;

  SocialPost({
    required this.id,
    required this.platform,
    required this.author,
    required this.verified,
    required this.text,
    required this.districtId,
    required this.category,
    required this.lat,
    required this.lng,
    required this.at,
    this.converted,
  });

  SocialPost copyWith({bool? converted}) => SocialPost(
        id: id,
        platform: platform,
        author: author,
        verified: verified,
        text: text,
        districtId: districtId,
        category: category,
        lat: lat,
        lng: lng,
        at: at,
        converted: converted ?? this.converted,
      );

  factory SocialPost.fromJson(Map<String, dynamic> j) => SocialPost(
        id: j['id'],
        platform: j['platform'],
        author: j['author'],
        verified: j['verified'],
        text: j['text'],
        districtId: j['districtId'],
        category: j['category'],
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        at: j['at'],
        converted: j['converted'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform': platform,
        'author': author,
        'verified': verified,
        'text': text,
        'districtId': districtId,
        'category': category,
        'lat': lat,
        'lng': lng,
        'at': at,
        'converted': converted,
      };
}

class Persona {
  final String id;
  final String name;
  final Role role;
  final String? districtId;
  final String? institutionId;
  final String? partnerId;
  final String? councilSeat; // CouncilVote.seat
  final String? department;
  final String avatarColor;
  final String blurb;

  Persona({
    required this.id,
    required this.name,
    required this.role,
    this.districtId,
    this.institutionId,
    this.partnerId,
    this.councilSeat,
    this.department,
    required this.avatarColor,
    required this.blurb,
  });

  factory Persona.fromJson(Map<String, dynamic> j) => Persona(
        id: j['id'],
        name: j['name'],
        role: j['role'],
        districtId: j['districtId'],
        institutionId: j['institutionId'],
        partnerId: j['partnerId'],
        councilSeat: j['councilSeat'],
        department: j['department'],
        avatarColor: j['avatarColor'],
        blurb: j['blurb'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'districtId': districtId,
        'institutionId': institutionId,
        'partnerId': partnerId,
        'councilSeat': councilSeat,
        'department': department,
        'avatarColor': avatarColor,
        'blurb': blurb,
      };
}
