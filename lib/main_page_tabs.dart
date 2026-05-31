part of 'main_page.dart';

class _HomeTab extends StatefulWidget {
  const _HomeTab({
    required this.user,
    required this.displayName,
    required this.preferredLocation,
    required this.emailVerified,
    required this.photoUrl,
    required this.openGroups,
    required this.notificationCount,
    required this.onCreateGroup,
    required this.onEditPreferredLocation,
    required this.onFilterPressed,
    required this.onNotificationsPressed,
    required this.activeFilterCount,
    required this.onOpenGroup,
  });

  final User user;
  final String displayName;
  final String? preferredLocation;
  final bool emailVerified;
  final String? photoUrl;
  final List<_GroupEntry> openGroups;
  final int notificationCount;
  final VoidCallback onCreateGroup;
  final Future<void> Function(String? currentValue) onEditPreferredLocation;
  final VoidCallback onFilterPressed;
  final VoidCallback onNotificationsPressed;
  final int activeFilterCount;
  final ValueChanged<_GroupEntry> onOpenGroup;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String? _selectedGroupId;

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
    final initial = widget.displayName.isNotEmpty
        ? widget.displayName[0].toUpperCase()
        : 'W';
    final selectedMatches = _selectedGroupId == null
        ? <_GroupEntry>[]
        : widget.openGroups
              .where((group) => group.id == _selectedGroupId)
              .toList();
    final selectedGroup = selectedMatches.isEmpty
        ? null
        : selectedMatches.first;
    final featuredGroup = selectedGroup;

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
                      'Hello, ${widget.displayName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _MainVisuals.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _NotificationButton(
                count: widget.notificationCount,
                onTap: widget.onNotificationsPressed,
              ),
              const SizedBox(width: 10),
              _AvatarBadge(letter: initial, photoUrl: widget.photoUrl),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () =>
                      widget.onEditPreferredLocation(widget.preferredLocation),
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
                            widget.preferredLocation ??
                                'Set preferred location',
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
                onTap: widget.onFilterPressed,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _MainVisuals.greenGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.tune_rounded, color: Colors.white),
                      if (widget.activeFilterCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '${widget.activeFilterCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: widget.onCreateGroup,
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
                  '${widget.openGroups.length}',
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
          if (widget.openGroups.isEmpty)
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
                    'No groups available.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _MainVisuals.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'There are no joinable groups. Tap Create a Group to start one.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _MainVisuals.mutedText,
                    ),
                  ),
                ],
              ),
            )
          else if (selectedGroup == null)
            for (final group in widget.openGroups) ...[
              _CompactGroupCard(
                group: group,
                formatDateTime: _formatDateTime,
                actionLabel: 'VIEW',
                actionIcon: Icons.visibility_outlined,
                onTap: () {
                  setState(() {
                    _selectedGroupId = group.id;
                  });
                },
                onAction: () {
                  widget.onOpenGroup(group);
                },
              ),
              const SizedBox(height: 12),
            ]
          else ...[
            for (final group in widget.openGroups) ...[
              if (group.id == featuredGroup!.id)
                _FeaturedGroupCard(
                  group: group,
                  formatDateTime: _formatDateTime,
                  actionLabel: 'VIEW',
                  actionIcon: Icons.visibility_outlined,
                  badgeLabel: group.location,
                  onTap: () {
                    setState(() {
                      _selectedGroupId = null;
                    });
                  },
                  onAction: () {
                    widget.onOpenGroup(group);
                  },
                )
              else
                _CompactGroupCard(
                  group: group,
                  formatDateTime: _formatDateTime,
                  actionLabel: 'VIEW',
                  actionIcon: Icons.visibility_outlined,
                  onTap: () {
                    setState(() {
                      _selectedGroupId = group.id;
                    });
                  },
                  onAction: () {
                    widget.onOpenGroup(group);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 6),
          Text(
            widget.emailVerified
                ? 'Email verified'
                : 'Email verification pending',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: widget.emailVerified
                  ? _MainVisuals.green
                  : _MainVisuals.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyPageTab extends StatelessWidget {
  const _MyPageTab({
    required this.displayName,
    required this.email,
    required this.preferredLocation,
    required this.emailVerified,
    required this.photoUrl,
    required this.ratingAverage,
    required this.ratingCount,
    required this.onEditPreferredLocation,
    required this.onEditProfile,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final String displayName;
  final String email;
  final String? preferredLocation;
  final bool emailVerified;
  final String? photoUrl;
  final double ratingAverage;
  final int ratingCount;
  final Future<void> Function(String? currentValue) onEditPreferredLocation;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'W';
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(
            'My Page',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _MainVisuals.text,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: _MainVisuals.featuredGradient,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                _ProfileAvatar(initial: initial, photoUrl: photoUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _MainVisuals.featuredMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onEditProfile,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _RatingSummaryCard(average: ratingAverage, count: ratingCount),
          const SizedBox(height: 16),
          _InfoPanel(
            title: 'ACCOUNT',
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: email,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: emailVerified
                      ? Icons.verified_rounded
                      : Icons.schedule_rounded,
                  label: 'Email verification',
                  value: emailVerified ? 'Verified' : 'Pending',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoPanel(
            title: 'PREFERENCES',
            child: InkWell(
              onTap: () => onEditPreferredLocation(preferredLocation),
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _MainVisuals.softMint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: _MainVisuals.green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferred location',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: _MainVisuals.mutedText,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preferredLocation ?? 'Not set',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _MainVisuals.text,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _MainVisuals.subtleText,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onEditProfile,
            icon: const Icon(Icons.manage_accounts_outlined),
            label: const Text('Edit profile'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              foregroundColor: _MainVisuals.green,
              side: const BorderSide(color: Color(0xFFD1FAE5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor: _MainVisuals.softMint,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFECACA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor: const Color(0xFFFFF1F2),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onDeleteAccount,
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Delete account'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              foregroundColor: const Color(0xFFB91C1C),
              side: const BorderSide(color: Color(0xFFFECACA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor: const Color(0xFFFFF1F2),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
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
                  _GroupOwnerAvatar(
                    ownerId: group.ownerId,
                    fallbackLetter: group.title.isNotEmpty
                        ? group.title[0].toUpperCase()
                        : 'G',
                    size: 48,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360;
                  final actions = [
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
                  ];

                  if (compact) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _GroupOwnerAvatar(
                          ownerId: group.ownerId,
                          fallbackLetter: group.title.isNotEmpty
                              ? group.title[0].toUpperCase()
                              : 'G',
                          size: 46,
                        ),
                        Text(
                          '${group.nowNum} / ${group.maxNum} members',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: _MainVisuals.featuredMuted),
                        ),
                        ...actions,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      _GroupOwnerAvatar(
                        ownerId: group.ownerId,
                        fallbackLetter: group.title.isNotEmpty
                            ? group.title[0].toUpperCase()
                            : 'G',
                        size: 52,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${group.nowNum} / ${group.maxNum} members',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: _MainVisuals.featuredMuted),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              if (group.items.isEmpty)
                Text(
                  'No shared items yet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _MainVisuals.featuredMuted,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in group.items)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({required this.average, required this.count});

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    final displayAverage = average.toStringAsFixed(1);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _MainVisuals.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x110F172A),
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rating',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _MainVisuals.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayAverage,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: _MainVisuals.text,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count == 0
                          ? 'No ratings yet'
                          : 'Based on community feedback',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _MainVisuals.subtleText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Text(
              '총 평가 $count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFD97706),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initial, required this.photoUrl});

  final String initial;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: hasPhoto ? null : _MainVisuals.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        image: hasPhoto
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: hasPhoto
          ? null
          : Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
            ),
    );
  }
}

class _GroupOwnerAvatar extends StatelessWidget {
  const _GroupOwnerAvatar({
    required this.ownerId,
    required this.fallbackLetter,
    required this.size,
  });

  final String ownerId;
  final String fallbackLetter;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (ownerId.isEmpty) {
      return _AvatarFrame(size: size, letter: fallbackLetter, photoUrl: null);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: AuthService.instance.watchProfile(ownerId),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final displayName = data?['displayName']?.toString().trim();
        final legacyNickname = data?['nickname']?.toString().trim();
        final photoUrlValue = data?['photoURL']?.toString().trim();
        final photoUrl = (photoUrlValue?.isNotEmpty ?? false)
            ? photoUrlValue
            : null;
        final letter = (displayName?.isNotEmpty ?? false)
            ? displayName![0].toUpperCase()
            : (legacyNickname?.isNotEmpty ?? false)
            ? legacyNickname![0].toUpperCase()
            : fallbackLetter;

        return _AvatarFrame(size: size, letter: letter, photoUrl: photoUrl);
      },
    );
  }
}

class _AvatarFrame extends StatelessWidget {
  const _AvatarFrame({
    required this.size,
    required this.letter,
    required this.photoUrl,
  });

  final double size;
  final String letter;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasPhoto ? Colors.white.withValues(alpha: 0.14) : null,
        gradient: hasPhoto ? null : _MainVisuals.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.31),
        image: hasPhoto
            ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
            : null,
        border: Border.all(
          color: Colors.white.withValues(alpha: hasPhoto ? 0.16 : 0.0),
        ),
      ),
      child: hasPhoto
          ? null
          : Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.38,
                ),
              ),
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
