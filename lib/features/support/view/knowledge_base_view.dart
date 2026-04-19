import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/admin_ui_components.dart';
import '../data/repositories/support_repository.dart';

class KnowledgeBaseView extends StatefulWidget {
  const KnowledgeBaseView({super.key});

  @override
  State<KnowledgeBaseView> createState() => _KnowledgeBaseViewState();
}

class _KnowledgeBaseViewState extends State<KnowledgeBaseView> {
  final SupportRepository _repository = SupportRepository();
  bool _isLoading = true;
  
  Map<String, dynamic> _stats = {};
  List<KnowledgeBaseArticle> _articles = [];
  String _categoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _repository.getKnowledgeBaseStats();
      final articles = await _repository.getArticles(category: _categoryFilter);
      
      setState(() {
        _stats = stats;
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 24),
          Expanded(
            child: _buildArticlesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return PageHeader(
      title: 'Knowledge Base',
      subtitle: 'Manage FAQ articles and help guides for Wezu users.',
      actionButton: ElevatedButton.icon(
        onPressed: () => _openArticleDialog(),
        icon: const Icon(Icons.add, size: 20, color: Colors.white),
        label: const Text('Add Article', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: StatCard(label: 'Total Articles', value: '${_stats['total_articles'] ?? 0}', icon: Icons.library_books)),
        const SizedBox(width: 16),
        Expanded(child: StatCard(label: 'Active Articles', value: '${_stats['active_articles'] ?? 0}', icon: Icons.check_circle_outline)),
        const SizedBox(width: 16),
        Expanded(child: StatCard(label: 'Helpful Votes', value: '${_stats['total_helpful'] ?? 0}', icon: Icons.thumb_up_alt_outlined)),
        const SizedBox(width: 16),
        Expanded(child: StatCard(label: 'Satisfaction Rate', value: '${_stats['satisfaction_rate'] ?? 0}%', icon: Icons.star_border)),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildFilters() {
    final Map<String, dynamic> categories = _stats['categories'] ?? {};
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text('Category:', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          _buildFilterChip('All', 'all'),
          ...categories.keys.map((cat) => _buildFilterChip(
                _capitalize(cat),
                cat,
              )),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  String _capitalize(String s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');

  Widget _buildFilterChip(String label, String value) {
    final isSelected = value == _categoryFilter;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _categoryFilter = value);
          _loadData();
        },
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        checkmarkColor: const Color(0xFF3B82F6),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildArticlesList() {
    if (_articles.isEmpty) {
      return const Center(child: Text('No articles found.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.separated(
      itemCount: _articles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final article = _articles[index];
        final totalVotes = article.helpfulCount + article.notHelpfulCount;
        final helpfulPct = totalVotes > 0 ? (article.helpfulCount / totalVotes * 100).toInt() : 0;

        return AdvancedCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Icon(
                      article.category == 'technical' ? Icons.build_circle :
                      article.category == 'billing' ? Icons.receipt_long :
                      article.category == 'account' ? Icons.person_outline :
                      article.category == 'dealer' ? Icons.storefront : 
                      Icons.help_outline,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(article.question, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                            if (!article.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                                child: const Text('INACTIVE', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.white54),
                              onPressed: () => _openArticleDialog(article),
                              tooltip: 'Edit Article',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article.answer,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                    child: Text(article.category.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Text('${article.helpfulCount}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.thumb_down_alt_outlined, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Text('${article.notHelpfulCount}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(width: 24),
                  Container(
                    width: 120,
                    height: 6,
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(3)),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        Expanded(flex: helpfulPct, child: Container(color: Colors.green)),
                        Expanded(flex: 100 - helpfulPct, child: Container(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$helpfulPct%', style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: (300 + index * 50).ms).slideY(begin: 0.05);
      },
    );
  }

  void _openArticleDialog([KnowledgeBaseArticle? article]) {
    showDialog(
      context: context,
      builder: (context) => _ArticleFormDialog(article: article, repository: _repository),
    ).then((changed) {
      if (changed == true) _loadData();
    });
  }
}

class _ArticleFormDialog extends StatefulWidget {
  final KnowledgeBaseArticle? article;
  final SupportRepository repository;

  const _ArticleFormDialog({this.article, required this.repository});

  @override
  State<_ArticleFormDialog> createState() => _ArticleFormDialogState();
}

class _ArticleFormDialogState extends State<_ArticleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _question;
  late String _answer;
  late String _category;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _question = widget.article?.question ?? '';
    _answer = widget.article?.answer ?? '';
    _category = widget.article?.category ?? 'general';
    _isActive = widget.article?.isActive ?? true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isSaving = true);
    
    bool success;
    if (widget.article == null) {
      success = await widget.repository.createArticle(_question, _answer, _category, _isActive);
    } else {
      success = await widget.repository.updateArticle(widget.article!.id, _question, _answer, _category, _isActive);
    }
    
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(border: Border.all(color: Colors.white12), borderRadius: BorderRadius.circular(16)),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.article == null ? 'New Article' : 'Edit Article',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: _question,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Question / Title',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _question = v!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'getting_started', child: Text('Getting Started')),
                  DropdownMenuItem(value: 'payment', child: Text('Payment')),
                  DropdownMenuItem(value: 'technical', child: Text('Technical')),
                  DropdownMenuItem(value: 'billing', child: Text('Billing')),
                  DropdownMenuItem(value: 'account', child: Text('Account')),
                  DropdownMenuItem(value: 'dealer', child: Text('Dealer')),
                  DropdownMenuItem(value: 'safety', child: Text('Safety')),
                  DropdownMenuItem(value: 'general', child: Text('General')),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _answer,
                style: const TextStyle(color: Colors.white),
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Detailed Answer',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _answer = v!,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Published (Active)', style: TextStyle(color: Colors.white)),
                activeThumbColor: const Color(0xFF3B82F6),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Article', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
