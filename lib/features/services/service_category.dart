import 'package:flutter/material.dart';

import '../../core/network/json_parse.dart';

/// The three buckets `serviceType` sorts categories into. The API sends a
/// single letter; anything unrecognised falls back to [other] rather than
/// dropping the category off the screen.
enum ServiceGroup {
  home('H', 'Home appliances', Icons.home_repair_service_rounded),
  technical('T', 'Technical', Icons.memory_rounded),
  sell('S', 'Sell & digital', Icons.storefront_rounded),
  other('', 'Other services', Icons.category_rounded);

  const ServiceGroup(this.code, this.label, this.icon);

  final String code;
  final String label;
  final IconData icon;

  static ServiceGroup fromCode(String code) {
    final normalised = code.trim().toUpperCase();
    for (final group in values) {
      if (group.code.isNotEmpty && group.code == normalised) return group;
    }
    return other;
  }
}

/// One row of `ServiceProviderCategory/getServiceCategory`.
@immutable
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.group,
    this.iconUrl = '',
    this.description,
  });

  final int id;
  final String name;
  final String subtitle;
  final ServiceGroup group;

  /// `categoryIcon` is empty for every row today, so the UI falls back to
  /// [icon]. Kept so artwork can be shown the moment the API supplies it.
  final String iconUrl;
  final String? description;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    // Several names come back with trailing spaces ("Refrigerator ").
    final name = asString(json['categoryName']).trim();
    return ServiceCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: name,
      subtitle: asString(json['subtitle']).trim(),
      group: ServiceGroup.fromCode(asString(json['serviceType'])),
      iconUrl: asString(json['categoryIcon']).trim(),
      description: json['description'] as String?,
    );
  }

  /// Local artwork keyed on the category name, since the API sends none.
  IconData get icon => _icons[name.toLowerCase()] ?? group.icon;

  static const Map<String, IconData> _icons = {
    'air conditioner': Icons.ac_unit_rounded,
    'refrigerator': Icons.kitchen_rounded,
    'water purifier': Icons.water_drop_rounded,
    'cooler': Icons.air_rounded,
    'geyser': Icons.hot_tub_rounded,
    'inverter': Icons.battery_charging_full_rounded,
    'microwave': Icons.microwave_rounded,
    'washing machine': Icons.local_laundry_service_rounded,
    'kitchen chimney': Icons.countertops_rounded,
    'electrician': Icons.electrical_services_rounded,
    'computer': Icons.desktop_windows_rounded,
    'laptop': Icons.laptop_rounded,
    'cctv': Icons.videocam_rounded,
    'printer': Icons.print_rounded,
    'ups': Icons.power_rounded,
    'website development': Icons.language_rounded,
    'app development': Icons.phone_iphone_rounded,
    'sell ewaste': Icons.recycling_rounded,
    'software': Icons.code_rounded,
    'support': Icons.support_agent_rounded,
    'data entry': Icons.keyboard_rounded,
  };
}

/// Artwork for a category named anywhere in the app, e.g. on a booking row
/// where only `categoryName` comes back.
IconData serviceIconFor(
  String categoryName, {
  IconData fallback = Icons.handyman_rounded,
}) => ServiceCategory._icons[categoryName.trim().toLowerCase()] ?? fallback;

/// Categories of one [ServiceGroup], ready to render as a titled section.
@immutable
class ServiceCategoryGroup {
  const ServiceCategoryGroup({required this.group, required this.categories});

  final ServiceGroup group;
  final List<ServiceCategory> categories;
}
