// Ported 1:1 from src/data/projects.ts
import '../models/types.dart';
import 'reports.dart' as reports_data;

String _iso(int daysAgo) => reports_data.NOW.subtract(Duration(days: daysAgo)).toUtc().toIso8601String();
String _isoFuture(int daysAhead) => reports_data.NOW.add(Duration(days: daysAhead)).toUtc().toIso8601String();

MasterIssue _findIssue(bool Function(MasterIssue) test) => reports_data.seedMasterIssues.firstWhere(test);

final List<Team> seedTeams = [
  Team(
      id: 'team-fluoride',
      institutionId: 'jharkhand-water-lab',
      memberIds: const ['Dr. R. Singh', 'Field technician P. Yadav'],
      disciplines: const ['environmental science', 'water-quality']),
  Team(
      id: 'team-cold-storage',
      institutionId: 'bau-ranchi',
      memberIds: const ['Dr. P. Mahto', 'Student intern A. Kujur'],
      disciplines: const ['agri-postharvest', 'agri']),
  Team(
      id: 'team-lac',
      institutionId: 'ilri-namkum',
      memberIds: const ['Dr. M. Kerketta'],
      disciplines: const ['lac cultivation', 'value-addition']),
  Team(
      id: 'team-handpump',
      institutionId: 'bit-mesra',
      memberIds: const ['Dr. N. Verma', 'Student intern R. Ho'],
      disciplines: const ['iot/embedded', 'mechanical engineering']),
  Team(
      id: 'team-solar-irrigation',
      institutionId: 'nit-jamshedpur',
      memberIds: const ['Dr. K. Oraon'],
      disciplines: const ['renewable energy']),
  Team(
      id: 'team-rainwater',
      institutionId: 'bit-mesra',
      memberIds: const ['Dr. A. Kumari', 'Dr. S. Toppo'],
      disciplines: const ['civil engineering', 'environmental science']),
  Team(
      id: 'team-forest-produce',
      institutionId: 'nit-jamshedpur',
      memberIds: const ['Dr. B. Hembrom'],
      disciplines: const ['value-addition', 'social science']),
  Team(
      id: 'team-health-camp',
      institutionId: 'vbu-hazaribagh',
      memberIds: const ['Dr. F. Ansari', 'Student intern L. Kumari'],
      disciplines: const ['public policy', 'social science']),
  Team(
      id: 'team-wildlife-fence',
      institutionId: 'kolhan-university',
      memberIds: const ['Dr. J. Munda'],
      disciplines: const ['social science', 'civil engineering']),
  Team(
      id: 'team-irrigation',
      institutionId: 'npu-medininagar',
      memberIds: const ['Dr. S. Bhagat', 'Student intern D. Ram'],
      disciplines: const ['agri-irrigation', 'civil engineering']),
];

List<Project> _buildProjects() {
  final fluorideIssue = _findIssue((i) => i.title.contains('Fluoride'));
  final tomatoIssue = _findIssue((i) => i.title.contains('Tomatoes'));
  final lacIssue = _findIssue((i) => i.title.contains('lac and mahua'));
  final forestProduceIssue = _findIssue((i) =>
      i.districtId == 'east-singhbhum' && i.category == 'livelihood-forest-produce' && i.village == 'Bhawnathpur');
  final healthCampIssue =
      _findIssue((i) => i.districtId == 'hazaribagh' && i.category == 'health-environment' && i.village == 'Ghatshila');
  final wildlifeFenceIssue =
      _findIssue((i) => i.districtId == 'palamu' && i.category == 'wildlife-conflict' && i.village == 'Bundu');
  final irrigationIssue =
      _findIssue((i) => i.districtId == 'lohardaga' && i.category == 'agri-irrigation' && i.village == 'Devipur');
  final handpumpIssue = _findIssue((i) => i.title.contains('Non-working hand pumps'));
  final solarIrrigationFailedIssue = _findIssue((i) => i.title.contains('Solar irrigation pump failed'));
  final firstIssue = reports_data.seedMasterIssues[0];

  return [
    Project(
      id: 'proj-fluoride',
      issueId: fluorideIssue.id,
      title: 'Community fluoride filtration units, Badih',
      teamId: 'team-fluoride',
      stage: 'deployed',
      ownerId: 'jharkhand-water-lab',
      districtId: 'palamu',
      budget: 620000,
      milestones: [
        Milestone(id: 'ms-f1', title: 'Site survey and water testing', budget: 80000, due: _iso(100), status: 'released'),
        Milestone(
            id: 'ms-f2',
            title: 'Filtration unit procurement and installation',
            budget: 340000,
            due: _iso(50),
            status: 'released'),
        Milestone(
          id: 'ms-f3',
          title: 'Community caretaker training and handover',
          budget: 200000,
          due: _iso(10),
          status: 'submitted',
          proof: Doc(
            id: 'doc-f3',
            title: 'Handover and training completion report',
            kind: 'proof',
            addedAt: _iso(9),
            url: '/images/milestone-report-badih-caretaker-handover.png',
            attachments: [
              DocAttachment(
                  id: 'doc-f3-att1',
                  title: 'Filtration unit installed and handed over — Badih',
                  url: '/images/filtration-unit-installed-badih.png'),
            ],
          ),
        ),
      ],
      pledges: [
        Pledge(
            id: 'pl-f1',
            partnerId: 'bccl-csr',
            type: 'funding',
            amount: 400000,
            description: 'Filtration hardware funding',
            scope: 'project',
            status: 'released'),
        Pledge(
            id: 'pl-f2',
            partnerId: 'state-ngo',
            type: 'mentoring',
            description: 'Community mobilisation support',
            scope: 'project',
            status: 'released'),
      ],
      documents: [
        Doc(id: 'doc-f-proposal', title: 'Innovation Twin proposal', kind: 'proposal', addedAt: _iso(110)),
        Doc(id: 'doc-f-test', title: 'Water quality test results (pre/post)', kind: 'test', addedAt: _iso(30)),
        Doc(
            id: 'doc-f-funds',
            title: 'PHED funds allocation order, Palamu',
            kind: 'funds-allocation',
            addedAt: _iso(98),
            contentHash: 'a1f4c9e2b7d0356819aa4f6c2e0b8d17f3c5a9e6d2b41708c3f5a9e0b6d2c418',
            duplicateStatus: 'unique'),
      ],
      risks: const [],
      pilotResults: [
        PilotMetric(id: 'pm-f1', label: 'Fluoride level', value: 0.8, unit: 'mg/L', target: 1.0),
        PilotMetric(id: 'pm-f2', label: 'Households served', value: 63, unit: 'households'),
      ],
      councilVotes: [
        CouncilVote(id: 'cv-f1', stage: 'problem', seat: 'reporter', vote: 'yes', at: _iso(105)),
        CouncilVote(id: 'cv-f2', stage: 'problem', seat: 'panchayat', vote: 'yes', at: _iso(105)),
        CouncilVote(id: 'cv-f3', stage: 'problem', seat: 'beneficiary', vote: 'yes', at: _iso(104)),
        CouncilVote(id: 'cv-f4', stage: 'problem', seat: 'expert', vote: 'yes', at: _iso(104)),
        CouncilVote(id: 'cv-f5', stage: 'problem', seat: 'official', vote: 'yes', at: _iso(103)),
        CouncilVote(id: 'cv-f6', stage: 'prototype', seat: 'reporter', vote: 'yes', at: _iso(70)),
        CouncilVote(id: 'cv-f7', stage: 'prototype', seat: 'panchayat', vote: 'yes', at: _iso(70)),
        CouncilVote(
            id: 'cv-f8',
            stage: 'prototype',
            seat: 'beneficiary',
            vote: 'partial',
            comment: 'Works, but caretaker training needs to happen sooner',
            at: _iso(69)),
        CouncilVote(id: 'cv-f9', stage: 'prototype', seat: 'expert', vote: 'yes', at: _iso(68)),
        CouncilVote(id: 'cv-f10', stage: 'prototype', seat: 'official', vote: 'yes', at: _iso(68)),
        CouncilVote(id: 'cv-f11', stage: 'pilot', seat: 'reporter', vote: 'yes', at: _iso(20)),
        CouncilVote(id: 'cv-f12', stage: 'pilot', seat: 'panchayat', vote: 'yes', at: _iso(20)),
        CouncilVote(id: 'cv-f13', stage: 'pilot', seat: 'beneficiary', vote: 'yes', at: _iso(19)),
        CouncilVote(id: 'cv-f14', stage: 'pilot', seat: 'expert', vote: 'yes', at: _iso(18)),
        CouncilVote(id: 'cv-f15', stage: 'pilot', seat: 'official', vote: 'yes', at: _iso(18)),
      ],
      qrFeedback: const [],
      updates: [
        Update(id: 'u-f1', text: 'Filtration units installed at 3 hand-pump clusters.', at: _iso(45), by: 'Dr. R. Singh'),
        Update(id: 'u-f2', text: 'Deployed and awaiting final council validation.', at: _iso(9), by: 'Dr. R. Singh'),
      ],
      maintenancePlan: 'Community caretaker replaces filter media every 6 months; PHED provides annual water testing.',
      createdAt: _iso(115),
    ),
    Project(
      id: 'proj-solar-cold',
      issueId: tomatoIssue.id,
      title: 'Solar cold-storage pods, Ormanjhi',
      teamId: 'team-cold-storage',
      stage: 'piloting',
      ownerId: 'bau-ranchi',
      districtId: 'ranchi',
      budget: 890000,
      milestones: [
        Milestone(id: 'ms-c1', title: 'Design and site preparation', budget: 150000, due: _iso(60), status: 'released'),
        Milestone(id: 'ms-c2', title: 'Pod fabrication and solar install', budget: 500000, due: _iso(20), status: 'approved'),
        Milestone(
            id: 'ms-c3', title: 'Pilot operation and monitoring', budget: 240000, due: _isoFuture(20), status: 'pending'),
      ],
      pledges: [
        Pledge(
            id: 'pl-c1',
            partnerId: 'solar-epc-firm',
            type: 'equipment',
            description: 'Solar panel array and inverters',
            scope: 'project',
            status: 'released'),
        Pledge(
            id: 'pl-c2',
            partnerId: 'tata-steel-foundation',
            type: 'funding',
            amount: 300000,
            description: 'Fabrication cost support',
            scope: 'milestone',
            milestoneId: 'ms-c2',
            status: 'released'),
      ],
      documents: [
        Doc(
            id: 'doc-c-proposal',
            title: 'Innovation Twin proposal',
            kind: 'proposal',
            addedAt: _iso(65),
            url: '/images/proposal-solar-cold-storage.png'),
        Doc(
            id: 'doc-c-funds',
            title: 'Ranchi district funds allocation order',
            kind: 'funds-allocation',
            addedAt: _iso(58),
            contentHash: 'b2e5d0f3a8c1467925bb5a7d3f1c9e28a4d6b0f7e3c52819d4a6b1c7e3f5a029',
            duplicateStatus: 'unique',
            url: '/images/funds-allocation-solar-cold-storage.png'),
      ],
      risks: [Risk(id: 'risk-c1', label: 'Monsoon cloud cover may reduce solar charging', severity: 'medium')],
      pilotResults: [
        PilotMetric(id: 'pm-c1', label: 'Post-harvest loss reduction', value: 14, unit: '%', target: 20),
      ],
      councilVotes: [
        CouncilVote(id: 'cv-c1', stage: 'problem', seat: 'reporter', vote: 'yes', at: _iso(62)),
        CouncilVote(id: 'cv-c2', stage: 'problem', seat: 'panchayat', vote: 'yes', at: _iso(62)),
        CouncilVote(id: 'cv-c3', stage: 'problem', seat: 'beneficiary', vote: 'yes', at: _iso(61)),
        CouncilVote(id: 'cv-c4', stage: 'problem', seat: 'expert', vote: 'yes', at: _iso(61)),
        CouncilVote(id: 'cv-c5', stage: 'problem', seat: 'official', vote: 'yes', at: _iso(60)),
      ],
      qrFeedback: const [],
      updates: [
        Update(
            id: 'u-c1',
            text: 'Pod fabrication complete, monitoring pilot performance through monsoon.',
            at: _iso(15),
            by: 'Dr. P. Mahto'),
      ],
      maintenancePlan: 'BAU field station provides quarterly maintenance checks for the first year.',
      createdAt: _iso(65),
    ),
    Project(
      id: 'proj-lac-value',
      issueId: lacIssue.id,
      title: 'Lac value-addition unit, Khunti',
      teamId: 'team-lac',
      stage: 'building',
      ownerId: 'ilri-namkum',
      districtId: 'khunti',
      budget: 540000,
      milestones: [
        Milestone(id: 'ms-l1', title: 'Equipment procurement', budget: 200000, due: _iso(30), status: 'released'),
        Milestone(
          id: 'ms-l2',
          title: 'Processing unit construction',
          budget: 250000,
          due: _iso(2),
          status: 'submitted',
          proof: Doc(
            id: 'doc-l2',
            title: 'Construction completion photos and report',
            kind: 'proof',
            addedAt: _iso(2),
            url: '/images/milestone-report-lac-processing-unit-khunti.png',
            attachments: [
              DocAttachment(
                  id: 'doc-l2-att1',
                  title: 'Inauguration — Lac value-addition unit, Khunti',
                  url: '/images/lac-unit-inauguration-khunti.png'),
            ],
          ),
        ),
        Milestone(id: 'ms-l3', title: 'Artisan training and handover', budget: 90000, due: _isoFuture(30), status: 'pending'),
      ],
      pledges: [
        Pledge(
            id: 'pl-l1',
            partnerId: 'state-ngo',
            type: 'funding',
            amount: 200000,
            description: 'Working capital support',
            scope: 'project',
            status: 'pledged'),
      ],
      documents: [
        Doc(id: 'doc-l-proposal', title: 'Innovation Twin proposal', kind: 'proposal', addedAt: _iso(35)),
        Doc(
            id: 'doc-l-funds',
            title: 'Khunti district funds allocation order',
            kind: 'funds-allocation',
            addedAt: _iso(29),
            contentHash: 'c3f6e1a4b9d2578036cc6b8e4f2d0a39b5e7c1a8f4d63920e5b7c2d8f4a6b130',
            duplicateStatus: 'unique'),
      ],
      risks: [
        Risk(id: 'risk-l1', label: 'Milestone 2 proof pending Government approval', severity: 'low', daysLate: 0),
      ],
      pilotResults: const [],
      councilVotes: [
        CouncilVote(id: 'cv-l1', stage: 'problem', seat: 'reporter', vote: 'yes', at: _iso(32)),
        CouncilVote(id: 'cv-l2', stage: 'problem', seat: 'panchayat', vote: 'yes', at: _iso(32)),
        CouncilVote(id: 'cv-l3', stage: 'problem', seat: 'beneficiary', vote: 'yes', at: _iso(31)),
        CouncilVote(
            id: 'cv-l4',
            stage: 'problem',
            seat: 'expert',
            vote: 'partial',
            comment: 'Grading protocol needs more detail',
            at: _iso(31)),
        CouncilVote(id: 'cv-l5', stage: 'problem', seat: 'official', vote: 'yes', at: _iso(30)),
      ],
      qrFeedback: const [],
      updates: [
        Update(
            id: 'u-l1',
            text: 'Processing unit construction complete, awaiting milestone approval.',
            at: _iso(2),
            by: 'Dr. M. Kerketta'),
      ],
      maintenancePlan: 'Local artisan cooperative takes over equipment maintenance post-handover.',
      createdAt: _iso(40),
    ),
    Project(
      id: 'proj-handpump-iot',
      issueId: handpumpIssue.id,
      title: 'IoT hand-pump health monitors, Latehar',
      teamId: 'team-handpump',
      stage: 'pending-approval',
      ownerId: 'bit-mesra',
      districtId: 'latehar',
      budget: 310000,
      milestones: [
        Milestone(
            id: 'ms-h1',
            title: 'Sensor deployment across 20 hand pumps',
            budget: 180000,
            due: _isoFuture(30),
            status: 'pending'),
        Milestone(id: 'ms-h2', title: 'Dashboard and alerting rollout', budget: 130000, due: _isoFuture(60), status: 'pending'),
      ],
      pledges: const [],
      documents: [Doc(id: 'doc-h-proposal', title: 'Innovation Twin proposal', kind: 'proposal', addedAt: _iso(4))],
      risks: const [],
      pilotResults: const [],
      councilVotes: const [],
      qrFeedback: const [],
      updates: [
        Update(id: 'u-h1', text: 'Team submitted proposal, awaiting Government approval.', at: _iso(4), by: 'Dr. N. Verma'),
      ],
      maintenancePlan: 'BIT Mesra IoT lab provides remote monitoring; local mechanic handles physical repairs.',
      createdAt: _iso(4),
    ),
    Project(
      id: 'proj-solar-irrigation-failed',
      issueId: solarIrrigationFailedIssue.id,
      title: 'Solar irrigation pump, Gumla',
      teamId: 'team-solar-irrigation',
      stage: 'failed',
      ownerId: 'nit-jamshedpur',
      districtId: 'gumla',
      budget: 275000,
      milestones: [Milestone(id: 'ms-s1', title: 'Pump installation', budget: 275000, due: _iso(310), status: 'released')],
      pledges: [
        Pledge(
            id: 'pl-s1',
            partnerId: 'solar-epc-firm',
            type: 'equipment',
            description: 'Solar pump hardware',
            scope: 'project',
            status: 'released'),
      ],
      documents: [
        Doc(id: 'doc-s-proposal', title: 'Innovation Twin proposal', kind: 'proposal', addedAt: _iso(320)),
        Doc(
            id: 'doc-s-funds',
            title: 'Gumla district funds allocation order',
            kind: 'funds-allocation',
            addedAt: _iso(312),
            contentHash: 'd4a7f2b5c0e3689147dd7c9f5a3e1b40c6f8d2b9a5e74031f6c8d3e9a5b7c241',
            duplicateStatus: 'unique'),
      ],
      risks: [Risk(id: 'risk-s1', label: 'No local maintenance capacity budgeted', severity: 'high')],
      pilotResults: [PilotMetric(id: 'pm-s1', label: 'Uptime after month 6', value: 0, unit: '%')],
      councilVotes: const [],
      qrFeedback: [
        QRFeedback(
            id: 'qr-s1',
            outcome: 'not-working',
            note: 'Pump stopped working, no one available to repair it',
            at: _iso(180)),
      ],
      updates: [
        Update(id: 'u-s1', text: 'Marked failed after 6 months of non-operation.', at: _iso(175), by: 'Dr. K. Oraon'),
      ],
      maintenancePlan: 'None budgeted — identified as the root cause of failure.',
      createdAt: _iso(320),
    ),
    Project(
      id: 'proj-rainwater',
      issueId: firstIssue.id,
      title: 'Rainwater-harvesting retrofit, Ranchi',
      teamId: 'team-rainwater',
      stage: 'scaled',
      ownerId: 'bit-mesra',
      districtId: 'ranchi',
      budget: 480000,
      milestones: [
        Milestone(id: 'ms-r1', title: 'Rooftop retrofit, pilot ward', budget: 480000, due: _iso(400), status: 'released'),
      ],
      pledges: [
        Pledge(
            id: 'pl-r1',
            partnerId: 'ccl-csr',
            type: 'funding',
            amount: 480000,
            description: 'Full project funding',
            scope: 'project',
            status: 'released'),
      ],
      documents: [
        Doc(id: 'doc-r-proposal', title: 'Innovation Twin proposal', kind: 'proposal', addedAt: _iso(410)),
        Doc(
            id: 'doc-r-funds',
            title: 'Ranchi district funds allocation order',
            kind: 'funds-allocation',
            addedAt: _iso(403),
            contentHash: 'e5b8a3c6d1f4790258ee8dae6b4f2c51d7a9e3c0b6f85142a7d9e4f0b6c8d352',
            duplicateStatus: 'unique'),
      ],
      risks: const [],
      pilotResults: [PilotMetric(id: 'pm-r1', label: 'Groundwater recharge improvement', value: 22, unit: '%')],
      councilVotes: [
        CouncilVote(id: 'cv-r1', stage: 'final', seat: 'reporter', vote: 'yes', at: _iso(200)),
        CouncilVote(id: 'cv-r2', stage: 'final', seat: 'panchayat', vote: 'yes', at: _iso(200)),
        CouncilVote(id: 'cv-r3', stage: 'final', seat: 'beneficiary', vote: 'yes', at: _iso(199)),
        CouncilVote(id: 'cv-r4', stage: 'final', seat: 'expert', vote: 'yes', at: _iso(199)),
        CouncilVote(id: 'cv-r5', stage: 'final', seat: 'official', vote: 'yes', at: _iso(198)),
      ],
      qrFeedback: [
        QRFeedback(id: 'qr-r1', outcome: 'works', at: _iso(150)),
        QRFeedback(id: 'qr-r2', outcome: 'works', at: _iso(120)),
      ],
      updates: [
        Update(id: 'u-r1', text: 'Community validated as final deployment.', at: _iso(198), by: 'Dr. A. Kumari'),
        Update(id: 'u-r2', text: 'Replicated to Hazaribagh, Giridih and Dumka.', at: _iso(90), by: 'Dr. A. Kumari'),
      ],
      maintenancePlan: 'Ward water committee inspects catchment and diverter before each monsoon.',
      createdAt: _iso(420),
    ),
    Project(
      id: 'proj-forest-produce',
      issueId: forestProduceIssue.id,
      title: 'Forest-produce grading and value-addition unit, Bhawnathpur',
      teamId: 'team-forest-produce',
      stage: 'team-forming',
      ownerId: 'nit-jamshedpur',
      districtId: 'east-singhbhum',
      budget: 260000,
      milestones: [
        Milestone(
            id: 'ms-fp1',
            title: 'Grading protocol design and collector survey',
            budget: 60000,
            due: _isoFuture(20),
            status: 'pending'),
        Milestone(id: 'ms-fp2', title: 'Grading station construction', budget: 140000, due: _isoFuture(60), status: 'pending'),
        Milestone(
            id: 'ms-fp3', title: 'Collector training and handover', budget: 60000, due: _isoFuture(90), status: 'pending'),
      ],
      pledges: const [],
      documents: [Doc(id: 'doc-fp-proposal', title: 'Innovation Twin proposal', kind: 'proposal', addedAt: _iso(3))],
      risks: const [],
      pilotResults: const [],
      councilVotes: const [],
      qrFeedback: const [],
      updates: [Update(id: 'u-fp1', text: 'Institution matched, team still forming.', at: _iso(3), by: 'Dr. B. Hembrom')],
      maintenancePlan: 'Forest-produce collector cooperative to take over grading station operations post-handover.',
      createdAt: _iso(3),
    ),
    Project(
      id: 'proj-health-camp',
      issueId: healthCampIssue.id,
      title: 'Mobile health-camp scheduling for mining-affected wards, Ghatshila',
      teamId: 'team-health-camp',
      stage: 'community-validated',
      ownerId: 'vbu-hazaribagh',
      districtId: 'hazaribagh',
      budget: 150000,
      milestones: [
        Milestone(id: 'ms-hc1', title: 'ASHA dashboard and SMS scheduler build', budget: 90000, due: _iso(60), status: 'released'),
        Milestone(id: 'ms-hc2', title: 'Pilot rollout across 5 wards', budget: 60000, due: _iso(15), status: 'released'),
      ],
      pledges: [
        Pledge(
            id: 'pl-hc1',
            partnerId: 'sail-bokaro-csr',
            type: 'funding',
            amount: 150000,
            description: 'Full project funding',
            scope: 'project',
            status: 'released'),
      ],
      documents: [
        Doc(id: 'doc-hc-proposal', title: 'Innovation Twin proposal', kind: 'proposal', addedAt: _iso(70)),
        Doc(
            id: 'doc-hc-funds',
            title: 'Hazaribagh district funds allocation order',
            kind: 'funds-allocation',
            addedAt: _iso(63),
            contentHash: 'f6c9b4d7e2a5891369ff9ebf7c5a3d62e8b0f4d1c7a96253b8e0f5a1c7d9e463',
            duplicateStatus: 'unique'),
      ],
      risks: const [],
      pilotResults: [PilotMetric(id: 'pm-hc1', label: 'Health-camp attendance', value: 41, unit: '%', target: 30)],
      councilVotes: [
        CouncilVote(id: 'cv-hc1', stage: 'final', seat: 'reporter', vote: 'yes', at: _iso(12)),
        CouncilVote(id: 'cv-hc2', stage: 'final', seat: 'panchayat', vote: 'yes', at: _iso(12)),
        CouncilVote(id: 'cv-hc3', stage: 'final', seat: 'beneficiary', vote: 'yes', at: _iso(11)),
        CouncilVote(
            id: 'cv-hc4',
            stage: 'final',
            seat: 'expert',
            vote: 'partial',
            comment: 'SMS reach still limited on feature phones',
            at: _iso(11)),
        CouncilVote(id: 'cv-hc5', stage: 'final', seat: 'official', vote: 'yes', at: _iso(10)),
      ],
      qrFeedback: [QRFeedback(id: 'qr-hc1', outcome: 'works', at: _iso(9))],
      updates: [
        Update(
            id: 'u-hc1',
            text: 'Community validated after pilot rollout across 5 wards.',
            at: _iso(10),
            by: 'Dr. F. Ansari'),
      ],
      maintenancePlan: 'District health office takes over SMS scheduling costs after year one.',
      createdAt: _iso(75),
    ),
    Project(
      id: 'proj-wildlife-fence-2',
      issueId: wildlifeFenceIssue.id,
      title: 'Solar deterrent fencing pilot, Bundu (Palamu)',
      teamId: 'team-wildlife-fence',
      stage: 'piloting',
      ownerId: 'kolhan-university',
      districtId: 'palamu',
      budget: 380000,
      milestones: [
        Milestone(
            id: 'ms-wf1',
            title: 'Fence line survey and community patrol plan',
            budget: 80000,
            due: _iso(40),
            status: 'released'),
        Milestone(id: 'ms-wf2', title: 'Fence energiser installation', budget: 220000, due: _iso(10), status: 'approved'),
        Milestone(id: 'ms-wf3', title: 'Pilot monitoring season', budget: 80000, due: _isoFuture(45), status: 'pending'),
      ],
      pledges: [
        Pledge(
            id: 'pl-wf1',
            partnerId: 'tata-steel-foundation',
            type: 'funding',
            amount: 380000,
            description: 'Full project funding',
            scope: 'project',
            status: 'released'),
      ],
      documents: [
        Doc(id: 'doc-wf-proposal', title: 'Innovation Twin proposal', kind: 'proposal', addedAt: _iso(45)),
        Doc(
            id: 'doc-wf-funds',
            title: 'Palamu district funds allocation order',
            kind: 'funds-allocation',
            addedAt: _iso(38),
            contentHash: 'a7d0c5e8f3b6902470aa0fca8d6b4e73f9c1a5e2d8b07364c9f1a6b2d8e0f574',
            duplicateStatus: 'unique'),
      ],
      risks: [Risk(id: 'risk-wf1', label: 'Community patrol rota not yet finalised', severity: 'medium')],
      pilotResults: [PilotMetric(id: 'pm-wf1', label: 'Crop-raiding incidents', value: 3, unit: 'per month', target: 1)],
      councilVotes: [
        CouncilVote(id: 'cv-wf1', stage: 'prototype', seat: 'reporter', vote: 'yes', at: _iso(20)),
        CouncilVote(id: 'cv-wf2', stage: 'prototype', seat: 'panchayat', vote: 'yes', at: _iso(20)),
        CouncilVote(id: 'cv-wf3', stage: 'prototype', seat: 'beneficiary', vote: 'yes', at: _iso(19)),
      ],
      qrFeedback: const [],
      updates: [
        Update(
            id: 'u-wf1',
            text: 'Fence energiser installed, monitoring incidents through the pilot season.',
            at: _iso(10),
            by: 'Dr. J. Munda'),
      ],
      maintenancePlan:
          'Village patrol committee inspects fence line weekly; Kolhan University replaces energiser batteries annually.',
      createdAt: _iso(50),
    ),
    Project(
      id: 'proj-irrigation',
      issueId: irrigationIssue.id,
      title: 'Solar micro-irrigation retrofit, Devipur (Lohardaga)',
      teamId: 'team-irrigation',
      stage: 'building',
      ownerId: 'npu-medininagar',
      districtId: 'lohardaga',
      budget: 300000,
      milestones: [
        Milestone(id: 'ms-ir1', title: 'Field survey and pump sizing', budget: 60000, due: _iso(25), status: 'released'),
        Milestone(
            id: 'ms-ir2',
            title: 'Solar pump and drip-line installation',
            budget: 180000,
            due: _isoFuture(15),
            status: 'pending'),
        Milestone(id: 'ms-ir3', title: 'Farmer training and handover', budget: 60000, due: _isoFuture(45), status: 'pending'),
      ],
      pledges: [
        Pledge(
            id: 'pl-ir1',
            partnerId: 'solar-epc-firm',
            type: 'equipment',
            description: 'Solar pump and drip-line hardware',
            scope: 'project',
            status: 'pledged'),
      ],
      documents: [
        Doc(id: 'doc-ir-proposal', title: 'Innovation Twin proposal', kind: 'proposal', addedAt: _iso(28)),
        Doc(
            id: 'doc-ir-funds',
            title: 'Lohardaga district funds allocation order',
            kind: 'funds-allocation',
            addedAt: _iso(22),
            contentHash: 'b8e1d6f9a4c703581bb1f0adb9e7c584f0d2b6e3f9c18475d0a2b7c3e9f1a685',
            duplicateStatus: 'unique'),
      ],
      risks: [
        Risk(id: 'risk-ir1', label: 'Local mechanic not yet identified for post-handover repairs', severity: 'high'),
      ],
      pilotResults: const [],
      councilVotes: [
        CouncilVote(id: 'cv-ir1', stage: 'problem', seat: 'reporter', vote: 'yes', at: _iso(30)),
        CouncilVote(id: 'cv-ir2', stage: 'problem', seat: 'panchayat', vote: 'yes', at: _iso(30)),
        CouncilVote(id: 'cv-ir3', stage: 'problem', seat: 'official', vote: 'yes', at: _iso(29)),
      ],
      qrFeedback: const [],
      updates: [
        Update(
            id: 'u-ir1',
            text: 'Field survey complete, procuring pump and drip-line hardware.',
            at: _iso(25),
            by: 'Dr. S. Bhagat'),
      ],
      maintenancePlan: 'Local mechanic to be identified and trained before handover — currently the top project risk.',
      createdAt: _iso(30),
    ),
  ];
}

final List<Project> seedProjects = _buildProjects();

String _formatINR(num n) {
  final s = n.round().toString();
  final parts = <String>[];
  if (s.length > 3) {
    parts.add(s.substring(s.length - 3));
    var rest = s.substring(0, s.length - 3);
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
  } else {
    parts.add(s);
  }
  return '₹${parts.join(',')}';
}

// Each project's own real history (proposal, milestone approvals, council votes, funds orders)
// re-expressed as audit entries targeting that project — otherwise every project's Audit tab is
// permanently empty, since the generic misc.ts seed audit log never targets real project ids.
int _auditCounter = 0;
String _auditId() => 'audit-proj-${_auditCounter++}';

List<AuditEntry> _buildProjectAuditLog() {
  final out = <AuditEntry>[];
  for (final p in seedProjects) {
    final team = seedTeams.where((t) => t.id == p.teamId);
    final teamLead = team.isNotEmpty && team.first.memberIds.isNotEmpty ? team.first.memberIds[0] : 'Institution lead';
    final entries = <AuditEntry>[
      AuditEntry(
          id: _auditId(),
          actor: teamLead,
          role: 'university',
          action: 'Submitted Innovation Twin proposal',
          target: p.id,
          at: p.createdAt),
    ];

    for (final m in p.milestones) {
      if (m.status == 'submitted' || m.status == 'approved' || m.status == 'released') {
        entries.add(AuditEntry(
            id: _auditId(),
            actor: teamLead,
            role: 'university',
            action: 'Submitted milestone proof',
            target: p.id,
            detail: m.title,
            at: m.due));
      }
      if (m.status == 'approved' || m.status == 'released') {
        entries.add(AuditEntry(
          id: _auditId(),
          actor: 'Control Room Officer',
          role: 'government',
          action: m.status == 'released' ? 'Approved milestone and released funds' : 'Approved milestone',
          target: p.id,
          detail: '${m.title} · ${_formatINR(m.budget)}',
          at: m.due,
        ));
      }
    }

    for (final v in p.councilVotes) {
      entries.add(AuditEntry(
        id: _auditId(),
        actor: '${v.seat} seat',
        role: 'council',
        action: 'Cast ${v.vote} vote (${v.seat} seat, ${v.stage} stage)',
        target: p.id,
        detail: v.comment,
        at: v.at,
      ));
    }

    for (final d in p.documents) {
      if (d.kind == 'funds-allocation') {
        entries.add(AuditEntry(
            id: _auditId(),
            actor: 'District Treasury Officer',
            role: 'government',
            action: 'Uploaded funds allocation order',
            target: p.id,
            detail: d.title,
            at: d.addedAt));
      }
    }

    entries.sort((a, b) => DateTime.parse(a.at).compareTo(DateTime.parse(b.at)));
    out.addAll(entries);
  }
  return out;
}

final List<AuditEntry> seedProjectAuditLog = _buildProjectAuditLog();
