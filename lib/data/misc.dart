// Ported 1:1 from src/data/misc.ts
import '../models/types.dart';
import 'reports.dart' as reports_data;

String _iso(int daysAgo) => reports_data.NOW.subtract(Duration(days: daysAgo)).toUtc().toIso8601String();

List<SystemicChallenge> _buildSystemicChallenges() {
  final fluorideIssue = reports_data.seedMasterIssues.firstWhere((i) => i.title.contains('Fluoride'));
  final floodingIssues = reports_data.seedMasterIssues
      .where((i) => i.category == 'flooding-roads' && ['dhanbad', 'hazaribagh', 'pakur'].contains(i.districtId))
      .toList();
  final forestProduceIssues = reports_data.seedMasterIssues
      .where((i) =>
          i.category == 'livelihood-forest-produce' && ['khunti', 'east-singhbhum', 'dumka'].contains(i.districtId))
      .toList();
  final wildlifeIssues = reports_data.seedMasterIssues.where((i) => i.category == 'wildlife-conflict').toList();

  return [
    SystemicChallenge(
      id: 'sys-fluoride',
      title: 'Fluoride contamination across the Palamu belt',
      rootCause: 'Geogenic fluoride in groundwater, no filtration at hand-pump level',
      issueIds: [fluorideIssue.id],
      districtIds: const ['palamu', 'garhwa', 'latehar'],
      promoted: true,
    ),
    SystemicChallenge(
      id: 'sys-monsoon-roads',
      title: 'Monsoon culverts fail across coalfield districts',
      rootCause: 'Undersized culverts built before rainfall-intensity data was available',
      issueIds: floodingIssues.map((i) => i.id).toList(),
      districtIds: const ['dhanbad', 'hazaribagh', 'pakur'],
      promoted: false,
    ),
    SystemicChallenge(
      id: 'sys-lac-value',
      title: 'Forest-produce collectors sell raw, lose margin to middlemen',
      rootCause: 'No local processing or grading infrastructure',
      issueIds: forestProduceIssues.map((i) => i.id).toList(),
      districtIds: const ['khunti', 'east-singhbhum', 'dumka'],
      promoted: false,
    ),
    SystemicChallenge(
      id: 'sys-wildlife-corridor',
      title: 'Elephant corridors cut through farmland at the forest edge',
      rootCause: 'No coordinated deterrent infrastructure or patrol scheduling across the corridor',
      issueIds: wildlifeIssues.map((i) => i.id).toList(),
      districtIds: {for (final i in wildlifeIssues) i.districtId}.toList(),
      promoted: true,
    ),
  ];
}

final List<SystemicChallenge> seedSystemicChallenges = _buildSystemicChallenges();

final List<SolutionMemoryEntry> seedSolutionMemory = [
  SolutionMemoryEntry(
    id: 'sme-1',
    projectId: 'proj-rainwater',
    category: 'water-scarcity',
    title: 'Rainwater-harvesting rooftop retrofit',
    districtId: 'ranchi',
    components: ['rooftop catchment', 'first-flush diverter', 'storage tank', 'recharge pit'],
    cost: 480000,
    pilotResult: 'Groundwater recharge improved by 22% in pilot wards',
    lessons: ['Use first-flush diverters to avoid contaminating stored water'],
    researchers: ['Dr. A. Kumari', 'Dr. S. Toppo'],
    institutionId: 'bit-mesra',
  ),
  SolutionMemoryEntry(
    id: 'sme-2',
    projectId: 'proj-fluoride',
    category: 'water-quality',
    title: 'Community fluoride filtration units',
    districtId: 'palamu',
    components: ['activated alumina filter', 'community tank', 'testing kit'],
    cost: 620000,
    pilotResult: 'Fluoride reduced from 4.2 to 0.8 mg/L in pilot village',
    lessons: [
      'Filter media needs replacement every 6 months',
      'Community caretaker model works better than department maintenance',
    ],
    researchers: ['Dr. R. Singh'],
    institutionId: 'jharkhand-water-lab',
  ),
  SolutionMemoryEntry(
    id: 'sme-3',
    projectId: 'proj-solar-cold',
    category: 'agri-postharvest',
    title: 'Solar cold-storage pods',
    districtId: 'ranchi',
    components: ['solar panel array', 'insulated pod', 'battery backup'],
    cost: 890000,
    pilotResult: 'Post-harvest loss reduced from 30% to 11%',
    lessons: ['Battery sizing must account for monsoon cloud cover'],
    researchers: ['Dr. P. Mahto'],
    institutionId: 'bau-ranchi',
  ),
  SolutionMemoryEntry(
    id: 'sme-4',
    projectId: 'proj-lac-value',
    category: 'livelihood-forest-produce',
    title: 'Lac value-addition processing unit',
    districtId: 'khunti',
    components: ['lac refining unit', 'grading station', 'packaging line'],
    cost: 540000,
    pilotResult: 'Collector margins rose by 35%',
    lessons: ['Grading standards need periodic recalibration'],
    researchers: ['Dr. M. Kerketta'],
    institutionId: 'ilri-namkum',
  ),
  SolutionMemoryEntry(
    id: 'sme-5',
    projectId: 'proj-handpump-iot',
    category: 'water-scarcity',
    title: 'IoT hand-pump health monitors',
    districtId: 'latehar',
    components: ['vibration sensor', 'LoRa gateway', 'dashboard'],
    cost: 310000,
    pilotResult: 'Repair response time cut from 21 to 4 days',
    lessons: ['LoRa range drops significantly in dense forest terrain'],
    researchers: ['Dr. N. Verma'],
    institutionId: 'bit-mesra',
  ),
  SolutionMemoryEntry(
    id: 'sme-6',
    projectId: 'proj-solar-irrigation-failed',
    category: 'agri-irrigation',
    title: 'Solar irrigation pump (failed pilot)',
    districtId: 'gumla',
    components: ['solar pump', 'drip line'],
    cost: 275000,
    pilotResult: 'Pump failed after 6 months, no local maintenance capacity',
    lessons: ['Always pair hardware deployment with a trained local mechanic'],
    researchers: ['Dr. K. Oraon'],
    institutionId: 'nit-jamshedpur',
  ),
  SolutionMemoryEntry(
    id: 'sme-7',
    projectId: 'proj-anganwadi-solar',
    category: 'education-access',
    title: 'Solar-powered anganwadi retrofit',
    districtId: 'pakur',
    components: ['solar panel', 'battery', 'LED lighting kit'],
    cost: 95000,
    pilotResult: 'Extended usable hours by 3 per day',
    lessons: ['Panel angle needs seasonal adjustment for monsoon cloud cover'],
    researchers: ['Dr. S. Hansda'],
    institutionId: 'skmu-dumka',
  ),
  SolutionMemoryEntry(
    id: 'sme-8',
    projectId: 'proj-wildlife-fence',
    category: 'wildlife-conflict',
    title: 'Solar-powered elephant deterrent fencing',
    districtId: 'west-singhbhum',
    components: ['solar fence energiser', 'early-warning sensors'],
    cost: 410000,
    pilotResult: 'Crop-raiding incidents dropped 60% in pilot village',
    lessons: ['Community patrol coordination matters as much as the fence itself'],
    researchers: ['Dr. J. Munda'],
    institutionId: 'bau-ranchi',
  ),
  SolutionMemoryEntry(
    id: 'sme-9',
    projectId: 'proj-water-quality-sensor',
    category: 'water-quality',
    title: 'Low-cost water-quality sensing kiosk',
    districtId: 'bokaro',
    components: ['multi-parameter sensor', 'public display'],
    cost: 220000,
    pilotResult: 'Enabled daily public reporting of pond water quality',
    lessons: ['Sensor calibration drifts; needs monthly field checks'],
    researchers: ['Dr. A. Ghosh'],
    institutionId: 'ism-dhanbad',
  ),
  SolutionMemoryEntry(
    id: 'sme-10',
    projectId: 'proj-culvert-retrofit',
    category: 'flooding-roads',
    title: 'Culvert capacity retrofit using rainfall-intensity data',
    districtId: 'dhanbad',
    components: ['widened culvert', 'debris screen', 'early-warning gauge'],
    cost: 730000,
    pilotResult: 'Village access maintained through full monsoon season',
    lessons: ['Debris screens need pre-monsoon clearing schedule'],
    researchers: ['Dr. T. Mahato'],
    institutionId: 'ism-dhanbad',
  ),
  SolutionMemoryEntry(
    id: 'sme-11',
    projectId: 'proj-sanitation-biodigester',
    category: 'sanitation',
    title: 'Community biodigester toilet blocks',
    districtId: 'giridih',
    components: ['biodigester tank', 'community toilet block'],
    cost: 380000,
    pilotResult: 'Open defecation incidents dropped to near zero in pilot hamlet',
    lessons: ['Desludging schedule must be set before commissioning'],
    researchers: ['Dr. R. Das'],
    institutionId: 'vbu-hazaribagh',
  ),
  SolutionMemoryEntry(
    id: 'sme-12',
    projectId: 'proj-health-camp-app',
    category: 'health-environment',
    title: 'Mobile health-camp scheduling tool for mining-affected wards',
    districtId: 'bokaro',
    components: ['SMS scheduling', 'ASHA dashboard'],
    cost: 140000,
    pilotResult: 'Camp attendance rose 40%',
    lessons: ['SMS reminders in local language doubled response rate'],
    researchers: ['Dr. F. Ansari'],
    institutionId: 'cuj-brambe',
  ),
];

final List<FailureLesson> seedFailureLessons = [
  FailureLesson(
    id: 'fl-1',
    projectId: 'proj-solar-irrigation-failed',
    category: 'agri-irrigation',
    type: 'maintenance',
    lesson: 'Solar irrigation pump in Gumla failed after 6 months with no local repair capacity.',
    designWarning:
        'Pair any solar-pump deployment with a trained local mechanic and a spare-parts stock, not just the hardware.',
  ),
  FailureLesson(
    id: 'fl-2',
    projectId: 'proj-solar-irrigation-failed',
    category: 'agri-irrigation',
    type: 'cost',
    lesson: 'Battery replacement cost was not budgeted, so the pump was abandoned rather than repaired.',
    designWarning: 'Include a 3-year consumables budget line (battery, filters) in every solar hardware proposal.',
  ),
  FailureLesson(
    id: 'fl-3',
    category: 'wildlife-conflict',
    type: 'community',
    lesson: 'An earlier fencing pilot in Saraikela failed because the community was not involved in patrol scheduling.',
    designWarning: 'Co-design patrol and maintenance schedules with the affected village before deployment, not after.',
  ),
  FailureLesson(
    id: 'fl-4',
    category: 'water-quality',
    type: 'maintenance',
    lesson: 'Filter media in an unnamed pilot clogged within 3 months due to high turbidity, with no cleaning protocol.',
    designWarning: 'Specify a filter-cleaning and media-replacement protocol as a deliverable, not an afterthought.',
  ),
  FailureLesson(
    id: 'fl-5',
    category: 'agri-postharvest',
    type: 'technical',
    lesson: 'A cold-storage prototype under-performed in high-humidity months.',
    designWarning: 'Size dehumidification capacity for monsoon-month humidity, not annual average.',
  ),
  FailureLesson(
    id: 'fl-6',
    category: 'sanitation',
    type: 'community',
    lesson: 'A toilet-block pilot saw low usage because desludging fees were unclear upfront.',
    designWarning: 'Publish the desludging fee and schedule to the community before construction begins.',
  ),
  FailureLesson(
    id: 'fl-7',
    category: 'power-lighting',
    type: 'technical',
    lesson: 'Solar streetlights in one pilot dimmed rapidly due to undersized batteries.',
    designWarning: 'Size battery capacity for 3 cloudy days in a row, not a single-day average.',
  ),
  FailureLesson(
    id: 'fl-8',
    category: 'livelihood-forest-produce',
    type: 'cost',
    lesson: 'A lac processing pilot elsewhere over-ran budget due to underestimated transport costs.',
    designWarning: 'Add a 15% contingency line for transport in remote-district livelihood projects.',
  ),
];

final List<CapabilityGap> seedCapabilityGaps = [
  CapabilityGap(
    id: 'cg-1',
    kind: 'equipment',
    label: 'Thermal-imaging camera for night-time elephant tracking',
    districtIds: ['saraikela-kharsawan'],
    published: false,
  ),
  CapabilityGap(
    id: 'cg-2',
    kind: 'expert',
    label: 'Hydrogeologist for fluoride-belt groundwater mapping',
    districtIds: ['palamu', 'garhwa'],
    published: true,
  ),
  CapabilityGap(
    id: 'cg-3',
    kind: 'lab',
    label: 'Certified metallurgy testing lab access in Kolhan region',
    districtIds: ['west-singhbhum'],
    published: true,
  ),
  CapabilityGap(
    id: 'cg-4',
    kind: 'expert',
    label: 'Agronomist for forest-produce grading standards',
    districtIds: ['east-singhbhum', 'khunti'],
    published: true,
    filledBy: 'Vikas Sahyog Samiti (NGO)',
  ),
  CapabilityGap(
    id: 'cg-5',
    kind: 'capacity',
    label: 'Field surveyors for door-to-door household surveys, Palamu belt',
    districtIds: ['palamu', 'garhwa', 'latehar'],
    published: false,
  ),
  CapabilityGap(
    id: 'cg-6',
    kind: 'equipment',
    label: 'Portable water-testing kits for remote hand-pump clusters',
    districtIds: ['gumla', 'simdega'],
    published: true,
  ),
  CapabilityGap(
    id: 'cg-7',
    kind: 'lab',
    label: 'Soil-testing lab access for irrigation retrofit projects',
    districtIds: ['lohardaga'],
    published: false,
  ),
  CapabilityGap(
    id: 'cg-8',
    kind: 'expert',
    label: 'Public-health specialist for mining-belt health camps',
    districtIds: ['bokaro', 'hazaribagh'],
    published: true,
    filledBy: 'SAIL Bokaro CSR',
  ),
];

final List<OutreachTask> seedOutreachTasks = [
  OutreachTask(id: 'out-1', districtId: 'simdega', institutionId: 'kolhan-university', status: 'assigned'),
  OutreachTask(id: 'out-2', districtId: 'pakur', institutionId: 'skmu-dumka', status: 'assigned'),
  OutreachTask(id: 'out-3', districtId: 'godda', institutionId: 'skmu-dumka', status: 'assigned'),
  OutreachTask(id: 'out-4', districtId: 'chatra', institutionId: 'vbu-hazaribagh', status: 'completed'),
  OutreachTask(id: 'out-5', districtId: 'sahibganj', institutionId: 'skmu-dumka', status: 'assigned'),
];

List<SocialPost> _buildSocialPosts() => [
      SocialPost(
        id: 'sp-1',
        platform: 'x',
        author: '@RanchiRoadsWatch',
        verified: true,
        text:
            "Culvert near Baliapur, Dhanbad completely submerged again this monsoon. Kids can't reach school. #JharkhandRoads",
        districtId: 'dhanbad',
        category: 'flooding-roads',
        lat: 23.69,
        lng: 86.55,
        at: _iso(29),
      ),
      SocialPost(
        id: 'sp-2',
        platform: 'instagram',
        author: 'jharkhand.voices',
        verified: true,
        text: 'Anganwadi in Litipara, Pakur still running without power. Kids study by window light.',
        districtId: 'pakur',
        category: 'education-access',
        lat: 24.55,
        lng: 87.60,
        at: _iso(19),
      ),
      SocialPost(
        id: 'sp-3',
        platform: 'telegram',
        author: 'Khunti Farmers Group',
        verified: false,
        text: 'Lac prices crashed again, no local buyer this season.',
        districtId: 'khunti',
        category: 'livelihood-forest-produce',
        lat: 23.02,
        lng: 85.24,
        at: _iso(48),
      ),
      SocialPost(
        id: 'sp-4',
        platform: 'x',
        author: '@BokaroEnviro',
        verified: true,
        text: 'Pond near Chandankiyari mining belt is black with coal dust runoff. Health risk for kids swimming there.',
        districtId: 'bokaro',
        category: 'health-environment',
        lat: 23.55,
        lng: 86.30,
        at: _iso(54),
      ),
      SocialPost(
        id: 'sp-5',
        platform: 'x',
        author: '@localnews_jh',
        verified: false,
        text: 'Hand pumps in Latehar villages non-functional for weeks, third time this year.',
        districtId: 'latehar',
        category: 'water-scarcity',
        lat: 23.76,
        lng: 84.51,
        at: _iso(77),
      ),
      SocialPost(
        id: 'sp-6',
        platform: 'instagram',
        author: 'gumla.ground.report',
        verified: true,
        text: 'Solar pump installed last year in Ghaghra sitting idle, no one to repair it.',
        districtId: 'gumla',
        category: 'agri-irrigation',
        lat: 23.15,
        lng: 84.60,
        at: _iso(200),
      ),
      SocialPost(
        id: 'sp-7',
        platform: 'telegram',
        author: 'Simdega Update Channel',
        verified: false,
        text: 'Artisans here selling raw lac at throwaway prices again.',
        districtId: 'simdega',
        category: 'livelihood-forest-produce',
        lat: 22.63,
        lng: 84.52,
        at: _iso(44),
      ),
      SocialPost(
        id: 'sp-8',
        platform: 'x',
        author: '@DhanbadDaily',
        verified: true,
        text: 'Water testing report leaked shows high fluoride near Badih, Palamu — residents demand action.',
        districtId: 'palamu',
        category: 'water-quality',
        lat: 24.01,
        lng: 84.05,
        at: _iso(41),
      ),
      SocialPost(
        id: 'sp-9',
        platform: 'instagram',
        author: 'westsinghbhum.watch',
        verified: false,
        text: 'Elephant herd damaged three more acres of paddy near forest edge this week.',
        districtId: 'west-singhbhum',
        category: 'wildlife-conflict',
        lat: 22.50,
        lng: 85.75,
        at: _iso(15),
      ),
      SocialPost(
        id: 'sp-10',
        platform: 'x',
        author: '@SaraikelaNews',
        verified: true,
        text: 'Villagers near forest edge in Saraikela-Kharsawan report nightly elephant raids on paddy fields, appeal for help.',
        districtId: 'saraikela-kharsawan',
        category: 'wildlife-conflict',
        lat: 22.68,
        lng: 85.90,
        at: _iso(3),
      ),
      SocialPost(
        id: 'sp-11',
        platform: 'facebook',
        author: 'Ranchi Citizens Forum',
        verified: true,
        text: 'Open defecation still an issue in outskirts of Ranchi — toilets built under the scheme are locked and unused.',
        districtId: 'ranchi',
        category: 'sanitation',
        lat: 23.30,
        lng: 85.28,
        at: _iso(9),
      ),
      SocialPost(
        id: 'sp-12',
        platform: 'facebook',
        author: 'Hazaribagh Community Page',
        verified: false,
        text: 'Streetlights on the main Hazaribagh–Barhi road have been dark for a month, unsafe for evening commuters.',
        districtId: 'hazaribagh',
        category: 'power-lighting',
        lat: 23.99,
        lng: 85.36,
        at: _iso(6),
      ),
    ];

final List<SocialPost> seedSocialPosts = _buildSocialPosts();

List<AuditEntry> _buildAuditEntries() {
  const actors = [
    'Control Room Officer R. Verma',
    'Control Room Officer S. Iqbal',
    'Dr. A. Kumari (BIT Mesra)',
    'District Nodal Officer',
  ];
  const roles = ['government', 'government', 'university', 'government'];
  const actions = ['Validated issue', 'Merged duplicate reports', 'Routed to department', 'Approved milestone'];
  return List.generate(
    40,
    (i) => AuditEntry(
      id: 'audit-seed-$i',
      actor: actors[i % 4],
      role: roles[i % 4],
      action: actions[i % 4],
      target: 'issue-$i',
      at: _iso(150 - i * 3),
    ),
  );
}

final List<AuditEntry> seedAuditEntries = _buildAuditEntries();

List<AppNotification> _buildNotifications() {
  const roles = ['citizen', 'government', 'university', 'industry', 'council'];
  const texts = [
    'Your report has been merged into an existing case.',
    'New case awaiting validation in your district.',
    'A challenge matching your capabilities was routed to you.',
    'A capability gap was published for your review.',
    'A project has reached the Council review stage.',
  ];
  return List.generate(
    20,
    (i) => AppNotification(
      id: 'notif-seed-$i',
      toRole: roles[i % 5],
      text: texts[i % 5],
      at: _iso(60 - i * 2),
      read: i > 4,
    ),
  );
}

final List<AppNotification> seedNotifications = _buildNotifications();
