import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 공동구매 품목 카테고리. 그룹 품목 필터와 동일 품목 중복 참여 제한에서도
/// 같은 목록을 재사용한다.
const List<String> kItemCategories = <String>[
  'Fresh',
  'Chilled/Frozen',
  'Packaged',
  'Beverage',
  'Household',
  'Other',
];

/// 그룹 공동구매 품목 한 건.
@immutable
class GroupItem {
  const GroupItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    this.claimedBy,
  });

  factory GroupItem.fromMap(Map<String, dynamic> map) {
    final rawQuantity = map['quantity'];
    final rawClaimedBy = map['claimedBy']?.toString();
    final rawId = map['id']?.toString();
    return GroupItem(
      id: (rawId != null && rawId.isNotEmpty) ? rawId : newGroupItemId(),
      name: map['name']?.toString() ?? '',
      category: _normalizeCategory(map['category']?.toString()),
      quantity: rawQuantity is num && rawQuantity > 0 ? rawQuantity.toInt() : 1,
      claimedBy: (rawClaimedBy != null && rawClaimedBy.isNotEmpty)
          ? rawClaimedBy
          : null,
    );
  }

  /// 품목 배열 안에서 항목을 안정적으로 식별하는 ID.
  final String id;
  final String name;
  final String category;
  final int quantity;

  /// 이 품목을 담당하기로 한 멤버 UID. 미담당이면 null.
  final String? claimedBy;

  bool get isClaimed => claimedBy != null && claimedBy!.isNotEmpty;

  GroupItem claimedByUser(String uid) => GroupItem(
    id: id,
    name: name,
    category: category,
    quantity: quantity,
    claimedBy: uid,
  );

  GroupItem released() =>
      GroupItem(id: id, name: name, category: category, quantity: quantity);

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'category': category,
    'quantity': quantity,
    'claimedBy': claimedBy,
  };
}

String _normalizeCategory(String? value) {
  if (value != null && kItemCategories.contains(value)) {
    return value;
  }
  return kItemCategories.last;
}

/// 그룹 문서 데이터에서 품목 목록을 읽는다.
List<GroupItem> readGroupItems(Map<String, dynamic> data) {
  final raw = data['items'];
  if (raw is! Iterable) {
    return const <GroupItem>[];
  }
  return raw
      .whereType<Map>()
      .map((entry) => GroupItem.fromMap(Map<String, dynamic>.from(entry)))
      .toList();
}

/// 품목 목록을 Firestore 저장용 맵 리스트로 변환한다.
List<Map<String, dynamic>> itemsToMaps(List<GroupItem> items) =>
    items.map((item) => item.toMap()).toList();

/// 품목 목록에서 중복 없는 카테고리 집합을 뽑는다.
Set<String> categoriesOf(List<GroupItem> items) =>
    items.map((item) => item.category).toSet();

final Random _itemIdRandom = Random();

/// 품목 배열 안에서 항목을 안정적으로 식별하기 위한 새 ID를 만든다.
String newGroupItemId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
    '${_itemIdRandom.nextInt(1 << 32).toRadixString(36)}';

/// 그룹 문서의 한 품목 담당을 토글한다.
///
/// 본인이 담당 중이면 해제하고, 미담당이면 담당으로 잡는다. 이미 다른 멤버가
/// 담당 중이면 [StateError]를 던진다. 품목은 인덱스가 아닌 [itemId]로 찾아
/// 동시 추가/삭제와 무관하게 정확한 항목을 갱신한다.
Future<void> toggleItemClaim({
  required DocumentReference<Map<String, dynamic>> groupRef,
  required String itemId,
  required String uid,
}) {
  return FirebaseFirestore.instance.runTransaction((transaction) async {
    if (uid.isEmpty) {
      throw StateError('Cannot verify your sign-in.');
    }
    final snapshot = await transaction.get(groupRef);
    final items = readGroupItems(snapshot.data() ?? <String, dynamic>{});
    final index = items.indexWhere((item) => item.id == itemId);
    if (index < 0) {
      throw StateError('Item not found.');
    }

    final item = items[index];
    final GroupItem updated;
    if (item.claimedBy == uid) {
      updated = item.released();
    } else if (item.isClaimed) {
      throw StateError('Another member already claimed this item.');
    } else {
      updated = item.claimedByUser(uid);
    }

    final nextItems = [...items]..[index] = updated;
    transaction.update(groupRef, {
      'items': itemsToMaps(nextItems),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });
}

/// 호스트의 품목 편집을 저장하되, 현재 문서에 살아있는 담당(claimedBy)을
/// 품목 id 기준으로 보존한다. 설정 저장이 다른 멤버의 담당 변경을 덮어쓰지
/// 않도록 트랜잭션으로 병합한다.
Future<void> saveGroupItems({
  required DocumentReference<Map<String, dynamic>> groupRef,
  required List<GroupItem> editedItems,
}) {
  return FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(groupRef);
    final current = readGroupItems(snapshot.data() ?? <String, dynamic>{});
    final liveClaims = <String, String>{
      for (final item in current)
        if (item.claimedBy != null) item.id: item.claimedBy!,
    };
    final merged = editedItems.map((item) {
      final claim = liveClaims[item.id];
      return claim == null ? item.released() : item.claimedByUser(claim);
    }).toList();
    transaction.update(groupRef, {
      'items': itemsToMaps(merged),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });
}
