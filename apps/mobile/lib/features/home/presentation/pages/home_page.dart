import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_wallet/core/theme/app_colors.dart';
import 'package:eco_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eco_wallet/features/disposal/domain/entities/disposal_submission.dart';
import 'package:eco_wallet/features/disposal/domain/repositories/disposal_repository.dart';
import 'package:eco_wallet/features/disposal/domain/services/disposal_location_provider.dart';
import 'package:eco_wallet/features/disposal/domain/utils/disposal_status_labels.dart';
import 'package:eco_wallet/features/disposal/presentation/bloc/disposal_bloc.dart';
import 'package:eco_wallet/features/disposal/presentation/bloc/disposal_detail_bloc.dart';
import 'package:eco_wallet/features/disposal/presentation/pages/disposal_detail_page.dart';
import 'package:eco_wallet/features/disposal/presentation/pages/disposal_submission_page.dart';
import 'package:eco_wallet/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:eco_wallet/features/rewards/presentation/pages/rewards_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(label: 'Início', icon: Icons.home_outlined),
    _NavItem(label: 'Descartes', icon: Icons.recycling_outlined),
    _NavItem(label: 'Recompensas', icon: Icons.card_giftcard_outlined),
    _NavItem(label: 'Perfil', icon: Icons.person_outline),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<WalletBloc>().add(const WalletRefreshRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : '';

    return switch (_selectedIndex) {
      0 => _HomeTab(
        onNewDisposal: _openDisposalSubmission,
        onOpenRewards: () => setState(() => _selectedIndex = 2),
      ),
      1 => const _DisposalsTab(),
      2 => RewardsPage(userId: userId),
      _ => const _ProfileTab(),
    };
  }

  void _openDisposalSubmission(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (routeContext) => BlocProvider(
              create:
                  (_) => DisposalBloc(
                    disposalRepository: routeContext.read<DisposalRepository>(),
                    locationProvider: GeolocatorDisposalLocationProvider(),
                  ),
              child: DisposalSubmissionPage(
                userId: authState.user.id,
                onSubmissionSuccess: (submission) {
                  context.read<WalletBloc>().add(
                    WalletRealtimeSubmissionUpdated(submission),
                  );
                },
              ),
            ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final selected = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.brandGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: selected ? AppColors.primary : AppColors.stone,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color:
                                selected
                                    ? AppColors.primary
                                    : AppColors.stone,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.onNewDisposal,
    required this.onOpenRewards,
  });

  final void Function(BuildContext context) onNewDisposal;
  final VoidCallback onOpenRewards;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, walletState) {
        final available =
            walletState is WalletReady
                ? walletState.wallet.availableBalance
                : 0;
        final pending =
            walletState is WalletReady ? walletState.wallet.pendingBalance : 0;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildGreeting(context)),
            SliverToBoxAdapter(
              child: _WalletSummaryCard(
                available: available,
                pending: pending,
                onNewDisposal: () => onNewDisposal(context),
                onOpenWallet: onOpenRewards,
              ),
            ),
            SliverToBoxAdapter(child: _buildRecentActivityHeader(context)),
            if (walletState is WalletReady && walletState.submissions.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final submission = walletState.submissions[index];
                  if (index >= 3) {
                    return null;
                  }
                  return _ActivityRow(
                    title: submission.dropOffName ?? 'Descarte de óleo',
                    subtitle: disposalStatusLabel(submission.status),
                    amount: _amountFor(submission),
                    accent: _accentFor(submission.status),
                    onTap: () => _openDetail(context, submission),
                  );
                }, childCount: walletState.submissions.length.clamp(0, 3)),
              )
            else
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Nenhuma atividade recente.',
                    style: TextStyle(color: AppColors.stone),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        );
      },
    );
  }

  String _amountFor(DisposalSubmission submission) {
    return switch (submission.status) {
      DisposalStatus.rewarded => '+ EC',
      DisposalStatus.rejected => '—',
      _ => 'Pendente',
    };
  }

  Color _accentFor(DisposalStatus status) {
    return switch (status) {
      DisposalStatus.rewarded => AppColors.brandGreen,
      DisposalStatus.rejected => AppColors.brandError,
      _ => AppColors.stone,
    };
  }

  void _openDetail(BuildContext context, DisposalSubmission submission) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (routeContext) => BlocProvider(
              create:
                  (_) => DisposalDetailBloc(
                    disposalRepository: routeContext.read<DisposalRepository>(),
                  )..add(
                    DisposalDetailStarted(
                      userId: authState.user.id,
                      submissionId: submission.id,
                      initialSubmission: submission,
                    ),
                  ),
              child: const DisposalDetailPage(),
            ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          const SizedBox(width: 48),
          const Expanded(
            child: Text(
              'UniFacens EcoWallet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, Estudante',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Bem-vindo de volta. Acompanhe suas moedas e descartes.',
            style: TextStyle(fontSize: 14, color: AppColors.stone),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Text(
        'Atividade recente',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _WalletSummaryCard extends StatelessWidget {
  const _WalletSummaryCard({
    required this.available,
    required this.pending,
    required this.onNewDisposal,
    this.onOpenWallet,
  });

  final int available;
  final int pending;
  final VoidCallback onNewDisposal;
  final VoidCallback? onOpenWallet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.walletCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saldo disponível',
              style: TextStyle(color: AppColors.onDarkMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.onDark,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(text: '$available '),
                  const TextSpan(
                    text: 'EC',
                    style: TextStyle(color: AppColors.rewardCoral),
                  ),
                ],
              ),
            ),
            if (pending > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$pending EC pendentes',
                style: const TextStyle(
                  color: AppColors.onDarkMuted,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNewDisposal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Novo descarte'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onOpenWallet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onDark,
                  side: const BorderSide(color: AppColors.onDarkMuted),
                ),
                child: const Text('Minhas recompensas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisposalsTab extends StatelessWidget {
  const _DisposalsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        if (state is WalletLoading || state is WalletInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is WalletFailure) {
          return Center(child: Text(state.message));
        }
        if (state is! WalletReady) {
          return const SizedBox.shrink();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const Text(
              'Meus descartes',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (state.submissions.isEmpty)
              const Text(
                'Nenhum descarte registrado ainda.',
                style: TextStyle(color: AppColors.stone),
              )
            else
              ...state.submissions.map(
                (submission) => _DisposalListTile(submission: submission),
              ),
          ],
        );
      },
    );
  }
}

class _DisposalListTile extends StatelessWidget {
  const _DisposalListTile({required this.submission});

  final DisposalSubmission submission;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _openDetail(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.dropOffName ?? 'Descarte de óleo',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        disposalStatusLabel(submission.status),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.stone,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.stone),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (routeContext) => BlocProvider(
              create:
                  (_) => DisposalDetailBloc(
                    disposalRepository: routeContext.read<DisposalRepository>(),
                  )..add(
                    DisposalDetailStarted(
                      userId: authState.user.id,
                      submissionId: submission.id,
                      initialSubmission: submission,
                    ),
                  ),
              child: const DisposalDetailPage(),
            ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Perfil em breve',
        style: TextStyle(color: AppColors.stone),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.accent,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.stone,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accent,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
