part of 'main_page.dart';

class _MyGroupsTab extends StatelessWidget {
  const _MyGroupsTab({
    required this.displayName,
    required this.hostedGroups,
    required this.joinedGroups,
    required this.onCreateGroup,
    required this.onOpenGroup,
    required this.onOpenChat,
  });

  final String displayName;
  final List<_GroupEntry> hostedGroups;
  final List<_GroupEntry> joinedGroups;
  final VoidCallback onCreateGroup;
  final ValueChanged<_GroupEntry> onOpenGroup;
  final ValueChanged<_GroupEntry> onOpenChat;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'W';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            children: [
              _AvatarBadge(letter: initial),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Groups',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: _MainVisuals.text,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'See only the groups you are part of.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _MainVisuals.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _MainVisuals.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatsChip(
                    label: 'HOSTING',
                    value: '${hostedGroups.length}',
                    color: const Color(0xFFD97706),
                    background: const Color(0xFFFEF3C7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatsChip(
                    label: 'JOINED',
                    value: '${joinedGroups.length}',
                    color: _MainVisuals.green,
                    background: _MainVisuals.softMint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: onCreateGroup,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: _MainVisuals.primaryGradient,
                borderRadius: BorderRadius.circular(20),
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
          _SectionHeader(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'HOSTING',
            count: hostedGroups.length,
            countBackground: const Color(0xFFFEF3C7),
            countForeground: const Color(0xFFD97706),
          ),
          const SizedBox(height: 12),
          if (hostedGroups.isEmpty)
            _EmptyGroupCard(
              title: 'You are not hosting any group.',
              subtitle: 'Tap Create a Group to host your first one.',
            )
          else ...[
            _FeaturedGroupCard(
              group: hostedGroups.first,
              formatDateTime: _formatDateTime,
              actionLabel: 'Host',
              actionIcon: Icons.manage_search_rounded,
              badgeLabel: 'HOST',
              onTap: () => onOpenGroup(hostedGroups.first),
              onAction: () => onOpenGroup(hostedGroups.first),
              onChat: () => onOpenChat(hostedGroups.first),
            ),
            const SizedBox(height: 12),
            for (final group in hostedGroups.skip(1)) ...[
              _CompactGroupCard(
                group: group,
                formatDateTime: _formatDateTime,
                actionLabel: 'Edit',
                actionIcon: Icons.edit_outlined,
                onTap: () => onOpenGroup(group),
                onAction: () => onOpenGroup(group),
                onChat: () => onOpenChat(group),
                isJoined: true,
              ),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 6),
          _SectionHeader(
            icon: Icons.groups_rounded,
            iconColor: _MainVisuals.green,
            title: 'JOINED',
            count: joinedGroups.length,
            countBackground: _MainVisuals.softMint,
            countForeground: _MainVisuals.green,
          ),
          const SizedBox(height: 12),
          if (joinedGroups.isEmpty)
            _EmptyGroupCard(
              title: 'You have not joined any group yet.',
              subtitle: 'Find a group on the Home tab or create a new one.',
            )
          else
            for (final group in joinedGroups) ...[
              _CompactGroupCard(
                group: group,
                formatDateTime: _formatDateTime,
                actionLabel: 'View',
                actionIcon: Icons.chevron_right_rounded,
                onTap: () => onOpenGroup(group),
                onAction: () => onOpenGroup(group),
                onChat: () => onOpenChat(group),
                isJoined: true,
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  final h = value.hour.toString().padLeft(2, '0');
  final min = value.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}
