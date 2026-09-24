import '../models/types.dart';

enum AppLang { en, hi }

class Session {
  final Role role;
  final Persona? profile;
  final AppLang lang;

  const Session({required this.role, this.profile, required this.lang});

  Session copyWith({Role? role, Persona? profile, AppLang? lang}) => Session(
        role: role ?? this.role,
        profile: profile ?? this.profile,
        lang: lang ?? this.lang,
      );

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        role: j['role'],
        profile: j['profile'] != null ? Persona.fromJson(j['profile']) : null,
        lang: j['lang'] == 'hi' ? AppLang.hi : AppLang.en,
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'profile': profile?.toJson(),
        'lang': lang == AppLang.hi ? 'hi' : 'en',
      };
}
