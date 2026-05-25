import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _storageKey = 'tasks';

class Task {
  final String id;
  final String title;
  final bool done;

  const Task({
    required this.id,
    required this.title,
    this.done = false,
  });

  Task copyWith({String? title, bool? done}) {
    return Task(
      id: id,
      title: title ?? this.title,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'done': done,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      done: json['done'] == true,
    );
  }
}

class TaskProvider extends ChangeNotifier {
  TaskProvider({SharedPreferences? preferences}) : _preferences = preferences;

  SharedPreferences? _preferences;
  List<Task> _tasks = const [];

  List<Task> get tasks => List.unmodifiable(_tasks);
  int get completedCount => _tasks.where((task) => task.done).length;

  Future<void> loadTasks() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    _preferences = prefs;

    final savedTasks = prefs.getStringList(_storageKey) ?? const <String>[];
    _tasks = savedTasks
        .map((item) => Task.fromJson(jsonDecode(item)))
        .toList(growable: false);

    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    _preferences = prefs;

    await prefs.setStringList(
      _storageKey,
      _tasks.map((task) => jsonEncode(task.toJson())).toList(),
    );
  }

  Future<void> addTask(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _tasks = [
      Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: trimmed,
      ),
      ..._tasks,
    ];

    notifyListeners();
    await _persist();
  }

  Future<void> toggleTask(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) {
      return;
    }

    _tasks = [
      ..._tasks.take(index),
      _tasks[index].copyWith(done: !_tasks[index].done),
      ..._tasks.skip(index + 1),
    ];

    notifyListeners();
    await _persist();
  }

  Future<void> updateTask(String id, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) {
      return;
    }

    _tasks = [
      ..._tasks.take(index),
      _tasks[index].copyWith(title: trimmed),
      ..._tasks.skip(index + 1),
    ];

    notifyListeners();
    await _persist();
  }

  Future<void> deleteTask(String id) async {
    _tasks = _tasks.where((task) => task.id != id).toList(growable: false);
    notifyListeners();
    await _persist();
  }
}

void main() {
  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider()..loadTasks(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Task Manager',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitTask({Task? editingTask}) async {
    final provider = context.read<TaskProvider>();

    if (editingTask == null) {
      await provider.addTask(_controller.text);
    } else {
      await provider.updateTask(editingTask.id, _controller.text);
    }

    if (!mounted) {
      return;
    }

    _controller.clear();
    Navigator.of(context).pop();
  }

  void _showTaskDialog({Task? editingTask}) {
    _controller.text = editingTask?.title ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(editingTask == null ? 'Add Task' : 'Edit Task'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter task title',
          ),
          onSubmitted: (_) => _submitTask(editingTask: editingTask),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitTask(editingTask: editingTask),
            child: Text(editingTask == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'My Tasks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showTaskDialog(),
            icon: const Icon(Icons.add_task),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const _SummaryCard(),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<TaskProvider>(
                  builder: (context, provider, _) {
                    if (provider.tasks.isEmpty) {
                      return const _EmptyState();
                    }

                    return ListView.builder(
                      itemCount: provider.tasks.length,
                      itemBuilder: (context, index) {
                        final task = provider.tasks[index];

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            );
                          },
                          child: _TaskTile(
                            key: ValueKey(task.id),
                            task: task,
                            onToggle: () => provider.toggleTask(task.id),
                            onDelete: () => provider.deleteTask(task.id),
                            onEdit: () => _showTaskDialog(editingTask: task),
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
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B67F1), Color(0xFF7D8BFF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: Text(
          key: ValueKey('${provider.completedCount}-${provider.tasks.length}'),
          '${provider.completedCount} of ${provider.tasks.length} tasks completed',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 250),
        child: Text(
          key: ValueKey('empty-state'),
          'No tasks yet',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: ListTile(
          leading: Checkbox(
            value: task.done,
            onChanged: (_) => onToggle(),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.done ? TextDecoration.lineThrough : null,
              color: task.done ? Colors.black54 : Colors.black87,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
                tooltip: 'Edit task',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onDelete,
                tooltip: 'Delete task',
              ),
            ],
          ),
        ),
      ),
    );
  }
}