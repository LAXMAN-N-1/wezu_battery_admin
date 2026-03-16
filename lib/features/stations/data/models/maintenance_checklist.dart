// Removed unused material import

class ChecklistTask {
  final String id;
  final String title;
  final String description;
  final bool isRequired;
  final bool isCompleted;
  final String? note;
  final List<String>? photoPaths;

  const ChecklistTask({
    required this.id,
    required this.title,
    required this.description,
    this.isRequired = true,
    this.isCompleted = false,
    this.note,
    this.photoPaths,
  });

  ChecklistTask copyWith({
    String? id,
    String? title,
    String? description,
    bool? isRequired,
    bool? isCompleted,
    String? note,
    List<String>? photoPaths,
  }) {
    return ChecklistTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      isCompleted: isCompleted ?? this.isCompleted,
      note: note ?? this.note,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }

  factory ChecklistTask.fromJson(Map<String, dynamic> json) {
    return ChecklistTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isRequired: json['is_required'] as bool? ?? true,
      isCompleted: json['is_completed'] as bool? ?? false,
      note: json['note'] as String?,
      photoPaths: (json['photo_paths'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_required': isRequired,
      'is_completed': isCompleted,
      'note': note,
      'photo_paths': photoPaths,
    };
  }
}

class ChecklistTemplate {
  final String id;
  final String name;
  final String description;
  final String stationType;
  final String maintenanceType;
  final List<ChecklistTask> tasks;
  final int version;
  final DateTime createdAt;

  const ChecklistTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.stationType,
    required this.maintenanceType,
    required this.tasks,
    this.version = 1,
    required this.createdAt,
  });

  ChecklistTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? stationType,
    String? maintenanceType,
    List<ChecklistTask>? tasks,
    int? version,
    DateTime? createdAt,
  }) {
    return ChecklistTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      stationType: stationType ?? this.stationType,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      tasks: tasks ?? this.tasks,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChecklistTemplate.fromJson(Map<String, dynamic> json) {
    // Backend uses 'items' (List<String>), Frontend uses 'tasks' (List<ChecklistTask>)
    final List<dynamic>? backendItems = json['items'] as List<dynamic>?;
    final List<dynamic>? frontendTasks = json['tasks'] as List<dynamic>?;

    List<ChecklistTask> mappedTasks = [];
    if (frontendTasks != null) {
      mappedTasks = frontendTasks.map((e) => ChecklistTask.fromJson(e as Map<String, dynamic>)).toList();
    } else if (backendItems != null) {
      mappedTasks = backendItems.map((e) => ChecklistTask(
        id: e.toString().toLowerCase().replaceAll(' ', '_'),
        title: e.toString(),
        description: '',
      )).toList();
    }

    return ChecklistTemplate(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      stationType: json['station_type'] as String? ?? '',
      maintenanceType: json['maintenance_type'] as String? ?? '',
      tasks: mappedTasks,
      version: json['version'] as int? ?? 1,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'entity_type': stationType.toLowerCase() == 'standard' ? 'station' : stationType.toLowerCase(),
      'items': tasks.map((e) => e.title).toList(), // Backend expects 'items'
      'description': description, // For internal UI use
      'maintenance_type': maintenanceType, // For internal UI use
    };
  }
}

class ChecklistSubmission {
  final String id;
  final String eventId;
  final String templateId;
  final int templateVersion;
  final List<ChecklistTask> completedTasks;
  final String submittedBy;
  final DateTime submittedAt;
  final bool isFinal;

  const ChecklistSubmission({
    required this.id,
    required this.eventId,
    required this.templateId,
    required this.templateVersion,
    required this.completedTasks,
    required this.submittedBy,
    required this.submittedAt,
    this.isFinal = false,
  });

  factory ChecklistSubmission.fromJson(Map<String, dynamic> json) {
    return ChecklistSubmission(
      id: json['id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      templateId: json['template_id'] as String? ?? '',
      templateVersion: json['template_version'] as int? ?? 1,
      completedTasks: (json['completed_tasks'] as List<dynamic>?)
          ?.map((e) => ChecklistTask.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      submittedBy: json['submitted_by'] as String? ?? '',
      submittedAt: DateTime.parse(json['submitted_at']),
      isFinal: json['is_final'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'template_id': templateId,
      'template_version': templateVersion,
      'completed_tasks': completedTasks.map((e) => e.toJson()).toList(),
      'submitted_by': submittedBy,
      'submitted_at': submittedAt.toIso8601String(),
      'is_final': isFinal,
    };
  }
}
