import 'package:flutter/material.dart';

import 'group_items.dart';

const Color _editorBorder = Color(0xFFE2E8F0);
const Color _editorMuted = Color(0xFF64748B);
const Color _editorGreen = Color(0xFF22C55E);
const Color _editorText = Color(0xFF0F172A);
const Color _editorSurface = Color(0xFFF8FAFC);

/// 그룹 생성·설정 화면에서 공동구매 품목 목록을 편집하는 위젯.
///
/// 부모가 [items]를 보관하고, 변경 시 [onChanged]로 새 목록을 받는
/// 제어 컴포넌트다.
class GroupItemsEditor extends StatelessWidget {
  const GroupItemsEditor({
    super.key,
    required this.items,
    required this.onChanged,
  });

  final List<GroupItem> items;
  final ValueChanged<List<GroupItem>> onChanged;

  Future<void> _addItem(BuildContext context) async {
    final item = await showItemDialog(context);
    if (item != null) {
      onChanged([...items, item]);
    }
  }

  void _removeAt(int index) {
    onChanged([...items]..removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No items yet. Add what you want to buy together.',
              style: TextStyle(color: _editorMuted, fontSize: 13),
            ),
          )
        else
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ItemRow(item: items[i], onRemove: () => _removeAt(i)),
            ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => _addItem(context),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add item'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: _editorGreen,
            side: const BorderSide(color: Color(0xFF86EFAC)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onRemove});

  final GroupItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _editorSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _editorBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: _editorText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.category} · qty ${item.quantity}',
                  style: const TextStyle(color: _editorMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: _editorMuted,
            tooltip: 'Remove item',
          ),
        ],
      ),
    );
  }
}

/// 품목 이름·카테고리·수량을 입력받는 다이얼로그. 취소 시 null을 반환한다.
Future<GroupItem?> showItemDialog(BuildContext context) {
  return showDialog<GroupItem>(
    context: context,
    builder: (context) => const _ItemDialog(),
  );
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog();

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _category = kItemCategories.first;
  int _quantity = 1;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter an item name.');
      return;
    }
    Navigator.of(context).pop(
      GroupItem(
        id: newGroupItemId(),
        name: name,
        category: _category,
        quantity: _quantity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Item name',
              hintText: 'e.g. 6-pack 2L water',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: kItemCategories
                .map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Quantity'),
              const Spacer(),
              IconButton(
                onPressed: _quantity <= 1
                    ? null
                    : () => setState(() => _quantity--),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$_quantity',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: _quantity >= 99
                    ? null
                    : () => setState(() => _quantity++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
