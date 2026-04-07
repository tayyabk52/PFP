import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/profile_provider.dart';

class VerificationStatusPage extends ConsumerStatefulWidget {
  const VerificationStatusPage({super.key});

  @override
  ConsumerState<VerificationStatusPage> createState() => _VerificationStatusPageState();
}

class _VerificationStatusPageState extends ConsumerState<VerificationStatusPage> {
  Future<void> _onRefresh() async {
    ref.invalidate(sellerApplicationProvider);
    ref.invalidate(currentProfileProvider);
    // Wait for the provider to re-resolve
    await ref.read(sellerApplicationProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(sellerApplicationProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: appAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (_, __) => _buildError(),
            data: (app) {
              if (app == null) {
                final profileRole = ref.watch(currentProfileProvider).valueOrNull?['role'];
                if (profileRole == 'seller') {
                  return _buildRefreshable(
                    _buildContent({
                      'status': 'Approved',
                      'submitted_at': null,
                      'rejection_reason': null,
                    }),
                  );
                }
                return _buildRefreshable(_buildNoApplication());
              }
              return _buildRefreshable(_buildContent(app));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshable(Widget child) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: child,
    );
  }

  Widget _buildContent(Map<String, dynamic> app) {
    final status = (app['status'] as String?) ?? 'Pending';
    final submittedAt = app['submitted_at'] != null
        ? DateTime.tryParse(app['submitted_at'] as String)
        : null;
    final rejectionReason = app['rejection_reason'] as String?;
    final profileRole = ref.watch(currentProfileProvider).valueOrNull?['role'] as String?;
    final isApproved = status == 'Approved' || profileRole == 'seller';
    final isRejected = status == 'Rejected';

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;

        // Responsive metrics
        final isMobile = screenW < 600;
        final isWideDesktop = screenW > 900;

        final hPad = isMobile ? 24.0 : isWideDesktop ? 64.0 : 40.0;
        final topPad = isMobile ? 36.0 : isWideDesktop ? 72.0 : 52.0;
        final bottomPad = isMobile ? 100.0 : 72.0;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, bottomPad),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(
                    status,
                    isApproved,
                    isRejected,
                    isMobile: isMobile,
                  ),
                  SizedBox(height: isMobile ? 40 : 56),
                  // Switch to two-column at 720px of content area
                  LayoutBuilder(
                    builder: (context, inner) {
                      if (inner.maxWidth >= 720) {
                        return _buildDesktopLayout(
                          app, status, submittedAt, rejectionReason,
                          isApproved: isApproved,
                          isRejected: isRejected,
                        );
                      }
                      return _buildMobileLayout(
                        app, status, submittedAt, rejectionReason,
                        isApproved: isApproved,
                        isRejected: isRejected,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildPageHeader(
    String status,
    bool isApproved,
    bool isRejected, {
    required bool isMobile,
  }) {
    final titleSize = isMobile ? 30.0 : 44.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eyebrow chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF5a4000).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 13, color: Color(0xFF5d4201)),
              const SizedBox(width: 6),
              Text(
                'SELLER VERIFICATION',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                  color: const Color(0xFF5d4201),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isApproved
              ? 'Verification Complete'
              : isRejected
                  ? 'Application Rejected'
                  : 'Verification in Progress',
          style: GoogleFonts.notoSerif(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Text(
            isApproved
                ? 'Congratulations — your credentials have been verified. You can now list fragrances on the Archive.'
                : isRejected
                    ? 'Your application was not approved. Please review the notes below and resubmit when ready.'
                    : 'Your credentials are being meticulously reviewed to maintain the integrity of our curated fragrance collective.',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 14 : 15,
              color: AppColors.textSecondary,
              height: 1.75,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Desktop two-column ──────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
    Map<String, dynamic> app,
    String status,
    DateTime? submittedAt,
    String? rejectionReason, {
    required bool isApproved,
    required bool isRejected,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left — main content (flex 7)
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _buildStatusCard(status, isApproved, isRejected),
              const SizedBox(height: 36),
              _buildProgressTracker(submittedAt, isApproved, isRejected),
              const SizedBox(height: 36),
              _buildAdminNotes(rejectionReason),
              const SizedBox(height: 36),
              _buildActionButtons(isRejected),
            ],
          ),
        ),
        const SizedBox(width: 40),
        // Right — sidebar (flex 4)
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildGoldSillageCard(),
              const SizedBox(height: 20),
              _buildFaqCard(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Mobile single-column ────────────────────────────────────────────────────

  Widget _buildMobileLayout(
    Map<String, dynamic> app,
    String status,
    DateTime? submittedAt,
    String? rejectionReason, {
    required bool isApproved,
    required bool isRejected,
  }) {
    return Column(
      children: [
        _buildStatusCard(status, isApproved, isRejected),
        const SizedBox(height: 28),
        _buildProgressTracker(submittedAt, isApproved, isRejected),
        const SizedBox(height: 28),
        _buildAdminNotes(rejectionReason),
        const SizedBox(height: 28),
        _buildActionButtons(isRejected),
        const SizedBox(height: 36),
        _buildGoldSillageCard(),
        const SizedBox(height: 20),
        _buildFaqCard(),
      ],
    );
  }

  // ─── Status card ─────────────────────────────────────────────────────────────

  Widget _buildStatusCard(String status, bool isApproved, bool isRejected) {
    final icon = isApproved
        ? Icons.verified_rounded
        : isRejected
            ? Icons.cancel_outlined
            : Icons.hourglass_empty_rounded;
    final iconColor = isApproved
        ? AppColors.success
        : isRejected
            ? AppColors.error
            : AppColors.primary;
    final body = isApproved
        ? 'Your application has been approved. Welcome to the Archive — listing capabilities are now active.'
        : isRejected
            ? 'Your application was reviewed and could not be approved at this time. See admin notes below.'
            : 'Your application is currently being reviewed by an admin. This process typically takes 48–72 hours.';

    return Container(
      padding: const EdgeInsets.all(28),
      color: AppColors.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            color: iconColor.withValues(alpha: 0.07),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review Status',
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Progress tracker ─────────────────────────────────────────────────────────

  Widget _buildProgressTracker(
      DateTime? submittedAt, bool isApproved, bool isRejected) {
    final submittedStr = submittedAt != null
        ? '${submittedAt.day} ${_monthName(submittedAt.month)} ${submittedAt.year}'
        : 'Submitted';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VERIFICATION ROADMAP',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth > 480
              ? _buildHorizontalStepper(submittedStr, isApproved, isRejected)
              : _buildVerticalStepper(submittedStr, isApproved, isRejected),
        ),
      ],
    );
  }

  Widget _buildHorizontalStepper(
      String submittedStr, bool isApproved, bool isRejected) {
    return Row(
      children: [
        _StepDot(
            label: 'Submitted',
            sub: submittedStr,
            state: _StepState.done),
        const _StepConnector(active: true),
        _StepDot(
          label: 'Under Review',
          sub: isApproved || isRejected ? 'Completed' : 'Current Phase',
          state:
              isApproved || isRejected ? _StepState.done : _StepState.active,
        ),
        _StepConnector(active: isApproved),
        _StepDot(
          label: isRejected ? 'Not Approved' : 'Verified',
          sub: isApproved
              ? 'Final Access'
              : isRejected
                  ? ''
                  : 'Pending',
          state: isApproved
              ? _StepState.done
              : isRejected
                  ? _StepState.rejected
                  : _StepState.pending,
        ),
      ],
    );
  }

  Widget _buildVerticalStepper(
      String submittedStr, bool isApproved, bool isRejected) {
    return Column(
      children: [
        _StepRow(
            label: 'Submitted',
            sub: submittedStr,
            state: _StepState.done,
            showLine: true),
        _StepRow(
          label: 'Under Review',
          sub: isApproved || isRejected ? 'Completed' : 'Current Phase',
          state:
              isApproved || isRejected ? _StepState.done : _StepState.active,
          showLine: true,
        ),
        _StepRow(
          label: isRejected ? 'Not Approved' : 'Verified',
          sub: isApproved
              ? 'Final Access'
              : isRejected
                  ? ''
                  : 'Pending',
          state: isApproved
              ? _StepState.done
              : isRejected
                  ? _StepState.rejected
                  : _StepState.pending,
          showLine: false,
        ),
      ],
    );
  }

  // ─── Admin notes ──────────────────────────────────────────────────────────────

  Widget _buildAdminNotes(String? rejectionReason) {
    final hasNote =
        rejectionReason != null && rejectionReason.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADMIN NOTES',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border(
              left: BorderSide(
                color: hasNote
                    ? AppColors.error
                    : AppColors.primaryGradientEnd,
                width: 4,
              ),
            ),
          ),
          child: Text(
            hasNote
                ? rejectionReason
                : 'Pending review. Our curators will provide feedback if additional documentation is required.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color:
                  hasNote ? AppColors.error : AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Action buttons ───────────────────────────────────────────────────────────

  Widget _buildActionButtons(bool isRejected) {
    final profileRole = ref.watch(currentProfileProvider).valueOrNull?['role'] as String?;
    final isApprovedSeller = profileRole == 'seller';

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (isRejected)
          _ActionButton(
            label: 'RESUBMIT APPLICATION',
            icon: Icons.refresh_rounded,
            filled: true,
            onPressed: () => context.go('/register/seller-apply'),
          )
        else if (isApprovedSeller)
          _ActionButton(
            label: 'CREATE A LISTING',
            icon: Icons.add_circle_outline,
            filled: true,
            onPressed: () => context.go('/dashboard/create-listing'),
          )
        else
          _ActionButton(
            label: 'CONTACT SUPPORT',
            icon: Icons.mail_outline_rounded,
            filled: false,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('To update your application details, please contact support.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        _ActionButton(
          label: 'BACK TO DASHBOARD',
          icon: Icons.grid_view_outlined,
          filled: false,
          onPressed: () => context.go('/dashboard'),
        ),
      ],
    );
  }

  // ─── FAQ card ─────────────────────────────────────────────────────────────────

  Widget _buildFaqCard() {
    const faqs = [
      (
        'What documentation is required?',
        'We require a valid CNIC for identity verification. Heritage archive sellers may be asked for additional provenance documents.',
      ),
      (
        'How long is the vetting process?',
        'Most reviews are completed within 72 hours, though complex applications may take longer.',
      ),
      (
        'Can I sell before verification?',
        'To ensure buyer trust, listing capabilities are unlocked only after the Verified status is achieved.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification FAQ',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 24),
          ...faqs.map((faq) => Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            faq.$1,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      faq.$2,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              )),
          Container(
            height: 1,
            color: AppColors.ghostBorderBase.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'Need immediate assistance?',
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Contact Curator Support',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor:
                  AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Gold Sillage card ────────────────────────────────────────────────────────

  Widget _buildGoldSillageCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      color: AppColors.primary,
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gold Sillage Status',
                style: GoogleFonts.notoSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Once verified, your profile will be eligible for heritage badges and community salon privileges.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'HERITAGE READY',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: const Color(0xFF261900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Error / no-app states ────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Could not load application.',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
              ),
              onPressed: () {
                ref.invalidate(sellerApplicationProvider);
                ref.invalidate(currentProfileProvider);
              },
              child: Text('Retry',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoApplication() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 52, color: AppColors.textMuted),
                  const SizedBox(height: 20),
                  Text(
                    'No application found.',
                    style: GoogleFonts.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onBackground),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Submit a seller application to get started.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                    ),
                    onPressed: () => context.go('/register/seller-apply'),
                    child: Text(
                      'APPLY NOW',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero),
            padding:
                const EdgeInsets.symmetric(horizontal: 24),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0),
          ),
        ),
      );
    }
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: AppColors.ghostBorderBase.withValues(alpha: 0.5)),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero),
          padding:
              const EdgeInsets.symmetric(horizontal: 24),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: AppColors.textSecondary),
        label: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ─── Step widgets ─────────────────────────────────────────────────────────────

enum _StepState { done, active, pending, rejected }

class _StepDot extends StatelessWidget {
  final String label;
  final String sub;
  final _StepState state;

  const _StepDot({
    required this.label,
    required this.sub,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _dot(),
        const SizedBox(height: 10),
        if (label.isNotEmpty)
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: state == _StepState.pending
                  ? AppColors.textMuted
                  : AppColors.primary,
            ),
          ),
        if (sub.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              sub,
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  Widget _dot() {
    return switch (state) {
      _StepState.done => Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              color: Colors.white, size: 20),
        ),
      _StepState.active => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: const Icon(Icons.visibility_outlined,
              color: AppColors.primary, size: 20),
        ),
      _StepState.rejected => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.error, width: 3),
          ),
          child: const Icon(Icons.close_rounded,
              color: AppColors.error, size: 20),
        ),
      _StepState.pending => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.ghostBorderBase, width: 2),
            color: AppColors.surfaceContainerLow,
          ),
          child: const Icon(Icons.verified_outlined,
              color: AppColors.textMuted, size: 20),
        ),
    };
  }
}

class _StepConnector extends StatelessWidget {
  final bool active;
  const _StepConnector({required this.active});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        color: active
            ? AppColors.primary
            : AppColors.surfaceContainerHighest,
        margin: const EdgeInsets.only(bottom: 44),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final String sub;
  final _StepState state;
  final bool showLine;

  const _StepRow({
    required this.label,
    required this.sub,
    required this.state,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _StepDot(label: '', sub: '', state: state),
            if (showLine)
              Container(
                  width: 2,
                  height: 36,
                  color: AppColors.surfaceContainerHighest),
          ],
        ),
        const SizedBox(width: 18),
        Padding(
          padding: const EdgeInsets.only(top: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: state == _StepState.pending
                      ? AppColors.textMuted
                      : AppColors.primary,
                ),
              ),
              if (sub.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    sub,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
