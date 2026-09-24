// Ported from src/features/landing/RoleLogin.tsx
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/departments.dart';
import '../../data/districts.dart';
import '../../data/institutions.dart';
import '../../data/partners.dart';
import '../../i18n/dictionary.dart';
import '../../models/types.dart';
import '../../state/civix_store.dart';
import '../../theme/theme.dart';
import '../../widgets/captcha_challenge.dart';
import '../../widgets/civix_button.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/panel.dart';

const Map<String, String> _dest = {
  'citizen': '/citizen',
  'government': '/gov',
  'university': '/uni',
  'industry': '/industry',
  'council': '/council',
};

const Map<String, String> _roleDomain = {
  'citizen': 'citizen.civix.jharkhand.gov.in',
  'government': 'gov.jharkhand.gov.in',
  'university': 'edu.jharkhand.gov.in',
  'industry': 'corp.csr.in',
  'council': 'council.civix.jharkhand.gov.in',
};

final RegExp _gstinRe = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$', caseSensitive: false);
final RegExp _udyamRe = RegExp(r'^UDYAM-[A-Z]{2}-\d{2}-\d{7}$', caseSensitive: false);

String _slug(String s) {
  final cleaned = s.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.').replaceAll(RegExp(r'(^\.+|\.+$)'), '');
  return cleaned.isEmpty ? 'guest' : cleaned;
}

enum _Step { details, captcha, otp }

class RoleLoginScreen extends ConsumerStatefulWidget {
  final String role;
  const RoleLoginScreen({super.key, required this.role});

  @override
  ConsumerState<RoleLoginScreen> createState() => _RoleLoginScreenState();
}

class _RoleLoginScreenState extends ConsumerState<RoleLoginScreen> {
  _Step _step = _Step.details;
  final _nameCtrl = TextEditingController(text: 'Guest');
  final _phoneCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  String _districtId = districts.isNotEmpty ? districts.first.id : '';
  String _department = jharkhandDepartments.isNotEmpty ? jharkhandDepartments.first.name : '';
  String _institutionId = institutions.isNotEmpty ? institutions.first.id : '';
  String _partnerId = partners.isNotEmpty ? partners.first.id : '';
  String _seat = councilSeats.first;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final role = widget.role;
    if (!_dest.containsKey(role)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return const SizedBox.shrink();
    }

        final t = ref.watch(dictionaryProvider);
        final partner = partners.where((p) => p.id == _partnerId).isNotEmpty
            ? partners.firstWhere((p) => p.id == _partnerId)
            : null;
        final email = '${_slug(role == 'industry' && partner != null ? partner.name : _nameCtrl.text)}@${_roleDomain[role]}';
        final gstValid = role != 'industry' || _gstinRe.hasMatch(_gstCtrl.text.trim()) || _udyamRe.hasMatch(_gstCtrl.text.trim());
        final detailsValid = _nameCtrl.text.trim().isNotEmpty && gstValid;

        void finish() {
          final profile = Persona(
            id: '$role-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
            name: _nameCtrl.text.trim(),
            role: role,
            avatarColor: roleAvatarColor[role] ?? '#1C2B5A',
            blurb: _phoneCtrl.text.isNotEmpty ? 'Phone: ${_phoneCtrl.text}' : '',
            districtId: (role == 'citizen' || role == 'government') ? _districtId : null,
            department: role == 'government' ? _department : null,
            institutionId: role == 'university' ? _institutionId : null,
            partnerId: role == 'industry' ? _partnerId : null,
            councilSeat: role == 'council' ? _seat : null,
          );
          ref.read(civixStoreProvider.notifier).setProfile(profile);
          context.go(_dest[role]!);
        }

        return Scaffold(
          appBar: AppBar(title: Text('${t('roleLogin.labels.$role')} ${t('roleLogin.signIn')}')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(t('roleLogin.blurbs.$role'), style: const TextStyle(fontSize: 13, color: CivixColors.neelSoft)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 14, color: CivixColors.sal),
                  const SizedBox(width: 6),
                  Expanded(child: Text(t('roleLogin.securedSignIn'), style: const TextStyle(fontSize: 12, color: CivixColors.sal))),
                ],
              ),
              const SizedBox(height: 16),
              Panel(
                child: switch (_step) {
                  _Step.details => _DetailsForm(
                      role: role,
                      t: t,
                      nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl,
                      gstCtrl: _gstCtrl,
                      email: email,
                      gstValid: gstValid,
                      detailsValid: detailsValid,
                      districtId: _districtId,
                      onDistrictChanged: (v) => setState(() => _districtId = v),
                      department: _department,
                      onDepartmentChanged: (v) => setState(() => _department = v),
                      institutionId: _institutionId,
                      onInstitutionChanged: (v) => setState(() => _institutionId = v),
                      partnerId: _partnerId,
                      onPartnerChanged: (v) => setState(() => _partnerId = v),
                      seat: _seat,
                      onSeatChanged: (v) => setState(() => _seat = v),
                      onContinue: () => setState(() => _step = _Step.captcha),
                      onNameChanged: () => setState(() {}),
                    ),
                  _Step.captcha => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CaptchaChallenge(onVerified: () => setState(() => _step = _Step.otp)),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() => _step = _Step.details),
                          child: Text(t('roleLogin.back')),
                        ),
                      ],
                    ),
                  _Step.otp => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OtpInput(destination: _phoneCtrl.text, onVerified: finish),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() => _step = _Step.captcha),
                          child: Text(t('roleLogin.back')),
                        ),
                      ],
                    ),
                },
              ),
            ],
          ),
        );
  }
}

class _DetailsForm extends StatelessWidget {
  final String role;
  final AppDictionary t;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController gstCtrl;
  final String email;
  final bool gstValid;
  final bool detailsValid;
  final String districtId;
  final ValueChanged<String> onDistrictChanged;
  final String department;
  final ValueChanged<String> onDepartmentChanged;
  final String institutionId;
  final ValueChanged<String> onInstitutionChanged;
  final String partnerId;
  final ValueChanged<String> onPartnerChanged;
  final String seat;
  final ValueChanged<String> onSeatChanged;
  final VoidCallback onContinue;
  final VoidCallback onNameChanged;

  const _DetailsForm({
    required this.role,
    required this.t,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.gstCtrl,
    required this.email,
    required this.gstValid,
    required this.detailsValid,
    required this.districtId,
    required this.onDistrictChanged,
    required this.department,
    required this.onDepartmentChanged,
    required this.institutionId,
    required this.onInstitutionChanged,
    required this.partnerId,
    required this.onPartnerChanged,
    required this.seat,
    required this.onSeatChanged,
    required this.onContinue,
    required this.onNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(role == 'industry' ? t('roleLogin.contactPersonName') : t('roleLogin.fullName'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: nameCtrl,
          onChanged: (_) => onNameChanged(),
          decoration: InputDecoration(hintText: t('roleLogin.namePlaceholder'), border: const OutlineInputBorder(), isDense: true, contentPadding: const EdgeInsets.all(12)),
        ),
        const SizedBox(height: 14),

        Text(t('roleLogin.registeredEmail'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: email),
          readOnly: true,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: CivixColors.neelSoft),
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12), filled: true, fillColor: CivixColors.chuna),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(t('roleLogin.autoAssignedEmail'), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
        ),
        const SizedBox(height: 14),

        Text(t('roleLogin.mobileNumber'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(hintText: t('roleLogin.mobilePlaceholder'), border: const OutlineInputBorder(), isDense: true, contentPadding: const EdgeInsets.all(12)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(t('roleLogin.otpHint'), style: const TextStyle(fontSize: 11, color: CivixColors.neelSoft)),
        ),
        const SizedBox(height: 14),

        if (role == 'citizen' || role == 'government') ...[
          Text(t('roleLogin.district'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: districtId,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12)),
            items: [for (final d in districts) DropdownMenuItem(value: d.id, child: Text(d.name))],
            onChanged: (v) => v != null ? onDistrictChanged(v) : null,
          ),
          const SizedBox(height: 14),
        ],

        if (role == 'government') ...[
          Text(t('roleLogin.department'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: department,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12)),
            items: [for (final d in jharkhandDepartments) DropdownMenuItem(value: d.name, child: Text(d.name, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => v != null ? onDepartmentChanged(v) : null,
          ),
          const SizedBox(height: 14),
        ],

        if (role == 'university') ...[
          Text(t('roleLogin.institution'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: institutionId,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12)),
            items: [for (final i in institutions) DropdownMenuItem(value: i.id, child: Text(i.name, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => v != null ? onInstitutionChanged(v) : null,
          ),
          const SizedBox(height: 14),
        ],

        if (role == 'industry') ...[
          Text(t('roleLogin.organisation'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: partnerId,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12)),
            items: [for (final p in partners) DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => v != null ? onPartnerChanged(v) : null,
          ),
          const SizedBox(height: 14),
          Text(t('roleLogin.gstOrUdyam'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: gstCtrl,
            textCapitalization: TextCapitalization.characters,
            onChanged: (v) => onNameChanged(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText: t('roleLogin.gstPlaceholder'),
              border: OutlineInputBorder(borderSide: BorderSide(color: gstCtrl.text.isNotEmpty && !gstValid ? CivixColors.ember : CivixColors.rule)),
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              gstCtrl.text.isNotEmpty && !gstValid ? t('roleLogin.gstInvalid') : t('roleLogin.gstHint'),
              style: TextStyle(fontSize: 11, color: gstCtrl.text.isNotEmpty && !gstValid ? CivixColors.ember : CivixColors.neelSoft),
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (role == 'council') ...[
          Text(t('roleLogin.councilSeat'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: seat,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(12)),
            items: [for (final s in councilSeats) DropdownMenuItem(value: s, child: Text(s))],
            onChanged: (v) => v != null ? onSeatChanged(v) : null,
          ),
          const SizedBox(height: 14),
        ],

        SizedBox(
          width: double.infinity,
          child: CivixButton(label: t('roleLogin.continue'), onPressed: detailsValid ? onContinue : null),
        ),
      ],
    );
  }
}
