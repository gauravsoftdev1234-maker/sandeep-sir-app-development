import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/stat_tile.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/status_pill.dart';
import '../../shared/widgets/surface_card.dart';
import '../auth/auth_controller.dart';
import '../bookings/bookings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          FadeSlideIn(
            child: _ProfileHeader(
              name: user?.fullName ?? 'Partner',
              partnerId: user?.id,
              image: user?.profileImage,
              serviceSelected: auth.serviceSelected,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const FadeSlideIn(index: 1, child: _JobStats()),
          const SizedBox(height: AppSpacing.xl),
          const FadeSlideIn(index: 2, child: SectionHeader(title: 'Account')),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            index: 3,
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuRow(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => context.push(Routes.settings),
                  ),
                  const _MenuDivider(),
                  _MenuRow(
                    icon: Icons.work_outline_rounded,
                    label: 'My services',
                    onTap: () {},
                  ),
                  const _MenuDivider(),
                  _MenuRow(
                    icon: Icons.support_agent_outlined,
                    label: 'Help & support',
                    onTap: () {},
                  ),
                  const _MenuDivider(),
                  _MenuRow(
                    icon: Icons.info_outline_rounded,
                    label: 'About app',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'SevaHub Partner',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(
                        Icons.handyman_rounded,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FadeSlideIn(
            index: 4,
            child: _LogoutButton(onTap: () => _confirmLogout(context, ref)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need your password to sign back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout ?? false) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.serviceSelected,
    this.partnerId,
    this.image,
  });

  final String name;
  final bool serviceSelected;
  final int? partnerId;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasImage = image != null && image!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, AppColors.brandDeep, 0.65)!,
          ],
        ),
      ),
      child: Column(
        children: [
          PopIn(
            child: CircleAvatar(
              radius: 38,
              backgroundColor: scheme.onPrimary.withValues(alpha: 0.18),
              foregroundImage: hasImage ? NetworkImage(image!) : null,
              child: Icon(
                Icons.person_rounded,
                size: 38,
                color: scheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.onPrimary,
            ),
          ),
          if (partnerId != null) ...[
            const SizedBox(height: 2),
            Text(
              'Partner ID $partnerId',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          StatusPill(
            label: serviceSelected ? 'Verified partner' : 'Setup pending',
            tone: serviceSelected ? PillTone.positive : PillTone.pending,
            icon: serviceSelected
                ? Icons.verified_rounded
                : Icons.pending_outlined,
          ),
        ],
      ),
    );
  }
}

/// The partner's job tally, straight off the booking feed.
class _JobStats extends ConsumerWidget {
  const _JobStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(bookingFeedProvider).value;

    return Row(
      children: [
        Expanded(
          child: StatTile(
            value: feed?.upcomingCount.toString() ?? '--',
            label: 'Open jobs',
            icon: Icons.bolt_rounded,
            accent: AppColors.warning,
            onTap: () => context.go(Routes.jobs),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatTile(
            value: feed?.completedCount.toString() ?? '--',
            label: 'Completed',
            icon: Icons.check_circle_outline_rounded,
            accent: AppColors.success,
            onTap: () => context.go(Routes.jobs),
          ),
        ),
      ],
    );
  }
}

/// A soft-red pill, styled apart from the account menu so signing out reads
/// as a distinct, deliberate action.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.button);

    return Material(
      color: scheme.errorContainer.withValues(alpha: 0.5),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 18, color: scheme.error),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Log out',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        child: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
      ),
      title: Text(label),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}
