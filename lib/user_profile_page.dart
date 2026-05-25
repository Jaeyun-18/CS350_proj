part of 'main_page.dart';

class _UserProfilePage extends StatefulWidget {
  const _UserProfilePage({
    required this.userId,
    required this.viewerUserId,
    this.groupId,
    this.groupTitle,
  });

  final String userId;
  final String viewerUserId;
  final String? groupId;
  final String? groupTitle;

  @override
  State<_UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<_UserProfilePage> {
  Future<RatingEligibility>? _eligibilityFuture;
  int _selectedRating = 0;
  bool _isSubmitting = false;

  bool get _isSelf => widget.userId == widget.viewerUserId;

  @override
  void initState() {
    super.initState();
    _refreshEligibility();
  }

  @override
  void didUpdateWidget(covariant _UserProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.viewerUserId != widget.viewerUserId ||
        oldWidget.groupId != widget.groupId) {
      _selectedRating = 0;
      _refreshEligibility();
    }
  }

  void _refreshEligibility() {
    if (widget.groupId == null || _isSelf) {
      _eligibilityFuture = null;
      return;
    }
    _eligibilityFuture = RatingService.instance.loadEligibility(
      groupId: widget.groupId!,
      viewerUid: widget.viewerUserId,
      targetUid: widget.userId,
    );
  }

  Future<void> _openEditProfile({
    required String displayName,
    required String? photoUrl,
  }) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ProfileEditPage(
          uid: widget.viewerUserId,
          currentDisplayName: displayName,
          currentPhotoUrl: photoUrl,
        ),
      ),
    );
  }

  Future<void> _submitRating(RatingEligibility eligibility) async {
    if (_isSubmitting) {
      return;
    }
    final rating = _selectedRating == 0
        ? (eligibility.existingValue ?? 0)
        : _selectedRating;
    if (rating < 1 || rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await RatingService.instance.submitRating(
        groupId: widget.groupId!,
        viewerUid: widget.viewerUserId,
        targetUid: widget.userId,
        value: rating,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedRating = rating;
        _refreshEligibility();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rating saved.')));
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rating failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MainVisuals.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _MainVisuals.text,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.3),
        ),
        centerTitle: false,
        actions: [
          if (_isSelf)
            IconButton(
              onPressed: () async {
                final snapshot = await AuthService.instance
                    .profileRef(widget.viewerUserId)
                    .get();
                final data = snapshot.data();
                final displayName =
                    data?['displayName']?.toString().trim() ??
                    widget.viewerUserId;
                final photoUrl = data?['photoURL']?.toString().trim();
                if (!mounted) {
                  return;
                }
                await _openEditProfile(
                  displayName: displayName,
                  photoUrl: (photoUrl?.isNotEmpty ?? false) ? photoUrl : null,
                );
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit profile',
            ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: AuthService.instance.watchProfile(widget.userId),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final displayNameValue = data?['displayName']?.toString().trim();
            final legacyNickname = data?['nickname']?.toString().trim();
            final displayName = (displayNameValue?.isNotEmpty ?? false)
                ? displayNameValue!
                : (legacyNickname?.isNotEmpty ?? false)
                ? legacyNickname!
                : widget.userId;
            final photoUrlValue = data?['photoURL']?.toString().trim();
            final photoUrl = (photoUrlValue?.isNotEmpty ?? false)
                ? photoUrlValue
                : null;
            final ratingAverage = _readDouble(
              data?['ratingAverage'],
              fallback: 0.0,
            );
            final ratingCount = _readInt(data?['ratingCount'], fallback: 0);
            final initial = displayName.isNotEmpty
                ? displayName[0].toUpperCase()
                : 'U';

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSelf ? 'This is your profile' : 'Group member',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: _MainVisuals.featuredMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_isSelf)
                        Material(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openEditProfile(
                              displayName: displayName,
                              photoUrl: photoUrl,
                            ),
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
                if (!_isSelf && widget.groupId != null)
                  FutureBuilder<RatingEligibility>(
                    future: _eligibilityFuture,
                    builder: (context, eligibilitySnapshot) {
                      final eligibility = eligibilitySnapshot.data;
                      if (eligibilitySnapshot.connectionState ==
                              ConnectionState.waiting &&
                          eligibility == null) {
                        return const _ProfileLoadingCard();
                      }

                      if (eligibility == null) {
                        return _InfoPanel(
                          title: 'RATING',
                          child: Text(
                            'Rating is unavailable right now.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: _MainVisuals.mutedText),
                          ),
                        );
                      }

                      if (!eligibility.canSubmit) {
                        return _InfoPanel(
                          title: 'RATING',
                          child: Text(
                            eligibility.message ??
                                'Only group participants can rate within 7 days after the meeting.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: _MainVisuals.mutedText),
                          ),
                        );
                      }

                      final effectiveRating = _selectedRating == 0
                          ? (eligibility.existingValue ?? 0)
                          : _selectedRating;
                      return _InfoPanel(
                        title: 'RATING',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.groupTitle == null
                                  ? 'Tap a star to rate this member.'
                                  : 'Tap a star to rate this member for ${widget.groupTitle}.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: _MainVisuals.mutedText),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: List.generate(5, (index) {
                                final rating = index + 1;
                                final filled = rating <= effectiveRating;
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isSubmitting
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedRating = rating;
                                            });
                                          },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: filled
                                            ? const Color(0xFFFFF7ED)
                                            : _MainVisuals.pageBackground,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: filled
                                              ? const Color(0xFFFCD34D)
                                              : _MainVisuals.cardBorder,
                                        ),
                                      ),
                                      child: Icon(
                                        filled
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              effectiveRating == 0
                                  ? (eligibility.existingValue == null
                                        ? 'Choose one star to five stars.'
                                        : 'Your current rating is ${eligibility.existingValue}/5.')
                                  : 'Selected $effectiveRating / 5',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: _MainVisuals.subtleText),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting || effectiveRating == 0
                                    ? null
                                    : () => _submitRating(eligibility),
                                icon: const Icon(Icons.check_rounded),
                                label: Text(
                                  _selectedRating == 0 &&
                                          eligibility.existingValue != null
                                      ? 'Update rating'
                                      : 'Save rating',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _MainVisuals.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                else if (_isSelf)
                  _InfoPanel(
                    title: 'PROFILE',
                    child: Text(
                      'Use the edit button to update your profile photo and nickname.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _MainVisuals.mutedText,
                      ),
                    ),
                  )
                else
                  _InfoPanel(
                    title: 'RATING',
                    child: Text(
                      'Ratings are public, but only group participants can submit them during the 7-day window after the meeting.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _MainVisuals.mutedText,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileLoadingCard extends StatelessWidget {
  const _ProfileLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _MainVisuals.cardBorder),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
