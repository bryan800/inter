import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

enum _IdentityStep {
  intro,
  document,
  consent,
  checklist,
  pin,
  recording,
  review,
}

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  static const _countries = [
    'Uganda',
    'Kenya',
    'Tanzania',
    'Rwanda',
    'Nigeria',
    'Ghana',
    'South Africa',
    'United States',
    'Canada',
    'Mexico',
  ];

  static const Map<String, String> _countryIsoCodes = {
    'Uganda': 'UG',
    'Kenya': 'KE',
    'Tanzania': 'TZ',
    'Rwanda': 'RW',
    'Nigeria': 'NG',
    'Ghana': 'GH',
    'South Africa': 'ZA',
    'United States': 'US',
    'Canada': 'CA',
    'Mexico': 'MX',
  };

  static const _documents = [
    'Passport',
    'National ID card',
    'Driving licence',
    'Residence permit',
  ];

  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  _IdentityStep _step = _IdentityStep.intro;
  String? _selectedCountry;
  String? _selectedDocument;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final country = context.read<AuthService>().userCountry;
    _selectedCountry = _countries.contains(country) ? country : null;
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  String _flagEmojiFor(String country) {
    final iso = _countryIsoCodes[country];
    if (iso == null || iso.length != 2) return '';

    const flagBase = 0x1F1E6;
    final codeUnits = iso.toUpperCase().codeUnits;
    if (codeUnits.any((c) => c < 0x41 || c > 0x5A)) return '';

    return String.fromCharCodes(codeUnits.map((c) => flagBase + (c - 0x41)));
  }

  Widget _countryLabel(String country) {
    final flag = _flagEmojiFor(country);
    return Text(
      flag.isEmpty ? country : '$flag $country',
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_step) {
      _IdentityStep.intro => _buildIntro(),
      _IdentityStep.document => _buildDocumentSelection(),
      _IdentityStep.consent => _buildConsent(),
      _IdentityStep.checklist => _buildChecklist(),
      _IdentityStep.pin => _buildPinSetup(),
      _IdentityStep.recording => _buildRecording(),
      _IdentityStep.review => _buildReview(),
    };

    return PopScope(
      canPop: _step == _IdentityStep.intro,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _step != _IdentityStep.intro) {
          _previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            tooltip: _step == _IdentityStep.intro ? 'Back' : 'Previous step',
            onPressed: () {
              if (_step == _IdentityStep.intro) {
                Navigator.pop(context);
                return;
              }
              _previousStep();
            },
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(_title),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Padding(
              key: ValueKey(_step),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  String get _title {
    return switch (_step) {
      _IdentityStep.intro => 'Secure your account',
      _IdentityStep.document => 'Select document',
      _IdentityStep.consent => 'Consent',
      _IdentityStep.checklist => 'Verify your identity',
      _IdentityStep.pin => 'Create security PIN',
      _IdentityStep.recording => 'Liveness check',
      _IdentityStep.review => 'Review',
    };
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5EC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    size: 96,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'We need to verify your identity',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                const Text(
                  'To protect your money transfers, we will ask for your identity document, a quick face check, and a transaction PIN.',
                  style: TextStyle(fontSize: 15, height: 1.35),
                ),
              ],
            ),
          ),
        ),
        _PrivacyNotice(),
        const SizedBox(height: 12),
        _PrimaryAction(
          label: 'Continue',
          onPressed: () => _goTo(_IdentityStep.document),
        ),
      ],
    );
  }

  Widget _buildDocumentSelection() {
    final canContinue = _selectedCountry != null && _selectedDocument != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose the country and document you will use for verification.',
                  style: TextStyle(height: 1.35),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedCountry,
                  decoration: const InputDecoration(
                    labelText: 'Select a country',
                    prefixIcon: Icon(Icons.public_outlined),
                  ),
                  items: _countries
                      .map(
                        (country) => DropdownMenuItem(
                          value: country,
                          child: _countryLabel(country),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (context) =>
                      _countries.map(_countryLabel).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCountry = value),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedDocument,
                  decoration: const InputDecoration(
                    labelText: 'Select a document',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: _documents
                      .map(
                        (document) => DropdownMenuItem(
                          value: document,
                          child:
                              Text(document, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedDocument = value),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Use a valid, unexpired document. Photos should be clear, uncropped, and readable.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        _PrimaryAction(
          label: 'Continue',
          onPressed: canContinue ? () => _goTo(_IdentityStep.consent) : null,
        ),
      ],
    );
  }

  Widget _buildConsent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Consent to process biometric data and sensitive data',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 16),
                Text(
                  'To continue, INTERFLEX and its trusted verification providers may process your document photo, face recording, biometric data, and personal data for identity verification, fraud prevention, and account protection.',
                  style: TextStyle(height: 1.35),
                ),
                SizedBox(height: 14),
                Text(
                  'By accepting, you confirm that you understand this data is used only for verification and security purposes. If you do not accept, identity verification cannot continue in the app.',
                  style: TextStyle(height: 1.35, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        _PrimaryAction(
          label: 'Accept',
          onPressed: () => _goTo(_IdentityStep.checklist),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Do not accept'),
        ),
      ],
    );
  }

  Widget _buildChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 32),
                Text(
                  'Use your device to:',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 24),
                _StepInstruction(
                  number: '1',
                  text: 'Take a photo of your identity document',
                ),
                SizedBox(height: 18),
                _StepInstruction(
                  number: '2',
                  text: 'Record a short video of your face',
                ),
                SizedBox(height: 18),
                _StepInstruction(
                  number: '3',
                  text: 'Create a private transaction PIN',
                ),
              ],
            ),
          ),
        ),
        _PrimaryAction(
          label: 'Start',
          onPressed: () => _goTo(_IdentityStep.pin),
        ),
      ],
    );
  }

  Widget _buildPinSetup() {
    final pinTheme = PinTheme(
      width: 54,
      height: 54,
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F8),
        border: Border.all(color: const Color(0xFFD7DEE2)),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Set a 4-digit PIN',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This PIN protects transfers, withdrawals, and account changes.',
                  style: TextStyle(height: 1.35),
                ),
                const SizedBox(height: 28),
                Pinput(
                  controller: _pinController,
                  length: 4,
                  obscureText: true,
                  defaultPinTheme: pinTheme,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Confirm PIN',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Pinput(
                  controller: _confirmPinController,
                  length: 4,
                  obscureText: true,
                  defaultPinTheme: pinTheme,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ),
        _PrimaryAction(
          label: 'Continue',
          onPressed: _canSavePin ? _savePinAndContinue : null,
        ),
      ],
    );
  }

  Widget _buildRecording() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 72),
                Icon(
                  Icons.face_retouching_natural_outlined,
                  size: 92,
                  color: Color(0xFF168A96),
                ),
                SizedBox(height: 28),
                Text(
                  'Record a video',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 10),
                Text('This helps us verify that you are a real person.'),
                SizedBox(height: 24),
                Text('First, position your face in the frame.'),
                SizedBox(height: 10),
                Text('Then, turn your head slowly to both sides.'),
                SizedBox(height: 28),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFECEBFF),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF3437D7)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your face and background will be recorded during this process.',
                            style: TextStyle(fontSize: 12),
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
        _PrimaryAction(
          label: _isSubmitting ? 'Recording...' : 'Start recording',
          onPressed: _isSubmitting ? null : _simulateRecording,
        ),
      ],
    );
  }

  Widget _buildReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.manage_search_outlined,
                size: 112,
                color: Color(0xFF4A1021),
              ),
              SizedBox(height: 28),
              Text(
                'Thank you!\nWe are reviewing your documents',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 14),
              Text(
                'It usually takes less than a minute.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        _PrimaryAction(
          label: 'Go to Home',
          onPressed: _finish,
        ),
      ],
    );
  }

  bool get _canSavePin {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;
    return pin.length == 4 && confirmPin.length == 4 && confirmPin == pin;
  }

  void _goTo(_IdentityStep step) {
    setState(() => _step = step);
  }

  void _previousStep() {
    final nextIndex = _IdentityStep.values.indexOf(_step) - 1;
    if (nextIndex < 0) return;
    setState(() => _step = _IdentityStep.values[nextIndex]);
  }

  Future<void> _savePinAndContinue() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match.')),
      );
      return;
    }

    await context.read<AuthService>().changePin(pin);
    if (!mounted) return;
    _goTo(_IdentityStep.recording);
  }

  Future<void> _simulateRecording() async {
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    await context.read<AuthService>().submitIdentityVerification(
          documentCountry: _selectedCountry!,
          documentType: _selectedDocument!,
        );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _step = _IdentityStep.review;
    });
  }

  void _finish() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFFFFBEA)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 18, color: Colors.black54),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'We take your privacy and security seriously. Your personal information is used for verification only.',
                style: TextStyle(fontSize: 12, height: 1.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepInstruction extends StatelessWidget {
  const _StepInstruction({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFFE7F7F8),
          foregroundColor: const Color(0xFF168A96),
          child: Text(
            number,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(text)),
      ],
    );
  }
}
