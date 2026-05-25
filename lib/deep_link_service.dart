import 'dart:async';

import 'package:app_links/app_links.dart';

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  final StreamController<String> _groupIdController =
      StreamController<String>.broadcast();

  Stream<String> get groupIdStream => _groupIdController.stream;

  String? _pendingGroupId;
  StreamSubscription<Uri>? _subscription;

  Future<void> init() async {
    if (_subscription != null) {
      return;
    }

    _subscription = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    final groupId = parseGroupId(uri);
    if (groupId == null || groupId.isEmpty) {
      return;
    }

    _pendingGroupId = groupId;
    _groupIdController.add(groupId);
  }

  Uri buildGroupUri(String groupId) {
    return Uri(scheme: 'webuydivvy', host: 'group', pathSegments: [groupId]);
  }

  String? parseGroupId(Uri uri) {
    if (uri.host == 'group' && uri.pathSegments.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.first);
    }

    if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'group') {
      return Uri.decodeComponent(uri.pathSegments[1]);
    }

    final queryGroupId = uri.queryParameters['groupId'];
    if (queryGroupId != null && queryGroupId.trim().isNotEmpty) {
      return queryGroupId.trim();
    }

    return null;
  }

  String? takePendingGroupId() {
    final groupId = _pendingGroupId;
    _pendingGroupId = null;
    return groupId;
  }

  void clearPendingGroupId(String groupId) {
    if (_pendingGroupId == groupId) {
      _pendingGroupId = null;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _groupIdController.close();
  }
}
