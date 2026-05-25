import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'auth/auth_service.dart';
import 'deep_link_service.dart';
import 'chat_page.dart';
import 'chat_service.dart';
import 'group_filter.dart';
import 'group_items.dart';
import 'group_items_editor.dart';
import 'groupcreate.dart' as groupcreate;
import 'messaging_service.dart';
import 'rating_service.dart';
import 'profile_edit_page.dart';

part 'main_page_tabs.dart';
part 'group_page.dart';
part 'group_settings_page.dart';
part 'my_groups_page.dart';
part 'user_profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.user});

  final User user;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final Future<void> _profileInitFuture;
  StreamSubscription<String>? _deepLinkSubscription;
  int _selectedIndex = 0;
  GroupFilter _filter = GroupFilter();

  @override
  void initState() {
    super.initState();
    _profileInitFuture = AuthService.instance.ensureProfile(widget.user);
    // 로그인 직후 FCM 토큰 등록(외부 인프라 미구성이면 silent no-op).
    unawaited(MessagingService.instance.registerForUser(widget.user.uid));
    _deepLinkSubscription = DeepLinkService.instance.groupIdStream.listen((
      groupId,
    ) {
      DeepLinkService.instance.clearPendingGroupId(groupId);
      unawaited(_openGroupFromDeepLink(groupId));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingGroupId = DeepLinkService.instance.takePendingGroupId();
      if (pendingGroupId != null) {
        unawaited(_openGroupFromDeepLink(pendingGroupId));
      }
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
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
                title: Text('Choose preferred location'),
                subtitle: Text('You can change this later.'),
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
    ).showSnackBar(const SnackBar(content: Text('Preferred location saved.')));
  }

  void _openCreateGroup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const groupcreate.GroupCreatePage(),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('You will need to sign in again to use the app.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await MessagingService.instance.unregister();
      await AuthService.instance.signOut();
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final passwordController = TextEditingController();
    try {
      final password = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete account?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will permanently delete your profile, avatar, and sign-in account.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                    hintText: 'Enter your password to confirm',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your hosted groups will be removed automatically when you delete your account.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(passwordController.text.trim());
                },
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (!mounted || password == null || password.isEmpty) {
        return;
      }

      await AuthService.instance.deleteAccount(password: password);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyAuthMessage(error))));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    } finally {
      passwordController.dispose();
    }
  }

  Future<void> _openFilter() async {
    final result = await showGroupFilterSheet(context, _filter);
    if (result != null && mounted) {
      setState(() {
        _filter = result;
      });
    }
  }

  void _openNotifications(List<_NotificationEntry> notifications) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _MainVisuals.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Meeting reminders and rating windows appear here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _MainVisuals.mutedText,
                  ),
                ),
                const SizedBox(height: 16),
                if (notifications.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _MainVisuals.pageBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _MainVisuals.cardBorder),
                    ),
                    child: Text(
                      'No active notifications yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _MainVisuals.mutedText,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: notifications.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = notifications[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              _openGroupPage(entry.group);
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _MainVisuals.pageBackground,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _MainVisuals.cardBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: entry.accent.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      entry.icon,
                                      color: entry.accent,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: _MainVisuals.text,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.subtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: _MainVisuals.mutedText,
                                              ),
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
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
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

  Future<void> _openGroupFromDeepLink(String groupId) async {
    if (!mounted || groupId.trim().isEmpty) {
      return;
    }

    final group = await _fetchGroupById(groupId.trim());
    if (!mounted) {
      return;
    }

    if (group == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공유된 그룹을 찾을 수 없어요.')));
      return;
    }

    DeepLinkService.instance.clearPendingGroupId(groupId.trim());
    await _openGroupPage(group);
  }

  Future<_GroupEntry?> _fetchGroupById(String groupId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('group')
        .doc(groupId)
        .get();
    if (!snapshot.exists) {
      return null;
    }

    return _GroupEntry.fromData(
      id: snapshot.id,
      data: snapshot.data() ?? <String, dynamic>{},
      currentUserId: widget.user.uid,
      reference: snapshot.reference,
    );
  }

  List<_NotificationEntry> _buildNotificationEntries(List<_GroupEntry> groups) {
    final now = DateTime.now();
    final entries = <_NotificationEntry>[];

    for (final group in groups) {
      if (!group.isMember || group.isEnded || group.dateTime == null) {
        continue;
      }
      final meetingTime = group.dateTime!;
      final difference = meetingTime.difference(now);
      if (difference.inMinutes >= 0 && difference <= const Duration(days: 1)) {
        entries.add(
          _NotificationEntry(
            group: group,
            title: 'Meeting soon',
            subtitle:
                '${group.title} starts at ${_formatNotificationDateTime(meetingTime)}',
            icon: Icons.schedule_rounded,
            accent: const Color(0xFF0EA5E9),
            priority: 0,
          ),
        );
      } else if (now.isAfter(meetingTime) &&
          now.isBefore(meetingTime.add(const Duration(days: 7)))) {
        entries.add(
          _NotificationEntry(
            group: group,
            title: 'Rate members',
            subtitle:
                'You can still rate participants for ${group.title} until 7 days after the meeting.',
            icon: Icons.star_rounded,
            accent: const Color(0xFFF59E0B),
            priority: 1,
          ),
        );
      }
    }

    entries.sort((a, b) {
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      final dateA = a.group.dateTime;
      final dateB = b.group.dateTime;
      if (dateA != null && dateB != null) {
        return dateA.compareTo(dateB);
      }
      return a.title.compareTo(b.title);
    });

    return entries;
  }

  String _formatNotificationDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Future<void> _openProfileEdit({
    required String displayName,
    required String? photoUrl,
  }) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ProfileEditPage(
          uid: widget.user.uid,
          currentDisplayName: displayName,
          currentPhotoUrl: photoUrl,
        ),
      ),
    );
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

  /// 동일 품목 카테고리 그룹에 이미 참여 중이면 그 카테고리명을, 없으면 null을
  /// 반환한다(명세 5.4.2 — 동일 품목 카테고리 중복 참여 제한).
  Future<String?> _findCategoryConflict(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final targetSnapshot = await ref.get();
    final targetData = targetSnapshot.data();
    if (targetData == null) {
      return null;
    }
    final targetCategories = categoriesOf(
      _GroupEntry.fromData(
        id: ref.id,
        data: targetData,
        currentUserId: widget.user.uid,
      ).items,
    );
    if (targetCategories.isEmpty) {
      return null;
    }

    final myGroups = await FirebaseFirestore.instance
        .collection('group')
        .where('member_ids', arrayContains: widget.user.uid)
        .get();
    for (final doc in myGroups.docs) {
      if (doc.id == ref.id) {
        continue;
      }
      final other = _GroupEntry.fromData(
        id: doc.id,
        data: doc.data(),
        currentUserId: widget.user.uid,
      );
      if (other.isEnded) {
        continue;
      }
      final overlap = targetCategories.intersection(categoriesOf(other.items));
      if (overlap.isNotEmpty) {
        return overlap.first;
      }
    }
    return null;
  }

  Future<bool> _joinGroup(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      final conflictCategory = await _findCategoryConflict(ref);
      if (conflictCategory != null) {
        if (!mounted) {
          return false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You are already in a "$conflictCategory" group, so you cannot join.',
            ),
          ),
        );
        return false;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'Group not found.',
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
            message: 'This group has already ended.',
          );
        }
        if (group.isMember) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'You are already in this group.',
          );
        }
        if (group.isFull) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'This group is already full.',
          );
        }

        transaction.update(ref, {
          'now_num': FieldValue.increment(1),
          'member_ids': FieldValue.arrayUnion([widget.user.uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      try {
        await FirestoreChatService.instance.postMembershipNotice(
          groupId: ref.id,
          uid: widget.user.uid,
          joined: true,
        );
      } on Exception catch (_) {
        // 시스템 메시지 실패는 참여 자체를 막지 않는다.
      }

      if (!mounted) {
        return true;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Joined the group.')));
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Join failed: $error')));
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
                child: Text('Failed to load profile.\n${initSnapshot.error}'),
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
            final ratingAverageValue = data?['ratingAverage'];
            final ratingCountValue = data?['ratingCount'];
            final authDisplayName = widget.user.displayName?.trim();
            final authPhotoUrl = widget.user.photoURL?.trim();
            final displayName = (displayNameValue?.isNotEmpty ?? false)
                ? displayNameValue!
                : (nicknameValue?.isNotEmpty ?? false)
                ? nicknameValue!
                : (authDisplayName?.isNotEmpty ?? false)
                ? authDisplayName!
                : 'Student';
            final preferredLocation =
                (preferredLocationValue?.isNotEmpty ?? false)
                ? preferredLocationValue
                : null;
            final photoUrlValue = data?['photoURL']?.toString().trim();
            final photoUrl = (photoUrlValue?.isNotEmpty ?? false)
                ? photoUrlValue
                : (authPhotoUrl?.isNotEmpty ?? false)
                ? authPhotoUrl
                : null;
            final emailVerified =
                data?['emailVerified'] == true || widget.user.emailVerified;
            final ratingAverage = _readDouble(
              ratingAverageValue,
              fallback: 0.0,
            );
            final ratingCount = _readInt(ratingCountValue, fallback: 0);
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
                        .where(
                          (entry) =>
                              entry.isOwner && !entry.isExpiredForHistory,
                        )
                        .toList()
                      ..sort(_sortMyGroups);
                final joinedGroupEntries =
                    groupEntries
                        .where(
                          (entry) =>
                              entry.isMember &&
                              !entry.isOwner &&
                              !entry.isExpiredForHistory,
                        )
                        .toList()
                      ..sort(_sortMyGroups);
                final notificationEntries = _buildNotificationEntries(
                  groupEntries,
                );
                final homePage = _HomeTab(
                  user: widget.user,
                  displayName: displayName,
                  preferredLocation: preferredLocation,
                  emailVerified: emailVerified,
                  photoUrl: photoUrl,
                  openGroups: openGroupEntries,
                  notificationCount: notificationEntries.length,
                  onCreateGroup: _openCreateGroup,
                  onEditPreferredLocation: _editPreferredLocation,
                  onFilterPressed: _openFilter,
                  onNotificationsPressed: () =>
                      _openNotifications(notificationEntries),
                  activeFilterCount: _filter.activeCount,
                  onOpenGroup: _openGroupPage,
                );

                final myGroupsPage = _MyGroupsTab(
                  displayName: displayName,
                  hostedGroups: hostedGroupEntries,
                  joinedGroups: joinedGroupEntries,
                  onCreateGroup: _openCreateGroup,
                  onOpenGroup: _openGroupPage,
                  onOpenChat: _openChat,
                );

                final myPage = _MyPageTab(
                  displayName: displayName,
                  email: widget.user.email ?? 'No email',
                  preferredLocation: preferredLocation,
                  emailVerified: emailVerified,
                  photoUrl: photoUrl,
                  ratingAverage: ratingAverage,
                  ratingCount: ratingCount,
                  onEditPreferredLocation: _editPreferredLocation,
                  onEditProfile: () => _openProfileEdit(
                    displayName: displayName,
                    photoUrl: photoUrl,
                  ),
                  onLogout: _confirmLogout,
                  onDeleteAccount: _confirmDeleteAccount,
                );

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

  bool get isUpcoming {
    final scheduled = dateTime;
    if (scheduled == null) {
      return true;
    }
    return scheduled.isAfter(DateTime.now());
  }

  bool get isJoinable =>
      !isEnded && isRecruitmentOpen && !isMember && !isFull && isUpcoming;

  int get remainingSlots => maxNum <= 0 ? 0 : maxNum - nowNum;

  bool get isExpiredForHistory {
    final scheduled = dateTime;
    if (scheduled == null) {
      return false;
    }
    return DateTime.now().isAfter(scheduled.add(const Duration(days: 7)));
  }

  DocumentReference<Map<String, dynamic>> get docRef {
    final ref = reference;
    if (ref == null) {
      throw StateError('Document reference is not attached to this entry.');
    }
    return ref;
  }
}

class _NotificationEntry {
  const _NotificationEntry({
    required this.group,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.priority,
  });

  final _GroupEntry group;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final int priority;
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

double _readDouble(dynamic value, {required double fallback}) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
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
  const _NotificationButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
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
              if (count > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
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

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.letter, this.photoUrl});

  final String letter;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: hasPhoto ? null : _MainVisuals.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        image: hasPhoto
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: hasPhoto
          ? null
          : Center(
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
