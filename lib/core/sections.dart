import 'package:flutter/material.dart';

/// أسماء المراحل حسب خطة المشروع.
const phaseNames = <int, String>{
  1: 'التأسيس والتصميم',
  2: 'الحسابات وقاعدة البيانات',
  3: 'المخزون',
  4: 'الباركود والفواتير',
  5: 'المشتريات والميزانية',
  6: 'التنبيهات والملاحظات',
  7: 'الذكاء الاصطناعي',
  8: 'العائلة والمزامنة',
  9: 'الاختبارات والإطلاق',
};

class AppSection {
  const AppSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.group,
    required this.phase,
    this.route,
  });

  final String id;
  final String title;
  final IconData icon;
  final String group;
  final int phase;

  /// مسار الشاشة الحقيقية إن كانت منفذة؛ وإلا تُفتح شاشة "تتوفر في المرحلة X".
  final String? route;

  bool get isBuilt => route != null;
  String get path => route ?? '/coming/$id';
}

const sections = <AppSection>[
  // المخزون
  AppSection(id: 'barcode', title: 'ماسح الباركود', icon: Icons.qr_code_scanner, group: 'المخزون', phase: 4),
  AppSection(id: 'consumption', title: 'سجل الاستهلاك', icon: Icons.history, group: 'المخزون', phase: 3),
  AppSection(id: 'storage', title: 'أماكن التخزين', icon: Icons.kitchen_outlined, group: 'المخزون', phase: 3),
  // المشتريات والمال
  AppSection(id: 'invoices', title: 'تصوير الفواتير', icon: Icons.photo_camera_outlined, group: 'المشتريات والمال', phase: 4),
  AppSection(id: 'daily', title: 'المشتريات اليومية', icon: Icons.shopping_cart_outlined, group: 'المشتريات والمال', phase: 5),
  AppSection(id: 'monthly', title: 'المشتريات الشهرية', icon: Icons.calendar_month_outlined, group: 'المشتريات والمال', phase: 5),
  AppSection(id: 'budget', title: 'الميزانية', icon: Icons.account_balance_wallet_outlined, group: 'المشتريات والمال', phase: 5),
  AppSection(id: 'reports', title: 'التقارير والإحصائيات', icon: Icons.pie_chart_outline, group: 'المشتريات والمال', phase: 5),
  AppSection(id: 'prices', title: 'مقارنة الأسعار', icon: Icons.price_change_outlined, group: 'المشتريات والمال', phase: 5),
  // الملاحظات والتنبيهات
  AppSection(id: 'notes', title: 'الملاحظات', icon: Icons.edit_note, group: 'الملاحظات والتذكير', phase: 6),
  AppSection(id: 'reminders', title: 'التذكيرات', icon: Icons.alarm, group: 'الملاحظات والتذكير', phase: 6),
  AppSection(id: 'waste', title: 'سجل الهدر', icon: Icons.delete_outline, group: 'الملاحظات والتذكير', phase: 6),
  // الذكاء
  AppSection(id: 'recipes', title: 'مساعد الوصفات الذكي', icon: Icons.psychology_outlined, group: 'الذكاء الاصطناعي', phase: 7),
  AppSection(id: 'mealplanner', title: 'مخطط الوجبات', icon: Icons.restaurant_menu, group: 'الذكاء الاصطناعي', phase: 7),
  // العائلة والنظام
  AppSection(id: 'family', title: 'أفراد العائلة', icon: Icons.groups_outlined, group: 'العائلة والنظام', phase: 8),
  AppSection(id: 'backup', title: 'النسخ الاحتياطي والاستعادة', icon: Icons.cloud_upload_outlined, group: 'العائلة والنظام', phase: 8),
  AppSection(id: 'settings', title: 'إعدادات التطبيق', icon: Icons.settings_outlined, group: 'العائلة والنظام', phase: 1, route: '/settings'),
];

AppSection sectionById(String id) => sections.firstWhere((s) => s.id == id);

/// ترتيب اختصارات الرئيسية. في RTL يبدأ الصف الأول من اليمين، مطابقاً للصورة.
const quickActionIds = ['daily', 'barcode', 'invoices', 'monthly', 'reports', 'notes'];
