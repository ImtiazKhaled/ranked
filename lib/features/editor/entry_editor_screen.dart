import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/emotion.dart';
import '../../models/entry.dart';
import '../../models/tier.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_border_box.dart';
import '../emotion/emotion_picker.dart';
import 'tag_multiselect.dart';
import 'tier_selector.dart';

/// Create or edit an entry. [entryId] null => create.
class EntryEditorScreen extends ConsumerStatefulWidget {
  const EntryEditorScreen({super.key, this.entryId});

  final String? entryId;

  @override
  ConsumerState<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends ConsumerState<EntryEditorScreen> {
  final _summaryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _uuid = const Uuid();

  Tier _tier = Tier.b;
  EmotionRef? _emotion;
  List<String> _tagIds = [];
  Uint8List? _imageBytes;

  Entry? _existing;
  bool _loaded = false;

  bool get _isEditing => widget.entryId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    if (_isEditing) {
      final entry = ref.read(entriesProvider.notifier).byId(widget.entryId!);
      if (entry != null) {
        _existing = entry;
        _summaryCtrl.text = entry.summary;
        _descCtrl.text = entry.description;
        _tier = entry.tier;
        _emotion = entry.emotion;
        _tagIds = [...entry.tagIds];
        _imageBytes = entry.imageBytes;
      }
    }
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 82,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _imageBytes = bytes);
  }

  void _save() {
    final summary = _summaryCtrl.text.trim();
    if (summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your entry a summary first.')),
      );
      return;
    }
    final now = DateTime.now();
    final notifier = ref.read(entriesProvider.notifier);

    if (_isEditing && _existing != null) {
      notifier.update(_existing!.copyWith(
        summary: summary,
        description: _descCtrl.text.trim(),
        tier: _tier,
        emotion: _emotion,
        clearEmotion: _emotion == null,
        tagIds: _tagIds,
        imageBytes: _imageBytes,
        clearImage: _imageBytes == null,
        updatedAt: now,
      ));
    } else {
      notifier.add(Entry(
        id: _uuid.v4(),
        summary: summary,
        description: _descCtrl.text.trim(),
        tier: _tier,
        emotion: _emotion,
        tagIds: _tagIds,
        imageBytes: _imageBytes,
        createdAt: now,
        updatedAt: now,
      ));
    }
    _close();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This can’t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && _existing != null) {
      ref.read(entriesProvider.notifier).delete(_existing!.id);
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit rank' : 'New rank'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _close,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmDelete,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _label('Summary'),
              TextField(
                controller: _summaryCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'A short title for this moment',
                ),
              ),
              const SizedBox(height: 20),
              _label('Description'),
              TextField(
                controller: _descCtrl,
                maxLines: 5,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'What happened? How did it go?',
                ),
              ),
              const SizedBox(height: 20),
              _label('Rank'),
              TierSelector(value: _tier, onChanged: (t) => setState(() => _tier = t)),
              const SizedBox(height: 20),
              _label('Emotion'),
              EmotionPicker(
                value: _emotion,
                onChanged: (e) => setState(() => _emotion = e),
              ),
              const SizedBox(height: 20),
              _label('Image'),
              _imageSection(),
              const SizedBox(height: 20),
              _label('Tags'),
              TagMultiSelect(
                selectedIds: _tagIds,
                onChanged: (ids) => setState(() => _tagIds = ids),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.4,
            color: AppTheme.textMuted,
          ),
        ),
      );

  Widget _imageSection() {
    if (_imageBytes != null) {
      return GradientBorderBox(
        radius: 18,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _imageBytes!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 18,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() => _imageBytes = null),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pickImage,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.hairline,
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textMuted),
              SizedBox(height: 8),
              Text(
                'Add an image (optional)',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
