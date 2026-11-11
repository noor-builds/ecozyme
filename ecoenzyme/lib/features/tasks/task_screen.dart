import 'package:ecoenzyme/features/tasks/data/task_service.dart';
import 'package:flutter/material.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _taskService = TaskService();
  List<EcoTask> _tasks = const [];
  final Set<int> _updatingTaskIds = {};
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;

  int get _completedCount => _tasks.where((task) => task.isCompleted).length;

  @override
  void initState() {
    super.initState();
    _loadTasks();
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
    if (!_updatingTaskIds.add(task.id)) return;
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
        _showMessage(_readableError(error));
      }
    } finally {
      _updatingTaskIds.remove(task.id);
    }
  }

  Future<void> _generateTasks() async {
    final input = await _showGenerateDialog();
    if (input == null || !mounted) return;

    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final newTasks = await _taskService.generateTasks(
        cropType: input.cropType,
        soilType: input.soilType,
        location: input.location,
        season: input.season,
        farmerExperience: input.farmerExperience,
      );
      if (mounted) {
        setState(() => _tasks = [...newTasks, ..._tasks]);
        _showMessage('Added ${newTasks.length} tasks for ${input.cropType}.');
      }
    } catch (error) {
      if (mounted) _showMessage(_readableError(error));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<_TaskGenerationInput?> _showGenerateDialog() async {
    final cropController = TextEditingController();
    final soilController = TextEditingController();
    final locationController = TextEditingController();
    final seasonController = TextEditingController();
    final experienceController = TextEditingController();
    var error = '';

    try {
      return await showDialog<_TaskGenerationInput>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Create crop tasks'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: cropController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: 'Crop type *',
                      hintText: 'e.g. Tomato',
                      errorText: error.isEmpty ? null : error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: soilController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Soil type *',
                      hintText: "e.g. loamy, or 'not sure'",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Region or country *',
                      hintText: 'No exact address needed',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: seasonController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Growing season *',
                      hintText: 'e.g. monsoon, spring',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: experienceController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Farming experience *',
                      hintText: 'e.g. beginner, 5 years',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final cropType = cropController.text.trim();
                  final soilType = soilController.text.trim();
                  final location = locationController.text.trim();
                  final season = seasonController.text.trim();
                  final farmerExperience = experienceController.text.trim();
                  if (cropType.isEmpty ||
                      soilType.isEmpty ||
                      location.isEmpty ||
                      season.isEmpty ||
                      farmerExperience.isEmpty) {
                    setDialogState(
                      () => error = 'Complete all required fields.',
                    );
                    return;
                  }
                  Navigator.pop(
                    context,
                    _TaskGenerationInput(
                      cropType: cropType,
                      soilType: soilType,
                      location: location,
                      season: season,
                      farmerExperience: farmerExperience,
                    ),
                  );
                },
                child: const Text('Generate'),
              ),
            ],
          ),
        ),
      );
    } finally {
      cropController.dispose();
      soilController.dispose();
      locationController.dispose();
      seasonController.dispose();
      experienceController.dispose();
    }
  }

  String _readableError(Object error) => error.toString().replaceFirst(
    RegExp(r'^(Exception|StateError|FormatException):\s*'),
    '',
  );

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = _tasks.isEmpty ? 0.0 : _completedCount / _tasks.length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text('Small actions add up.', style: textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Make today a little kinder to the planet.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4E7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Your progress',
                          style: textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '$_completedCount of ${_tasks.length}',
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white,
                      color: const Color(0xFF43A047),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text('YOUR ECO TASKS', style: textTheme.labelMedium),
                ),
                FilledButton.tonalIcon(
                  onPressed: _isGenerating || _isLoading
                      ? null
                      : _generateTasks,
                  icon: _isGenerating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_isGenerating ? 'Creating…' : 'Create tasks'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoading && _tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(36),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _tasks.isEmpty)
              _MessageCard(
                icon: Icons.cloud_off_outlined,
                message: _error!,
                actionLabel: 'Try again',
                onAction: _loadTasks,
              )
            else if (_error != null)
              _MessageCard(
                icon: Icons.cloud_off_outlined,
                message: _error!,
                actionLabel: 'Refresh tasks',
                onAction: _loadTasks,
              )
            else if (_tasks.isEmpty)
              _MessageCard(
                icon: Icons.eco_outlined,
                message:
                    'No tasks yet. Create a crop plan and EcoAI will make a checklist for you.',
                actionLabel: 'Create crop tasks',
                onAction: _generateTasks,
              )
            else
              for (final task in _tasks)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: CheckboxListTile(
                    value: task.isCompleted,
                    onChanged: _updatingTaskIds.contains(task.id)
                        ? null
                        : (value) => _toggleTask(task, value ?? false),
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    secondary: CircleAvatar(
                      backgroundColor: const Color(0xFFEAF4E7),
                      foregroundColor: const Color(0xFF2E7D32),
                      child: Icon(_iconForTask(task), size: 20),
                    ),
                    title: Text(
                      task.title,
                      style: textTheme.titleSmall?.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(_taskDescription(task)),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  IconData _iconForTask(EcoTask task) {
    final value = '${task.title} ${task.applicationMethod}'.toLowerCase();
    if (value.contains('water') || value.contains('irrigat')) {
      return Icons.water_drop_outlined;
    }
    if (value.contains('compost')) return Icons.compost_outlined;
    if (value.contains('recycl')) return Icons.recycling_outlined;
    if (value.contains('spray') || value.contains('foliar')) {
      return Icons.grass_outlined;
    }
    return Icons.eco_outlined;
  }

  String _taskDescription(EcoTask task) {
    final details = <String>[
      if (task.description.isNotEmpty) task.description,
      if (task.frequency?.isNotEmpty == true) task.frequency!,
      if (task.bioenzymeRatio?.isNotEmpty == true)
        'Bioenzyme ${task.bioenzymeRatio}',
    ];
    return details.isEmpty
        ? 'A small step for a healthier crop.'
        : details.join(' · ');
  }
}

class _TaskGenerationInput {
  const _TaskGenerationInput({
    required this.cropType,
    required this.soilType,
    required this.location,
    required this.season,
    required this.farmerExperience,
  });

  final String cropType;
  final String soilType;
  final String location;
  final String season;
  final String farmerExperience;
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
