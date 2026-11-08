import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mawoonati/core/data/models.dart';
import 'package:mawoonati/core/settings/settings_provider.dart';

/// كل بيانات المستخدم المحلية في وثيقة واحدة تُحفظ في SharedPreferences.
class AppData {
  const AppData({
    this.locations = const [],
    this.products = const [],
    this.movements = const [],
    this.shopping = const [],
    this.expenses = const [],
    this.notes = const [],
    this.reminders = const [],
    this.prices = const [],
    this.meals = const {},
    this.budget = 0,
    this.geminiKey = '',
    this.geminiModel = 'gemini-flash-latest',
  });

  final List<StorageLocation> locations;
  final List<Product> products;
  final List<Movement> movements;
  final List<ShoppingItem> shopping;
  final List<Expense> expenses;
  final List<Note> notes;
  final List<Reminder> reminders;
  final List<PricePoint> prices;
  final Map<String, String> meals;
  final double budget;
  final String geminiKey;
  final String geminiModel;

  factory AppData.initial() => AppData(locations: const [
        StorageLocation(id: 'loc_fridge', name: 'الثلاجة', kind: 'fridge'),
        StorageLocation(id: 'loc_freezer', name: 'الفريزر', kind: 'freezer'),
        StorageLocation(id: 'loc_pantry', name: 'المخزن', kind: 'pantry'),
      ]);

  AppData copyWith({
    List<StorageLocation>? locations,
    List<Product>? products,
    List<Movement>? movements,
    List<ShoppingItem>? shopping,
    List<Expense>? expenses,
    List<Note>? notes,
    List<Reminder>? reminders,
    List<PricePoint>? prices,
    Map<String, String>? meals,
    double? budget,
    String? geminiKey,
    String? geminiModel,
  }) =>
      AppData(
        locations: locations ?? this.locations,
        products: products ?? this.products,
        movements: movements ?? this.movements,
        shopping: shopping ?? this.shopping,
        expenses: expenses ?? this.expenses,
        notes: notes ?? this.notes,
        reminders: reminders ?? this.reminders,
        prices: prices ?? this.prices,
        meals: meals ?? this.meals,
        budget: budget ?? this.budget,
        geminiKey: geminiKey ?? this.geminiKey,
        geminiModel: geminiModel ?? this.geminiModel,
      );

  Map<String, dynamic> toJson() => {
        'v': 1,
        'locations': [for (final x in locations) x.toJson()],
        'products': [for (final x in products) x.toJson()],
        'movements': [for (final x in movements) x.toJson()],
        'shopping': [for (final x in shopping) x.toJson()],
        'expenses': [for (final x in expenses) x.toJson()],
        'notes': [for (final x in notes) x.toJson()],
        'reminders': [for (final x in reminders) x.toJson()],
        'prices': [for (final x in prices) x.toJson()],
        'meals': meals,
        'budget': budget,
        'geminiKey': geminiKey,
        'geminiModel': geminiModel,
      };

  static List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
      [for (final e in (v as List? ?? const [])) f(Map<String, dynamic>.from(e as Map))];

  factory AppData.fromJson(Map<String, dynamic> j) => AppData(
        locations: _list(j['locations'], StorageLocation.fromJson),
        products: _list(j['products'], Product.fromJson),
        movements: _list(j['movements'], Movement.fromJson),
        shopping: _list(j['shopping'], ShoppingItem.fromJson),
        expenses: _list(j['expenses'], Expense.fromJson),
        notes: _list(j['notes'], Note.fromJson),
        reminders: _list(j['reminders'], Reminder.fromJson),
        prices: _list(j['prices'], PricePoint.fromJson),
        meals: {
          for (final e in ((j['meals'] as Map?) ?? const {}).entries)
            e.key.toString(): e.value.toString()
        },
        budget: (j['budget'] as num?)?.toDouble() ?? 0,
        geminiKey: (j['geminiKey'] as String?) ?? '',
        geminiModel: (j['geminiModel'] as String?) ?? 'gemini-flash-latest',
      );

  // ---------- مشتقات ----------
  double spentInMonth(DateTime month) => expenses
      .where((e) => e.date.year == month.year && e.date.month == month.month)
      .fold(0.0, (a, e) => a + e.amount);

  List<Product> get expiringSoon => products
      .where((p) => p.qty > 0 && p.daysLeft != null && p.daysLeft! >= 0 && p.daysLeft! <= 3)
      .toList()
    ..sort((a, b) => a.daysLeft!.compareTo(b.daysLeft!));
  List<Product> get expired => products.where((p) => p.qty > 0 && p.isExpired).toList();
  List<Product> get lowStock => products.where((p) => p.isLow && !p.isExpired).toList();
  List<Reminder> get dueReminders => reminders
      .where((r) => !r.done && !dateOnly(r.due).isAfter(dateOnly(DateTime.now())))
      .toList()
    ..sort((a, b) => a.due.compareTo(b.due));
}

class DataNotifier extends Notifier<AppData> {
  static const _key = 'db_v1';

  @override
  AppData build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_key);
    if (raw != null) {
      try {
        return AppData.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {
        // بيانات تالفة: نبدأ من جديد بدل أن ينهار التطبيق.
      }
    }
    return AppData.initial();
  }

  void _set(AppData d) {
    state = d;
    ref.read(sharedPrefsProvider).setString(_key, jsonEncode(d.toJson()));
  }

  List<T> _upsert<T>(List<T> list, T item, String Function(T) id) {
    final i = list.indexWhere((x) => id(x) == id(item));
    return i < 0 ? [...list, item] : ([...list]..[i] = item);
  }

  // ---------- أماكن التخزين ----------
  void saveLocation(StorageLocation l) =>
      _set(state.copyWith(locations: _upsert(state.locations, l, (x) => x.id)));

  void deleteLocation(String id) => _set(state.copyWith(
        locations: state.locations.where((l) => l.id != id).toList(),
        products: [
          for (final p in state.products) p.locationId == id ? p.copyWith(locationId: null) : p
        ],
      ));

  // ---------- المنتجات ----------
  void saveProduct(Product p) {
    final isNew = !state.products.any((x) => x.id == p.id);
    var d = state.copyWith(products: _upsert(state.products, p, (x) => x.id));
    if (isNew && p.qty > 0) {
      d = d.copyWith(movements: [
        ...d.movements,
        Movement(
            id: newId(),
            productId: p.id,
            name: p.name,
            delta: p.qty,
            reason: 'add',
            at: DateTime.now(),
            value: p.price * p.qty,
            unit: p.unit),
      ]);
    }
    _set(d);
  }

  void deleteProduct(String id) =>
      _set(state.copyWith(products: state.products.where((p) => p.id != id).toList()));

  /// تغيير الكمية وتسجيل حركة. reason: add | consume | waste | adjust
  void adjust(Product p, double delta, String reason) {
    final newQty = (p.qty + delta) < 0 ? 0.0 : p.qty + delta;
    final applied = newQty - p.qty;
    if (applied == 0) return;
    _set(state.copyWith(
      products: [for (final x in state.products) x.id == p.id ? p.copyWith(qty: newQty) : x],
      movements: [
        ...state.movements,
        Movement(
            id: newId(),
            productId: p.id,
            name: p.name,
            delta: applied,
            reason: reason,
            at: DateTime.now(),
            value: p.price * applied.abs(),
            unit: p.unit),
      ],
    ));
  }

  Product? productByBarcode(String code) {
    for (final p in state.products) {
      if (p.barcode.isNotEmpty && p.barcode == code) return p;
    }
    return null;
  }

  // ---------- المشتريات ----------
  void saveShopping(ShoppingItem s) =>
      _set(state.copyWith(shopping: _upsert(state.shopping, s, (x) => x.id)));

  void deleteShopping(String id) =>
      _set(state.copyWith(shopping: state.shopping.where((s) => s.id != id).toList()));

  void clearBought(String period) => _set(state.copyWith(
      shopping: state.shopping.where((s) => !(s.period == period && s.done)).toList()));

  /// شراء عنصر: يسجّل مصروفاً (إن وُجد سعر) ويضيفه للمخزون اختيارياً.
  void markBought(ShoppingItem s, {required bool addToInventory}) {
    final now = DateTime.now();
    final d = state.copyWith(
      shopping: [
        for (final x in state.shopping) x.id == s.id ? s.copyWith(done: true, doneAt: now) : x
      ],
      expenses: s.total > 0
          ? [
              ...state.expenses,
              Expense(
                  id: newId(),
                  amount: s.total,
                  date: now,
                  source: 'shopping',
                  note: s.name,
                  refId: s.id),
            ]
          : state.expenses,
    );
    _set(d);
    if (addToInventory) {
      final existing = state.products.where((p) => p.name.trim() == s.name.trim()).toList();
      if (existing.isNotEmpty) {
        adjust(existing.first, s.qty, 'add');
      } else {
        saveProduct(Product(id: newId(), name: s.name, qty: s.qty, price: s.price));
      }
    }
  }

  void unmarkBought(ShoppingItem s) => _set(state.copyWith(
        shopping: [
          for (final x in state.shopping) x.id == s.id ? s.copyWith(done: false, doneAt: null) : x
        ],
        expenses: state.expenses.where((e) => e.refId != s.id).toList(),
      ));

  // ---------- المصاريف ----------
  void saveExpense(Expense e) =>
      _set(state.copyWith(expenses: _upsert(state.expenses, e, (x) => x.id)));

  void deleteExpense(String id) =>
      _set(state.copyWith(expenses: state.expenses.where((e) => e.id != id).toList()));

  void setBudget(double v) => _set(state.copyWith(budget: v));

  // ---------- الملاحظات والتذكيرات ----------
  void saveNote(Note n) => _set(state.copyWith(notes: _upsert(state.notes, n, (x) => x.id)));
  void deleteNote(String id) =>
      _set(state.copyWith(notes: state.notes.where((n) => n.id != id).toList()));

  void saveReminder(Reminder r) =>
      _set(state.copyWith(reminders: _upsert(state.reminders, r, (x) => x.id)));
  void deleteReminder(String id) =>
      _set(state.copyWith(reminders: state.reminders.where((r) => r.id != id).toList()));

  // ---------- الأسعار ----------
  void addPrices(List<PricePoint> pts) => _set(state.copyWith(prices: [...state.prices, ...pts]));
  void deletePrice(String id) =>
      _set(state.copyWith(prices: state.prices.where((p) => p.id != id).toList()));

  // ---------- الوجبات والإعدادات ----------
  void setMeal(String key, String text) {
    final m = Map<String, String>.from(state.meals);
    if (text.trim().isEmpty) {
      m.remove(key);
    } else {
      m[key] = text.trim();
    }
    _set(state.copyWith(meals: m));
  }

  void setMeals(Map<String, String> entries) =>
      _set(state.copyWith(meals: {...state.meals, ...entries}));

  void setGemini({required String key, required String model}) => _set(state.copyWith(
      geminiKey: key.trim(), geminiModel: model.trim().isEmpty ? 'gemini-flash-latest' : model.trim()));

  // ---------- نسخ احتياطي ----------
  String exportJson() => const JsonEncoder.withIndent(' ').convert(state.toJson());

  /// يرجع true عند النجاح.
  bool importJson(String text) {
    try {
      final j = jsonDecode(text);
      if (j is! Map) return false;
      _set(AppData.fromJson(Map<String, dynamic>.from(j)));
      return true;
    } catch (_) {
      return false;
    }
  }

  void resetAll() => _set(AppData.initial());
}

final dataProvider = NotifierProvider<DataNotifier, AppData>(DataNotifier.new);
