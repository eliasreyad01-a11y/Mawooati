import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawoonati/core/data/app_data.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/settings/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _c([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(p)]);
}

void main() {
  test('starts with default storage locations', () async {
    final c = await _c();
    expect(c.read(dataProvider).locations.length, 3);
  });

  test('adding a product logs an add movement; consume reduces qty and never below 0', () async {
    final c = await _c();
    final n = c.read(dataProvider.notifier);
    final p = Product(id: 'p1', name: 'حليب', qty: 2, price: 1.5);
    n.saveProduct(p);
    expect(c.read(dataProvider).movements.single.reason, 'add');
    n.adjust(c.read(dataProvider).products.first, -1, 'consume');
    expect(c.read(dataProvider).products.first.qty, 1);
    n.adjust(c.read(dataProvider).products.first, -5, 'waste');
    final after = c.read(dataProvider);
    expect(after.products.first.qty, 0);
    final waste = after.movements.last;
    expect(waste.reason, 'waste');
    expect(waste.delta, -1);
    expect(waste.value, 1.5);
  });

  test('marking a shopping item bought records an expense and updates inventory', () async {
    final c = await _c();
    final n = c.read(dataProvider.notifier);
    n.saveProduct(const Product(id: 'p1', name: 'رز', qty: 1));
    final item = ShoppingItem(id: 's1', name: 'رز', qty: 2, price: 3, period: 'daily');
    n.saveShopping(item);
    n.markBought(item, addToInventory: true);
    var d = c.read(dataProvider);
    expect(d.shopping.single.done, isTrue);
    expect(d.expenses.single.amount, 6);
    expect(d.products.single.qty, 3);
    expect(d.spentInMonth(DateTime.now()), 6);
    n.unmarkBought(d.shopping.single);
    d = c.read(dataProvider);
    expect(d.shopping.single.done, isFalse);
    expect(d.expenses, isEmpty);
  });

  test('expiry helpers', () async {
    final c = await _c();
    final n = c.read(dataProvider.notifier);
    final today = DateTime.now();
    n.saveProduct(Product(id: 'a', name: 'منتهي', qty: 1, expiry: today.subtract(const Duration(days: 2))));
    n.saveProduct(Product(id: 'b', name: 'قريب', qty: 1, expiry: today.add(const Duration(days: 2))));
    n.saveProduct(Product(id: 'c', name: 'بعيد', qty: 1, expiry: today.add(const Duration(days: 30))));
    n.saveProduct(const Product(id: 'd', name: 'ناقص', qty: 1, minQty: 2));
    final d = c.read(dataProvider);
    expect(d.expired.map((p) => p.id), ['a']);
    expect(d.expiringSoon.map((p) => p.id), ['b']);
    expect(d.lowStock.map((p) => p.id), ['d']);
  });

  test('data persists across containers and export/import round-trips', () async {
    final c = await _c();
    final n = c.read(dataProvider.notifier);
    n.saveProduct(const Product(id: 'p1', name: 'سكر', qty: 4, unit: 'كغم'));
    n.setBudget(250);
    n.saveNote(Note(id: 'n1', text: 'اشتر خبز', at: DateTime(2026, 1, 1)));
    final json = n.exportJson();

    final prefs = await SharedPreferences.getInstance();
    final c2 = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    expect(c2.read(dataProvider).products.single.name, 'سكر');
    expect(c2.read(dataProvider).budget, 250);

    final c3 = await _c();
    expect(c3.read(dataProvider.notifier).importJson('not json'), isFalse);
    expect(c3.read(dataProvider.notifier).importJson(json), isTrue);
    expect(c3.read(dataProvider).notes.single.text, 'اشتر خبز');
    c3.read(dataProvider.notifier).resetAll();
    expect(c3.read(dataProvider).products, isEmpty);
  });

  test('deleting a location keeps its products without a location', () async {
    final c = await _c();
    final n = c.read(dataProvider.notifier);
    n.saveProduct(const Product(id: 'p1', name: 'جبنة', qty: 1, locationId: 'loc_fridge'));
    n.deleteLocation('loc_fridge');
    expect(c.read(dataProvider).products.single.locationId, isNull);
  });
}
