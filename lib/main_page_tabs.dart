part of 'main_page.dart';

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.user,
    required this.displayName,
    required this.preferredLocation,
    required this.emailVerified,
    required this.openGroups,
    required this.onCreateGroup,
    required this.onEditPreferredLocation,
    required this.onFilterPressed,
    required this.onOpenGroup,
    required this.onJoinGroup,
  });

  final User user;
  final String displayName;
  final String? preferredLocation;
  final bool emailVerified;
  final List<_GroupEntry> openGroups;
  final VoidCallback onCreateGroup;
  final Future<void> Function(String? currentValue) onEditPreferredLocation;
  final VoidCallback onFilterPressed;
  final ValueChanged<_GroupEntry> onOpenGroup;
  final Future<bool> Function(DocumentReference<Map<String, dynamic>> ref)
  onJoinGroup;

  String _formatDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'W';
    final featuredGroup = openGroups.isNotEmpty ? openGroups.first : null;
    final remainingGroups = openGroups.length > 1
        ? openGroups.sublist(1)
        : <_GroupEntry>[];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _MainVisuals.subtleText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find a Group 🛒',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: _MainVisuals.text,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '안녕하세요, $displayName',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _MainVisuals.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _NotificationButton(count: 3),
              const SizedBox(width: 10),
              _AvatarBadge(letter: initial),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onEditPreferredLocation(preferredLocation),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _MainVisuals.softMint,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _MainVisuals.softBorder,
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: _MainVisuals.green,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            preferredLocation ?? '선호 위치 미설정',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: _MainVisuals.locationText,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _MainVisuals.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onFilterPressed,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _MainVisuals.greenGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onCreateGroup,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: _MainVisuals.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2222C55E),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Create a Group',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Joinable Groups',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _MainVisuals.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _MainVisuals.softMint,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _MainVisuals.softBorder),
                ),
                child: Text(
                  '${openGroups.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _MainVisuals.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: _MainVisuals.green,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (openGroups.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _MainVisuals.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '등록된 그룹이 없습니다.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _MainVisuals.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '참여 가능한 그룹이 없어요. Create a Group 버튼으로 새 그룹을 만들어보세요.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _MainVisuals.mutedText,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _FeaturedGroupCard(
              group: featuredGroup!,
              formatDateTime: _formatDateTime,
              actionLabel: 'JOIN',
              actionIcon: Icons.how_to_reg_rounded,
              badgeLabel: featuredGroup.location,
              onTap: () => onOpenGroup(featuredGroup),
              onAction: () {
                unawaited(onJoinGroup(featuredGroup.docRef));
              },
            ),
            const SizedBox(height: 12),
            for (final group in remainingGroups) ...[
              _CompactGroupCard(
                group: group,
                formatDateTime: _formatDateTime,
                actionLabel: 'JOIN',
                actionIcon: Icons.add_circle_outline_rounded,
                onTap: () => onOpenGroup(group),
                onAction: () {
                  unawaited(onJoinGroup(group.docRef));
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 6),
          Text(
            emailVerified ? '이메일 인증 완료' : '이메일 인증 대기',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: emailVerified
                  ? _MainVisuals.green
                  : _MainVisuals.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlankTab extends StatelessWidget {
  const _BlankTab();

  @override
  Widget build(BuildContext context) {
    // TODO: Replace this blank tab with the real page implementation.
    return const SizedBox.expand();
  }
}

class _FeaturedGroupCard extends StatelessWidget {
  const _FeaturedGroupCard({
    required this.group,
    required this.formatDateTime,
    required this.actionLabel,
    required this.actionIcon,
    required this.badgeLabel,
    required this.onAction,
    this.onTap,
    this.onChat,
  });

  final _GroupEntry group;
  final String Function(DateTime value) formatDateTime;
  final String actionLabel;
  final IconData actionIcon;
  final String badgeLabel;
  final VoidCallback onAction;
  final VoidCallback? onTap;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final dateText = group.dateTime == null
        ? '(no date)'
        : formatDateTime(group.dateTime!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: _MainVisuals.featuredGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badgeLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: _MainVisuals.featuredGreen,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          group.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: _MainVisuals.featuredMuted,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dateText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: _MainVisuals.featuredMuted,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _MainVisuals.featuredBadge,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('🛒', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _StackAvatar(
                        letter: 'S',
                        background: const LinearGradient(
                          colors: [_MainVisuals.green, Color(0xFF4ADE80)],
                        ),
                        textColor: Colors.white,
                      ),
                      const Positioned(
                        left: 18,
                        child: _StackAvatar(
                          letter: 'M',
                          background: LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                          ),
                          textColor: Colors.white,
                        ),
                      ),
                      const Positioned(
                        left: 36,
                        child: _StackAvatar(
                          letter: 'A',
                          background: LinearGradient(
                            colors: [Color(0xFF818CF8), Color(0xFFA78BFA)],
                          ),
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 84),
                  Text(
                    '${group.nowNum} / ${group.maxNum} members',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _MainVisuals.featuredMuted,
                    ),
                  ),
                  const Spacer(),
                  if (onChat != null) ...[
                    _CardChatButton(onPressed: onChat!),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: onAction,
                    icon: Icon(actionIcon, size: 16),
                    label: Text(actionLabel),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      backgroundColor: _MainVisuals.featuredButton,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

class _CompactGroupCard extends StatelessWidget {
  const _CompactGroupCard({
    required this.group,
    required this.formatDateTime,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.onTap,
    this.onChat,
    this.isJoined = false,
  });

  final _GroupEntry group;
  final String Function(DateTime value) formatDateTime;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final VoidCallback? onTap;
  final VoidCallback? onChat;
  final bool isJoined;

  @override
  Widget build(BuildContext context) {
    final dateText = group.dateTime == null
        ? '(no date)'
        : formatDateTime(group.dateTime!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _MainVisuals.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isJoined
                      ? _MainVisuals.softMint
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isJoined
                      ? Icons.storefront_outlined
                      : Icons.shopping_bag_outlined,
                  color: isJoined
                      ? _MainVisuals.green
                      : const Color(0xFFEA580C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _MainVisuals.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.location} · $dateText',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _MainVisuals.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${group.nowNum} / ${group.maxNum} members',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _MainVisuals.subtleText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (onChat != null) ...[
                _CardChatButton(onPressed: onChat!),
                const SizedBox(width: 8),
              ],
              TextButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon, size: 16),
                label: Text(actionLabel),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  backgroundColor: isJoined
                      ? _MainVisuals.softMint
                      : _MainVisuals.pageBackground,
                  foregroundColor: isJoined
                      ? _MainVisuals.green
                      : _MainVisuals.text,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isJoined
                          ? _MainVisuals.softBorder
                          : _MainVisuals.cardBorder,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.countBackground,
    required this.countForeground,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final Color countBackground;
  final Color countForeground;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: _MainVisuals.text,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: countBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count group${count == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: countForeground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: const Color(0xFFE8F0E8))),
      ],
    );
  }
}

class _EmptyGroupCard extends StatelessWidget {
  const _EmptyGroupCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _MainVisuals.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _MainVisuals.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _MainVisuals.mutedText),
          ),
        ],
      ),
    );
  }
}

class _StatsChip extends StatelessWidget {
  const _StatsChip({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _MainVisuals.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _MainVisuals.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardChatButton extends StatelessWidget {
  const _CardChatButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _MainVisuals.softMint,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _MainVisuals.softBorder),
          ),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: _MainVisuals.green,
            size: 18,
          ),
        ),
      ),
    );
  }
}
