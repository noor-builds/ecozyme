import 'package:ecoenzyme/features/tasks/data/task_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.refreshTrigger = 0});

  final int refreshTrigger;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _taskService = TaskService();
  List<EcoTask> _tasks = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tasks = await _taskService.getTasks();
      if (mounted) setState(() => _tasks = tasks);
    } catch (error) {
      if (mounted) setState(() => _error = _readableError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTask(EcoTask task, bool completed) async {
    setState(() {
      _tasks = _tasks
          .map(
            (item) => item.id == task.id
                ? item.copyWith(isCompleted: completed)
                : item,
          )
          .toList();
    });
    try {
      final updated = await _taskService.setCompleted(task, completed);
      if (mounted) {
        setState(() {
          _tasks = _tasks
              .map((item) => item.id == task.id ? updated : item)
              .toList();
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _tasks = _tasks
              .map(
                (item) => item.id == task.id
                    ? item.copyWith(isCompleted: task.isCompleted)
                    : item,
              )
              .toList();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_readableError(error))));
      }
    }
  }

  String _readableError(Object error) => error.toString().replaceFirst(
    RegExp(r'^(Exception|StateError|FormatException):\s*'),
    '',
  );

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadataName = user?.userMetadata?['name'];
    final displayName = metadataName is String && metadataName.trim().isNotEmpty
        ? metadataName.trim()
        : user?.email?.split('@').first ?? 'there';
    final textTheme = Theme.of(context).textTheme;
    final completed = _tasks.where((task) => task.isCompleted).length;
    final progress = _tasks.isEmpty ? 0.0 : completed / _tasks.length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          children: [
            Text(
              'WELCOME BACK',
              style: textTheme.labelMedium?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text('Great to have you here.', style: textTheme.bodyLarge),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _ProgressCard(
                    headline: 'Progress made',
                    value: '${(progress * 100).round()}%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ProgressCard(
                    headline: 'Tasks completed',
                    value: '$completed/${_tasks.length}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tasks for the day',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh tasks',
                  onPressed: _isLoading ? null : _loadTasks,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoading && _tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _tasks.isEmpty)
              _HomeMessage(
                message: _error!,
                actionLabel: 'Try again',
                onAction: _loadTasks,
              )
            else if (_error != null)
              _HomeMessage(
                message: _error!,
                actionLabel: 'Refresh tasks',
                onAction: _loadTasks,
              )
            else if (_tasks.isEmpty)
              const _HomeMessage(
                message:
                    'No crop tasks yet. Visit My tasks to create a plan for your crops.',
              )
            else
              for (final task in _tasks.take(5))
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: CheckboxListTile(
                    value: task.isCompleted,
                    onChanged: (value) => _toggleTask(task, value ?? false),
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(
                      task.title,
                      style: textTheme.titleSmall?.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      task.description.isEmpty
                          ? task.frequency ?? 'Your crop-care task'
                          : task.description,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.headline, required this.value});

  final String headline;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 138,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD9F1DA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            headline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 10),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
