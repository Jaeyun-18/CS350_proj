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

  @override
  void initState() {
    super.initState();
    _profileInitFuture = AuthService.instance.ensureProfile(widget.user);
  }

  String _formatDateTime(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Future<void> _editPreferredLocation(String? currentValue) async {
    final chosen = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('선호 위치를 저장했어요.')),
    );
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
            final preferredLocationValue =
                data?['preferredLocation']?.toString().trim();
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
            final emailVerified = data?['emailVerified'] == true ||
                widget.user.emailVerified;

            return Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: const Text('Group List'),
                actions: [
                  IconButton(
                    tooltip: '로그아웃',
                    onPressed: () async {
                      await AuthService.instance.signOut();
                    },
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '안녕하세요, $displayName',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(widget.user.email ?? ''),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Chip(
                                      label: Text(
                                        emailVerified ? '이메일 인증 완료' : '이메일 인증 대기',
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        preferredLocation ?? '선호 위치 미설정',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _editPreferredLocation(preferredLocation),
                                    icon: const Icon(Icons.tune),
                                    label: Text(
                                      preferredLocation == null
                                          ? '선호 위치 선택'
                                          : '선호 위치 변경',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Group List',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('group')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                return const Center(
                                  child: Text('데이터를 불러오지 못했습니다.'),
                                );
                              }

                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return const Center(
                                  child: Text('등록된 그룹이 없습니다.'),
                                );
                              }

                              return ListView.separated(
                                itemCount: docs.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data();
                                  final name =
                                      data['name']?.toString() ?? '(no name)';
                                  final location = data['location']?.toString() ??
                                      '(no location)';
                                  final maxNum =
                                      data['max_num']?.toString() ?? '(no max)';
                                  final Timestamp? date =
                                      data['date_time'] as Timestamp?;
                                  final dateText = date == null
                                      ? '(no date)'
                                      : _formatDateTime(date.toDate());

                                  return Card(
                                    child: ListTile(
                                      title: Text(name),
                                      subtitle: Text(
                                        '$location\n$maxNum\n$dateText',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              floatingActionButton: SizedBox(
                width: 160,
                height: 64,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const groupcreate.GroupCreatePage(),
                      ),
                    );
                  },
                  child: const Text('Create Group'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
