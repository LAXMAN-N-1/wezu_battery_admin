import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/maintenance_checklist.dart';
import '../data/providers/checklist_provider.dart';

class ChecklistTemplateDialog extends ConsumerStatefulWidget {
  final ChecklistTemplate? initialTemplate;

  const ChecklistTemplateDialog({super.key, this.initialTemplate});

  @override
  ConsumerState<ChecklistTemplateDialog> createState() => _ChecklistTemplateDialogState();
}

class _ChecklistTemplateDialogState extends ConsumerState<ChecklistTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _stationType;
  late String _maintenanceType;
  late List<ChecklistTask> _tasks;

  final List<String> _stationTypes = ['Standard', 'Rapid', 'Battery Swap', 'Hub'];
  final List<String> _maintenanceTypes = ['routine', 'repair', 'inspection', 'emergency'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialTemplate?.name ?? '');
    _descController = TextEditingController(text: widget.initialTemplate?.description ?? '');
    _stationType = widget.initialTemplate?.stationType ?? 'Standard';
    _maintenanceType = widget.initialTemplate?.maintenanceType ?? 'routine';
    _tasks = widget.initialTemplate?.tasks != null 
        ? List.from(widget.initialTemplate!.tasks) 
        : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addTask() {
    setState(() {
      _tasks.add(ChecklistTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        description: '',
      ));
    });
  }

  void _removeTask(int index) {
    setState(() => _tasks.removeAt(index));
  }

  void _saveTemplate() {
    if (_formKey.currentState!.validate()) {
      final template = ChecklistTemplate(
        id: widget.initialTemplate?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descController.text,
        stationType: _stationType,
        maintenanceType: _maintenanceType,
        tasks: _tasks,
        version: widget.initialTemplate != null ? widget.initialTemplate!.version + 1 : 1,
        createdAt: widget.initialTemplate?.createdAt ?? DateTime.now(),
      );

      if (widget.initialTemplate == null) {
        ref.read(checklistTemplateNotifierProvider.notifier).addTemplate(template);
      } else {
        ref.read(checklistTemplateNotifierProvider.notifier).updateTemplate(template);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_add, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    widget.initialTemplate == null ? 'New Checklist Template' : 'Edit Template',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 32),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Template Name', Icons.title),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: _inputDecoration('Description', Icons.description),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown('Station Type', _stationTypes, _stationType, (v) => setState(() => _stationType = v!)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown('Type', _maintenanceTypes, _maintenanceType, (v) => setState(() => _maintenanceType = v!)),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Text('Tasks', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18)),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Task'),
                            onPressed: _addTask,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (_tasks.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.list_alt, color: Colors.white10, size: 48),
                              const SizedBox(height: 8),
                              Text('No tasks added yet', style: TextStyle(color: Colors.white38)),
                            ],
                          ),
                        ),
                      
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildTaskTile(index);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveTemplate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(widget.initialTemplate == null ? 'Create Template' : 'Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTile(int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _tasks[index].title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Task Title',
                    hintStyle: TextStyle(color: Colors.white24),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => _tasks[index] = _tasks[index].copyWith(title: v),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => _removeTask(index),
              ),
            ],
          ),
          const Divider(color: Colors.white10),
          TextFormField(
            initialValue: _tasks[index].description,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Task Description',
              hintStyle: TextStyle(color: Colors.white24),
              isDense: true,
              border: InputBorder.none,
            ),
            onChanged: (v) => _tasks[index] = _tasks[index].copyWith(description: v),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String current, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: current,
      decoration: _inputDecoration(label, Icons.category),
      dropdownColor: const Color(0xFF1E293B),
      items: items.map((t) => DropdownMenuItem(
        value: t,
        child: Text(t, style: const TextStyle(color: Colors.white)),
      )).toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: Colors.blue),
      labelStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
    );
  }
}
