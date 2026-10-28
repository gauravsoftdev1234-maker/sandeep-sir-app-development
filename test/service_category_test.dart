import 'package:flutter_test/flutter_test.dart';
import 'package:partner_app/features/services/service_categories_provider.dart';
import 'package:partner_app/features/services/service_category.dart';

Map<String, dynamic> _row(int id, String name, String type) => {
  'id': id,
  'categoryName': name,
  'subtitle': 'General Services',
  'categoryIcon': '',
  'serviceType': type,
  'description': null,
};

void main() {
  test('trims names the API pads', () {
    final category = ServiceCategory.fromJson(_row(2, 'Refrigerator ', 'H'));

    expect(category.name, 'Refrigerator');
    expect(category.group, ServiceGroup.home);
  });

  test('maps serviceType letters, falling back to other', () {
    expect(ServiceGroup.fromCode('H'), ServiceGroup.home);
    expect(ServiceGroup.fromCode('t'), ServiceGroup.technical);
    expect(ServiceGroup.fromCode('S'), ServiceGroup.sell);
    expect(ServiceGroup.fromCode('X'), ServiceGroup.other);
    expect(ServiceGroup.fromCode(''), ServiceGroup.other);
  });

  test('groups by serviceType and drops empty buckets', () {
    final groups = groupByServiceType([
      ServiceCategory.fromJson(_row(1, 'Air Conditioner', 'H')),
      ServiceCategory.fromJson(_row(9, 'Laptop', 'T')),
      ServiceCategory.fromJson(_row(19, 'Washing Machine', 'H')),
    ]);

    expect(groups.map((group) => group.group).toList(), [
      ServiceGroup.home,
      ServiceGroup.technical,
    ]);
    expect(groups.first.categories.map((c) => c.name).toList(), [
      'Air Conditioner',
      'Washing Machine',
    ]);
  });
}
