import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/config/app_config.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/result/result.dart';
import '../data/meal_repository.dart';
import '../domain/meal_review.dart';
import '../domain/image_validation.dart';
import '../../settings/data/meal_vision_settings_repository.dart';

class CapturePreviewPage extends ConsumerStatefulWidget {
  const CapturePreviewPage({super.key});
  @override
  ConsumerState<CapturePreviewPage> createState() => _CapturePreviewPageState();
}

class _CapturePreviewPageState extends ConsumerState<CapturePreviewPage> {
  final _picker = ImagePicker();
  File? _image;
  CameraController? _camera;
  String? _error;
  bool _analysing = false;
  double _progress = 0;
  DateTime _consumedAt = DateTime.now();
  String? _hint;
  String? _scenario = 'BengaliLunch';
  CancelToken? _cancel;
  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _gallery() async {
    final selected =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (selected != null) {
      await _select(File(selected.path));
    }
  }

  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera is available on this device.');
        return;
      }
      final controller = CameraController(
          cameras.first, ResolutionPreset.medium,
          enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera?.dispose();
        _camera = controller;
        _error = null;
      });
    } on CameraException catch (e) {
      setState(() => _error =
          'Camera permission or initialization failed: ${e.description ?? e.code}');
    }
  }

  Future<void> _takePhoto() async {
    final camera = _camera;
    if (camera == null) return;
    try {
      final photo = await camera.takePicture();
      await _select(File(photo.path));
      await camera.dispose();
      if (mounted) setState(() => _camera = null);
    } on CameraException catch (e) {
      setState(
          () => _error = 'Photo capture failed: ${e.description ?? e.code}');
    }
  }

  Future<void> _select(File image) async {
    final bytes = await image.length();
    final header = await image
        .openRead(0, 12)
        .fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
    final validation = validateMealImage(
        path: image.path, bytes: bytes, header: Uint8List.fromList(header));
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _image = image;
      _error = null;
    });
  }

  Future<void> _analyse() async {
    final image = _image;
    if (image == null) return;
    setState(() {
      _analysing = true;
      _progress = 0;
      _error = null;
      _cancel = CancelToken();
    });
    final config = ref.read(appConfigProvider);
    final selection =
        await ref.read(mealVisionSettingsRepositoryProvider).selected();
    final result = await ref.read(mealRepositoryProvider).analyse(image,
        consumedAtUtc: _consumedAt.toUtc(),
        cuisineHint: _hint,
        mockMode: config.enableMockMode,
        mockScenario: _scenario,
        providerId: selection?.providerId,
        modelId: selection?.modelId,
        cancelToken: _cancel, onProgress: (sent, total) {
      if (mounted) setState(() => _progress = total == 0 ? 0 : sent / total);
    });
    if (!mounted) return;
    setState(() {
      _analysing = false;
      _cancel = null;
    });
    if (result is Success<MealReview>) {
      context.push(RoutePaths.review(result.value.mealId));
    } else if (result is Failure<MealReview>) {
      setState(() => _error = result.failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final camera = _camera;
    final content = <Widget>[
      Text('Capture meal', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text(
          'Your image is retained on the development backend for draft review. Do not upload sensitive images.'),
      const SizedBox(height: 20),
      _preview(camera),
      const SizedBox(height: 16),
      _sourceControls(camera),
      TextButton.icon(
          onPressed: () => context.push(RoutePaths.manualMeal),
          icon: const Icon(Icons.edit_note),
          label: const Text('Log a meal manually')),
      if (_image != null) ..._analysisControls(config),
      if (_error != null) ...[
        const SizedBox(height: 16),
        Text(_error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center)
      ]
    ];
    return Scaffold(
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.all(20), children: content)));
  }

  Widget _preview(CameraController? camera) {
    if (camera != null && camera.value.isInitialized) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
              aspectRatio: camera.value.aspectRatio,
              child: CameraPreview(camera)));
    }
    if (_image != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.file(_image!,
              height: 280, width: double.infinity, fit: BoxFit.cover));
    }
    return Container(
        height: 280,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.secondary)),
        child: const Center(
            child: Icon(Icons.document_scanner_outlined, size: 92)));
  }

  Widget _sourceControls(CameraController? camera) => camera != null
      ? FilledButton.icon(
          onPressed: _takePhoto,
          icon: const Icon(Icons.camera),
          label: const Text('Take photo'))
      : Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: _openCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'))),
          const SizedBox(width: 12),
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: _gallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery')))
        ]);
  List<Widget> _analysisControls(AppConfig config) => [
        const SizedBox(height: 16),
        TextField(
            decoration:
                const InputDecoration(labelText: 'Cuisine hint (optional)'),
            onChanged: (value) => _hint = value),
        const SizedBox(height: 12),
        ListTile(
            title: const Text('Consumed time'),
            subtitle: Text(
                MaterialLocalizations.of(context).formatFullDate(_consumedAt)),
            trailing: const Icon(Icons.schedule),
            onTap: () async {
              final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now(),
                  initialDate: _consumedAt);
              if (date != null && mounted) {
                final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_consumedAt));
                if (time == null || !mounted) return;
                setState(() => _consumedAt = DateTime(
                    date.year, date.month, date.day, time.hour, time.minute));
              }
            }),
        if (config.enableMockMode)
          DropdownButtonFormField<String>(
              value: _scenario,
              decoration: const InputDecoration(
                  labelText: 'Development analysis scenario'),
              items: const [
                'BengaliLunch',
                'NoFood',
                'PoorImageQuality',
                'AmbiguousFishCurry',
                'ProviderTimeout',
                'MalformedResponse'
              ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (value) => setState(() => _scenario = value)),
        const SizedBox(height: 16),
        if (_analysing) ...[
          LinearProgressIndicator(value: _progress == 0 ? null : _progress),
          TextButton(
              onPressed: () => _cancel?.cancel('Cancelled by user'),
              child: const Text('Cancel upload'))
        ] else
          FilledButton.icon(
              onPressed: _analyse,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Analyse meal'))
      ];
}
