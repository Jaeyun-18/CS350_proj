import 'package:flutter/material.dart';

import 'group_items.dart';

const Color _filterText = Color(0xFF0F172A);
const Color _filterMuted = Color(0xFF64748B);
const Color _filterGreen = Color(0xFF22C55E);

/// 그룹 피드 필터 대상 마켓 위치.
const List<String> kGroupLocations = <String>[
  'Homeplus Yusung',
  'Traders Wolpyeong',
  'KAIST Area',
];

/// 홈 피드 그룹 필터 조건. 두 집합이 모두 비어 있으면 전체를 의미한다.
@immutable
class GroupFilter {
  GroupFilter({
    Set<String> locations = const <String>{},
    Set<String> categories = const <String>{},
  }) : locations = Set<String>.unmodifiable(locations),
       categories = Set<String>.unmodifiable(categories);

  final Set<String> locations;
  final Set<String> categories;

  bool get isEmpty => locations.isEmpty && categories.isEmpty;

  int get activeCount => locations.length + categories.length;

  /// 그룹의 위치·품목 카테고리가 현재 필터를 통과하는지 검사한다.
  bool matches({
    required String location,
    required Set<String> itemCategories,
  }) {
    if (locations.isNotEmpty && !locations.contains(location)) {
      return false;
    }
    if (categories.isNotEmpty &&
        categories.intersection(itemCategories).isEmpty) {
      return false;
    }
    return true;
  }
}

/// 위치·품목 카테고리를 다중 선택하는 바텀시트. 취소 시 null을 반환한다.
Future<GroupFilter?> showGroupFilterSheet(
  BuildContext context,
  GroupFilter current,
) {
  return showModalBottomSheet<GroupFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _GroupFilterSheet(initial: current),
  );
}

class _GroupFilterSheet extends StatefulWidget {
  const _GroupFilterSheet({required this.initial});

  final GroupFilter initial;

  @override
  State<_GroupFilterSheet> createState() => _GroupFilterSheetState();
}

class _GroupFilterSheetState extends State<_GroupFilterSheet> {
  late final Set<String> _locations = {...widget.initial.locations};
  late final Set<String> _categories = {...widget.initial.categories};

  void _toggle(Set<String> target, String value) {
    setState(() {
      if (!target.add(value)) {
        target.remove(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _locations.isEmpty && _categories.isEmpty;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '그룹 필터',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _filterText,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: isEmpty
                        ? null
                        : () => setState(() {
                            _locations.clear();
                            _categories.clear();
                          }),
                    child: const Text('초기화'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _label('마켓 위치'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final location in kGroupLocations)
                    _FilterOptionChip(
                      label: location,
                      selected: _locations.contains(location),
                      onTap: () => _toggle(_locations, location),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _label('품목 카테고리'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in kItemCategories)
                    _FilterOptionChip(
                      label: category,
                      selected: _categories.contains(category),
                      onTap: () => _toggle(_categories, category),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(
                    GroupFilter(
                      locations: {..._locations},
                      categories: {..._categories},
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: _filterGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '적용',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: _filterMuted,
      letterSpacing: 0.6,
    ),
  );
}

class _FilterOptionChip extends StatelessWidget {
  const _FilterOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: const Color(0xFFDCFCE7),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide(
        color: selected ? _filterGreen : const Color(0xFFE2E8F0),
      ),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF166534) : _filterText,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
