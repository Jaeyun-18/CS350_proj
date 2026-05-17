import 'package:flutter/material.dart';
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

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    setState(() {
      _selectedDate = pickedDate;
      _selectedTime = pickedTime;
    });
  }

  String _dateTimeLabel(BuildContext context) {
    if (_selectedDate == null || _selectedTime == null) {
      return 'Choose shop Date & Time';
    }
    final date = _selectedDate!;
    final formattedTime = _selectedTime!.format(context);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} $formattedTime';
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
        'now_num' : 1,
      });
      _textController.clear();
      setState(() {
        _selectedLocation = null;
        _selectedDate = null;
        _selectedTime = null;
        _maxMembers = 2;
      });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'group name',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 40),
                DropdownButtonFormField<String>(
                  key: _locationFieldKey,
                  initialValue: _selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'MARKET LOCATION',
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 40),
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'SHOPPING DATE & TIME',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_dateTimeLabel(context)),
                  ),
                ),
                const SizedBox(height: 40),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'MAX NUMBER',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _maxMembers <= 1
                            ? null
                            : () {
                                setState(() {
                                  _maxMembers--;
                                });
                              },
                        icon: const Icon(Icons.remove),
                      ),
                      Expanded(
                        child: Text(
                          '$_maxMembers 명',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: _maxMembers >= 10
                            ? null
                            : () {
                                setState(() {
                                  _maxMembers++;
                                });
                              },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 360,
        height: 64,
        child: Row(
          children: [
            Expanded(
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                backgroundColor: Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FloatingActionButton.extended(
                onPressed: saveData,
                icon: const Icon(Icons.check),
                label: const Text('Create Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
