// Ported 1:1 from src/data/govContacts.ts
// A CSR partner deciding to fund a project needs a named government point of contact to verify
// progress with directly — not just a district label. No real personnel directory exists in this
// demo dataset, so each district gets a stable, deterministically generated nodal officer instead
// of a random one, so the same district always shows the same contact.
const List<String> _firstNames = [
  'Anil', 'Sunita', 'Rakesh', 'Meena', 'Prakash', 'Kavita', 'Suresh', 'Anita', 'Deepak', 'Rina', 'Vikram', 'Neha',
];
const List<String> _lastNames = [
  'Kumar', 'Singh', 'Oraon', 'Mahto', 'Toppo', 'Prasad', 'Verma', 'Soren', 'Sinha', 'Bhagat',
];

int _hashStr(String s) {
  int h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0xFFFFFFFF;
  }
  return h;
}

class GovContact {
  final String name;
  final String designation;
  final String phone;
  final String email;
  const GovContact({required this.name, required this.designation, required this.phone, required this.email});
}

GovContact govContactForDistrict(String districtId, String districtName) {
  final h = _hashStr(districtId);
  final first = _firstNames[h % _firstNames.length];
  final last = _lastNames[(h ~/ _firstNames.length) % _lastNames.length];
  final phoneDigits = (h % 900000000) + 100000000;
  return GovContact(
    name: '$first $last',
    designation: 'District Nodal Officer — CIVIX Monitoring, $districtName Collectorate',
    phone: '+91 9$phoneDigits',
    email: '${first.toLowerCase()}.${last.toLowerCase()}.$districtId@jharkhand.gov.in',
  );
}
