import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'selected_categories_store.dart';
import 'service_api.dart';
import 'service_category.dart';

/// The full catalogue, keyed on the token so a re-login refetches.
final serviceCategoriesProvider =
    FutureProvider.autoDispose<List<ServiceCategory>>((ref) async {
      final token = ref.watch(
        authProvider.select((state) => state.user?.appToken ?? ''),
      );
      if (token.isEmpty) return const [];
      return ref.watch(serviceApiProvider).getCategories(token);
    });

/// The catalogue bucketed by `serviceType`, in enum order, empty buckets
/// dropped.
final groupedServiceCategoriesProvider =
    FutureProvider.autoDispose<List<ServiceCategoryGroup>>((ref) async {
      final categories = await ref.watch(serviceCategoriesProvider.future);
      return groupByServiceType(categories);
    });

/// Ids the partner saved during onboarding, cached per user id.
class SelectedCategoryIds extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    final userId = ref.watch(authProvider.select((state) => state.user?.id));
    if (userId == null) return const {};
    return ref.read(selectedCategoriesStoreProvider).read(userId);
  }

  Future<void> save(Set<int> ids) async {
    final userId = ref.read(authProvider).user?.id;
    if (userId != null) {
      await ref.read(selectedCategoriesStoreProvider).write(userId, ids);
    }
    state = ids;
  }
}

final selectedCategoryIdsProvider =
    NotifierProvider<SelectedCategoryIds, Set<int>>(SelectedCategoryIds.new);

/// Buckets [categories] by `serviceType`, keeping [ServiceGroup] order.
List<ServiceCategoryGroup> groupByServiceType(
  List<ServiceCategory> categories,
) {
  return [
    for (final group in ServiceGroup.values)
      if (categories.any((category) => category.group == group))
        ServiceCategoryGroup(
          group: group,
          categories: categories
              .where((category) => category.group == group)
              .toList(),
        ),
  ];
}
