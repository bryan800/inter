import 'package:flutter/material.dart';

import 'login_screen.dart';
import '../utils/platform_gate.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String _backgroundAssetMoney = 'uploads/money.png';
  static const String _backgroundAssetPng = 'assets/images/welcome_bg.png';
  static const String _backgroundAssetJpg = 'assets/images/welcome_bg.jpg';
  static const String _backgroundAssetJpeg = 'assets/images/welcome_bg.jpeg';

  Widget _fallbackGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF061F18),
            Color(0xFFEFF7F1),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Image.asset(
      _backgroundAssetMoney,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, error, __) {
        debugPrint(
            'Failed to load background asset "$_backgroundAssetMoney": $error');
        return Image.asset(
          _backgroundAssetPng,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, error, __) {
            debugPrint(
                'Failed to load background asset "$_backgroundAssetPng": $error');
            return Image.asset(
              _backgroundAssetJpg,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, error, __) {
                debugPrint(
                    'Failed to load background asset "$_backgroundAssetJpg": $error');
                return Image.asset(
                  _backgroundAssetJpeg,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, error, __) {
                    debugPrint(
                        'Failed to load background asset "$_backgroundAssetJpeg": $error');
                    return _fallbackGradient();
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  static const Map<String, List<Map<String, Object>>> _regionalCountries = {
    'Africa': [
      {'name': 'Nigeria', 'currency': 'NGN', 'rate': 1475.00, 'iso': 'NG'},
      {'name': 'Kenya', 'currency': 'KES', 'rate': 131.50, 'iso': 'KE'},
      {'name': 'Ghana', 'currency': 'GHS', 'rate': 12.80, 'iso': 'GH'},
      {'name': 'South Africa', 'currency': 'ZAR', 'rate': 18.90, 'iso': 'ZA'},
      {'name': 'Egypt', 'currency': 'EGP', 'rate': 47.30, 'iso': 'EG'},
      {'name': 'Senegal', 'currency': 'XOF', 'rate': 605.00, 'iso': 'SN'},
      {'name': 'Tanzania', 'currency': 'TZS', 'rate': 2550.00, 'iso': 'TZ'},
      {'name': 'Uganda', 'currency': 'UGX', 'rate': 3880.00, 'iso': 'UG'},
    ],
    'North America': [
      {'name': 'USA', 'currency': 'USD', 'rate': 1.00, 'iso': 'US'},
      {'name': 'Canada', 'currency': 'CAD', 'rate': 1.36, 'iso': 'CA'},
      {'name': 'Mexico', 'currency': 'MXN', 'rate': 16.70, 'iso': 'MX'},
      {'name': 'Jamaica', 'currency': 'JMD', 'rate': 155.00, 'iso': 'JM'},
    ],
  };

  String _flagEmojiFromIso(String iso) {
    if (iso.length != 2) return '';

    const flagBase = 0x1F1E6;
    final codeUnits = iso.toUpperCase().codeUnits;
    if (codeUnits.any((c) => c < 0x41 || c > 0x5A)) return '';

    return String.fromCharCodes(codeUnits.map((c) => flagBase + (c - 0x41)));
  }

  void _goToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(initialCreateAccount: false),
      ),
    );
  }

  void _goToSignUp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(initialCreateAccount: true),
      ),
    );
  }

  void _showExchangeRates(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFEFB).withAlpha(226),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Exchange rates',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: _regionalCountries.entries
                        .expand((entry) => [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              ...entry.value.map((c) {
                                final name = c['name']! as String;
                                final currency = c['currency']! as String;
                                final rate = c['rate']! as double;
                                final iso = c['iso']! as String;
                                final flag = _flagEmojiFromIso(iso);
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    '$flag $name (1 USD = $rate $currency)',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                );
                              }),
                              const Divider(height: 1),
                            ])
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          // Keep the photo visible while ensuring readable UI.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF061F18).withAlpha(150),
                  const Color(0xFF061F18).withAlpha(95),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF061F18).withAlpha(150),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'INTERFLEX',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF061F18).withAlpha(150),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton(
                          onPressed: () => _goToLogin(context),
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'FOR HERE\nFOR THERE\nFOR HOME',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => _goToSignUp(context),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child:
                            Text('or', style: TextStyle(color: Colors.black54)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isIOS) ...[
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => _goToLogin(context),
                        icon: const Icon(Icons.apple),
                        label: const Text(
                          'Continue with Apple',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _goToLogin(context),
                      icon: const Icon(Icons.mail_outline),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => _showExchangeRates(context),
                    child: const Text(
                      'Check our exchange rate',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
