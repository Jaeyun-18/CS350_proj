import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth/auth_service.dart';
import 'chat_page.dart';
import 'group_filter.dart';
import 'group_items.dart';
import 'group_items_editor.dart';
import 'groupcreate.dart' as groupcreate;

part 'main_page_tabs.dart';
part 'group_page.dart';
part 'group_settings_page.dart';
part 'my_groups_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.user});

  final User user;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final Future<void> _profileInitFuture;
  int _selectedIndex = 0;
  GroupFilter _filter = GroupFilter();

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

  Future<void> _openFilter() async {
    final result = await showGroupFilterSheet(context, _filter);
    if (result != null && mounted) {
      setState(() {
        _filter = result;
      });
    }
  }

  Future<void> _openGroupPage(_GroupEntry group) async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (context) => _GroupPage(group: group, onJoinGroup: _joinGroup),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == 'open_my_groups') {
      setState(() {
        _selectedIndex = 1;
      });
    }
  }

  void _openChat(_GroupEntry group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          groupId: group.id,
          groupName: group.title,
          memberCount: group.nowNum,
          currentUserId: widget.user.uid,
        ),
      ),
    );
  }

  Future<bool> _joinGroup(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: '그룹을 찾을 수 없어요.',
          );
        }

        final data = snapshot.data() ?? <String, dynamic>{};
        final group = _GroupEntry.fromData(
          id: snapshot.id,
          data: data,
          currentUserId: widget.user.uid,
        );

        if (group.isEnded) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: '이미 종료된 그룹이에요.',
          );
        }
        if (group.isMember) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: '이미 참여 중인 그룹이에요.',
          );
        }
        if (group.isFull) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: '이미 정원이 꽉 찬 그룹이에요.',
          );
        }

        transaction.update(ref, {
          'now_num': FieldValue.increment(1),
          'member_ids': FieldValue.arrayUnion([widget.user.uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) {
        return true;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('그룹에 참여했어요.')));
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('참여 실패: $error')));
      return false;
    }
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
                final groupEntries = groupDocs
                    .map(
                      (doc) => _GroupEntry.fromSnapshot(
                        doc,
                        currentUserId: widget.user.uid,
                      ),
                    )
                    .toList();
                final openGroupEntries =
                    groupEntries
                        .where(
                          (entry) =>
                              entry.isJoinable &&
                              _filter.matches(
                                location: entry.location,
                                itemCategories: categoriesOf(entry.items),
                              ),
                        )
                        .toList()
                      ..sort(_sortOpenGroups);
                final hostedGroupEntries =
                    groupEntries
                        .where((entry) => entry.isOwner && !entry.isEnded)
                        .toList()
                      ..sort(_sortMyGroups);
                final joinedGroupEntries =
                    groupEntries
                        .where(
                          (entry) =>
                              entry.isMember &&
                              !entry.isOwner &&
                              !entry.isEnded,
                        )
                        .toList()
                      ..sort(_sortMyGroups);
                final homePage = _HomeTab(
                  user: widget.user,
                  displayName: displayName,
                  preferredLocation: preferredLocation,
                  emailVerified: emailVerified,
                  openGroups: openGroupEntries,
                  onCreateGroup: _openCreateGroup,
                  onEditPreferredLocation: _editPreferredLocation,
                  onFilterPressed: _openFilter,
                  activeFilterCount: _filter.activeCount,
                  onOpenGroup: _openGroupPage,
                  onJoinGroup: _joinGroup,
                );

                final myGroupsPage = _MyGroupsTab(
                  displayName: displayName,
                  hostedGroups: hostedGroupEntries,
                  joinedGroups: joinedGroupEntries,
                  onCreateGroup: _openCreateGroup,
                  onOpenGroup: _openGroupPage,
                  onOpenChat: _openChat,
                );

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

class _GroupEntry {
  _GroupEntry.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot, {
    required this.currentUserId,
  }) : id = snapshot.id,
       data = snapshot.data(),
       reference = snapshot.reference;

  _GroupEntry.fromData({
    required this.id,
    required this.data,
    required this.currentUserId,
    this.reference,
  });

  final String id;
  final Map<String, dynamic> data;
  final String currentUserId;
  final DocumentReference<Map<String, dynamic>>? reference;

  String get ownerId => data['user_id']?.toString() ?? '';

  String get title => data['name']?.toString() ?? '(no name)';

  String get location => data['location']?.toString() ?? '(no location)';

  String get status => data['status']?.toString() ?? 'active';

  bool get isEnded => status == 'ended';

  String get recruitmentStatus =>
      data['recruitment_status']?.toString() ?? 'open';

  bool get isRecruitmentOpen => recruitmentStatus == 'open';

  bool get isRecruitmentClosed => recruitmentStatus == 'closed';

  int get maxNum => _readInt(data['max_num'], fallback: 0);

  int get nowNum => _readInt(data['now_num'], fallback: 0);

  DateTime? get dateTime => _readDateTime(data['date_time']);

  List<String> get memberIds {
    final rawMembers = _readStringList(data['member_ids']);
    if (rawMembers.isNotEmpty) {
      return rawMembers;
    }
    if (ownerId.isEmpty) {
      return const [];
    }
    return [ownerId];
  }

  List<GroupItem> get items => readGroupItems(data);

  bool get isOwner => ownerId == currentUserId;

  bool get isMember => memberIds.contains(currentUserId);

  bool get isFull => !isEnded && maxNum > 0 && nowNum >= maxNum;

  bool get isJoinable => !isEnded && isRecruitmentOpen && !isMember && !isFull;

  int get remainingSlots => maxNum <= 0 ? 0 : maxNum - nowNum;

  DocumentReference<Map<String, dynamic>> get docRef {
    final ref = reference;
    if (ref == null) {
      throw StateError('Document reference is not attached to this entry.');
    }
    return ref;
  }
}

int _readInt(dynamic value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

DateTime? _readDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

List<String> _readStringList(dynamic value) {
  if (value is! Iterable) {
    return const [];
  }
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();
}

int _sortOpenGroups(_GroupEntry a, _GroupEntry b) {
  final dateA = a.dateTime;
  final dateB = b.dateTime;
  if (dateA != null && dateB != null) {
    final dateCompare = dateA.compareTo(dateB);
    if (dateCompare != 0) {
      return dateCompare;
    }
  } else if (dateA != null) {
    return -1;
  } else if (dateB != null) {
    return 1;
  }

  final remainingCompare = a.remainingSlots.compareTo(b.remainingSlots);
  if (remainingCompare != 0) {
    return remainingCompare;
  }

  return a.title.compareTo(b.title);
}

int _sortMyGroups(_GroupEntry a, _GroupEntry b) {
  if (a.isOwner != b.isOwner) {
    return a.isOwner ? -1 : 1;
  }

  final dateA = a.dateTime;
  final dateB = b.dateTime;
  if (dateA != null && dateB != null) {
    final dateCompare = dateA.compareTo(dateB);
    if (dateCompare != 0) {
      return dateCompare;
    }
  } else if (dateA != null) {
    return -1;
  } else if (dateB != null) {
    return 1;
  }

  return a.title.compareTo(b.title);
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
