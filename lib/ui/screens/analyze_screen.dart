import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controller/app_controller.dart';
import '../../core/engine/decision_engine.dart';
import '../../services/persistence_service.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) {
      return;
    }
    setState(() {
      _selectedImage = file;
      _isAnalyzing = true;
      _analysisResult = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 650));
    final Map<String, dynamic> analysis = widget.controller.analyzeStyle();
    await widget.controller.applyAnalysisToSystem(analysis);
    await widget.controller.persistState();
    await PersistenceService.saveData(
      vibeWeights: DecisionEngine.vibeWeights,
      likeStreak: widget.controller.likeStreak,
      skipStreak: widget.controller.skipStreak,
      confidence: widget.controller.confidence,
      score: widget.controller.getScore(),
      lastUpdatedDay: DateTime.now().day,
      streakDays: widget.controller.getStreakDays(),
      lastOpenedDay: widget.controller.lastOpenedDay,
      hasSeenOnboarding: true,
      selectedVibe: widget.controller.preferredVibe,
      savedItemIds: widget.controller.savedItems.map((e) => e.id).toList(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isAnalyzing = false;
      _analysisResult = analysis;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> hairstyles = widget.controller.getHairstyleSuggestions();
    final List<String> tips = widget.controller.getImprovementTips();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze My Style'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                'Upload a selfie to get a calm, focused style analysis.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Upload section',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      if (_selectedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 180,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          child: const Text('Upload a photo to begin analysis'),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              child: const Text('Pick from gallery'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickImage(ImageSource.camera),
                              child: const Text('Use camera'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analysis result section',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      if (_isAnalyzing)
                        const Text('Analyzing style...')
                      else if (_analysisResult == null)
                        const Text('Upload a photo to begin analysis')
                      else ...[
                        _ResultTile(
                          label: 'Detected Style',
                          value: (_analysisResult!['vibe'] as String).toUpperCase(),
                        ),
                        _ResultTile(
                          label: 'Confidence',
                          value:
                              (_analysisResult!['confidence'] as num).toStringAsFixed(1),
                        ),
                        _ResultTile(
                          label: 'Preferred Fit',
                          value: (_analysisResult!['fit'] as String).toUpperCase(),
                        ),
                        _ResultTile(
                          label: 'Face Shape',
                          value:
                              (_analysisResult!['faceShape'] as String).toUpperCase(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended Hairstyles',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      ...hairstyles.map(
                        (String style) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '$style — Improves balance for your current style direction',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Style Improvement Tips',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      ...tips.map(
                        (String tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('• $tip'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
