import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/status_pill.dart';
import '../../shared/widgets/surface_card.dart';
import '../../shared/widgets/celebration_dialog.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/loading_label.dart';
import '../auth/auth_controller.dart';
import '../services/service_category.dart';
import 'booking.dart';
import 'booking_api.dart';
import 'bookings_provider.dart';
import 'jobs_screen.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _busy = false;

  /// Takes the job: `updateServiceRequestStatus` with "A", then reloads the
  /// feeds so the row shows its new status.
  Future<void> _accept(Booking booking) async {
    if (_busy) return;
    setState(() => _busy = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final auth = ref.read(authProvider);
      await ref
          .read(bookingApiProvider)
          .updateRequestStatus(
            appToken: auth.user?.appToken ?? '',
            serviceRequestId: booking.id,
            status: BookingStatus.accepted,
            servicePartnerId: auth.user?.id ?? 0,
          );

      ref.invalidate(bookingFeedProvider);
      ref.invalidate(completedBookingsProvider);
      ref.invalidate(bookingByIdProvider(booking.id));

      if (!mounted) return;
      // Drop the spinner before the dialog, or the button keeps spinning
      // behind it until the dialog is dismissed.
      setState(() => _busy = false);
      await showCelebrationDialog(
        context,
        title: 'Job accepted',
        message:
            '${booking.subCategoryName.isEmpty ? booking.categoryName : booking.subCategoryName} '
            'for ${booking.userName} is yours now.',
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(widget.bookingId) ?? 0;
    final booking = ref.watch(bookingByIdProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
      body: booking.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load this job',
          message: error is ApiException ? error.message : 'Please try again.',
        ),
        data: (value) => value == null
            ? const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Job not found',
                message: 'It is no longer in your list.',
              )
            : _Details(
                booking: value,
                busy: _busy,
                onAccept: () => _accept(value),
              ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.booking,
    required this.busy,
    required this.onAccept,
  });

  final Booking booking;
  final bool busy;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = booking.status == BookingStatus.completed;

    // Built as a list of blocks so each one can arrive in sequence.
    final blocks = <Widget>[
      SurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: done
                        ? scheme.secondaryContainer
                        : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: Icon(
                    serviceIconFor(booking.categoryName),
                    color: done
                        ? scheme.onSecondaryContainer
                        : scheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                StatusPill(
                  label: booking.status.label,
                  tone: booking.status.tone,
                  icon: booking.status.icon,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              booking.subCategoryName.isEmpty
                  ? booking.categoryName
                  : booking.subCategoryName,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(booking.categoryName, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
      if (booking.requirementDetail.isNotEmpty)
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Requirement', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                booking.requirementDetail,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      SurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (final row in [
              (Icons.tag_rounded, 'Job ID', '#${booking.id}'),
              (Icons.person_outline_rounded, 'Customer', booking.userName),
              (Icons.call_outlined, 'Mobile', booking.mobileNumber),
              (Icons.location_on_outlined, 'City', booking.cityName),
              (Icons.schedule_rounded, 'Created', booking.createdLabel),
            ])
              if (row.$3.isNotEmpty) ...[
                _DetailRow(icon: row.$1, label: row.$2, value: row.$3),
                Divider(height: 1, color: scheme.outlineVariant),
              ],
            _DetailRow(
              icon: Icons.flag_outlined,
              label: 'Status',
              value: booking.status.label,
            ),
          ],
        ),
      ),
      if (booking.status == BookingStatus.submitted)
        FilledButton(
          onPressed: busy ? null : onAccept,
          child: LoadingLabel(busy: busy, label: 'Accept job'),
        ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      itemCount: blocks.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) =>
          FadeSlideIn(index: index, child: blocks[index]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
