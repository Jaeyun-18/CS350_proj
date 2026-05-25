part of 'main_page.dart';

class _GroupPage extends StatefulWidget {
  const _GroupPage({required this.group, required this.onJoinGroup});

  final _GroupEntry group;
  final Future<bool> Function(DocumentReference<Map<String, dynamic>> ref)
  onJoinGroup;

  @override
  State<_GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<_GroupPage> {
  late _GroupEntry _group;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  bool get _isOwner => _group.isOwner;

  bool get _isMember => _group.isMember;

  bool get _isEnded => _group.isEnded;

  bool get _isRecruitmentClosed => _group.isRecruitmentClosed;

  bool get _isJoinable => _group.isJoinable;

  bool get _isMeetingPassed {
    final scheduled = _group.dateTime;
    if (scheduled == null) {
      return false;
    }
    return DateTime.now().isAfter(scheduled);
  }

  bool get _isRatingOpen =>
      _isMeetingPassed && !_group.isExpiredForHistory && !_isEnded;

  List<String> get _orderedParticipantIds {
    final memberIds = _group.memberIds.toSet();
    final ordered = <String>[];
    if (_group.ownerId.isNotEmpty) {
      ordered.add(_group.ownerId);
      memberIds.remove(_group.ownerId);
    }
    final others = memberIds.toList()..sort();
    ordered.addAll(others);
    return ordered;
  }

  String get _statusLabel {
    if (_isEnded) {
      return 'ENDED';
    }
    if (_isRatingOpen) {
      return 'RATING';
    }
    if (_isRecruitmentClosed) {
      return 'CLOSED';
    }
    if (_isOwner) {
      return 'HOST';
    }
    if (_isMember) {
      return 'JOINED';
    }
    if (_group.isFull) {
      return 'FULL';
    }
    return 'OPEN';
  }

  Color get _statusColor {
    if (_isEnded) {
      return const Color(0xFF64748B);
    }
    if (_isRatingOpen) {
      return const Color(0xFF8B5CF6);
    }
    if (_isRecruitmentClosed) {
      return const Color(0xFFF59E0B);
    }
    if (_isOwner) {
      return const Color(0xFFF59E0B);
    }
    if (_isMember) {
      return _MainVisuals.green;
    }
    if (_group.isFull) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF0EA5E9);
  }

  void _applyGroupData(Map<String, dynamic> data) {
    setState(() {
      _group = _GroupEntry.fromData(
        id: _group.id,
        data: Map<String, dynamic>.from(data),
        currentUserId: _group.currentUserId,
        reference: _group.reference,
      );
    });
  }

  Future<void> _handleJoin() async {
    if (_isSubmitting || !_isJoinable) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await widget.onJoinGroup(_group.docRef);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      if (success) {
        final updated = Map<String, dynamic>.from(_group.data);
        final members = _group.memberIds.toSet()..add(_group.currentUserId);
        updated['now_num'] = _group.nowNum + 1;
        updated['member_ids'] = members.toList();
        updated['updatedAt'] = FieldValue.serverTimestamp();
        _group = _GroupEntry.fromData(
          id: _group.id,
          data: updated,
          currentUserId: _group.currentUserId,
          reference: _group.reference,
        );
      }
    });
  }

  Future<void> _handleLeave() async {
    if (!_isMember || _isOwner || _isEnded) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave the group?'),
          content: const Text(
            'If you leave, you will need to find this group from Home again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      // 멤버 제거 전(아직 멤버일 때) 이탈 안내를 채팅에 남긴다.
      try {
        await FirestoreChatService.instance.postMembershipNotice(
          groupId: _group.id,
          uid: _group.currentUserId,
          joined: false,
        );
      } on Exception catch (_) {
        // 시스템 메시지 실패는 나가기 자체를 막지 않는다.
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(_group.docRef);
        if (!snapshot.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'Group not found.',
          );
        }

        final currentGroup = _GroupEntry.fromData(
          id: snapshot.id,
          data: snapshot.data() ?? <String, dynamic>{},
          currentUserId: _group.currentUserId,
          reference: _group.reference,
        );

        if (!currentGroup.isMember) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'You have already left this group.',
          );
        }

        transaction.update(_group.docRef, {
          'now_num': FieldValue.increment(-1),
          'member_ids': FieldValue.arrayRemove([_group.currentUserId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Leave failed: $error')));
    }
  }

  Future<void> _openSettings() async {
    if (!_isOwner || _isEnded) {
      return;
    }

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => _GroupSettingsPage(group: _group),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result['ended'] == true) {
      if (mounted) {
        Navigator.of(context).pop('open_my_groups');
      }
      return;
    }

    _applyGroupData(result);
  }

  Future<void> _shareGroup(BuildContext context) async {
    final deepLink = DeepLinkService.instance.buildGroupUri(_group.id);
    final box = context.findRenderObject() as RenderBox?;
    final shareOrigin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    await SharePlus.instance.share(
      ShareParams(
        text: 'WeBuyDivvy group invite:\n$deepLink',
        title: 'Share group',
        sharePositionOrigin: shareOrigin,
      ),
    );
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          groupId: _group.id,
          groupName: _group.title,
          memberCount: _group.nowNum,
          currentUserId: _group.currentUserId,
        ),
      ),
    );
  }

  Future<void> _openMemberProfile(String userId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _UserProfilePage(
          userId: userId,
          viewerUserId: _group.currentUserId,
          groupId: _group.id,
          groupTitle: _group.title,
        ),
      ),
    );
  }

  Future<void> _claimItem(String itemId) async {
    try {
      await toggleItemClaim(
        groupRef: _group.docRef,
        itemId: itemId,
        uid: _group.currentUserId,
      );
      final snapshot = await _group.docRef.get();
      if (!mounted) {
        return;
      }
      final data = snapshot.data();
      if (data != null) {
        _applyGroupData(data);
      }
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Claim update failed: ${error.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _group.dateTime == null
        ? 'No date set'
        : _formatGroupDateTime(_group.dateTime!);
    final memberCountText = '${_group.nowNum} / ${_group.maxNum} members';

    return Scaffold(
      backgroundColor: _MainVisuals.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _MainVisuals.text,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Group Details',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.3),
        ),
        centerTitle: false,
        actions: [
          if ((_isOwner || _isMember) && !_isEnded)
            Builder(
              builder: (context) {
                return IconButton(
                  onPressed: () => _shareGroup(context),
                  icon: const Icon(Icons.ios_share_outlined),
                  tooltip: 'Share group',
                );
              },
            ),
          if (_isOwner && !_isEnded)
            IconButton(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Group settings',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GroupHeroCard(
                statusLabel: _statusLabel,
                statusColor: _statusColor,
                title: _group.title,
                subtitle: _group.location,
                dateText: dateText,
                memberCountText: memberCountText,
              ),
              const SizedBox(height: 16),
              _InfoPanel(
                title: 'GROUP INFO',
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Shopping location',
                      value: _group.location,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.calendar_month_rounded,
                      label: 'Schedule',
                      value: dateText,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.people_outline_rounded,
                      label: 'Capacity',
                      value: memberCountText,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.badge_outlined,
                      label: 'My status',
                      value: _isOwner
                          ? 'Host'
                          : _isMember
                          ? 'Joined'
                          : _isEnded
                          ? 'Ended'
                          : 'Not joined',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoPanel(
                title: 'PARTICIPANTS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tap a participant to view their profile and rating.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _MainVisuals.mutedText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_orderedParticipantIds.isEmpty)
                      _EmptyGroupCard(
                        title: 'No participants found.',
                        subtitle: 'The participant list will appear here.',
                      )
                    else
                      for (
                        var i = 0;
                        i < _orderedParticipantIds.length;
                        i++
                      ) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _GroupParticipantTile(
                          userId: _orderedParticipantIds[i],
                          isHost: _orderedParticipantIds[i] == _group.ownerId,
                          currentUserId: _group.currentUserId,
                          onTap: () =>
                              _openMemberProfile(_orderedParticipantIds[i]),
                        ),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoPanel(
                title: 'ITEMS',
                child: _GroupItemsView(
                  items: _group.items,
                  isMember: _isMember,
                  isEnded: _isEnded,
                  currentUserId: _group.currentUserId,
                  onToggleClaim: _claimItem,
                ),
              ),
              const SizedBox(height: 16),
              _InfoPanel(
                title: 'NEXT STEP',
                child: Text(
                  _isEnded
                      ? 'This group has ended. Go back to find another group.'
                      : _isRatingOpen
                      ? 'The meeting time has passed. You can view participants and rate them for one week.'
                      : _isOwner
                      ? 'As host, use the settings icon to edit or end the group.'
                      : _isMember
                      ? 'You can open chat or leave the group from the actions below.'
                      : 'A Join button appears below when you are not yet a member.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _MainVisuals.mutedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _buildActionBar(context),
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    if (_isEnded) {
      return _ActionButton(
        label: 'Back',
        icon: Icons.arrow_back_rounded,
        filled: true,
        onPressed: () => Navigator.of(context).maybePop(),
      );
    }

    if (_isOwner) {
      return _ActionButton(
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        filled: true,
        onPressed: _openChat,
      );
    }

    if (_isMember) {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Chat',
              icon: Icons.chat_bubble_outline_rounded,
              filled: true,
              onPressed: _openChat,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              label: 'Leave group',
              icon: Icons.exit_to_app_rounded,
              filled: false,
              onPressed: _handleLeave,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: _isSubmitting
                ? 'Joining...'
                : _isMeetingPassed
                ? 'Meeting passed'
                : _isRecruitmentClosed
                ? 'Recruitment closed'
                : _group.isFull
                ? 'Group is full'
                : 'Join group',
            icon: Icons.how_to_reg_rounded,
            filled: true,
            enabled: _isJoinable && !_isSubmitting,
            onPressed: _handleJoin,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Back',
            icon: Icons.arrow_back_rounded,
            filled: false,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ],
    );
  }
}

class _GroupHeroCard extends StatelessWidget {
  const _GroupHeroCard({
    required this.statusLabel,
    required this.statusColor,
    required this.title,
    required this.subtitle,
    required this.dateText,
    required this.memberCountText,
  });

  final String statusLabel;
  final Color statusColor;
  final String title;
  final String subtitle;
  final String dateText;
  final String memberCountText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _MainVisuals.featuredGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F172A),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const Spacer(),
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
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _MainVisuals.featuredMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  icon: Icons.calendar_today_outlined,
                  label: 'Schedule',
                  value: dateText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  icon: Icons.people_outline_rounded,
                  label: 'Members',
                  value: memberCountText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _MainVisuals.featuredGreen, size: 18),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _MainVisuals.featuredMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _MainVisuals.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _MainVisuals.mutedText,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _MainVisuals.softMint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _MainVisuals.green, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _MainVisuals.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupParticipantTile extends StatelessWidget {
  const _GroupParticipantTile({
    required this.userId,
    required this.isHost,
    required this.currentUserId,
    required this.onTap,
  });

  final String userId;
  final bool isHost;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: AuthService.instance.watchProfile(userId),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final displayNameValue = data?['displayName']?.toString().trim();
        final legacyNickname = data?['nickname']?.toString().trim();
        final authName = (displayNameValue?.isNotEmpty ?? false)
            ? displayNameValue!
            : (legacyNickname?.isNotEmpty ?? false)
            ? legacyNickname!
            : userId;
        final photoUrlValue = data?['photoURL']?.toString().trim();
        final photoUrl = (photoUrlValue?.isNotEmpty ?? false)
            ? photoUrlValue
            : null;
        final ratingAverage = _readDouble(
          data?['ratingAverage'],
          fallback: 0.0,
        );
        final ratingCount = _readInt(data?['ratingCount'], fallback: 0);
        final initial = authName.isNotEmpty ? authName[0].toUpperCase() : 'U';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _MainVisuals.pageBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _MainVisuals.cardBorder),
              ),
              child: Row(
                children: [
                  _ProfileAvatar(initial: initial, photoUrl: photoUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                authName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: _MainVisuals.text,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isHost)
                              _MemberChip(
                                label: 'HOST',
                                background: const Color(0xFFFEF3C7),
                                foreground: const Color(0xFFD97706),
                              ),
                            if (userId == currentUserId) ...[
                              const SizedBox(width: 6),
                              _MemberChip(
                                label: 'YOU',
                                background: _MainVisuals.softMint,
                                foreground: _MainVisuals.green,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF59E0B),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ratingCount == 0
                                  ? 'No ratings yet'
                                  : ratingAverage.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: _MainVisuals.mutedText,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '($ratingCount)',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: _MainVisuals.subtleText),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _MainVisuals.subtleText,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? Colors.white : _MainVisuals.text;
    final background = filled ? _MainVisuals.green : Colors.white;
    final borderColor = filled ? Colors.transparent : _MainVisuals.cardBorder;

    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: filled
              ? _MainVisuals.cardBorder
              : Colors.white,
          disabledForegroundColor: _MainVisuals.mutedText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

String _formatGroupDateTime(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  final h = value.hour.toString().padLeft(2, '0');
  final min = value.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}

class _GroupItemsView extends StatelessWidget {
  const _GroupItemsView({
    required this.items,
    required this.isMember,
    required this.isEnded,
    required this.currentUserId,
    required this.onToggleClaim,
  });

  final List<GroupItem> items;
  final bool isMember;
  final bool isEnded;
  final String currentUserId;
  final ValueChanged<String> onToggleClaim;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'No items yet. The host can add items in group settings.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: _MainVisuals.mutedText),
      );
    }

    final claimedCount = items.where((item) => item.isClaimed).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${items.length} items · $claimedCount claimed',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: _MainVisuals.mutedText),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _GroupItemTile(
            item: items[i],
            isMine: items[i].claimedBy == currentUserId,
            canClaim: isMember && !isEnded,
            onToggle: () => onToggleClaim(items[i].id),
          ),
        ],
      ],
    );
  }
}

class _GroupItemTile extends StatelessWidget {
  const _GroupItemTile({
    required this.item,
    required this.isMine,
    required this.canClaim,
    required this.onToggle,
  });

  final GroupItem item;
  final bool isMine;
  final bool canClaim;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _MainVisuals.pageBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _MainVisuals.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _MainVisuals.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.category} · qty ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _MainVisuals.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildClaimAction(),
        ],
      ),
    );
  }

  Widget _buildClaimAction() {
    if (isMine) {
      return TextButton.icon(
        onPressed: canClaim ? onToggle : null,
        icon: const Icon(Icons.check_circle_rounded, size: 16),
        label: const Text('Mine'),
        style: TextButton.styleFrom(
          foregroundColor: _MainVisuals.green,
          backgroundColor: _MainVisuals.softMint,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (item.isClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Claimed',
          style: TextStyle(
            color: _MainVisuals.mutedText,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    if (!canClaim) {
      return const Text(
        'Open',
        style: TextStyle(
          color: _MainVisuals.subtleText,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return TextButton(
      onPressed: onToggle,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _MainVisuals.green,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Claim'),
    );
  }
}
