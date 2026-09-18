import 'package:flutter/material.dart';

void main() => runApp(const DfuApp());

class DfuApp extends StatefulWidget {
  const DfuApp({super.key});

  @override
  State<DfuApp> createState() => _DfuAppState();
}

class _DfuAppState extends State<DfuApp> {
  final _repository = DemoRepository();
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
              onSignOut: () => setState(() => _signedIn = false),
            )
          : LoginScreen(onSignedIn: () => setState(() => _signedIn = true)),
    );
  }
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
    Patient(name: 'Amina Yusuf', externalRef: 'DFU-1042'),
    Patient(name: 'Thomas Reed', externalRef: 'DFU-1047'),
  ];

  @override
  List<Patient> get patients => List.unmodifiable(_patients);

  @override
  Future<void> addPatient(Patient patient) async =>
      _patients.insert(0, patient);
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
    required this.onSignOut,
  });

  final PatientRepository repository;
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
                      itemBuilder: (context, index) =>
                          PatientCard(patient: patients[index]),
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
  const PatientCard({super.key, required this.patient});

  final Patient patient;

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
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient history is coming in Feature 6.'),
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
