import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  int? _counter;
  final List<String> _history = [];
  String _username = '';

  int get value => _counter ?? 0;
  bool get isLoaded => _counter != null;
  List<String> get history => List.unmodifiable(_history);

  void setUsername(String username) {
    _username = username;
  }

  static const int _maxHistory = 5;

  String _timeNow() {
    final now = DateTime.now();
    final jam = now.hour.toString().padLeft(2, '0');
    final menit = now.minute.toString().padLeft(2, '0');
    return '$jam:$menit';
  }

  void _trimHistory() {
    while (_history.length > _maxHistory) {
      _history.removeAt(0);
    }
  }

  void increment({int step = 1}) {
    _counter = value + step;
    _history.add('$_username menambah +$step \u2192 nilai: $value (${_timeNow()})');
    _trimHistory();
    saveCounter();
  }

  void decrement({int step = 1}) {
    int prev = value;
    _counter = (value - step).clamp(0, double.infinity).toInt();
    _history.add('$_username mengurangi -$step dari $prev \u2192 nilai: $value (${_timeNow()})');
    _trimHistory();
    saveCounter();
  }

  void reset() {
    int prev = value;
    _counter = 0;
    _history.add('$_username reset dari $prev \u2192 0 (${_timeNow()})');
    _trimHistory();
    saveCounter();
  }

  Future<void> saveCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_counter_$_username', value);
    await prefs.setStringList('history_$_username', _history);
  }

  Future<void> loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'last_counter_$_username';

    _counter = prefs.getInt(key) ?? 0;

    _history.clear();
    _history.addAll(prefs.getStringList('history_$_username') ?? []);
    _trimHistory();
  }
}