import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
      ),
      home: const GroupCreatePage(),
    );
  }
}

class GroupCreatePage extends StatefulWidget {
  const GroupCreatePage({super.key});

  @override
  State<GroupCreatePage> createState() => GroupCreateState();
}

class GroupCreateState extends State<GroupCreatePage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _maxMembersController = TextEditingController(
    text: '2',
  );
  final GlobalKey<FormFieldState<String>> _locationFieldKey =
      GlobalKey<FormFieldState<String>>();
  final List<String> _locations = const [
    'Homeplus Yusung',
    'Traders Wolpyeong',
    'KAIST Area',
  ];
  String? _selectedLocation;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _maxMembers = 2;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (pickedDate == null || !mounted) return;

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedTime = pickedTime;
    });
  }

  void _setMaxMembers(int value) {
    final nextValue = value.clamp(1, 10);
    final text = '$nextValue';
    _maxMembersController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {
      _maxMembers = nextValue;
    });
  }

  Future<void> saveData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인된 사용자가 없습니다. 다시 로그인해주세요.')),
        );
        return;
      }

      final text = _textController.text.trim();
      final location = _selectedLocation;
      final date = _selectedDate;
      final time = _selectedTime;

      if (text.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('group name을 입력해야합니다')));
        return;
      }

      if (location == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('location을 선택해야합니다')));
        return;
      }

      if (date == null || time == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('쇼핑 날짜/시간을 선택해야합니다')));
        return;
      }

      final shoppingDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      await FirebaseFirestore.instance.collection('group').add({
        'name': text,
        'location': location,
        'date_time': Timestamp.fromDate(shoppingDateTime),
        'max_num': _maxMembers,
        'user_id': user.uid,
        'now_num': 1,
        'member_ids': [user.uid],
      });
      _textController.clear();
      setState(() {
        _selectedLocation = null;
        _selectedDate = null;
        _selectedTime = null;
        _maxMembers = 2;
      });
      _maxMembersController.value = const TextEditingValue(
        text: '2',
        selection: TextSelection.collapsed(offset: 1),
      );
      _locationFieldKey.currentState?.reset();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CreateVisuals.pageBackground,
      appBar: AppBar(
        backgroundColor: _CreateVisuals.pageBackground,
        elevation: 0,
        foregroundColor: _CreateVisuals.text,
        centerTitle: false,
        titleSpacing: 20,
        title: const Text(
          'Create Group',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.4),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: _CreateVisuals.heroGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x220F172A),
                      blurRadius: 18,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create a Group',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '함께 장볼 멤버와 일정, 장소를 빠르게 정해보세요.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _CreateSectionCard(
                title: 'GROUP NAME',
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(
                    color: _CreateVisuals.text,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: '예: Homeplus Yusung Run',
                    prefixIcon: Icon(
                      Icons.groups_rounded,
                      color: _CreateVisuals.subtleText,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _CreateSectionCard(
                title: 'MARKET LOCATION',
                child: DropdownButtonFormField<String>(
                  key: _locationFieldKey,
                  initialValue: _selectedLocation,
                  decoration: const InputDecoration(
                    hintText: '마켓 위치를 선택하세요',
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: _CreateVisuals.subtleText,
                    ),
                    border: InputBorder.none,
                  ),
                  items: _locations
                      .map(
                        (loc) => DropdownMenuItem(value: loc, child: Text(loc)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CreateSectionCard(
                      title: 'DATE',
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(18),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            hintText: '날짜 선택',
                            prefixIcon: Icon(
                              Icons.calendar_month_rounded,
                              color: _CreateVisuals.subtleText,
                            ),
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
                    child: _CreateSectionCard(
                      title: 'TIME',
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(18),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            hintText: '시간 선택',
                            prefixIcon: Icon(
                              Icons.schedule_rounded,
                              color: _CreateVisuals.subtleText,
                            ),
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
              _CreateSectionCard(
                title: 'MAX MEMBERS',
                child: InputDecorator(
                  decoration: const InputDecoration(border: InputBorder.none),
                  child: Row(
                    children: [
                      _CounterButton(
                        icon: Icons.remove_rounded,
                        onTap: _maxMembers <= 1
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
                                color: _CreateVisuals.text,
                                fontWeight: FontWeight.w900,
                              ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '1~10',
                            hintStyle: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: _CreateVisuals.subtleText),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            final parsed = int.tryParse(value);
                            if (parsed == null || parsed < 1 || parsed > 10) {
                              return;
                            }
                            _maxMembers = parsed;
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
                      color: _CreateVisuals.green,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '그룹을 만들면 바로 피드에 노출되고, 생성자가 HOST로 등록돼요.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _CreateVisuals.locationText,
                        ),
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
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        foregroundColor: _CreateVisuals.mutedText,
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
                      onPressed: saveData,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        elevation: 0,
                        backgroundColor: _CreateVisuals.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Create Group',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateSectionCard extends StatelessWidget {
  const _CreateSectionCard({required this.title, required this.child});

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
            color: _CreateVisuals.mutedText,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _CreateVisuals.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: filled
              ? (enabled ? _CreateVisuals.green : const Color(0xFFB7E4C7))
              : (enabled ? const Color(0xFFF0FAF4) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled
                ? (enabled ? _CreateVisuals.green : const Color(0xFFB7E4C7))
                : (enabled ? const Color(0xFFD1FAE5) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Icon(
          icon,
          color: filled
              ? Colors.white
              : (enabled ? _CreateVisuals.green : _CreateVisuals.subtleText),
          size: 20,
        ),
      ),
    );
  }
}

class _CreateVisuals {
  static const Color pageBackground = Color(0xFFF8FAFC);
  static const Color text = Color(0xFF0F172A);
  static const Color mutedText = Color(0xFF64748B);
  static const Color subtleText = Color(0xFF94A3B8);
  static const Color green = Color(0xFF22C55E);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color locationText = Color(0xFF1A2E1A);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111827), Color(0xFF334155)],
  );
}
