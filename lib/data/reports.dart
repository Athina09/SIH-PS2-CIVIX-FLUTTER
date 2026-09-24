// Ported 1:1 from src/data/reports.ts
import '../models/types.dart';
import 'districts.dart' as districts_data;

final DateTime NOW = DateTime.parse('2026-09-21T09:00:00+05:30');
String _iso(int daysAgo) => NOW.subtract(Duration(days: daysAgo)).toUtc().toIso8601String();

int _uid = 0;
String _nid(String prefix) => '$prefix-${(_uid++).toRadixString(36)}';

Evidence _evid(String kind, String label, String addedBy, int daysAgo, [String? url]) {
  return Evidence(id: _nid('ev'), kind: kind, label: label, addedBy: addedBy, addedAt: _iso(daysAgo), url: url);
}

class _ReportSeed {
  final Channel channel;
  final String language;
  final Category category;
  final String districtId;
  final String village;
  final double lat;
  final double lng;
  final int urgencyHint;
  final String affectedGroup;
  final int? households;
  final List<Evidence> evidence;
  final String reporterId;
  final String reporterName;
  final String createdAt;
  final String? rawText;
  final String? transcript;
  final String? translation;
  final bool? autoDiscovered;

  _ReportSeed({
    required this.channel,
    required this.language,
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
    this.rawText,
    this.transcript,
    this.translation,
    this.autoDiscovered,
  });
}

class _IssueSeed {
  final String title;
  final String? titleHi;
  final Category category;
  final String districtId;
  final String village;
  final double lat;
  final double lng;
  final int households;
  final String createdAt;
  const _IssueSeed({
    required this.title,
    this.titleHi,
    required this.category,
    required this.districtId,
    required this.village,
    required this.lat,
    required this.lng,
    required this.households,
    required this.createdAt,
  });
}

class _Seed {
  final _IssueSeed issue;
  final List<_ReportSeed> reports;
  final int upvotes;
  final int repeatCount;
  final IssueStage stage;
  final ServiceTicket? serviceTicket;
  _Seed({
    required this.issue,
    required this.reports,
    required this.upvotes,
    this.repeatCount = 0,
    required this.stage,
    this.serviceTicket,
  });
}

final List<_Seed> _seeds = [
  _Seed(
    stage: 'in-project',
    upvotes: 22,
    repeatCount: 1,
    issue: _IssueSeed(
      title: 'Fluoride-stained drinking water',
      titleHi: 'फ्लोराइड युक्त पीने का पानी',
      category: 'water-quality',
      districtId: 'palamu',
      village: 'Badih',
      lat: 24.01,
      lng: 84.05,
      households: 63,
      createdAt: _iso(140),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Hindi',
        category: 'water-quality',
        districtId: 'palamu',
        village: 'Badih',
        lat: 24.01,
        lng: 84.05,
        urgencyHint: 4,
        affectedGroup: 'households near the hand pump',
        households: 20,
        evidence: [_evid('photo', 'Stained teeth of village children', 'r-badih-1', 138)],
        reporterId: 'r-badih-1',
        reporterName: 'Manoj Bhuiyan',
        createdAt: _iso(138),
        transcript: 'हमारे गाँव के पानी से दांत पीले पड़ रहे हैं।',
        translation: "Our village water is turning children's teeth yellow.",
      ),
      _ReportSeed(
        channel: 'app',
        language: 'Hindi',
        category: 'water-quality',
        districtId: 'palamu',
        village: 'Badih',
        lat: 24.02,
        lng: 84.06,
        urgencyHint: 4,
        affectedGroup: 'households near the hand pump',
        households: 18,
        evidence: [_evid('photo', 'Water sample turning cloudy', 'r-badih-2', 120)],
        reporterId: 'r-badih-2',
        reporterName: 'Kamla Devi',
        createdAt: _iso(120),
      ),
      _ReportSeed(
        channel: 'web',
        language: 'Khortha',
        category: 'water-quality',
        districtId: 'palamu',
        village: 'Badih',
        lat: 24.00,
        lng: 84.04,
        urgencyHint: 3,
        affectedGroup: 'elderly residents',
        households: 15,
        evidence: const [],
        reporterId: 'r-badih-3',
        reporterName: 'Suresh Ram',
        createdAt: _iso(95),
      ),
      _ReportSeed(
        channel: 'app',
        language: 'Hindi',
        category: 'water-quality',
        districtId: 'palamu',
        village: 'Badih',
        lat: 24.01,
        lng: 84.07,
        urgencyHint: 5,
        affectedGroup: 'children under 12',
        households: 10,
        evidence: [_evid('document', 'PHED water test slip showing high fluoride', 'r-badih-4', 40)],
        reporterId: 'r-badih-4',
        reporterName: 'Anita Kumari',
        createdAt: _iso(40),
      ),
    ],
  ),
  _Seed(
    stage: 'routed-service',
    upvotes: 14,
    repeatCount: 3,
    issue: _IssueSeed(
      title: 'Non-working hand pumps',
      category: 'water-scarcity',
      districtId: 'latehar',
      village: 'Netarhat Road',
      lat: 23.76,
      lng: 84.51,
      households: 30,
      createdAt: _iso(80),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Hindi',
        category: 'water-scarcity',
        districtId: 'latehar',
        village: 'Netarhat Road',
        lat: 23.76,
        lng: 84.51,
        urgencyHint: 4,
        affectedGroup: 'entire hamlet',
        households: 30,
        evidence: [_evid('photo', 'Broken hand pump handle', 'r-latehar-1', 78)],
        reporterId: 'r-latehar-1',
        reporterName: 'Ramesh Mahto',
        createdAt: _iso(78),
      ),
    ],
    serviceTicket: ServiceTicket(
        id: _nid('svc'), department: 'PHED', status: 'assigned', slaDays: 15, assignedAt: _iso(60)),
  ),
  _Seed(
    stage: 'validated',
    upvotes: 19,
    issue: _IssueSeed(
      title: 'Tomatoes rotting, no cold storage',
      category: 'agri-postharvest',
      districtId: 'ranchi',
      village: 'Ormanjhi',
      lat: 23.53,
      lng: 85.36,
      households: 45,
      createdAt: _iso(65),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Hindi',
        category: 'agri-postharvest',
        districtId: 'ranchi',
        village: 'Ormanjhi',
        lat: 23.53,
        lng: 85.36,
        urgencyHint: 3,
        affectedGroup: 'vegetable farmers',
        households: 45,
        evidence: [
          _evid('photo', 'Crates of rotting tomatoes', 'r-orm-1', 63, '/images/rotting-tomatoes-crate.png'),
        ],
        reporterId: 'r-orm-1',
        reporterName: 'Jagdish Mahto',
        createdAt: _iso(63),
      ),
    ],
  ),
  _Seed(
    stage: 'awaiting-validation',
    upvotes: 27,
    issue: _IssueSeed(
      title: 'Low prices for lac and mahua, no local processing',
      category: 'livelihood-forest-produce',
      districtId: 'khunti',
      village: 'Murhu',
      lat: 23.02,
      lng: 85.24,
      households: 80,
      createdAt: _iso(50),
    ),
    reports: [
      _ReportSeed(
        channel: 'social',
        language: 'Hindi',
        category: 'livelihood-forest-produce',
        districtId: 'khunti',
        village: 'Murhu',
        lat: 23.02,
        lng: 85.24,
        urgencyHint: 3,
        affectedGroup: 'forest-produce collectors',
        households: 80,
        evidence: const [],
        reporterId: 'r-khunti-1',
        reporterName: 'Budhni Devi',
        createdAt: _iso(50),
        autoDiscovered: true,
      ),
      _ReportSeed(
        channel: 'app',
        language: 'Mundari',
        category: 'livelihood-forest-produce',
        districtId: 'simdega',
        village: 'Kolebira',
        lat: 22.63,
        lng: 84.52,
        urgencyHint: 3,
        affectedGroup: 'lac artisans',
        households: 25,
        evidence: [_evid('photo', 'Raw lac stock with no buyer', 'r-simdega-1', 45)],
        reporterId: 'r-simdega-1',
        reporterName: 'Sona Kumari',
        createdAt: _iso(45),
      ),
    ],
  ),
  _Seed(
    stage: 'routed-service',
    upvotes: 33,
    repeatCount: 2,
    issue: _IssueSeed(
      title: 'Flooded culvert cuts off a village during monsoon',
      category: 'flooding-roads',
      districtId: 'dhanbad',
      village: 'Baliapur',
      lat: 23.69,
      lng: 86.55,
      households: 55,
      createdAt: _iso(30),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Hindi',
        category: 'flooding-roads',
        districtId: 'dhanbad',
        village: 'Baliapur',
        lat: 23.69,
        lng: 86.55,
        urgencyHint: 5,
        affectedGroup: 'school children, daily commuters',
        households: 55,
        evidence: [_evid('video', 'Culvert underwater during rain', 'r-dhanbad-1', 28)],
        reporterId: 'r-dhanbad-1',
        reporterName: 'Firoz Ansari',
        createdAt: _iso(28),
      ),
    ],
    serviceTicket: ServiceTicket(
        id: _nid('svc'), department: 'Rural Works Dept', status: 'in-progress', slaDays: 21, assignedAt: _iso(25)),
  ),
  _Seed(
    stage: 'resolved',
    upvotes: 9,
    issue: _IssueSeed(
      title: 'Streetlight outage, Kanke ward',
      category: 'power-lighting',
      districtId: 'ranchi',
      village: 'Kanke',
      lat: 23.42,
      lng: 85.32,
      households: 40,
      createdAt: _iso(70),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Hindi',
        category: 'power-lighting',
        districtId: 'ranchi',
        village: 'Kanke',
        lat: 23.42,
        lng: 85.32,
        urgencyHint: 2,
        affectedGroup: 'ward residents',
        households: 40,
        evidence: const [],
        reporterId: 'r-kanke-1',
        reporterName: 'Deepak Oraon',
        createdAt: _iso(70),
      ),
    ],
    serviceTicket: ServiceTicket(
        id: _nid('svc'),
        department: 'Energy Dept',
        status: 'resolved',
        slaDays: 10,
        assignedAt: _iso(68),
        resolvedAt: _iso(55)),
  ),
  _Seed(
    stage: 'validated',
    upvotes: 17,
    issue: _IssueSeed(
      title: 'Coal dust and unsafe pond water near mining area',
      category: 'health-environment',
      districtId: 'bokaro',
      village: 'Chandankiyari',
      lat: 23.55,
      lng: 86.30,
      households: 38,
      createdAt: _iso(55),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Hindi',
        category: 'health-environment',
        districtId: 'bokaro',
        village: 'Chandankiyari',
        lat: 23.55,
        lng: 86.30,
        urgencyHint: 4,
        affectedGroup: 'families near pond',
        households: 38,
        evidence: [_evid('photo', 'Black dust settled on pond surface', 'r-bokaro-1', 53)],
        reporterId: 'r-bokaro-1',
        reporterName: 'Meena Kumari',
        createdAt: _iso(53),
      ),
    ],
  ),
  _Seed(
    stage: 'closed-failed',
    upvotes: 12,
    issue: _IssueSeed(
      title: 'Solar irrigation pump failed after 6 months',
      category: 'agri-irrigation',
      districtId: 'gumla',
      village: 'Ghaghra',
      lat: 23.15,
      lng: 84.60,
      households: 22,
      createdAt: _iso(300),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Hindi',
        category: 'agri-irrigation',
        districtId: 'gumla',
        village: 'Ghaghra',
        lat: 23.15,
        lng: 84.60,
        urgencyHint: 3,
        affectedGroup: 'irrigation-dependent farmers',
        households: 22,
        evidence: const [],
        reporterId: 'r-gumla-1',
        reporterName: 'Suresh Oraon',
        createdAt: _iso(300),
      ),
    ],
  ),
  _Seed(
    stage: 'awaiting-validation',
    upvotes: 8,
    issue: _IssueSeed(
      title: 'Anganwadi centre without electricity',
      category: 'education-access',
      districtId: 'pakur',
      village: 'Litipara',
      lat: 24.55,
      lng: 87.60,
      households: 16,
      createdAt: _iso(20),
    ),
    reports: [
      _ReportSeed(
        channel: 'web',
        language: 'Santali',
        category: 'education-access',
        districtId: 'pakur',
        village: 'Litipara',
        lat: 24.55,
        lng: 87.60,
        urgencyHint: 3,
        affectedGroup: 'anganwadi children',
        households: 16,
        evidence: const [],
        reporterId: 'r-pakur-1',
        reporterName: 'Somra Murmu',
        createdAt: _iso(20),
      ),
    ],
  ),
  _Seed(
    stage: 'validated',
    upvotes: 11,
    issue: _IssueSeed(
      title: 'Soil erosion on hill road, Netarhat',
      category: 'flooding-roads',
      districtId: 'latehar',
      village: 'Netarhat',
      lat: 23.47,
      lng: 84.27,
      households: 12,
      createdAt: _iso(38),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Hindi',
        category: 'flooding-roads',
        districtId: 'latehar',
        village: 'Netarhat',
        lat: 23.47,
        lng: 84.27,
        urgencyHint: 3,
        affectedGroup: 'hill-road commuters',
        households: 12,
        evidence: [_evid('photo', 'Washed-out road shoulder', 'r-net-1', 36)],
        reporterId: 'r-net-1',
        reporterName: 'Birsa Oraon',
        createdAt: _iso(36),
      ),
    ],
  ),

  // --- Culturally-grounded issues: tribal festivals, sacred sites, forest livelihoods and
  // languages of Jharkhand, spread across stages so every role (citizen, government, university,
  // mentor, industry, council) has relevant, specific work to look at — not generic filler.
  _Seed(
    stage: 'awaiting-validation',
    upvotes: 21,
    issue: _IssueSeed(
      title: 'Sarna sacred grove trees felled for road widening',
      titleHi: 'सड़क चौड़ीकरण के लिए सरना स्थल के पेड़ काटे गए',
      category: 'other',
      districtId: 'khunti',
      village: 'Rania',
      lat: 23.05,
      lng: 85.30,
      households: 90,
      createdAt: _iso(9),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Mundari',
        category: 'other',
        districtId: 'khunti',
        village: 'Rania',
        lat: 23.05,
        lng: 85.30,
        urgencyHint: 5,
        affectedGroup: 'the whole village that worships at the sarna sthal',
        households: 90,
        evidence: [_evid('photo', 'Felled sal trees at the edge of the sacred grove', 'r-sarna-1', 9)],
        reporterId: 'r-sarna-1',
        reporterName: 'Sukra Munda',
        createdAt: _iso(9),
        transcript: 'ठेकेदार ने सरना स्थल के साल के पेड़ काट दिए, यह हमारे पूर्वजों की पूजा-स्थली है।',
        translation:
            "The contractor cut down sal trees at our Sarna sthal — this is our ancestors' place of worship.",
      ),
      _ReportSeed(
        channel: 'social',
        language: 'Hindi',
        category: 'other',
        districtId: 'khunti',
        village: 'Rania',
        lat: 23.051,
        lng: 85.301,
        urgencyHint: 4,
        affectedGroup: 'village pahan (priest) and elders',
        households: 40,
        evidence: const [],
        reporterId: 'r-sarna-2',
        reporterName: 'Etwa Munda',
        createdAt: _iso(8),
        autoDiscovered: true,
      ),
    ],
  ),
  _Seed(
    stage: 'validated',
    upvotes: 15,
    issue: _IssueSeed(
      title: 'Akhra dance ground waterlogged before Sarhul',
      titleHi: 'सरहुल से पहले अखाड़ा में जलजमाव',
      category: 'flooding-roads',
      districtId: 'simdega',
      village: 'Kolebira',
      lat: 22.64,
      lng: 84.53,
      households: 60,
      createdAt: _iso(48),
    ),
    reports: [
      _ReportSeed(
        channel: 'web',
        language: 'Kurukh',
        category: 'flooding-roads',
        districtId: 'simdega',
        village: 'Kolebira',
        lat: 22.64,
        lng: 84.53,
        urgencyHint: 3,
        affectedGroup: 'youth dance groups preparing for Sarhul',
        households: 60,
        evidence: [_evid('photo', 'Standing water on the akhra', 'r-akhra-1', 46)],
        reporterId: 'r-akhra-1',
        reporterName: 'Mangra Kachhap',
        createdAt: _iso(46),
      ),
    ],
  ),
  _Seed(
    stage: 'awaiting-validation',
    upvotes: 13,
    issue: _IssueSeed(
      title: 'Chhath pokhar drying up before the festival',
      titleHi: 'छठ पर्व से पहले पोखर सूख रहा है',
      category: 'water-scarcity',
      districtId: 'deoghar',
      village: 'Sarwan',
      lat: 24.42,
      lng: 86.61,
      households: 110,
      createdAt: _iso(5),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Hindi',
        category: 'water-scarcity',
        districtId: 'deoghar',
        village: 'Sarwan',
        lat: 24.42,
        lng: 86.61,
        urgencyHint: 4,
        affectedGroup: 'households observing Chhath Puja',
        households: 110,
        evidence: [_evid('photo', 'Cracked, dry pokhar bed', 'r-chhath-1', 5)],
        reporterId: 'r-chhath-1',
        reporterName: 'Rekha Devi',
        createdAt: _iso(5),
      ),
    ],
  ),
  _Seed(
    stage: 'routed-innovation',
    upvotes: 24,
    repeatCount: 1,
    issue: _IssueSeed(
      title: 'Dokra metal-craft artisans losing income, no market link',
      titleHi: 'डोकरा शिल्पकारों की आय घट रही है, बाज़ार से जुड़ाव नहीं',
      category: 'livelihood-forest-produce',
      districtId: 'west-singhbhum',
      village: 'Tonto',
      lat: 22.48,
      lng: 85.62,
      households: 32,
      createdAt: _iso(85),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Ho',
        category: 'livelihood-forest-produce',
        districtId: 'west-singhbhum',
        village: 'Tonto',
        lat: 22.48,
        lng: 85.62,
        urgencyHint: 3,
        affectedGroup: 'dokra artisan families',
        households: 32,
        evidence: [_evid('photo', 'Unsold dokra figurines stacked at home', 'r-dokra-1', 83)],
        reporterId: 'r-dokra-1',
        reporterName: 'Somai Hembrom',
        createdAt: _iso(83),
      ),
      _ReportSeed(
        channel: 'web',
        language: 'Hindi',
        category: 'livelihood-forest-produce',
        districtId: 'west-singhbhum',
        village: 'Tonto',
        lat: 22.481,
        lng: 85.621,
        urgencyHint: 3,
        affectedGroup: 'dokra artisan families',
        households: 15,
        evidence: const [],
        reporterId: 'r-dokra-2',
        reporterName: 'Lalita Hembrom',
        createdAt: _iso(70),
      ),
    ],
  ),
  _Seed(
    stage: 'in-project',
    upvotes: 19,
    issue: _IssueSeed(
      title: 'Tussar reelers get sick from manual reeling, no machines',
      titleHi: 'तसर रीलिंग करने वाली महिलाएं बीमार हो रही हैं, मशीन नहीं है',
      category: 'livelihood-forest-produce',
      districtId: 'dumka',
      village: 'Kathikund',
      lat: 24.19,
      lng: 87.15,
      households: 44,
      createdAt: _iso(95),
    ),
    reports: [
      _ReportSeed(
        channel: 'web',
        language: 'Santali',
        category: 'livelihood-forest-produce',
        districtId: 'dumka',
        village: 'Kathikund',
        lat: 24.19,
        lng: 87.15,
        urgencyHint: 3,
        affectedGroup: 'tussar silk reeling women',
        households: 44,
        evidence: [_evid('photo', 'Blistered hands from hot-water reeling', 'r-tussar-1', 93)],
        reporterId: 'r-tussar-1',
        reporterName: 'Champa Murmu',
        createdAt: _iso(93),
      ),
    ],
  ),
  _Seed(
    stage: 'routed-service',
    upvotes: 16,
    issue: _IssueSeed(
      title: 'Weekly haat shed roof collapsed, produce spoils in rain',
      titleHi: 'साप्ताहिक हाट का छप्पर गिरा, बारिश में सामान खराब',
      category: 'other',
      districtId: 'chatra',
      village: 'Itkhori',
      lat: 24.13,
      lng: 84.98,
      households: 70,
      createdAt: _iso(33),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Nagpuri',
        category: 'other',
        districtId: 'chatra',
        village: 'Itkhori',
        lat: 24.13,
        lng: 84.98,
        urgencyHint: 3,
        affectedGroup: 'weekly haat vendors and buyers',
        households: 70,
        evidence: [_evid('photo', 'Collapsed haat shed roof', 'r-haat-1', 32)],
        reporterId: 'r-haat-1',
        reporterName: 'Nunu Ganjhu',
        createdAt: _iso(32),
      ),
    ],
    serviceTicket: ServiceTicket(
        id: _nid('svc'), department: 'Rural Works Dept', status: 'assigned', slaDays: 20, assignedAt: _iso(28)),
  ),
  _Seed(
    stage: 'validated',
    upvotes: 20,
    issue: _IssueSeed(
      title: 'Elephant corridor conflict during mahua season',
      titleHi: 'महुआ के मौसम में हाथी गलियारे में संघर्ष',
      category: 'wildlife-conflict',
      districtId: 'saraikela-kharsawan',
      village: 'Kuchai',
      lat: 22.62,
      lng: 85.85,
      households: 50,
      createdAt: _iso(18),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Ho',
        category: 'wildlife-conflict',
        districtId: 'saraikela-kharsawan',
        village: 'Kuchai',
        lat: 22.62,
        lng: 85.85,
        urgencyHint: 5,
        affectedGroup: 'mahua collectors walking at dawn',
        households: 50,
        evidence: [_evid('photo', 'Elephant tracks near the mahua grove', 'r-mahua-elep-1', 17)],
        reporterId: 'r-mahua-elep-1',
        reporterName: 'Dasrath Ho',
        createdAt: _iso(17),
      ),
    ],
  ),
  _Seed(
    stage: 'awaiting-validation',
    upvotes: 10,
    issue: _IssueSeed(
      title: 'Firewood smoke causing respiratory illness in Ho hamlet',
      titleHi: 'लकड़ी के धुएं से हो जनजाति बस्ती में सांस की बीमारी',
      category: 'health-environment',
      districtId: 'west-singhbhum',
      village: 'Goelkera',
      lat: 22.35,
      lng: 85.95,
      households: 26,
      createdAt: _iso(6),
    ),
    reports: [
      _ReportSeed(
        channel: 'web',
        language: 'Ho',
        category: 'health-environment',
        districtId: 'west-singhbhum',
        village: 'Goelkera',
        lat: 22.35,
        lng: 85.95,
        urgencyHint: 4,
        affectedGroup: 'women and young children cooking indoors',
        households: 26,
        evidence: const [],
        reporterId: 'r-smoke-1',
        reporterName: 'Puti Ho',
        createdAt: _iso(6),
      ),
    ],
  ),
  _Seed(
    stage: 'awaiting-validation',
    upvotes: 9,
    issue: _IssueSeed(
      title: 'Gram sabha bhavan roof damaged before monsoon',
      titleHi: 'ग्राम सभा भवन की छत बारिश से पहले क्षतिग्रस्त',
      category: 'other',
      districtId: 'latehar',
      village: 'Manika',
      lat: 23.85,
      lng: 84.35,
      households: 65,
      createdAt: _iso(14),
    ),
    reports: [
      _ReportSeed(
        channel: 'web',
        language: 'Hindi',
        category: 'other',
        districtId: 'latehar',
        village: 'Manika',
        lat: 23.85,
        lng: 84.35,
        urgencyHint: 3,
        affectedGroup: 'gram sabha members under PESA',
        households: 65,
        evidence: [_evid('photo', 'Cracked roof beam in the gram sabha hall', 'r-gsb-1', 14)],
        reporterId: 'r-gsb-1',
        reporterName: 'Chamra Bhagat',
        createdAt: _iso(14),
      ),
    ],
  ),
  _Seed(
    stage: 'validated',
    upvotes: 14,
    issue: _IssueSeed(
      title: 'Brick-kiln migrant children miss the school year',
      titleHi: 'ईंट भट्ठा प्रवास के कारण बच्चों की पढ़ाई छूट रही है',
      category: 'education-access',
      districtId: 'garhwa',
      village: 'Bhandaria',
      lat: 24.10,
      lng: 83.65,
      households: 38,
      createdAt: _iso(42),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Hindi',
        category: 'education-access',
        districtId: 'garhwa',
        village: 'Bhandaria',
        lat: 24.10,
        lng: 83.65,
        urgencyHint: 3,
        affectedGroup: 'seasonal brick-kiln migrant families',
        households: 38,
        evidence: const [],
        reporterId: 'r-migrant-1',
        reporterName: 'Somra Bhuiyan',
        createdAt: _iso(42),
      ),
    ],
  ),
  _Seed(
    stage: 'awaiting-validation',
    upvotes: 12,
    issue: _IssueSeed(
      title: 'Ol Chiki textbooks missing in Santali-medium school',
      titleHi: 'संताली माध्यम विद्यालय में ओल चिकी किताबें नहीं',
      category: 'education-access',
      districtId: 'pakur',
      village: 'Amrapara',
      lat: 24.58,
      lng: 87.72,
      households: 55,
      createdAt: _iso(11),
    ),
    reports: [
      _ReportSeed(
        channel: 'web',
        language: 'Santali',
        category: 'education-access',
        districtId: 'pakur',
        village: 'Amrapara',
        lat: 24.58,
        lng: 87.72,
        urgencyHint: 3,
        affectedGroup: 'Santali-medium primary school children',
        households: 55,
        evidence: const [],
        reporterId: 'r-olchiki-1',
        reporterName: 'Rupi Tudu',
        createdAt: _iso(11),
      ),
    ],
  ),
];

// Fill out to full coverage: every district hit at least twice, every category cycled several times,
// across all channels/languages/stages, using each district's real coordinates from districts.ts.
const List<Category> _fillerCategories = [
  'water-quality', 'water-scarcity', 'flooding-roads', 'power-lighting', 'agri-postharvest', 'agri-irrigation',
  'wildlife-conflict', 'health-environment', 'livelihood-forest-produce', 'education-access', 'sanitation', 'other',
];
const List<String> _fillerVillages = [
  'Sarwan', 'Madhupur', 'Kathikund', 'Kuru', 'Bhawnathpur', 'Poraiyahat', 'Rajmahal', 'Itkhori', 'Jainagar', 'Mandu',
  'Nala', 'Ghatshila', 'Chaibasa', 'Kharsawan', 'Bishunpur', 'Angara', 'Silli', 'Tamar', 'Bundu', 'Sonahatu',
  'Rajdhanwar', 'Bengabad', 'Pirtand', 'Jamua', 'Sarath', 'Devipur', 'Patratu', 'Chandwa', 'Manika', 'Barwadih',
  'Nagar Untari', 'Bhandaria', 'Rehla', 'Kisko', 'Torpa', 'Rania', 'Kurdeg', 'Bano', 'Sundarpahari', 'Boarijor',
  'Amrapara', 'Sikaripara', 'Narayanpur', 'Fatehpur', 'Mahagama', 'Barhet', 'Bagodar', 'Dumri',
];
const List<Channel> _fillerChannels = ['app', 'web', 'social'];
const List<String> _fillerLanguages = [
  'Hindi', 'English', 'Santali', 'Mundari', 'Ho', 'Kurukh', 'Khortha', 'Nagpuri', 'Kurmali', 'Panchpargania',
];
const List<IssueStage> _fillerStages = [
  'awaiting-validation', 'validated', 'routed-service', 'routed-innovation', 'in-project', 'resolved', 'closed-failed',
];
const List<String> _fillerAffected = [
  'local residents', 'farming households', 'school children', 'women and elderly', 'daily wage workers',
  'forest-fringe households', 'ward residents', 'migrant families',
];
const Map<Category, List<String>> _fillerQuotes = {
  'water-quality': [
    'The water from our hand pump smells bad and makes children sick.',
    'We have to boil every drop before drinking, even that does not fully help.',
  ],
  'water-scarcity': [
    'The well runs dry by February every year now.',
    'Women in our hamlet walk two kilometres for a single pot of water.',
  ],
  'flooding-roads': [
    'The road turns into a river the moment it rains — no one can reach the market.',
    'Our children miss school for days when the culvert floods.',
  ],
  'power-lighting': [
    'The streetlights have not worked in months, it is not safe to walk after dark.',
    'Power cuts here last most of the evening, every evening.',
  ],
  'agri-postharvest': [
    'Half of what we grow rots before it ever reaches a buyer.',
    'There is nowhere nearby to store the harvest during the rains.',
  ],
  'agri-irrigation': [
    'Our fields depend entirely on rainfall — one bad monsoon and we lose everything.',
    'The old canal has not carried water in years.',
  ],
  'wildlife-conflict': [
    'We are afraid to work in the fields after sunset because of the animals.',
    'Every season we lose part of the crop to raiding animals and no one compensates us.',
  ],
  'health-environment': [
    'Several people in our hamlet have fallen sick from the same cause and no one has checked why.',
    'The smoke and dust here are making our children cough through the whole winter.',
  ],
  'livelihood-forest-produce': [
    'We collect and grade the produce ourselves but traders still decide the price.',
    'There is no fair place nearby to sell what the forest gives us.',
  ],
  'education-access': [
    'Our children have to walk very far just to reach a working school.',
    'The school here has no teacher for most subjects.',
  ],
  'sanitation': [
    'There is no proper drainage, and it floods with waste water every monsoon.',
    'The community toilet has been broken for a long time now.',
  ],
  'other': [
    'We have raised this many times but nothing has changed on the ground.',
    'This affects the whole village, not just one household.',
  ],
};
String _fillerQuote(Category cat, int seedIdx) {
  final options = _fillerQuotes[cat]!;
  return options[seedIdx % options.length];
}

List<_Seed> _buildFillerSeeds() {
  final out = <_Seed>[];
  int fi = 0;
  for (final d in districts_data.districts) {
    for (int pass = 0; pass < 2; pass++) {
      final i = fi++;
      final cat = _fillerCategories[(i * 5) % _fillerCategories.length];
      final village = _fillerVillages[i % _fillerVillages.length];
      final stage = _fillerStages[i % _fillerStages.length];
      final chan = _fillerChannels[i % _fillerChannels.length];
      final lang = _fillerLanguages[i % _fillerLanguages.length];
      final daysAgo = 5 + (i * 7) % 260;
      final lat = d.lat + (((i * 37) % 21) - 10) * 0.01;
      final lng = d.lng + (((i * 53) % 21) - 10) * 0.01;
      final households = 6 + (i * 5) % 90;
      final numReports = 1 + (i % 3);
      final reports = <_ReportSeed>[];
      for (int r = 0; r < numReports; r++) {
        final rDaysAgo = (daysAgo - r * 6) < 1 ? 1 : daysAgo - r * 6;
        reports.add(_ReportSeed(
          channel: r == 0 ? chan : _fillerChannels[(i + r) % _fillerChannels.length],
          language: lang,
          category: cat,
          districtId: d.id,
          village: village,
          lat: lat + r * 0.003,
          lng: lng + r * 0.003,
          urgencyHint: ((i + r) % 5) + 1,
          affectedGroup: _fillerAffected[(i + r) % _fillerAffected.length],
          households: households - r * 2,
          rawText: _fillerQuote(cat, i + r),
          evidence: (i + r) % 5 != 0
              ? [
                  _evid(
                    (i + r) % 3 == 0 ? 'video' : (i + r) % 3 == 1 ? 'document' : 'photo',
                    '${cat.replaceAll('-', ' ')} evidence from $village',
                    'r-fill-$i-$r',
                    rDaysAgo - 1,
                  )
                ]
              : const [],
          reporterId: 'r-fill-$i-$r',
          reporterName: 'Resident ${i + 1}.${r + 1}',
          createdAt: _iso(rDaysAgo - 1),
          autoDiscovered: chan == 'social' && r == 0,
        ));
      }
      out.add(_Seed(
        stage: stage,
        upvotes: 2 + (i * 3) % 40,
        repeatCount: numReports > 1 ? numReports - 1 : 0,
        issue: _IssueSeed(
          title: '${cat.replaceAll('-', ' ')} issue reported in $village',
          category: cat,
          districtId: d.id,
          village: village,
          lat: lat,
          lng: lng,
          households: households,
          createdAt: _iso(daysAgo),
        ),
        reports: reports,
        serviceTicket: stage == 'routed-service'
            ? ServiceTicket(
                id: _nid('svc'),
                department: ['PHED', 'MGNREGA cell', 'Rural Works Dept', 'Energy Dept', 'Forest Dept'][i % 5],
                status: ['assigned', 'in-progress', 'resolved'][i % 3],
                slaDays: 10 + (i % 4) * 5,
                assignedAt: _iso(daysAgo - 5),
              )
            : null,
      ));
    }
  }
  return out;
}

// A couple of deliberate near-duplicates (same category, close location, close in time) so the
// Smart Duplicate Merger has real candidates to work with beyond the golden fluoride example.
final List<_Seed> _duplicateSeeds = [
  _Seed(
    stage: 'awaiting-validation',
    upvotes: 6,
    issue: _IssueSeed(
      title: 'Elephant herd raids paddy fields near forest edge',
      category: 'wildlife-conflict',
      districtId: 'west-singhbhum',
      village: 'Chaibasa Forest Edge',
      lat: 22.55,
      lng: 85.81,
      households: 34,
      createdAt: _iso(4),
    ),
    reports: [
      _ReportSeed(
        channel: 'app',
        language: 'Ho',
        category: 'wildlife-conflict',
        districtId: 'west-singhbhum',
        village: 'Chaibasa Forest Edge',
        lat: 22.55,
        lng: 85.81,
        urgencyHint: 4,
        affectedGroup: 'farming households',
        households: 34,
        evidence: [_evid('photo', 'Trampled paddy field', 'r-elep-dup-1', 4)],
        reporterId: 'r-elep-dup-1',
        reporterName: 'Sona Munda',
        createdAt: _iso(4),
      ),
    ],
  ),
  _Seed(
    stage: 'awaiting-validation',
    upvotes: 4,
    issue: _IssueSeed(
      title: 'Wild elephants damaging crops near village boundary',
      category: 'wildlife-conflict',
      districtId: 'west-singhbhum',
      village: 'Chaibasa Forest Edge',
      lat: 22.556,
      lng: 85.807,
      households: 20,
      createdAt: _iso(3),
    ),
    reports: [
      _ReportSeed(
        channel: 'social',
        language: 'Hindi',
        category: 'wildlife-conflict',
        districtId: 'west-singhbhum',
        village: 'Chaibasa Forest Edge',
        lat: 22.556,
        lng: 85.807,
        urgencyHint: 4,
        affectedGroup: 'farming households',
        households: 20,
        evidence: const [],
        reporterId: 'r-elep-dup-2',
        reporterName: 'Birsa Ho',
        createdAt: _iso(3),
        autoDiscovered: true,
      ),
    ],
  ),
];

// Mirrors the store's validateIssue disciplines guess (kept in sync manually), extended to cover
// every category so a seeded problem statement never falls back to a generic default.
const Map<Category, List<String>> _disciplinesGuess = {
  'wildlife-conflict': ['wildlife/ecology', 'agri', 'iot/embedded', 'social science'],
  'water-quality': ['environmental science', 'water-quality'],
  'agri-postharvest': ['agri-postharvest', 'agri'],
  'livelihood-forest-produce': ['lac cultivation', 'value-addition', 'social science'],
  'water-scarcity': ['civil engineering', 'iot/embedded'],
  'flooding-roads': ['civil engineering', 'environmental science'],
  'power-lighting': ['renewable energy', 'electrical fitting'],
  'agri-irrigation': ['renewable energy', 'civil engineering', 'agri'],
  'health-environment': ['environmental science', 'public policy'],
  'education-access': ['renewable energy', 'social science'],
  'sanitation': ['civil engineering', 'public policy'],
  'other': ['civil engineering', 'social science'],
};

class _Generated {
  final List<Report> reports;
  final List<MasterIssue> issues;
  _Generated(this.reports, this.issues);
}

final _Generated _generated = _generate();
List<Report> get seedReports => _generated.reports;
List<MasterIssue> get seedMasterIssues => _generated.issues;

_Generated _generate() {
  final seedReports = <Report>[];
  final seedMasterIssues = <MasterIssue>[];
  final allSeeds = [..._seeds, ..._buildFillerSeeds(), ..._duplicateSeeds];

  // Give the shared "Guest" identity (the fallback name for anyone who hasn't entered a custom
  // login name — used across every role) a real report history, so "My reports" is populated no
  // matter which role someone logs into without typing a name.
  const guestSeedIndexes = [1, 3, 5, 7, 12, 20, 28, 36, 44, 52];
  for (int n = 0; n < guestSeedIndexes.length; n++) {
    final idx = guestSeedIndexes[n];
    if (idx >= allSeeds.length) continue;
    final s = allSeeds[idx];
    final daysAgo = 6 + n * 11;
    s.reports.add(_ReportSeed(
      channel: _fillerChannels[n % 3],
      language: 'Hindi',
      category: s.issue.category,
      districtId: s.issue.districtId,
      village: s.issue.village,
      lat: s.issue.lat,
      lng: s.issue.lng,
      urgencyHint: (n % 5) + 1,
      affectedGroup: 'local residents',
      households: (s.issue.households - 5) < 4 ? 4 : s.issue.households - 5,
      evidence: n % 2 == 0 ? [_evid('photo', 'Photo taken on-site', 'r-guest-$n', daysAgo - 1)] : const [],
      reporterId: 'r-guest-$n',
      reporterName: 'Guest',
      createdAt: _iso(daysAgo - 1),
    ));
  }

  for (final s in allSeeds) {
    final issueId = _nid('issue');
    final reportIds = <String>[];
    for (final r in s.reports) {
      final id = _nid('report');
      reportIds.add(id);
      seedReports.add(Report(
        id: id,
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
      ));
    }
    // A real government workflow generates the problem statement at validateIssue time; every stage
    // past "awaiting-validation" implies that already happened, so seed one accordingly — otherwise
    // pages that filter on issue.problemStatement (e.g. University's matched-challenges list) stay
    // permanently empty for seeded data.
    final problemStatement = s.stage != 'awaiting-validation'
        ? ProblemStatement(
            summary:
                '${s.issue.title} affecting ${s.issue.households} households in ${s.issue.village}, ${s.issue.districtId}.',
            scope: '${reportIds.length} report(s) received across the affected area.',
            evidenceSummary: '${reportIds.length} report(s) on file with supporting evidence.',
            urgency: s.upvotes >= 20 ? 'High' : (s.upvotes >= 8 ? 'Medium' : 'Low'),
            successCriteria: const ['Root cause addressed', 'Community confirms improvement via QR feedback'],
            disciplinesNeeded: _disciplinesGuess[s.issue.category]!,
          )
        : null;
    seedMasterIssues.add(MasterIssue(
      id: issueId,
      title: s.issue.title,
      titleHi: s.issue.titleHi,
      category: s.issue.category,
      districtId: s.issue.districtId,
      village: s.issue.village,
      lat: s.issue.lat,
      lng: s.issue.lng,
      reportIds: reportIds,
      upvotes: s.upvotes,
      upvoterIds: const [],
      households: s.issue.households,
      stage: s.stage,
      problemStatement: problemStatement,
      serviceTicket: s.serviceTicket,
      repeatCount: s.repeatCount,
      createdAt: s.issue.createdAt,
    ));
  }

  // Link the handful of named issues to their eventual Innovation-Twin projects (mirrors
  // projects.ts's post-hoc `.projectId =` patch loop). NOTE: proj-rainwater and proj-fluoride
  // share the same source issue (the very first seed, the fluoride case) in the original data —
  // proj-rainwater's assignment runs later and intentionally overwrites proj-fluoride's, so the
  // fluoride issue ends up pointing at proj-rainwater. Replicated here verbatim.
  void patch(bool Function(MasterIssue) test, String projectId) {
    final idx = seedMasterIssues.indexWhere(test);
    if (idx != -1) {
      seedMasterIssues[idx] = seedMasterIssues[idx].copyWith(projectId: projectId);
    }
  }

  patch((i) => i.title.contains('Fluoride'), 'proj-fluoride');
  patch((i) => i.title.contains('Tomatoes'), 'proj-solar-cold');
  patch((i) => i.title.contains('lac and mahua'), 'proj-lac-value');
  patch((i) => i.title.contains('Non-working hand pumps'), 'proj-handpump-iot');
  patch((i) => i.title.contains('Solar irrigation pump failed'), 'proj-solar-irrigation-failed');
  if (seedMasterIssues.isNotEmpty) {
    seedMasterIssues[0] = seedMasterIssues[0].copyWith(projectId: 'proj-rainwater');
  }
  patch(
      (i) =>
          i.districtId == 'east-singhbhum' &&
          i.category == 'livelihood-forest-produce' &&
          i.village == 'Bhawnathpur',
      'proj-forest-produce');
  patch(
      (i) => i.districtId == 'hazaribagh' && i.category == 'health-environment' && i.village == 'Ghatshila',
      'proj-health-camp');
  patch((i) => i.districtId == 'palamu' && i.category == 'wildlife-conflict' && i.village == 'Bundu',
      'proj-wildlife-fence-2');
  patch((i) => i.districtId == 'lohardaga' && i.category == 'agri-irrigation' && i.village == 'Devipur',
      'proj-irrigation');
  patch((i) => i.title.contains('Solar irrigation pump failed'), 'proj-solar-irrigation-failed');

  return _Generated(seedReports, seedMasterIssues);
}

final Map<String, String> goldenElephantSeed = {
  'transcriptHi': 'हाथियों का झुंड रोज़ रात को हमारे धान के खेत में घुस आता है और फसल बर्बाद कर देता है। हमें डर लगता है, कृपया मदद करें।',
  'translationEn': 'A herd of elephants enters our paddy fields every night and destroys the crop. We are scared, please help.',
};

Report buildGoldenFluorideDuplicate() => Report(
      id: 'golden-fluoride-dup',
      channel: 'app',
      language: 'Hindi',
      category: 'water-quality',
      districtId: 'palamu',
      village: 'Badih',
      lat: 24.015,
      lng: 84.055,
      urgencyHint: 5,
      affectedGroup: 'households near the hand pump',
      households: 12,
      evidence: const [],
      reporterId: 'r-badih-golden',
      reporterName: 'Ravi Bhuiyan',
      createdAt: NOW.toUtc().toIso8601String(),
      masterIssueId: '',
      transcript: 'हमारे कुएं का पानी भी वैसा ही पीला दिखता है जैसा बादिह में बताया गया।',
      translation: 'Our well water also looks the same yellow as reported in Badih.',
    );
