import 'package:flutter/material.dart';
import 'package:mawoonati/core/theme/app_colors.dart';
import 'package:mawoonati/core/theme/app_spacing.dart';

enum FieldKind { text, number, multiline, date, choice }

class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.kind = FieldKind.text,
    this.options = const [],
    this.initial = '',
    this.required = false,
  });
  final String key;
  final String label;
  final FieldKind kind;
  final List<String> options;
  final String initial;
  final bool required;
}

String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// نموذج إدخال عام في ورقة سفلية. يرجع القيم نصاً لكل مفتاح، أو null عند الإلغاء.
Future<Map<String, String>?> showForm(
  BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
  String submitLabel = 'حفظ',
}) {
  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FormBody(title: title, fields: fields, submitLabel: submitLabel),
  );
}

class _FormBody extends StatefulWidget {
  const _FormBody({required this.title, required this.fields, required this.submitLabel});
  final String title;
  final List<FieldSpec> fields;
  final String submitLabel;

  @override
  State<_FormBody> createState() => _FormBodyState();
}

class _FormBodyState extends State<_FormBody> {
  final _values = <String, String>{};
  final _controllers = <String, TextEditingController>{};
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      _values[f.key] = f.initial;
      if (f.kind == FieldKind.text || f.kind == FieldKind.number || f.kind == FieldKind.multiline) {
        _controllers[f.key] = TextEditingController(text: f.initial);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(FieldSpec f) async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_values[f.key] ?? '') ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _values[f.key] = fmtDate(picked));
  }

  void _submit() {
    for (final f in widget.fields) {
      final c = _controllers[f.key];
      if (c != null) _values[f.key] = c.text.trim();
      if (f.required && (_values[f.key] ?? '').isEmpty) {
        setState(() => _error = 'الحقل "${f.label}" مطلوب');
        return;
      }
      if (f.kind == FieldKind.number && (_values[f.key] ?? '').isNotEmpty) {
        if (double.tryParse(_toLatin(_values[f.key]!)) == null) {
          setState(() => _error = 'الحقل "${f.label}" يجب أن يكون رقماً');
          return;
        }
      }
    }
    Navigator.pop(context, Map<String, String>.from(_values));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.md),
            for (final f in widget.fields) ...[_field(f), const SizedBox(height: 12)],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ),
            FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
          ],
        ),
      ),
    );
  }

  Widget _field(FieldSpec f) {
    switch (f.kind) {
      case FieldKind.date:
        final v = _values[f.key] ?? '';
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(f),
                icon: const Icon(Icons.event),
                label: Text(v.isEmpty ? f.label : '${f.label}: $v'),
              ),
            ),
            if (v.isNotEmpty && !f.required)
              IconButton(
                tooltip: 'مسح',
                onPressed: () => setState(() => _values[f.key] = ''),
                icon: const Icon(Icons.clear),
              ),
          ],
        );
      case FieldKind.choice:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final o in f.options)
                  ChoiceChip(
                    label: Text(o),
                    selected: _values[f.key] == o,
                    onSelected: (_) => setState(() => _values[f.key] = o),
                  ),
              ],
            ),
          ],
        );
      case FieldKind.number:
        return TextField(
          controller: _controllers[f.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: f.label),
        );
      case FieldKind.multiline:
        return TextField(
          controller: _controllers[f.key],
          minLines: 3,
          maxLines: 8,
          decoration: InputDecoration(labelText: f.label),
        );
      case FieldKind.text:
        return TextField(
          controller: _controllers[f.key],
          decoration: InputDecoration(labelText: f.label),
        );
    }
  }
}

/// يحوّل الأرقام العربية-الهندية إلى لاتينية ويستبدل الفاصلة العربية.
String _toLatin(String s) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final ch in s.runes) {
    final c = String.fromCharCode(ch);
    final i = ar.indexOf(c);
    b.write(i >= 0 ? '$i' : (c == '٫' || c == ',' ? '.' : c));
  }
  return b.toString();
}

double parseNum(String? s, [double fallback = 0]) =>
    double.tryParse(_toLatin((s ?? '').trim())) ?? fallback;

Future<bool> confirm(BuildContext context, String message, {String yes = 'نعم'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(yes)),
      ],
    ),
  );
  return r ?? false;
}

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
