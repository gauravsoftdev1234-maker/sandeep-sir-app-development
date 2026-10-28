import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/status_pill.dart';
import '../services/service_category.dart';
import 'booking.dart';
import 'bookings_provider.dart';

enum _Tab { upcoming, completed, cancelled }

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  _Tab _tab = _Tab.upcoming;

  Future<void> _refresh() async {
    ref.invalidate(bookingFeedProvider);
    ref.invalidate(completedBookingsProvider);
    ref.invalidate(cancelledBookingsProvider);
    await ref.read(bookingFeedProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(bookingFeedProvider);
    final completed = ref.watch(completedBookingsProvider);
    final cancelled = ref.watch(cancelledBookingsProvider);

    // Counters come from the requests endpoint; fall back to list lengths.
    final upcomingCount =
        feed.value?.upcomingCount ?? feed.value?.bookings.length;
    final completedCount =
        feed.value?.completedCount ?? completed.value?.length;
    final cancelledCount = cancelled.value?.length;

    final visible = switch (_tab) {
      _Tab.upcoming => feed.whenData((value) => value.bookings),
      _Tab.completed => completed,
      _Tab.cancelled => cancelled,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('My jobs'),
        titleSpacing: AppSpacing.md,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search jobs',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter',
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.sm,
            ),
            // Scrolls sideways so long counts never overflow a narrow phone.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in _Tab.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          _label(
                            option,
                            upcomingCount,
                            completedCount,
                            cancelledCount,
                          ),
                        ),
                        selected: _tab == option,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => setState(() => _tab = option),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: visible.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ScrollableMessage(
                  child: EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load your jobs',
                    message: error is ApiException
                        ? error.message
                        : 'Pull down to try again.',
                  ),
                ),
                data: (bookings) => bookings.isEmpty
                    ? _ScrollableMessage(
                        child: EmptyState(
                          icon: Icons.assignment_outlined,
                          title: switch (_tab) {
                            _Tab.completed => 'Nothing finished yet',
                            _Tab.cancelled => 'No cancelled jobs',
                            _Tab.upcoming => 'No open requests',
                          },
                          message: 'New jobs will show up here.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          AppSpacing.sm,
                          AppSpacing.page,
                          AppSpacing.xxl,
                        ),
                        itemCount: bookings.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) => FadeSlideIn(
                          // Keyed on the booking so a tab switch replays the
                          // entrance rather than reusing the old state.
                          key: ValueKey('${_tab.name}-${bookings[index].id}'),
                          index: index,
                          child: BookingRow(booking: bookings[index]),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(
    _Tab tab,
    int? upcoming,
    int? completed,
    int? cancelled,
  ) => switch (tab) {
    _Tab.upcoming => upcoming == null ? 'Upcoming' : 'Upcoming $upcoming',
    _Tab.completed => completed == null ? 'Completed' : 'Completed $completed',
    _Tab.cancelled => cancelled == null ? 'Cancelled' : 'Cancelled $cancelled',
  };
}

/// How each `orderStatus` reads on a pill, shared by the row and the detail
/// screen.
extension BookingStatusStyle on BookingStatus {
  PillTone get tone => switch (this) {
    BookingStatus.submitted => PillTone.pending,
    BookingStatus.accepted => PillTone.info,
    BookingStatus.completed => PillTone.positive,
    BookingStatus.cancelled => PillTone.negative,
    BookingStatus.unknown => PillTone.neutral,
  };

  IconData get icon => switch (this) {
    BookingStatus.submitted => Icons.schedule_rounded,
    BookingStatus.accepted => Icons.how_to_reg_rounded,
    BookingStatus.completed => Icons.check_rounded,
    BookingStatus.cancelled => Icons.close_rounded,
    BookingStatus.unknown => Icons.help_outline_rounded,
  };
}

/// A booking as a tappable row: service, customer, city and status.
class BookingRow extends StatelessWidget {
  const BookingRow({required this.booking, super.key});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.push(Routes.jobDetail('${booking.id}')),
        borderRadius: BorderRadius.circular(AppRadius.field),
        splashColor: scheme.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Icon(
                  serviceIconFor(booking.categoryName),
                  size: 20,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.subCategoryName.isEmpty
                          ? booking.categoryName
                          : booking.subCategoryName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '#JOB-${booking.id}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _MetaLine(
                      icon: Icons.location_on_outlined,
                      text: [
                        booking.userName,
                        booking.cityName,
                      ].where((part) => part.isNotEmpty).join(' · '),
                    ),
                    const SizedBox(height: 2),
                    _MetaLine(
                      icon: Icons.calendar_today_outlined,
                      text: booking.createdLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusPill(
                    label: booking.status.label,
                    tone: booking.status.tone,
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps a message pull-to-refreshable, which a bare [Center] is not.
/// A small icon-prefixed metadata line: customer/city or the created date.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 12, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: constraints.maxHeight, child: child),
      ),
    );
  }
}
