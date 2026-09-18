import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DfuApp());

class DfuApp extends StatefulWidget {
  const DfuApp({super.key});

  @override
  State<DfuApp> createState() => _DfuAppState();
}

class _DfuAppState extends State<DfuApp> {
  final _repository = DemoRepository();
  final _analysisRepository = _buildAnalysisRepository();
  bool _signedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedConnect',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: _signedIn
          ? PatientListScreen(
              repository: _repository,
              analysisRepository: _analysisRepository,
              onSignOut: () => setState(() => _signedIn = false),
            )
          : LoginScreen(onSignedIn: () => setState(() => _signedIn = true)),
    );
  }
}

AnalysisRepository _buildAnalysisRepository() {
  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  const accessToken = String.fromEnvironment('SUPABASE_ACCESS_TOKEN');
  return ApiAnalysisRepository(
    Dio(BaseOptions(baseUrl: apiBaseUrl)),
    () => accessToken,
  );
}

ThemeData _buildTheme() {
  const primary = Color(0xFF2D60DB);
  const text = Color(0xFF212B3B);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: text,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: text),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF6B778B)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFE),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0E6F2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0E6F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
  );
}

class Patient {
  Patient({required this.name, this.externalRef, this.dateOfBirth});

  final String name;
  final String? externalRef;
  final DateTime? dateOfBirth;
}

abstract interface class PatientRepository {
  List<Patient> get patients;
  Future<void> addPatient(Patient patient);
}

class DemoRepository implements PatientRepository {
  final List<Patient> _patients = [
    Patient(name: 'Amina Chelly', externalRef: 'DFU-1000'),
    Patient(name: 'Ahmed Aloulou', externalRef: 'DFU-1001'),
  ];

  @override
  List<Patient> get patients => List.unmodifiable(_patients);

  @override
  Future<void> addPatient(Patient patient) async =>
      _patients.insert(0, patient);
}

enum ImageSourceType { camera, upload }

class SelectedImage {
  SelectedImage({
    required this.bytes,
    required this.name,
    required this.source,
  });

  final List<int> bytes;
  final String name;
  final ImageSourceType source;
}

class AnalysisSubmission {
  AnalysisSubmission({required this.analysisId, required this.status});

  final String analysisId;
  final String status;
}

class AnalysisResult {
  AnalysisResult({
    required this.analysisId,
    required this.status,
    this.fellBack,
    this.maskUrl,
    this.overlayUrl,
    this.bbox,
    this.grade,
    this.classificationStatus,
    this.message,
  });

  final String analysisId;
  final String status;
  final bool? fellBack;
  final String? maskUrl;
  final String? overlayUrl;
  final List<dynamic>? bbox;
  final int? grade;
  final String? classificationStatus;
  final String? message;
}

abstract interface class AnalysisRepository {
  Future<AnalysisSubmission> submit({
    required String patientId,
    required SelectedImage image,
    void Function(double progress)? onProgress,
  });

  Future<AnalysisResult> process(String analysisId);
}

class DemoAnalysisRepository implements AnalysisRepository {
  @override
  Future<AnalysisSubmission> submit({
    required String patientId,
    required SelectedImage image,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    onProgress?.call(1);
    return AnalysisSubmission(
      analysisId: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      status: 'pending',
    );
  }

  @override
  Future<AnalysisResult> process(String analysisId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return AnalysisResult(
      analysisId: analysisId,
      status: 'complete',
      fellBack: false,
      grade: 2,
      classificationStatus: 'CONFIDENT',
      message: 'Demo result - review the wound classification clinically.',
    );
  }
}

class AnalysisUploadException implements Exception {
  AnalysisUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiAnalysisRepository implements AnalysisRepository {
  ApiAnalysisRepository(this._dio, this._getAccessToken);

  final Dio _dio;
  final String Function() _getAccessToken;

  @override
  Future<AnalysisSubmission> submit({
    required String patientId,
    required SelectedImage image,
    void Function(double progress)? onProgress,
  }) async {
    final token = _getAccessToken().trim();
    final extension = image.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final formData = FormData.fromMap({
      'patient_id': patientId,
      'source': image.source.name,
      'image': MultipartFile.fromBytes(
        image.bytes,
        filename: image.name.isEmpty ? 'wound.$extension' : image.name,
      ),
    });
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/analyses',
        data: formData,
        options: Options(
          headers: token.isEmpty ? null : {'Authorization': 'Bearer $token'},
        ),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
      final data = response.data;
      if (data == null ||
          data['analysis_id'] is! String ||
          data['status'] is! String) {
        throw AnalysisUploadException(
          'Upload failed - the server returned an invalid response.',
        );
      }
      return AnalysisSubmission(
        analysisId: data['analysis_id'] as String,
        status: data['status'] as String,
      );
    } on DioException catch (error) {
      throw AnalysisUploadException(_mapError(error));
    }
  }

  @override
  Future<AnalysisResult> process(String analysisId) async {
    final token = _getAccessToken().trim();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/analyses/$analysisId/process',
        options: Options(
          headers: token.isEmpty ? null : {'Authorization': 'Bearer $token'},
        ),
      );
      final data = response.data;
      if (data == null || data['analysis_id'] is! String || data['status'] is! String) {
        throw AnalysisUploadException(
          'Processing failed - the server returned an invalid response.',
        );
      }
      return AnalysisResult(
        analysisId: data['analysis_id'] as String,
        status: data['status'] as String,
        fellBack: data['fell_back'] as bool?,
        maskUrl: data['mask_url'] as String?,
        overlayUrl: data['overlay_url'] as String?,
        bbox: data['bbox'] as List<dynamic>?,
        grade: data['grade'] as int?,
        classificationStatus: data['classification_status'] as String?,
        message: data['message'] as String?,
      );
    } on DioException catch (error) {
      throw AnalysisUploadException(_mapError(error));
    }
  }

  String _mapError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Cannot reach the analysis server at ${_dio.options.baseUrl}. Start the backend and try again.';
    }
    switch (error.response?.statusCode) {
      case 401:
        return 'Session expired - please sign in again.';
      case 404:
        return 'Patient record not found.';
      case 413:
        return 'Image is too large (maximum 15 MB).';
      case 422:
        return 'Image type or resolution is not supported.';
      default:
        return 'Upload failed - check your connection and try again.';
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() => _error = null);
    if (!email.contains('@') || password.length < 6) {
      setState(
        () => _error =
            'Enter a valid email and a password of at least 6 characters.',
      );
      return;
    }
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _loading = false);
    widget.onSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 44),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D60DB),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(42),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'MedConnect',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Trusted clinical insight for every wound.',
                      style: TextStyle(color: Color(0xFFDDE7FF), fontSize: 16),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('Sign in to access your patient workspace.'),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Work email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFB3261E)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _signIn,
                        icon: _loading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.arrow_forward),
                        label: Text(_loading ? 'Signing in...' : 'Sign in'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({
    super.key,
    required this.repository,
    required this.analysisRepository,
    required this.onSignOut,
  });

  final PatientRepository repository;
  final AnalysisRepository analysisRepository;
  final VoidCallback onSignOut;

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  String _query = '';

  List<Patient> get _filteredPatients {
    final query = _query.toLowerCase();
    return widget.repository.patients
        .where(
          (patient) =>
              patient.name.toLowerCase().contains(query) ||
              (patient.externalRef?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  Future<void> _showNewPatient() async {
    final patient = await showModalBottomSheet<Patient>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const NewPatientSheet(),
    );
    if (patient == null) return;
    await widget.repository.addPatient(patient);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final patients = _filteredPatients;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patients',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: widget.onSignOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your clinical workspace',
              style: TextStyle(color: Color(0xFF6B778B)),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search by name or patient ID',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${patients.length} patients',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: patients.isEmpty
                  ? const Center(child: Text('No patients match your search.'))
                  : ListView.separated(
                      itemCount: patients.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) => PatientCard(
                        patient: patients[index],
                        analysisRepository: widget.analysisRepository,
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewPatient,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New patient'),
      ),
    );
  }
}

class PatientCard extends StatelessWidget {
  const PatientCard({
    super.key,
    required this.patient,
    required this.analysisRepository,
  });

  final Patient patient;
  final AnalysisRepository analysisRepository;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E6F2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8EEFF),
          foregroundColor: const Color(0xFF2D60DB),
          child: Text(patient.name.substring(0, 1).toUpperCase()),
        ),
        title: Text(
          patient.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(patient.externalRef ?? 'No patient ID'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PatientDetailScreen(
              patient: patient,
              analysisRepository: analysisRepository,
            ),
          ),
        ),
      ),
    );
  }
}

class NewPatientSheet extends StatefulWidget {
  const NewPatientSheet({super.key});

  @override
  State<NewPatientSheet> createState() => _NewPatientSheetState();
}

class _NewPatientSheetState extends State<NewPatientSheet> {
  final _nameController = TextEditingController();
  final _refController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _refController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient name is required.')),
      );
      return;
    }
    Navigator.of(context).pop(
      Patient(
        name: name,
        externalRef: _refController.text.trim().isEmpty
            ? null
            : _refController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New patient', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Create a patient record before starting an analysis.'),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name *'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _refController,
            decoration: const InputDecoration(
              labelText: 'Patient ID (optional)',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save patient'),
            ),
          ),
        ],
      ),
    );
  }
}

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({
    super.key,
    required this.patient,
    required this.analysisRepository,
  });

  final Patient patient;
  final AnalysisRepository analysisRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFE8EEFF),
              foregroundColor: const Color(0xFF2D60DB),
              child: Text(
                patient.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              patient.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(patient.externalRef ?? 'No patient ID'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewAnalysisScreen(
                      patientId: patient.externalRef ?? patient.name,
                      analysisRepository: analysisRepository,
                    ),
                  ),
                ),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('New analysis'),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Analysis history',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text('No analyses have been recorded for this patient yet.'),
          ],
        ),
      ),
    );
  }
}

class NewAnalysisScreen extends StatelessWidget {
  const NewAnalysisScreen({
    super.key,
    required this.patientId,
    required this.analysisRepository,
  });

  final String patientId;
  final AnalysisRepository analysisRepository;

  Future<void> _openPicker(BuildContext context, ImageSourceType source) async {
    if (source == ImageSourceType.camera) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GuidedCameraScreen(
            patientId: patientId,
            analysisRepository: analysisRepository,
          ),
        ),
      );
      return;
    }
    _openFilePicker(context);
  }

  void _openFilePicker(BuildContext context) {
    // Keep this call synchronous with the browser click so Edge allows the dialog.
    try {
      FilePicker.platform
          .pickFiles(
            type: FileType.custom,
            allowedExtensions: ['jpg', 'jpeg', 'png'],
            withData: true,
          )
          .then((result) async {
            if (!context.mounted || result == null || result.files.isEmpty) {
              return;
            }
            final picked = result.files.single;
            final bytes = picked.bytes;
            if (bytes == null || bytes.isEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('The selected file could not be read.'),
                  ),
                );
              }
              return;
            }
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ImageReviewScreen(
                  patientId: patientId,
                  image: SelectedImage(
                    bytes: bytes,
                    name: picked.name,
                    source: ImageSourceType.upload,
                  ),
                  analysisRepository: analysisRepository,
                  alternateSource: ImageSourceType.upload,
                ),
              ),
            );
          })
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint('pickFiles future error: $error\n$stackTrace');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Could not open the selected file: $error'),
                ),
              );
            }
          });
    } catch (error, stackTrace) {
      debugPrint('pickFiles synchronous error: $error\n$stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker unavailable: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New analysis')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a wound photo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how you want to provide the image for this analysis.',
            ),
            const SizedBox(height: 28),
            _AnalysisChoiceTile(
              icon: Icons.camera_alt_outlined,
              title: 'Take photo',
              subtitle: 'Use the guided camera viewfinder',
              onTap: () => _openPicker(context, ImageSourceType.camera),
            ),
            const SizedBox(height: 14),
            _AnalysisChoiceTile(
              icon: Icons.file_upload_outlined,
              title: 'Upload from files',
              subtitle: 'Choose a JPEG or PNG from your device',
              onTap: () => _openFilePicker(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisChoiceTile extends StatelessWidget {
  const _AnalysisChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E6F2)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8EEFF),
          foregroundColor: const Color(0xFF2D60DB),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class GuidedCameraScreen extends StatefulWidget {
  const GuidedCameraScreen({
    super.key,
    required this.patientId,
    required this.analysisRepository,
  });

  final String patientId;
  final AnalysisRepository analysisRepository;

  @override
  State<GuidedCameraScreen> createState() => _GuidedCameraScreenState();
}

class _GuidedCameraScreenState extends State<GuidedCameraScreen> {
  CameraController? _controller;
  String? _initError;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _initError = 'No camera found on this device.');
        }
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error) {
      if (mounted) setState(() => _initError = 'Camera unavailable: $error');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final image = SelectedImage(
        bytes: await file.readAsBytes(),
        name: file.name,
        source: ImageSourceType.camera,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ImageReviewScreen(
            patientId: widget.patientId,
            image: image,
            analysisRepository: widget.analysisRepository,
            alternateSource: ImageSourceType.camera,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _initError = 'Could not capture photo: $error');
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF172033),
      appBar: AppBar(
        backgroundColor: const Color(0xFF172033),
        foregroundColor: Colors.white,
        title: const Text('Guided camera'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _controller == null
                ? Center(
                    child: _initError != null
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _initError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          )
                        : const CircularProgressIndicator(color: Colors.white),
                  )
                : CameraPreview(_controller!),
          ),
          Positioned.fill(child: CustomPaint(painter: _FramingGuidePainter())),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2D60DB).withValues(alpha: .92),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wb_sunny_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Move to better light and fill the guide with the wound.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton.filled(
                onPressed:
                    _controller?.value.isInitialized == true && !_capturing
                    ? _capture
                    : null,
                tooltip: 'Capture photo',
                iconSize: 36,
                padding: const EdgeInsets.all(18),
                icon: _capturing
                    ? const SizedBox.square(
                        dimension: 36,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FramingGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final guide = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * .72,
      height: size.height * .42,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(guide, const Radius.circular(24)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ImageReviewScreen extends StatefulWidget {
  const ImageReviewScreen({
    super.key,
    required this.patientId,
    required this.image,
    required this.analysisRepository,
    required this.alternateSource,
  });

  final String patientId;
  final SelectedImage image;
  final AnalysisRepository analysisRepository;
  final ImageSourceType alternateSource;

  @override
  State<ImageReviewScreen> createState() => _ImageReviewScreenState();
}

class _ImageReviewScreenState extends State<ImageReviewScreen> {
  String? _error;
  bool _uploading = false;
  double _uploadProgress = 0;

  Future<String?> _validate() async {
    final lowerName = widget.image.name.toLowerCase();
    if (!lowerName.endsWith('.jpg') &&
        !lowerName.endsWith('.jpeg') &&
        !lowerName.endsWith('.png')) {
      return 'Only JPEG and PNG images can be uploaded.';
    }
    if (widget.image.bytes.length > 15 * 1024 * 1024) {
      return 'This image is larger than 15 MB. Choose a smaller file.';
    }
    try {
      final codec = await ui.instantiateImageCodec(
        Uint8List.fromList(widget.image.bytes),
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final tooSmall = image.width < 400 || image.height < 400;
      image.dispose();
      codec.dispose();
      if (tooSmall) {
        return 'Image resolution too low - please retake or choose a larger photo.';
      }
    } catch (_) {
      return 'The selected file could not be read as an image.';
    }
    return null;
  }

  Future<void> _continue() async {
    setState(() => _error = null);
    final validationError = await _validate();
    if (!mounted) return;
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });
    try {
      final result = await widget.analysisRepository.submit(
        patientId: widget.patientId,
        image: widget.image,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress.clamp(0, 1));
        },
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upload started'),
          content: Text('Analysis ${result.analysisId} is ${result.status}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      final processResult = await widget.analysisRepository.process(result.analysisId);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => AnalysisResultsScreen(
            result: processResult,
            originalImage: widget.image,
          ),
        ),
      );
    } on AnalysisUploadException catch (error) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = 'Upload failed - check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review photo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF1F4FA),
                  child: Image.memory(
                    Uint8List.fromList(widget.image.bytes),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.image.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_uploading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _uploadProgress == 0 ? null : _uploadProgress,
              ),
              const SizedBox(height: 6),
              Text(
                _uploadProgress == 0
                    ? 'Preparing upload...'
                    : 'Uploading ${(_uploadProgress * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: Icon(
                      widget.alternateSource == ImageSourceType.camera
                          ? Icons.refresh
                          : Icons.folder_open,
                    ),
                    label: Text(
                      widget.alternateSource == ImageSourceType.camera
                          ? 'Retake'
                          : 'Choose different',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _uploading ? null : _continue,
                    icon: _uploading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(_uploading ? 'Uploading...' : 'Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AnalysisResultsScreen extends StatelessWidget {
  const AnalysisResultsScreen({
    super.key,
    required this.result,
    required this.originalImage,
  });

  final AnalysisResult result;
  final SelectedImage originalImage;

  String? _assetUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8000',
    );
    return Uri.parse(baseUrl).resolve(path).toString();
  }

  @override
  Widget build(BuildContext context) {
    final isFallback = result.fellBack == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis results')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            isFallback ? 'Boundary not detected' : 'Analysis complete',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text('Analysis ${result.analysisId}'),
          const SizedBox(height: 20),
          if (result.overlayUrl != null) ...[
            _SegmentationPreview(
              originalImage: originalImage,
              overlayUrl: _assetUrl(result.overlayUrl)!,
            ),
            const SizedBox(height: 20),
          ],
          if (result.grade != null) _ResultRow('Grade', '${result.grade}'),
          if (result.classificationStatus != null)
            _ResultRow('Classification', result.classificationStatus!),
          if (result.message != null) ...[
            const SizedBox(height: 20),
            Text(result.message!),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to patient workspace'),
          ),
        ],
      ),
    );
  }
}

class _SegmentationPreview extends StatelessWidget {
  const _SegmentationPreview({
    required this.originalImage,
    required this.overlayUrl,
  });

  final SelectedImage originalImage;
  final String overlayUrl;

  @override
  Widget build(BuildContext context) {
    final imageBytes = Uint8List.fromList(originalImage.bytes);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: const Color(0xFFF1F4FA),
        constraints: const BoxConstraints(minHeight: 220, maxHeight: 440),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.memory(imageBytes, fit: BoxFit.contain),
            Image.network(
              overlayUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 220,
                child: Center(child: Text('Segmentation overlay unavailable.')),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .68),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    'Red overlay: detected wound region',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))],
      ),
    );
  }
}
