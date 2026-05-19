part of 'main_page.dart';

class _GroupSettingsPage extends StatefulWidget {
  const _GroupSettingsPage({required this.group});

  final _GroupEntry group;

  @override
  State<_GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<_GroupSettingsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _maxMembersController;
  final List<String> _locations = const [
    'Homeplus Yusung',
    'Traders Wolpyeong',
    'KAIST Area',
  ];

  String? _selectedLocation;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _maxMembers = 2;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.group.title);
    _maxMembers = widget.group.maxNum > 0 ? widget.group.maxNum : 2;
    _maxMembersController = TextEditingController(text: '$_maxMembers');
    _selectedLocation = widget.group.location;
    final dateTime = widget.group.dateTime;
    if (dateTime != null) {
      _selectedDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      _selectedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  void _setMaxMembers(int value) {
    final nextValue = value.clamp(2, 10);
    final text = '$nextValue';
    _maxMembersController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {
      _maxMembers = nextValue;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = picked;
    });
  }

  Future<void> _saveChanges() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final location = _selectedLocation;
    final date = _selectedDate;
    final time = _selectedTime;

    if (location == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('장보기 장소를 선택해주세요.')));
      return;
    }

    if (date == null || time == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('날짜와 시간을 모두 선택해주세요.')));
      return;
    }

    final nowNum = widget.group.nowNum;
    if (_maxMembers < nowNum) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 멤버 수는 현재 인원($nowNum)보다 작을 수 없어요.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      final updatedData = <String, dynamic>{
        ...widget.group.data,
        'name': title,
        'location': location,
        'date_time': Timestamp.fromDate(dateTime),
        'max_num': _maxMembers,
        'updatedAt': FieldValue.serverTimestamp(),
        'status': widget.group.status == 'ended' ? 'ended' : 'active',
      };

      await widget.group.docRef.update({
        'name': title,
        'location': location,
        'date_time': Timestamp.fromDate(dateTime),
        'max_num': _maxMembers,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(updatedData);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('그룹 설정 저장 실패: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _endGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('그룹을 종료할까요?'),
          content: const Text('종료하면 홈과 내 그룹에서 더 이상 보이지 않아요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('종료'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.group.docRef.update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop({'ended': true});
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('그룹 종료 실패: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _closeRecruitment() async {
    if (_isSaving || widget.group.isRecruitmentClosed) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('모집을 종료할까요?'),
          content: const Text(
            '모집을 종료하면 새 사람은 더 이상 이 그룹에 참여할 수 없어요.\n기존 멤버와 호스트는 계속 그룹을 볼 수 있어요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('종료'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedData = <String, dynamic>{
        ...widget.group.data,
        'recruitment_status': 'closed',
        'recruitmentClosedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await widget.group.docRef.update({
        'recruitment_status': 'closed',
        'recruitmentClosedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(updatedData);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('모집 종료 실패: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _startRecruitment() async {
    if (_isSaving || !widget.group.isRecruitmentClosed) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('모집을 다시 시작할까요?'),
          content: const Text(
            '모집을 다시 시작하면 다른 사람들이 이 그룹을 보고 참여할 수 있어요.\n정원이 가득 차 있으면 참여는 여전히 불가능해요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('시작'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedData = <String, dynamic>{
        ...widget.group.data,
        'recruitment_status': 'open',
        'recruitmentOpenedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await widget.group.docRef.update({
        'recruitment_status': 'open',
        'recruitmentOpenedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(updatedData);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('모집 시작 실패: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
          'Group Settings',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.3),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: _MainVisuals.featuredGradient,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '그룹 설정',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '그룹 이름, 장소, 일정, 최대 멤버 수를 수정할 수 있어요.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _MainVisuals.featuredMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.group.isRecruitmentClosed
                              ? '모집 상태: 종료'
                              : '모집 상태: 진행 중',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'GROUP NAME',
                  child: TextFormField(
                    controller: _titleController,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return '그룹 이름을 입력해주세요.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: '그룹 이름',
                      prefixIcon: Icon(Icons.groups_rounded),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'LOCATION',
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedLocation,
                    items: _locations
                        .map(
                          (location) => DropdownMenuItem(
                            value: location,
                            child: Text(location),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: '장보기 장소',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SectionCard(
                        title: 'DATE',
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(18),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              hintText: '날짜 선택',
                              prefixIcon: Icon(Icons.calendar_month_rounded),
                              border: InputBorder.none,
                            ),
                            child: Text(
                              _selectedDate == null
                                  ? '날짜를 선택하세요'
                                  : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SectionCard(
                        title: 'TIME',
                        child: InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(18),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              hintText: '시간 선택',
                              prefixIcon: Icon(Icons.schedule_rounded),
                              border: InputBorder.none,
                            ),
                            child: Text(
                              _selectedTime == null
                                  ? '시간을 선택하세요'
                                  : _selectedTime!.format(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'MAX MEMBERS',
                  child: InputDecorator(
                    decoration: const InputDecoration(border: InputBorder.none),
                    child: Row(
                      children: [
                        _CounterButton(
                          icon: Icons.remove_rounded,
                          onTap: _maxMembers <= 2
                              ? null
                              : () {
                                  _setMaxMembers(_maxMembers - 1);
                                },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _maxMembersController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 2,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: _MainVisuals.text,
                                  fontWeight: FontWeight.w900,
                                ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '2~10',
                              hintStyle: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: _MainVisuals.subtleText),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed == null || parsed < 2 || parsed > 10) {
                                return;
                              }
                              setState(() {
                                _maxMembers = parsed;
                              });
                            },
                            onSubmitted: (value) {
                              final parsed = int.tryParse(value);
                              if (parsed == null) {
                                _setMaxMembers(_maxMembers);
                                return;
                              }
                              _setMaxMembers(parsed);
                            },
                          ),
                        ),
                        _CounterButton(
                          icon: Icons.add_rounded,
                          filled: true,
                          onTap: _maxMembers >= 10
                              ? null
                              : () {
                                  _setMaxMembers(_maxMembers + 1);
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: _MainVisuals.green,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '물품 정보는 아직 준비 중이라 여기서는 그룹 기본 정보만 수정할 수 있어요.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: _MainVisuals.locationText),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                Navigator.of(context).maybePop();
                              },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          foregroundColor: _MainVisuals.mutedText,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          elevation: 0,
                          backgroundColor: _MainVisuals.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _endGroup,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('그룹 종료'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    backgroundColor: const Color(0xFFFFF1F2),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : widget.group.isRecruitmentClosed
                      ? _startRecruitment
                      : _closeRecruitment,
                  icon: Icon(
                    widget.group.isRecruitmentClosed
                        ? Icons.play_arrow_rounded
                        : Icons.how_to_reg_outlined,
                  ),
                  label: Text(
                    widget.group.isRecruitmentClosed ? '모집 시작' : '모집 종료',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: widget.group.isRecruitmentClosed
                        ? const Color(0xFF166534)
                        : const Color(0xFFB45309),
                    side: BorderSide(
                      color: widget.group.isRecruitmentClosed
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCD34D),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    backgroundColor: widget.group.isRecruitmentClosed
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFFFBEB),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _MainVisuals.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: child,
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? _MainVisuals.green : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: filled ? Colors.white : _MainVisuals.text),
        ),
      ),
    );
  }
}
