import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Household {
  const Household({required this.id, required this.name, required this.currency});
  final String id;
  final String name;
  final String currency;
}

abstract class HouseholdRepository {
  /// المنازل التي المستخدم عضو فيها (RLS يضمن ذلك من قاعدة البيانات).
  Future<List<Household>> myHouseholds();
  Future<String> createHousehold({required String name, required String currency});
}

final householdRepositoryProvider =
    Provider<HouseholdRepository>((ref) => SupabaseHouseholdRepository());

class SupabaseHouseholdRepository implements HouseholdRepository {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<List<Household>> myHouseholds() async {
    final rows = await _db
        .from('households')
        .select('id, name, currency')
        .isFilter('deleted_at', null);
    return [
      for (final r in rows)
        Household(
          id: r['id'] as String,
          name: r['name'] as String,
          currency: (r['currency'] as String).trim(),
        ),
    ];
  }

  @override
  Future<String> createHousehold({required String name, required String currency}) async {
    try {
      final id = await _db.rpc('create_household',
          params: {'p_name': name.trim(), 'p_currency': currency});
      return id as String;
    } on PostgrestException catch (e) {
      if (e.code == '54000') {
        throw const AppException('وصلت للحد الأقصى من المنازل (5).');
      }
      throw const AppException('تعذّر إنشاء المنزل. حاول مجدداً.');
    } catch (_) {
      throw const AppException('تعذّر الاتصال. تحقق من الإنترنت وحاول مجدداً.');
    }
  }
}
