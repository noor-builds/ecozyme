import 'package:ecoenzyme/core/network/api_client.dart';

class EcoTask {
  const EcoTask({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    this.frequency,
    this.cropStage,
    this.bioenzymeRatio,
    this.applicationMethod,
  });

  final int id;
  final String title;
  final String description;
  final bool isCompleted;
  final String? frequency;
  final String? cropStage;
  final String? bioenzymeRatio;
  final String? applicationMethod;

  factory EcoTask.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id is! num || title is! String || title.trim().isEmpty) {
      throw const FormatException('The server returned an invalid task.');
    }

    return EcoTask(
      id: id.toInt(),
      title: title,
      description: json['description'] is String
          ? json['description'] as String
          : '',
      isCompleted: json['is_completed'] == true,
      frequency: json['frequency'] as String?,
      cropStage: json['crop_stage'] as String?,
      bioenzymeRatio: json['bioenzyme_ratio'] as String?,
      applicationMethod: json['application_method'] as String?,
    );
  }

  EcoTask copyWith({bool? isCompleted}) => EcoTask(
    id: id,
    title: title,
    description: description,
    isCompleted: isCompleted ?? this.isCompleted,
    frequency: frequency,
    cropStage: cropStage,
    bioenzymeRatio: bioenzymeRatio,
    applicationMethod: applicationMethod,
  );
}

class TaskService {
  TaskService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<EcoTask>> getTasks() async {
    final response = await _apiClient.request('/api/tasks/');
    final tasks = response['tasks'];
    if (tasks is! List) {
      throw const FormatException('The server returned an invalid task list.');
    }
    return tasks.map((task) {
      if (task is! Map<String, dynamic>) {
        throw const FormatException('The server returned an invalid task.');
      }
      return EcoTask.fromJson(task);
    }).toList();
  }

  Future<List<EcoTask>> generateTasks({
    required String cropType,
    String? soilType,
    String? location,
    String? season,
    String? farmerExperience,
  }) async {
    final response = await _apiClient.request(
      '/api/tasks/generate',
      method: 'POST',
      body: {
        'cropType': cropType,
        if (soilType != null && soilType.isNotEmpty) 'soilType': soilType,
        if (location != null && location.isNotEmpty) 'location': location,
        if (season != null && season.isNotEmpty) 'season': season,
        if (farmerExperience != null && farmerExperience.isNotEmpty)
          'farmerExperience': farmerExperience,
      },
    );
    final tasks = response['tasks'];
    if (tasks is! List) {
      throw const FormatException('The server returned an invalid task list.');
    }
    return tasks.map((task) {
      if (task is! Map<String, dynamic>) {
        throw const FormatException('The server returned an invalid task.');
      }
      return EcoTask.fromJson(task);
    }).toList();
  }

  Future<EcoTask> setCompleted(EcoTask task, bool isCompleted) async {
    final response = await _apiClient.request(
      '/api/tasks/${task.id}',
      method: 'PATCH',
      body: {'is_completed': isCompleted},
    );
    final updatedTask = response['task'];
    if (updatedTask is! Map<String, dynamic>) {
      throw const FormatException('The server returned an invalid task.');
    }
    return EcoTask.fromJson(updatedTask);
  }
}
