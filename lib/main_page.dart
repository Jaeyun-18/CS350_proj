import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth/auth_service.dart';
import 'groupcreate.dart' as groupcreate;

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.user});

  final User user;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final Future<void> _profileInitFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _profileInitFuture = AuthService.instance.ensureProfile(widget.user);
  }

  Future<void> _editPreferredLocation(String? currentValue) async {
    final chosen = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('선호 위치 선택'),
                subtitle: Text('이 값은 나중에 다시 바꿀 수 있어요.'),
              ),
              for (final location in AuthService.preferredLocations)
                ListTile(
                  title: Text(location),
                  trailing: location == currentValue
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    Navigator.of(context).pop(location);
                  },
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || chosen == null) {
      return;
    }

    await AuthService.instance.updatePreferredLocation(
      uid: widget.user.uid,
      preferredLocation: chosen,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('선호 위치를 저장했어요.')));
  }

  void _openCreateGroup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const groupcreate.GroupCreatePage(),
      ),
    );
  }

  void _showFilterPlaceholder() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('필터 화면은 다음 단계에서 연결할 예정이에요.')));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _profileInitFuture,
      builder: (context, initSnapshot) {
        if (initSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (initSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('프로필을 불러오지 못했어요.\n${initSnapshot.error}'),
              ),
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: AuthService.instance.watchProfile(widget.user.uid),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final displayNameValue = data?['displayName']?.toString().trim();
            final nicknameValue = data?['nickname']?.toString().trim();
            final preferredLocationValue = data?['preferredLocation']
                ?.toString()
                .trim();
            final authDisplayName = widget.user.displayName?.trim();
            final displayName = (displayNameValue?.isNotEmpty ?? false)
                ? displayNameValue!
                : (nicknameValue?.isNotEmpty ?? false)
                ? nicknameValue!
                : (authDisplayName?.isNotEmpty ?? false)
                ? authDisplayName!
                : '학생';
            final preferredLocation =
                (preferredLocationValue?.isNotEmpty ?? false)
                ? preferredLocationValue
                : null;
            final emailVerified =
                data?['emailVerified'] == true || widget.user.emailVerified;
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('group')
                  .snapshots(),
              builder: (context, groupSnapshot) {
                final groupDocs = groupSnapshot.data?.docs ?? [];
                final homePage = _HomeTab(
                  user: widget.user,
                  displayName: displayName,
                  preferredLocation: preferredLocation,
                  emailVerified: emailVerified,
                  docs: groupDocs,
                  onCreateGroup: _openCreateGroup,
                  onEditPreferredLocation: _editPreferredLocation,
                  onFilterPressed: _showFilterPlaceholder,
                );

                // TODO: Implement the My Groups page and connect it to joined/hosted group data.
                const myGroupsPage = _BlankTab();

                // TODO: Implement the My Page screen with profile editing and account settings.
                const myPage = _BlankTab();

                final pages = <Widget>[homePage, myGroupsPage, myPage];

                return Scaffold(
                  body: Container(
                    decoration: const BoxDecoration(
                      gradient: _MainVisuals.pageGradient,
                    ),
                    child: IndexedStack(index: _selectedIndex, children: pages),
                  ),
                  bottomNavigationBar: _MainBottomBar(
                    selectedIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.user,
    required this.displayName,
    required this.preferredLocation,
    required this.emailVerified,
    required this.docs,
    required this.onCreateGroup,
    required this.onEditPreferredLocation,
    required this.onFilterPressed,
  });

  final User user;
  final String displayName;
  final String? preferredLocation;
  final bool emailVerified;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final VoidCallback onCreateGroup;
  final Future<void> Function(String? currentValue) onEditPreferredLocation;
  final VoidCallback onFilterPressed;

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
    final featuredDoc = docs.isNotEmpty ? docs.first : null;
    final remainingDocs = docs.length > 1 ? docs.sublist(1) : const [];

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
                'Open Groups',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _MainVisuals.text,
                  fontWeight: FontWeight.w800,
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
          if (docs.isEmpty)
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
                    'Create a Group 버튼으로 첫 그룹을 만들어보세요.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _MainVisuals.mutedText,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _FeaturedGroupCard(
              data: featuredDoc!.data(),
              currentUserId: user.uid,
              formatDateTime: _formatDateTime,
            ),
            const SizedBox(height: 12),
            for (final doc in remainingDocs) ...[
              _CompactGroupCard(
                data: doc.data(),
                currentUserId: user.uid,
                formatDateTime: _formatDateTime,
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

class _FeaturedGroupCard extends StatelessWidget {
  const _FeaturedGroupCard({
    required this.data,
    required this.currentUserId,
    required this.formatDateTime,
  });

  final Map<String, dynamic> data;
  final String currentUserId;
  final String Function(DateTime value) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final userId = data['user_id']?.toString() ?? '';
    final title = data['name']?.toString() ?? '(no name)';
    final location = data['location']?.toString() ?? '(no location)';
    final maxNum = data['max_num']?.toString() ?? '(no max)';
    final nowNum = data['now_num']?.toString() ?? '0';
    final Timestamp? date = data['date_time'] as Timestamp?;
    final dateText = date == null ? '(no date)' : formatDateTime(date.toDate());
    final isOwner = userId == currentUserId;

    return Container(
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
                      location.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _MainVisuals.featuredGreen,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                        Text(
                          dateText,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: _MainVisuals.featuredMuted),
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
                '$nowNum / $maxNum members',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _MainVisuals.featuredMuted,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
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
                child: Text(isOwner ? 'Edit →' : 'View →'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactGroupCard extends StatelessWidget {
  const _CompactGroupCard({
    required this.data,
    required this.currentUserId,
    required this.formatDateTime,
  });

  final Map<String, dynamic> data;
  final String currentUserId;
  final String Function(DateTime value) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final userId = data['user_id']?.toString() ?? '';
    final title = data['name']?.toString() ?? '(no name)';
    final location = data['location']?.toString() ?? '(no location)';
    final maxNum = data['max_num']?.toString() ?? '(no max)';
    final nowNum = data['now_num']?.toString() ?? '0';
    final Timestamp? date = data['date_time'] as Timestamp?;
    final dateText = date == null ? '(no date)' : formatDateTime(date.toDate());
    final isOwner = userId == currentUserId;

    return Container(
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
              color: isOwner ? _MainVisuals.softMint : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isOwner ? Icons.storefront_outlined : Icons.shopping_bag_outlined,
              color: isOwner ? _MainVisuals.green : const Color(0xFFEA580C),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _MainVisuals.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$location · $dateText',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _MainVisuals.mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$nowNum / $maxNum members',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _MainVisuals.subtleText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor: isOwner
                  ? _MainVisuals.softMint
                  : _MainVisuals.pageBackground,
              foregroundColor: isOwner ? _MainVisuals.green : _MainVisuals.text,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isOwner
                      ? _MainVisuals.softBorder
                      : _MainVisuals.cardBorder,
                ),
              ),
            ),
            child: Text(isOwner ? 'Edit' : 'JOIN'),
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

class _MainBottomBar extends StatelessWidget {
  const _MainBottomBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _MainNavItem(
              label: 'Home',
              icon: Icons.home_rounded,
              selected: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            _MainNavItem(
              label: 'My Groups',
              icon: Icons.groups_rounded,
              selected: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
            _MainNavItem(
              label: 'My Page',
              icon: Icons.person_rounded,
              selected: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainNavItem extends StatelessWidget {
  const _MainNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? _MainVisuals.green : _MainVisuals.navInactive,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? _MainVisuals.green : _MainVisuals.text,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _MainVisuals.cardBorder),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: _MainVisuals.subtleText,
            size: 20,
          ),
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFF97316),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: _MainVisuals.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StackAvatar extends StatelessWidget {
  const _StackAvatar({
    required this.letter,
    required this.background,
    required this.textColor,
  });

  final String letter;
  final Gradient background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: background,
        shape: BoxShape.circle,
        border: Border.all(color: _MainVisuals.featuredBorder, width: 2),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _MainVisuals {
  static const Color pageBackground = Color(0xFFF8FAFC);
  static const Color text = Color(0xFF0F172A);
  static const Color subtleText = Color(0xFF94A3B8);
  static const Color mutedText = Color(0xFF64748B);
  static const Color navInactive = Color(0xFF334155);
  static const Color green = Color(0xFF22C55E);
  static const Color softMint = Color(0xFFF0FAF4);
  static const Color softBorder = Color(0xFFD1FAE5);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color featuredBorder = Color(0xFF1E293B);
  static const Color featuredMuted = Color(0xFFCBD5E1);
  static const Color featuredGreen = Color(0xFF4ADE80);
  static const Color featuredButton = Color(0xFF4ADE80);
  static const Color featuredBadge = Color(0x264ADE80);
  static const Color locationText = Color(0xFF1A2E1A);

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pageBackground, pageBackground],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF72DCA0), Color(0xFF22C55E)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6EE7A0), Color(0xFF22C55E)],
  );

  static const LinearGradient featuredGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111827), Color(0xFF334155)],
  );
}
