/// نماذج البيانات المحلية. كل نموذج يُحوَّل إلى JSON ويُحفظ على الجهاز.
int _seq = 0;
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_seq++).toRadixString(36)}';

DateTime? _dt(dynamic v) => v is String ? DateTime.tryParse(v) : null;
double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class StorageLocation {
  const StorageLocation({required this.id, required this.name, this.kind = 'other'});
  final String id;
  final String name;
  final String kind; // fridge | freezer | pantry | cabinet | other

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'kind': kind};
  factory StorageLocation.fromJson(Map<String, dynamic> j) => StorageLocation(
      id: j['id'] as String, name: j['name'] as String, kind: (j['kind'] as String?) ?? 'other');
}

class Product {
  const Product({
    required this.id,
    required this.name,
    this.category = '',
    this.locationId,
    this.unit = 'حبة',
    this.qty = 0,
    this.minQty = 0,
    this.expiry,
    this.barcode = '',
    this.price = 0,
  });

  final String id;
  final String name;
  final String category;
  final String? locationId;
  final String unit;
  final double qty;
  final double minQty;
  final DateTime? expiry;
  final String barcode;
  final double price; // سعر الوحدة

  /// الأيام المتبقية للصلاحية (سالب = منتهي). null إن لم يُحدَّد تاريخ.
  int? get daysLeft =>
      expiry == null ? null : dateOnly(expiry!).difference(dateOnly(DateTime.now())).inDays;
  bool get isExpired => (daysLeft ?? 1) < 0;
  bool get isLow => minQty > 0 && qty <= minQty;

  Product copyWith({
    String? name,
    String? category,
    Object? locationId = _keep,
    String? unit,
    double? qty,
    double? minQty,
    Object? expiry = _keep,
    String? barcode,
    double? price,
  }) =>
      Product(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        locationId: identical(locationId, _keep) ? this.locationId : locationId as String?,
        unit: unit ?? this.unit,
        qty: qty ?? this.qty,
        minQty: minQty ?? this.minQty,
        expiry: identical(expiry, _keep) ? this.expiry : expiry as DateTime?,
        barcode: barcode ?? this.barcode,
        price: price ?? this.price,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'locationId': locationId,
        'unit': unit,
        'qty': qty,
        'minQty': minQty,
        'expiry': expiry?.toIso8601String(),
        'barcode': barcode,
        'price': price,
      };
  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        category: (j['category'] as String?) ?? '',
        locationId: j['locationId'] as String?,
        unit: (j['unit'] as String?) ?? 'حبة',
        qty: _num(j['qty']),
        minQty: _num(j['minQty']),
        expiry: _dt(j['expiry']),
        barcode: (j['barcode'] as String?) ?? '',
        price: _num(j['price']),
      );
}

const _keep = Object();

/// حركة مخزون: add | consume | waste | adjust
class Movement {
  const Movement({
    required this.id,
    this.productId,
    required this.name,
    required this.delta,
    required this.reason,
    required this.at,
    this.value = 0,
    this.unit = '',
  });
  final String id;
  final String? productId;
  final String name;
  final double delta;
  final String reason;
  final DateTime at;
  final double value; // قيمة تقريبية بالعملة
  final String unit;

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'name': name,
        'delta': delta,
        'reason': reason,
        'at': at.toIso8601String(),
        'value': value,
        'unit': unit,
      };
  factory Movement.fromJson(Map<String, dynamic> j) => Movement(
        id: j['id'] as String,
        productId: j['productId'] as String?,
        name: j['name'] as String,
        delta: _num(j['delta']),
        reason: j['reason'] as String,
        at: _dt(j['at']) ?? DateTime.now(),
        value: _num(j['value']),
        unit: (j['unit'] as String?) ?? '',
      );
}

/// عنصر في قائمة المشتريات (period: daily | monthly)
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    this.qty = 1,
    this.price = 0,
    required this.period,
    this.done = false,
    this.doneAt,
  });
  final String id;
  final String name;
  final double qty;
  final double price; // سعر الوحدة
  final String period;
  final bool done;
  final DateTime? doneAt;
  double get total => qty * price;

  ShoppingItem copyWith({String? name, double? qty, double? price, bool? done, Object? doneAt = _keep}) =>
      ShoppingItem(
        id: id,
        name: name ?? this.name,
        qty: qty ?? this.qty,
        price: price ?? this.price,
        period: period,
        done: done ?? this.done,
        doneAt: identical(doneAt, _keep) ? this.doneAt : doneAt as DateTime?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'qty': qty,
        'price': price,
        'period': period,
        'done': done,
        'doneAt': doneAt?.toIso8601String(),
      };
  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
        id: j['id'] as String,
        name: j['name'] as String,
        qty: _num(j['qty']),
        price: _num(j['price']),
        period: (j['period'] as String?) ?? 'daily',
        done: (j['done'] as bool?) ?? false,
        doneAt: _dt(j['doneAt']),
      );
}

/// مصروف. source: shopping | invoice | manual
class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.date,
    this.store = '',
    required this.source,
    this.note = '',
    this.imagePath,
    this.refId,
  });
  final String id;
  final double amount;
  final DateTime date;
  final String store;
  final String source;
  final String note;
  final String? imagePath;
  final String? refId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'store': store,
        'source': source,
        'note': note,
        'imagePath': imagePath,
        'refId': refId,
      };
  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        amount: _num(j['amount']),
        date: _dt(j['date']) ?? DateTime.now(),
        store: (j['store'] as String?) ?? '',
        source: (j['source'] as String?) ?? 'manual',
        note: (j['note'] as String?) ?? '',
        imagePath: j['imagePath'] as String?,
        refId: j['refId'] as String?,
      );
}

class Note {
  const Note({required this.id, required this.text, required this.at, this.pinned = false});
  final String id;
  final String text;
  final DateTime at;
  final bool pinned;

  Note copyWith({String? text, bool? pinned}) =>
      Note(id: id, text: text ?? this.text, at: at, pinned: pinned ?? this.pinned);

  Map<String, dynamic> toJson() =>
      {'id': id, 'text': text, 'at': at.toIso8601String(), 'pinned': pinned};
  factory Note.fromJson(Map<String, dynamic> j) => Note(
      id: j['id'] as String,
      text: j['text'] as String,
      at: _dt(j['at']) ?? DateTime.now(),
      pinned: (j['pinned'] as bool?) ?? false);
}

class Reminder {
  const Reminder({required this.id, required this.title, required this.due, this.done = false});
  final String id;
  final String title;
  final DateTime due;
  final bool done;

  Reminder copyWith({String? title, DateTime? due, bool? done}) =>
      Reminder(id: id, title: title ?? this.title, due: due ?? this.due, done: done ?? this.done);

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'due': due.toIso8601String(), 'done': done};
  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
      id: j['id'] as String,
      title: j['title'] as String,
      due: _dt(j['due']) ?? DateTime.now(),
      done: (j['done'] as bool?) ?? false);
}

class PricePoint {
  const PricePoint(
      {required this.id,
      required this.item,
      required this.store,
      required this.price,
      required this.date});
  final String id;
  final String item;
  final String store;
  final double price;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'item': item,
        'store': store,
        'price': price,
        'date': date.toIso8601String(),
      };
  factory PricePoint.fromJson(Map<String, dynamic> j) => PricePoint(
        id: j['id'] as String,
        item: j['item'] as String,
        store: (j['store'] as String?) ?? '',
        price: _num(j['price']),
        date: _dt(j['date']) ?? DateTime.now(),
      );
}
