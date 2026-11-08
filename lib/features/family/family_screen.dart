import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mawoonati/core/session/session_gate.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';
import 'package:mawoonati/features/auth/auth_repository.dart';
import 'package:mawoonati/features/household/household_repository.dart';
import 'package:mawoonati/shared/widgets/app_card.dart';
import 'package:mawoonati/shared/widgets/form_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _roleAr = {'owner': 'مالك', 'admin': 'مدير', 'member': 'عضو', 'viewer': 'مشاهد'};

class _FamilyData {
  _FamilyData(this.household, this.members, this.sentInvites, this.myInvites);
  final Household? household;
  final List<Map<String, String>> members; // name, role
  final List<Map<String, String>> sentInvites; // email, role
  final List<Map<String, String>> myInvites; // id, email
}

/// أفراد العائلة (يحتاج حساباً): عرض الأعضاء، دعوة بالبريد، وقبول دعوة وصلتك.
class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  Future<_FamilyData>? _future;

  @override
  void initState() {
    super.initState();
    if (ref.read(sessionGateProvider).signedIn) _future = _load();
  }

  SupabaseClient get _db => Supabase.instance.client;

  Future<_FamilyData> _load() async {
    final myEmail = (ref.read(authRepositoryProvider).email ?? '').toLowerCase();
    final hs = await ref.read(householdRepositoryProvider).myHouseholds();
    final h = hs.isEmpty ? null : hs.first;
    var members = <Map<String, String>>[];
    if (h != null) {
      final mem = await _db.from('household_members').select('user_id, role').eq('household_id', h.id);
      final ids = [for (final m in mem) m['user_id'] as String];
      final profs = ids.isEmpty
          ? <dynamic>[]
          : await _db.from('profiles').select('id, display_name').inFilter('id', ids);
      final names = {for (final p in profs) p['id'] as String: (p['display_name'] as String?) ?? ''};
      members = [
        for (final m in mem)
          {
            'name': (names[m['user_id']] ?? '').isEmpty ? 'عضو' : names[m['user_id']]!,
            'role': m['role'] as String,
          }
      ];
    }
    final inv = await _db
        .from('household_invites')
        .select('id, email, role, household_id')
        .isFilter('accepted_at', null);
    final sent = <Map<String, String>>[];
    final mine = <Map<String, String>>[];
    for (final i in inv) {
      final email = (i['email'] as String).toLowerCase();
      if (h != null && i['household_id'] == h.id) {
        sent.add({'email': email, 'role': i['role'] as String});
      } else if (email == myEmail) {
        mine.add({'id': i['id'] as String, 'email': email});
      }
    }
    return _FamilyData(h, members, sent, mine);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _invite(Household h) async {
    final r = await showForm(context, title: 'دعوة فرد من العائلة', submitLabel: 'إرسال الدعوة', fields: const [
      FieldSpec('email', 'البريد الإلكتروني', required: true),
      FieldSpec('role', 'الصلاحية', kind: FieldKind.choice, options: ['عضو', 'مدير', 'مشاهد'], initial: 'عضو'),
    ]);
    if (r == null) return;
    const roles = {'عضو': 'member', 'مدير': 'admin', 'مشاهد': 'viewer'};
    try {
      await _db.from('household_invites').insert({
        'household_id': h.id,
        'email': r['email']!.trim().toLowerCase(),
        'role': roles[r['role']] ?? 'member',
        'invited_by': _db.auth.currentUser?.id,
      });
      if (mounted) snack(context, 'أُرسلت الدعوة. يسجّل الشخص بنفس هذا البريد ثم يقبلها من هذه الشاشة.');
      _reload();
    } catch (_) {
      if (mounted) snack(context, 'تعذّر إرسال الدعوة. تحقق من الصلاحية والبريد.');
    }
  }

  Future<void> _accept(String id) async {
    try {
      await _db.rpc('accept_invite', params: {'p_invite': id});
      if (mounted) snack(context, 'انضممت للعائلة');
      await ref.read(sessionGateProvider).refresh();
      _reload();
    } catch (_) {
      if (mounted) snack(context, 'تعذّر قبول الدعوة. قد تكون منتهية.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(sessionGateProvider).signedIn;
    return Scaffold(
      appBar: AppBar(title: const Text('أفراد العائلة')),
      body: !signedIn
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_outlined, size: 56, color: AppColors.greenDark),
                    const SizedBox(height: 12),
                    const Text('العائلة تحتاج حساباً',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('سجّل الدخول لإنشاء عائلة ودعوة أفرادها. التطبيق يعمل بدون حساب لبقية الأقسام.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('تسجيل الدخول / إنشاء حساب')),
                  ],
                ),
              ),
            )
          : FutureBuilder<_FamilyData>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError || snap.data == null) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('تعذّر تحميل بيانات العائلة. تحقق من الإنترنت.'),
                      const SizedBox(height: 8),
                      FilledButton(onPressed: _reload, child: const Text('إعادة المحاولة')),
                    ]),
                  );
                }
                final d = snap.data!;
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    for (final i in d.myInvites)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          color: AppColors.greenSoft,
                          child: Row(children: [
                            const Expanded(child: Text('وصلتك دعوة للانضمام إلى عائلة',
                                style: TextStyle(fontWeight: FontWeight.w700))),
                            FilledButton(onPressed: () => _accept(i['id']!), child: const Text('قبول')),
                          ]),
                        ),
                      ),
                    if (d.household != null) ...[
                      Text(d.household!.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(children: [
                          for (final m in d.members)
                            ListTile(
                              leading: const CircleAvatar(
                                  backgroundColor: AppColors.greenSoft,
                                  child: Icon(Icons.person, color: AppColors.greenDark)),
                              title: Text(m['name']!),
                              subtitle: Text(_roleAr[m['role']] ?? m['role']!),
                            ),
                        ]),
                      ),
                      if (d.sentInvites.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('دعوات بانتظار القبول',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(children: [
                            for (final i in d.sentInvites)
                              ListTile(
                                leading: const Icon(Icons.mail_outline),
                                title: Text(i['email']!),
                                subtitle: Text(_roleAr[i['role']] ?? i['role']!),
                              ),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _invite(d.household!),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('دعوة فرد'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                          'ملاحظة: مزامنة المخزون والمشتريات بين أفراد العائلة لم تُفعَّل بعد. بياناتك الحالية محفوظة على هذا الجهاز فقط.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
