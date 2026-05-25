import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../models/transaction_model.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';

const Color _appBackground = Color(0xFFEFF7F1);
const Color _appSurface = Color(0xFFFAFEFB);
const Color _appPrimary = Color(0xFF0E7A5F);
const Color _appSecondary = Color(0xFF0F9AA7);
const Color _appAmber = Color(0xFFF4B740);
const Color _appTextMuted = Color(0xFF60766B);
const Color _appOutline = Color(0xFFC9DCD0);

class _DestinationCountry {
  const _DestinationCountry({
    required this.country,
    required this.currency,
    required this.rate,
    required this.delivery,
    required this.rail,
  });

  final String country;
  final String currency;
  final double rate;
  final String delivery;
  final String rail;
}

class Recipient {
  final String name;
  final String number;
  final String country;
  final bool isGroup;
  Recipient(this.name, this.number, this.country, {this.isGroup = false});
}

class AppNotification {
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  final _amountController = TextEditingController(text: '1250');
  final _searchController = TextEditingController();

  final List<AppNotification> _notifications = [];

  final List<Recipient> _allRecipients = [
    Recipient('Anna Keller', '+49 123 456 789', 'Germany'),
    Recipient('John Doe', '+234 801 234 5678', 'Nigeria'),
    Recipient('Maria Garcia', '+52 55 1234 5678', 'Mexico'),
    Recipient('Family Support', 'Multi-recipient', 'Global', isGroup: true),
    Recipient('Peter Chen', '+86 10 1234 5678', 'China'),
    Recipient('Sarah Smith', '+44 20 1234 5678', 'UK'),
  ];

  List<Recipient> _filteredRecipients = [];

  @override
  void initState() {
    super.initState();
    _filteredRecipients = _allRecipients;
    _searchController.addListener(_filterRecipients);

    // Request permissions
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    // Wait for the first frame to ensure context is ready for bottom sheets
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    // Check if PIN needs to be changed
    final authService = context.read<AuthService>();
    if (!authService.pinChanged) {
      _showMandatoryChangePinSheet();
    }

    // Request Location Permission
    await LocationService.requestLocationPermission();

    // Optional: Get initial location to "match live location"
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      _addNotification('Location Verified',
          'Live activity matched to your current location.');
    }
  }

  void _showMandatoryChangePinSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MandatoryChangePinSheet(
        onComplete: (title, msg) => _addNotification(title, msg),
      ),
    );
  }

  void _filterRecipients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRecipients = _allRecipients.where((r) {
        return r.name.toLowerCase().contains(query) ||
            r.number.toLowerCase().contains(query);
      }).toList();
    });
  }

  static const _destinations = [
    _DestinationCountry(
      country: 'Germany',
      currency: 'EUR',
      rate: 0.91,
      delivery: 'Instant SEPA',
      rail: 'SEPA / SWIFT',
    ),
    _DestinationCountry(
      country: 'United Kingdom',
      currency: 'GBP',
      rate: 0.78,
      delivery: 'Instant to 1 hour',
      rail: 'Faster Payments / SWIFT',
    ),
    _DestinationCountry(
      country: 'Nigeria',
      currency: 'NGN',
      rate: 1475.20,
      delivery: '10 minutes',
      rail: 'Bank / mobile wallet',
    ),
    _DestinationCountry(
      country: 'India',
      currency: 'INR',
      rate: 83.10,
      delivery: 'Instant to 2 hours',
      rail: 'UPI / bank transfer',
    ),
    _DestinationCountry(
      country: 'Philippines',
      currency: 'PHP',
      rate: 56.90,
      delivery: 'Instant to 1 hour',
      rail: 'Bank / cash pickup',
    ),
    _DestinationCountry(
      country: 'Mexico',
      currency: 'MXN',
      rate: 16.75,
      delivery: 'Under 30 minutes',
      rail: 'SPEI / cash pickup',
    ),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addNotification(String title, String message) {
    setState(() {
      _notifications.insert(
          0,
          AppNotification(
            title: title,
            message: message,
            timestamp: DateTime.now(),
          ));
    });
  }

  void _showNotifications() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: _notifications.isEmpty
                  ? const Center(child: Text('No new notifications'))
                  : ListView.separated(
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(n.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.message),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.jm().format(n.timestamp),
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _goHome() {
    if (_tabIndex == 0) return;
    setState(() => _tabIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    if (authService.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          ),
        );
      });
    }

    final pages = [
      _homePage(context),
      _historyPage(context),
      _supportPage(context),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 780;

        return Scaffold(
          backgroundColor: _appBackground,
          appBar: AppBar(
            title: Semantics(
              button: true,
              label: 'Home',
              child: Tooltip(
                message: 'Home',
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _goHome,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('INTERFLEX'),
                  ),
                ),
              ),
            ),
            backgroundColor: _appBackground,
            actions: [
              if (_tabIndex == 0) ...[
                Stack(
                  children: [
                    IconButton(
                      tooltip: 'Notifications',
                      icon: const Icon(Icons.notifications_none),
                      onPressed: _showNotifications,
                    ),
                    if (_notifications.any((n) => !n.isRead))
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              color: _appAmber,
                              borderRadius: BorderRadius.circular(6)),
                          constraints: const BoxConstraints(
                              minWidth: 12, minHeight: 12),
                          child: Text(
                            '${_notifications.where((n) => !n.isRead).length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    context.read<AuthService>().logout();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      backgroundColor: _appSurface.withAlpha(242),
                      indicatorColor: _appPrimary.withAlpha(40),
                      selectedIndex: _tabIndex,
                      onDestinationSelected: (value) =>
                          setState(() => _tabIndex = value),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.history),
                          selectedIcon: Icon(Icons.history),
                          label: Text('History'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.help_outline),
                          selectedIcon: Icon(Icons.help),
                          label: Text('Support'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: pages[_tabIndex]),
                  ],
                )
              : pages[_tabIndex],
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  backgroundColor: _appSurface.withAlpha(242),
                  indicatorColor: _appPrimary.withAlpha(40),
                  selectedIndex: _tabIndex,
                  onDestinationSelected: (value) =>
                      setState(() => _tabIndex = value),
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home),
                        label: 'Home'),
                    NavigationDestination(
                        icon: Icon(Icons.history),
                        selectedIcon: Icon(Icons.history),
                        label: 'History'),
                    NavigationDestination(
                        icon: Icon(Icons.help_outline),
                        selectedIcon: Icon(Icons.help),
                        label: 'Support'),
                  ],
                ),
        );
      },
    );
  }

  Widget _homePage(BuildContext context) {
    final authService = context.watch<AuthService>();
    final accountNumber = authService.accountNumber ?? 'Generating...';
    final userName = (authService.userName?.trim().isNotEmpty ?? false)
        ? authService.userName!.trim()
        : 'Customer';
    final currencySymbol = authService.currencySymbol;
    final userMoney = NumberFormat.currency(symbol: currencySymbol);
    final currentBalance = authService.balance;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
        _WaveBalanceCard(
          money: userMoney,
          balance: currentBalance,
          userName: userName,
          accountNumber: accountNumber,
          onSend: () => _showSendToUserSheet(userMoney, currencySymbol),
          onScan: () => _showScanToPaySheet(userMoney, currencySymbol),
          onWithdraw: () => _showWithdrawSheet(userMoney, currencySymbol),
          onTopup: () => _showTopupSheet(userMoney, currencySymbol),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 10 : 16,
            4,
            isCompact ? 10 : 16,
            8,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Send to name or number',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear())
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              fillColor: _appSurface,
            ),
          ),
        ),
        Expanded(
          child: _filteredRecipients.isEmpty
              ? const Center(child: Text('No recipients found'))
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 10 : 16,
                    12,
                    isCompact ? 10 : 16,
                    20,
                  ),
                  itemCount: _filteredRecipients.length +
                      (authService.recentTransactions.isEmpty ||
                              _searchController.text.isNotEmpty
                          ? 0
                          : 1),
                  itemBuilder: (context, index) {
                    if (_searchController.text.isEmpty &&
                        authService.recentTransactions.isNotEmpty &&
                        index == 0) {
                      return _LatestTransactionsPreview(
                        transactions:
                            authService.recentTransactions.take(3).toList(),
                      );
                    }

                    final recipientIndex =
                        authService.recentTransactions.isNotEmpty &&
                                _searchController.text.isEmpty
                            ? index - 1
                            : index;
                    final r = _filteredRecipients[recipientIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (recipientIndex == 0 &&
                            _searchController.text.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
                            child: Text(
                              'Recent recipients',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: _appTextMuted,
                                  ),
                            ),
                          ),
                        if (recipientIndex == 3 &&
                            _searchController.text.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'All contacts',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: _appTextMuted,
                                  ),
                            ),
                          ),
                        _RecipientTile(
                          name: r.name,
                          number: r.number,
                          country: r.country,
                          isGroup: r.isGroup,
                          onTap: () => _showTransferReview(r),
                        ),
                      ],
                    );
                  },
                ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _historyPage(BuildContext context) {
    return _ResponsivePageList(
      children: const [
        _RecentActivityPanel(),
      ],
    );
  }

  Widget _supportPage(BuildContext context) {
    return _ResponsivePageList(
      children: [
        const _SectionHeader(
          title: 'How can we help?',
          subtitle: 'Our support team is available 24/7 to assist you.',
          icon: Icons.support_agent,
        ),
        const SizedBox(height: 20),
        _SupportActionTile(
          Icons.chat_bubble_outline,
          'Chat with us',
          'Instant help from our team',
          () => _showLiveChatSheet(context),
        ),
        const SizedBox(height: 12),
        _SupportActionTile(
          Icons.phone_outlined,
          'Call support',
          'Speak to an agent',
          () => _showCallSupportSheet(context),
        ),
        const SizedBox(height: 12),
        _SupportActionTile(
          Icons.email_outlined,
          'Email us',
          'support@interflex.com',
          () => _showEmailSupportSheet(context),
        ),
        const SizedBox(height: 24),
        Text('Security Settings',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: _appTextMuted)),
        const SizedBox(height: 12),
        _SupportActionTile(
            Icons.lock_outline,
            'Change Transaction PIN',
            'Update your 4-digit security PIN',
            () => _showChangePinSheet(context)),
      ],
    );
  }

  void _showLiveChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LiveChatSheet(),
    );
  }

  void _showCallSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SupportContactSheet(
        icon: Icons.phone_outlined,
        title: 'Call support',
        subtitle: 'Our agents are available 24/7.',
        primaryText: AuthService.adminSupportNumber,
        primaryLabel: 'Copy admin number',
        copiedMessage: 'Admin number copied',
      ),
    );
  }

  void _showEmailSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SupportContactSheet(
        icon: Icons.email_outlined,
        title: 'Email support',
        subtitle: 'Send us your issue and account details.',
        primaryText: 'support@interflex.com',
        primaryLabel: 'Copy email',
        copiedMessage: 'Support email copied',
      ),
    );
  }

  void _showChangePinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MandatoryChangePinSheet(
        isMandatory: false,
        onComplete: (title, msg) => _addNotification(title, msg),
      ),
    );
  }

  void _showSendToUserSheet(NumberFormat moneyFormatter, String symbol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SecureSendToUserFlow(
        money: moneyFormatter,
        currencySymbol: symbol,
        onComplete: (amountStr, country, account) async {
          _addNotification('Send Successful',
              'Successfully sent $amountStr to account $account in $country.');
        },
        onReversalRequest: () =>
            _showReversalSheet(TransactionType.send, symbol),
      ),
    );
  }

  void _showWithdrawSheet(NumberFormat moneyFormatter, String symbol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SecureWithdrawFlow(
        money: moneyFormatter,
        currencySymbol: symbol,
        onComplete: (amountStr, method) async {
          _addNotification('Withdrawal Initiated',
              'Withdrawal of $amountStr to $method is being processed.');
        },
        onReversalRequest: () =>
            _showReversalSheet(TransactionType.withdraw, symbol),
      ),
    );
  }

  void _showScanToPaySheet(NumberFormat moneyFormatter, String symbol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SecureScanToPayFlow(
        money: moneyFormatter,
        currencySymbol: symbol,
        onComplete: (amountStr, merchant) async {
          _addNotification(
              'Payment Sent', 'You paid $amountStr to Merchant ID: $merchant.');
        },
        onReversalRequest: () =>
            _showReversalSheet(TransactionType.pay, symbol),
      ),
    );
  }

  void _showTopupSheet(NumberFormat moneyFormatter, String symbol) {
    final authService = context.read<AuthService>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SecureTopupFlow(
        money: moneyFormatter,
        currencySymbol: symbol,
        onComplete: (amountStr, card) async {
          final amount =
              double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                  0.0;

          if (amount <= 0) {
            _addNotification('Topup Failed', 'Enter a valid top-up amount.');
            showDialog(
              context: context,
              builder: (context) => const _FailureDialog(
                message: 'Enter a valid top-up amount to continue.',
              ),
            );
            return;
          }

          await authService.updateBalance(amount);
          authService.logTransaction(
            TransactionType.topup,
            amount,
            'Card ending ${card.substring(card.length - 4)}',
          );
          if (!mounted) return;
          _addNotification('Topup Successful',
              'Successfully topped up $amountStr from card ending in ${card.substring(card.length - 4)}.');
          showDialog(
            context: context,
            builder: (context) => _SuccessDialog(
              message:
                  'You have successfully topped up $amountStr from your bank account.',
            ),
          );
        },
      ),
    );
  }

  void _showReversalSheet(TransactionType type, String symbol) {
    Navigator.pop(context); // Close the current flow
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SecureReversalFlow(
        type: type,
        currencySymbol: symbol,
        onComplete: (title, msg) => _addNotification(title, msg),
      ),
    );
  }

  void _showTransferReview(Recipient recipient) {
    final authService = context.read<AuthService>();
    final currencySymbol = authService.currencySymbol;
    final userMoney = NumberFormat.currency(symbol: currencySymbol);

    final dest = _destinations.firstWhere((d) => d.country == recipient.country,
        orElse: () => _destinations.first);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WaveTransferSheet(
        money: userMoney,
        currencySymbol: currencySymbol,
        recipientName: recipient.name,
        recipientCountry: recipient.country,
        fxRate: dest.rate,
        currency: dest.currency,
        onComplete: (amount, currency) async {
          await authService.updateBalance(-amount / dest.rate); // Debit sender
          _addNotification('Transfer Sent',
              'You sent $currencySymbol ${userMoney.format(amount / dest.rate).replaceAll(currencySymbol, '').trim()} to ${recipient.name} ($amount $currency received).');
        },
      ),
    );
  }
}

class _WaveBalanceCard extends StatelessWidget {
  const _WaveBalanceCard({
    required this.money,
    required this.balance,
    required this.userName,
    required this.accountNumber,
    required this.onSend,
    required this.onScan,
    required this.onWithdraw,
    required this.onTopup,
  });
  final NumberFormat money;
  final double balance;
  final String userName;
  final String accountNumber;
  final VoidCallback onSend;
  final VoidCallback onScan;
  final VoidCallback onWithdraw;
  final VoidCallback onTopup;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;
        final horizontalPadding = isCompact ? 16.0 : 20.0;
        final balanceFontSize = isCompact ? 28.0 : 32.0;
        final accountFontSize = isCompact ? 11.0 : 12.0;
        final actionIconPadding = isCompact ? 9.0 : 10.0;

        return Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(
            isCompact ? 10 : 16,
            8,
            isCompact ? 10 : 16,
            10,
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            isCompact ? 14 : 18,
            horizontalPadding,
            isCompact ? 14 : 18,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _appPrimary,
                _appSecondary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _appPrimary.withAlpha(45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $userName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Your balance',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Account: $accountNumber',
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: accountFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  money.format(balance),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: balanceFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 14 : 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _WaveQuickAction(
                    icon: Icons.send_outlined,
                    label: 'Send',
                    iconPadding: actionIconPadding,
                    onTap: onSend,
                  ),
                  _WaveQuickAction(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan',
                    iconPadding: actionIconPadding,
                    onTap: onScan,
                  ),
                  _WaveQuickAction(
                    icon: Icons.account_balance_wallet,
                    label: 'Withdraw',
                    iconPadding: actionIconPadding,
                    onTap: onWithdraw,
                  ),
                  _WaveQuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Topup',
                    iconPadding: actionIconPadding,
                    onTap: onTopup,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResponsivePageList extends StatelessWidget {
  const _ResponsivePageList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _WaveQuickAction extends StatelessWidget {
  const _WaveQuickAction(
      {required this.icon,
      required this.label,
      required this.iconPadding,
      required this.onTap});
  final IconData icon;
  final String label;
  final double iconPadding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.black12,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(46),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(64)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _RecipientTile extends StatelessWidget {
  const _RecipientTile({
    required this.name,
    required this.number,
    required this.country,
    this.onTap,
    this.isGroup = false,
  });
  final String name;
  final String number;
  final String country;
  final VoidCallback? onTap;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE4F5F0),
        child: Icon(isGroup ? Icons.group : Icons.person, color: _appPrimary),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$country • $number',
          style: const TextStyle(color: _appTextMuted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: _appTextMuted),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFE4F5F0),
          child: Icon(icon, color: _appPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: _appTextMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _appTextMuted),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportActionTile extends StatelessWidget {
  const _SupportActionTile(this.icon, this.title, this.subtitle, [this.onTap]);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: _Panel(
        child: Row(
          children: [
            Icon(icon, color: _appPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style:
                          const TextStyle(color: _appTextMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _SupportContactSheet extends StatelessWidget {
  const _SupportContactSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryText,
    required this.primaryLabel,
    required this.copiedMessage,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryText;
  final String primaryLabel;
  final String copiedMessage;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottomPadding),
        decoration: BoxDecoration(
          color: _appSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE4F5F0),
                  child: Icon(icon, color: _appPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: _appTextMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2FAF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _appOutline),
              ),
              child: SelectableText(
                primaryText,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: primaryText));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(copiedMessage)),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.copy_outlined),
              label: Text(primaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveChatSheet extends StatefulWidget {
  const _LiveChatSheet();

  @override
  State<_LiveChatSheet> createState() => _LiveChatSheetState();
}

class _LiveChatSheetState extends State<_LiveChatSheet> {
  final _messageController = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Hi, welcome to INTERFLEX support. How can we help today?',
      fromAgent: true,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(bottom: keyboardPadding),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _appSurface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE4F5F0),
                      child: Icon(Icons.support_agent, color: _appPrimary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live chat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Usually replies instantly',
                            style: TextStyle(color: _appTextMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Align(
                      alignment: message.fromAgent
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: message.fromAgent
                              ? const Color(0xFFF2F7F4)
                              : _appPrimary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: message.fromAgent
                                ? const Color(0xFF17231E)
                                : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        decoration: const InputDecoration(
                          hintText: 'Type your message',
                          prefixIcon: Icon(Icons.chat_bubble_outline),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Send',
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send),
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, fromAgent: false));
      _messageController.clear();
      _messages.add(
        const _ChatMessage(
          text:
              'Thanks. A support agent has received this and will guide you shortly.',
          fromAgent: true,
        ),
      );
    });
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.fromAgent,
  });

  final String text;
  final bool fromAgent;
}

class _RecentActivityPanel extends StatelessWidget {
  const _RecentActivityPanel();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final symbol = authService.currencySymbol;
    final balance = authService.balance;
    final transactions = authService.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _ActivityRow(
            icon: Icons.account_balance_wallet,
            title: 'Current Wallet Balance',
            amount: '$symbol ${balance.toStringAsFixed(2)}',
            date: 'Live Status'),
        const Divider(),
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'No transactions yet.',
              style: TextStyle(color: _appTextMuted),
            ),
          )
        else
          ...transactions.map((tx) => _ActivityRow.fromTransaction(tx)),
      ],
    );
  }
}

class _LatestTransactionsPreview extends StatelessWidget {
  const _LatestTransactionsPreview({required this.transactions});

  final List<TransactionRecord> transactions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest transactions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _appTextMuted,
                ),
          ),
          const SizedBox(height: 8),
          ...transactions.map(_ActivityRow.fromTransaction),
          const Divider(height: 24),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(
      {required this.icon,
      required this.title,
      required this.amount,
      required this.date});

  factory _ActivityRow.fromTransaction(TransactionRecord tx) {
    final isCredit = tx.type == TransactionType.topup || tx.isReversed;
    final amountPrefix = isCredit ? '+' : '-';
    final title = switch (tx.type) {
      TransactionType.send => 'Sent to ${tx.destination}',
      TransactionType.pay => 'Paid ${tx.destination}',
      TransactionType.withdraw => 'Withdrew to ${tx.destination}',
      TransactionType.topup => 'Topup from ${tx.destination}',
    };
    final icon = switch (tx.type) {
      TransactionType.send => Icons.arrow_outward,
      TransactionType.pay => Icons.storefront_outlined,
      TransactionType.withdraw => Icons.account_balance_wallet_outlined,
      TransactionType.topup => Icons.arrow_downward,
    };

    return _ActivityRow(
      icon: icon,
      title: tx.isReversed ? '$title (reversed)' : title,
      amount:
          '$amountPrefix${tx.currency} ${NumberFormat('#,##0.00').format(tx.amount)}',
      date: DateFormat('MMM d, h:mm a').format(tx.timestamp),
    );
  }

  final IconData icon;
  final String title;
  final String amount;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[100],
            child: Icon(icon, color: Colors.black54, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(date,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(amount,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: amount.startsWith('+') ? Colors.green : Colors.black)),
        ],
      ),
    );
  }
}

class _WaveTransferSheet extends StatefulWidget {
  const _WaveTransferSheet({
    required this.money,
    required this.currencySymbol,
    required this.recipientName,
    required this.recipientCountry,
    required this.fxRate,
    required this.currency,
    required this.onComplete,
  });

  final NumberFormat money;
  final String currencySymbol;
  final String recipientName;
  final String recipientCountry;
  final double fxRate;
  final String currency;
  final Function(double, String) onComplete;

  @override
  State<_WaveTransferSheet> createState() => _WaveTransferSheetState();
}

class _WaveTransferSheetState extends State<_WaveTransferSheet> {
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  double _sendAmount = 0;
  bool _isVerifyingPin = false;

  @override
  void dispose() {
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerifyingPin) {
      return _buildPinStep();
    }

    final fee = (_sendAmount * 0.01).clamp(0.0, 50.0);
    final recipientGets = (_sendAmount - fee) * widget.fxRate;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.recipientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(widget.recipientCountry,
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              const Spacer(),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Amount to send',
              style: TextStyle(fontWeight: FontWeight.w500)),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '${widget.currencySymbol} ',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
            ),
            onChanged: (val) {
              setState(() {
                _sendAmount = double.tryParse(val) ?? 0;
              });
            },
          ),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fee (1%)', style: TextStyle(color: Colors.grey[600])),
              Text(widget.money.format(fee)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${widget.recipientName} receives',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${recipientGets.toStringAsFixed(2)} ${widget.currency}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _sendAmount > 0
                  ? () {
                      setState(() => _isVerifyingPin = true);
                    }
                  : null,
              child: const Text('Next',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinStep() {
    final authService = context.read<AuthService>();
    final fee = (_sendAmount * 0.01).clamp(0.0, 50.0);
    final recipientGets = (_sendAmount - fee) * widget.fxRate;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _isVerifyingPin = false)),
              const Text('Enter PIN',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Confirm your transaction with your 4-digit PIN'),
          const SizedBox(height: 24),
          Pinput(
            length: 4,
            obscureText: true,
            controller: _pinController,
            onCompleted: (pin) async {
              if (authService.verifyPin(pin)) {
                try {
                  await authService.updateBalance(
                      -recipientGets / widget.fxRate); // Debit sender
                  if (!mounted) return;
                  Navigator.pop(context);
                  widget.onComplete(recipientGets, widget.currency);
                  authService.logTransaction(TransactionType.send,
                      recipientGets / widget.fxRate, widget.recipientName);
                  _showSuccessDialog(context, widget.recipientName,
                      recipientGets, widget.currency);
                } catch (e) {
                  _pinController.clear();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red));
                  // Also add a notification for the failure
                  final homeState =
                      context.findAncestorStateOfType<_HomeScreenState>();
                  if (homeState != null) {
                    homeState._addNotification(
                        'Transaction Failed', e.toString());
                  }
                  Navigator.pop(context);
                }
              } else {
                _pinController.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Invalid PIN. Transaction failed.'),
                    backgroundColor: Colors.red));
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showSuccessDialog(
      BuildContext context, String name, double amount, String currency) {
    showDialog(
      context: context,
      builder: (context) => _SuccessDialog(
        message:
            'You have successfully sent ${widget.money.format(amount).replaceAll(widget.currencySymbol, '').trim()} $currency to $name.',
      ),
    );
  }
}

class _SecureSendToUserFlow extends StatefulWidget {
  const _SecureSendToUserFlow(
      {required this.money,
      required this.currencySymbol,
      required this.onComplete,
      required this.onReversalRequest});
  final NumberFormat money;
  final String currencySymbol;
  final Function(String, String, String) onComplete;
  final VoidCallback onReversalRequest;

  @override
  State<_SecureSendToUserFlow> createState() => _SecureSendToUserFlowState();
}

class _SecureSendToUserFlowState extends State<_SecureSendToUserFlow> {
  int _step = 1;
  String? _selectedRegion;
  String? _selectedCountry;
  String? _selectedCurrency;
  double? _exchangeRate;
  double _amount = 0;
  final _amountController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _destAccountController = TextEditingController();
  final _pinController = TextEditingController();

  static const List<Map<String, String>> _verifiedRecipients = [
    {
      'country': 'Canada',
      'account': '6765566556656765',
      'name': 'Grace Morgan',
    },
    {
      'country': 'Germany',
      'account': '8812345678',
      'name': 'Anna Keller',
    },
    {
      'country': 'Nigeria',
      'account': '8823456789',
      'name': 'John Doe',
    },
    {
      'country': 'Mexico',
      'account': '8834567890',
      'name': 'Maria Garcia',
    },
  ];

  static const Map<String, String> _countryToIsoCode = {
    'Nigeria': 'NG',
    'Kenya': 'KE',
    'Ghana': 'GH',
    'South Africa': 'ZA',
    'Egypt': 'EG',
    'Senegal': 'SN',
    'Tanzania': 'TZ',
    'Uganda': 'UG',
    'USA': 'US',
    'Canada': 'CA',
    'Mexico': 'MX',
    'Jamaica': 'JM',
  };

  String _flagEmojiForCountry(String countryName) {
    final iso = _countryToIsoCode[countryName];
    if (iso == null || iso.length != 2) return '';

    const flagBase = 0x1F1E6;
    final codeUnits = iso.toUpperCase().codeUnits;
    if (codeUnits.any((c) => c < 0x41 || c > 0x5A)) return '';

    return String.fromCharCodes(
      codeUnits.map((c) => flagBase + (c - 0x41)),
    );
  }

  String _flagPrefix(String? countryName) {
    if (countryName == null) return '';
    final flag = _flagEmojiForCountry(countryName);
    return flag.isEmpty ? '' : '$flag ';
  }

  final Map<String, List<Map<String, dynamic>>> _regionalCountries = {
    'Africa': [
      {'name': 'Nigeria', 'currency': 'NGN', 'rate': 1475.00},
      {'name': 'Kenya', 'currency': 'KES', 'rate': 131.50},
      {'name': 'Ghana', 'currency': 'GHS', 'rate': 12.80},
      {'name': 'South Africa', 'currency': 'ZAR', 'rate': 18.90},
      {'name': 'Egypt', 'currency': 'EGP', 'rate': 47.30},
      {'name': 'Senegal', 'currency': 'XOF', 'rate': 605.00},
      {'name': 'Tanzania', 'currency': 'TZS', 'rate': 2550.00},
      {'name': 'Uganda', 'currency': 'UGX', 'rate': 3880.00},
    ],
    'North America': [
      {'name': 'USA', 'currency': 'USD', 'rate': 1.00},
      {'name': 'Canada', 'currency': 'CAD', 'rate': 1.36},
      {'name': 'Mexico', 'currency': 'MXN', 'rate': 16.70},
      {'name': 'Jamaica', 'currency': 'JMD', 'rate': 155.00},
    ],
  };

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateAmount);
    _recipientNameController.addListener(_refreshButtonState);
    _destAccountController.addListener(_refreshButtonState);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateAmount);
    _recipientNameController.removeListener(_refreshButtonState);
    _destAccountController.removeListener(_refreshButtonState);
    _amountController.dispose();
    _recipientNameController.dispose();
    _destAccountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _updateAmount() {
    final normalized = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final parsed = double.tryParse(normalized) ?? 0;
    if (parsed == _amount) return;
    setState(() => _amount = parsed);
  }

  void _refreshButtonState() {
    if (mounted) setState(() {});
  }

  Map<String, String>? get _verifiedRecipient {
    final account = _destAccountController.text.trim().replaceAll(' ', '');
    if (account.isEmpty || _selectedCountry == null) return null;

    for (final recipient in _verifiedRecipients) {
      if (recipient['country'] == _selectedCountry &&
          recipient['account'] == account) {
        return recipient;
      }
    }
    return null;
  }

  bool get _recipientNameMatches {
    final account = _destAccountController.text.trim();
    final name = _recipientNameController.text.trim();
    if (account.isEmpty || name.isEmpty) return false;

    final verified = _verifiedRecipient;
    if (verified == null) return true;
    return verified['name']!.toLowerCase() == name.toLowerCase();
  }

  double get _sendFee => _amount * 0.01;
  double get _totalDebit => _amount + _sendFee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_step == 1) _buildCountryStep(),
          if (_step == 2) _buildAmountStep(),
          if (_step == 3) _buildReviewStep(),
          if (_step == 4) _buildPinStep(),
          const SizedBox(height: 24),
          _buildButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = 'Send Money';
    if (_step == 1) title = 'Select Destination';
    if (_step == 2) title = 'Enter Amount';
    if (_step == 3) title = 'Confirm Send';
    if (_step == 4) title = 'Enter PIN';

    return Row(
      children: [
        if (_step > 1)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _step--),
          ),
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildCountryStep() {
    return Column(
      children: [
        _buildRegionDropdown('Africa'),
        const SizedBox(height: 16),
        _buildRegionDropdown('North America'),
        if (_selectedCountry != null) ...[
          const SizedBox(height: 24),
          _Panel(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Selected', style: TextStyle(color: Colors.grey[600])),
                    Text(
                      '${_flagPrefix(_selectedCountry)}$_selectedCountry ($_selectedCurrency)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Exchange Rate',
                        style: TextStyle(color: Colors.grey[600])),
                    Text('1 USD = $_exchangeRate $_selectedCurrency',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildRegionDropdown(String region) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: region,
        prefixIcon: Icon(region == 'Africa' ? Icons.public : Icons.map),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      initialValue: _selectedRegion == region ? _selectedCountry : null,
      items: _regionalCountries[region]!.map((c) {
        final rate = c['rate'];
        final currency = c['currency'];
        final name = c['name'] as String;
        return DropdownMenuItem<String>(
          value: name,
          child: Text('${_flagPrefix(name)}$name (1 USD = $rate $currency)'),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          final countryData =
              _regionalCountries[region]!.firstWhere((c) => c['name'] == val);
          setState(() {
            _selectedRegion = region;
            _selectedCountry = val;
            _selectedCurrency = countryData['currency'] as String;
            _exchangeRate = countryData['rate'] as double;
          });
        }
      },
    );
  }

  Widget _buildAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sending to ${_flagPrefix(_selectedCountry)}$_selectedCountry',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _destAccountController,
          decoration: const InputDecoration(
            labelText: 'Receiver Account Number',
            hintText: 'e.g. 8812345678',
            prefixIcon: Icon(Icons.account_circle_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _recipientNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Receiver Full Name',
            hintText: 'Name on the receiver account',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 8),
        _buildAccountVerificationNotice(),
        const SizedBox(height: 16),
        const Text('Amount to send',
            style: TextStyle(fontWeight: FontWeight.w500)),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '${widget.currencySymbol} ',
            border: InputBorder.none,
            fillColor: Colors.transparent,
          ),
        ),
        if (_selectedCurrency != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'You are sending from your ${widget.currencySymbol} wallet. Recipient country currency: $_selectedCurrency.',
              style: const TextStyle(color: _appTextMuted, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final authService = context.watch<AuthService>();
    final remainingBalance = authService.balance - _totalDebit;

    return Column(
      children: [
        _QuoteRow('Receiver', _recipientNameController.text.trim()),
        _QuoteRow('Destination',
            '${_flagPrefix(_selectedCountry)}${_selectedCountry!}'),
        _QuoteRow('To Account', _destAccountController.text),
        _QuoteRow('Sent amount', widget.money.format(_amount)),
        _QuoteRow('Transfer charge', widget.money.format(_sendFee)),
        _QuoteRow('Total deducted', widget.money.format(_totalDebit)),
        _QuoteRow('Balance after', widget.money.format(remainingBalance)),
        _QuoteRow('Method', 'App-to-App Transfer'),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.shield, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Text('Securely encrypted by INTERFLEX',
                style: TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildButton() {
    if (_step == 1) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedCountry == null
                  ? null
                  : () => setState(() => _step = 2),
              child: const Text('Continue to Details'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: widget.onReversalRequest,
            icon: const Icon(Icons.history_outlined, size: 16),
            label: const Text('Reverse a wrong transaction'),
          ),
        ],
      );
    }
    if (_step == 4) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: !_canContinueCurrentStep()
            ? null
            : () {
                if (_step < 3) {
                  setState(() => _step++);
                } else {
                  setState(() => _step = 4);
                }
              },
        child: Text(_step == 3 ? 'Confirm & Authenticate' : 'Next'),
      ),
    );
  }

  bool _canContinueCurrentStep() {
    if (_step == 2) {
      return _amount > 0 && _recipientNameMatches;
    }
    if (_step == 3) return _amount > 0 && _recipientNameMatches;
    return true;
  }

  Widget _buildAccountVerificationNotice() {
    final account = _destAccountController.text.trim();
    final name = _recipientNameController.text.trim();
    if (account.isEmpty || name.isEmpty) {
      return const SizedBox.shrink();
    }

    final verified = _verifiedRecipient;
    if (verified == null) {
      return const Text(
        'Receiver details accepted.',
        style: TextStyle(
          color: _appPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    if (!_recipientNameMatches) {
      return const Text(
        'Account found. Receiver name must match the account holder.',
        style: TextStyle(color: _appAmber, fontSize: 12),
      );
    }

    return Text(
      'Verified: ${verified['name']}',
      style: const TextStyle(
        color: _appPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildPinStep() {
    final authService = context.read<AuthService>();
    return Column(
      children: [
        const Text('Confirm your transfer with your 4-digit PIN'),
        const SizedBox(height: 24),
        Pinput(
          length: 4,
          obscureText: true,
          controller: _pinController,
          onCompleted: (pin) async {
            if (authService.verifyPin(pin)) {
              try {
                final balanceAfter = authService.balance - _totalDebit;
                await authService.updateBalance(-_totalDebit);
                if (!mounted) return;
                authService.logTransaction(
                    TransactionType.send,
                    _totalDebit,
                    '${_recipientNameController.text.trim()} - ${_destAccountController.text.trim()}');
                _handleSuccess(balanceAfter);
              } catch (e) {
                _pinController.clear();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString()), backgroundColor: Colors.red));
                // Add notification to _HomeScreenState
                final homeState =
                    context.findAncestorStateOfType<_HomeScreenState>();
                if (homeState != null) {
                  homeState._addNotification(
                      'Transaction Failed', e.toString());
                }
                Navigator.pop(context);
              }
            } else {
              _pinController.clear();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Invalid PIN. Transaction failed.'),
                  backgroundColor: Colors.red));
              Navigator.pop(context);
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _handleSuccess(double balanceAfter) {
    if (!mounted) return;
    final recipientName = _recipientNameController.text.trim();
    final account = _destAccountController.text.trim();
    Navigator.pop(context);
    widget.onComplete(widget.money.format(_amount), _selectedCountry!,
        account);
    showDialog(
      context: context,
      builder: (context) => _SuccessDialog(
        message: 'Sent ${widget.money.format(_amount)} to $recipientName.\n'
            'Account: $account\n'
            'Charge: ${widget.money.format(_sendFee)}\n'
            'Total deducted: ${widget.money.format(_totalDebit)}\n'
            'Balance left: ${widget.money.format(balanceAfter)}',
      ),
    );
  }
}

class _SecureWithdrawFlow extends StatefulWidget {
  const _SecureWithdrawFlow(
      {required this.money,
      required this.currencySymbol,
      required this.onComplete,
      required this.onReversalRequest});
  final NumberFormat money;
  final String currencySymbol;
  final Function(String, String) onComplete;
  final VoidCallback onReversalRequest;

  @override
  State<_SecureWithdrawFlow> createState() => _SecureWithdrawFlowState();
}

class _SecureWithdrawFlowState extends State<_SecureWithdrawFlow> {
  int _step = 1;
  String? _selectedMethod;
  double _amount = 0;
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_step == 1) _buildMethodStep(),
          if (_step == 2) _buildDetailsStep(),
          if (_step == 3) _buildReviewStep(),
          if (_step == 4) _buildPinStep(),
          const SizedBox(height: 24),
          _buildButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = 'Withdraw';
    if (_step == 1) title = 'Select Payout Method';
    if (_step == 2) title = 'Enter Details';
    if (_step == 3) title = 'Confirm Withdrawal';
    if (_step == 4) title = 'Enter PIN';

    return Row(
      children: [
        if (_step > 1)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _step--),
          ),
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildMethodStep() {
    final methods = [
      {'name': 'Bank Account', 'icon': Icons.account_balance},
      {'name': 'Mobile Money', 'icon': Icons.phone_android},
      {'name': 'Debit Card', 'icon': Icons.credit_card},
    ];
    return Column(
      children: methods
          .map((m) => ListTile(
                leading: Icon(m['icon'] as IconData),
                title: Text(m['name'] as String),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() {
                    _selectedMethod = m['name'] as String;
                    _step = 2;
                  });
                },
              ))
          .toList(),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Withdraw to $_selectedMethod',
            style: TextStyle(color: Colors.grey[600])),
        TextField(
          controller: _detailsController,
          decoration: InputDecoration(
            hintText: _selectedMethod == 'Bank Account'
                ? 'Account Number'
                : 'Phone Number',
          ),
        ),
        const SizedBox(height: 16),
        const Text('Amount to withdraw',
            style: TextStyle(fontWeight: FontWeight.w500)),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '${widget.currencySymbol} ',
            border: InputBorder.none,
            fillColor: Colors.transparent,
          ),
          onChanged: (val) =>
              setState(() => _amount = double.tryParse(val) ?? 0),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        _QuoteRow('Method', _selectedMethod!),
        _QuoteRow('Details', _detailsController.text),
        _QuoteRow('Amount', widget.money.format(_amount)),
        _QuoteRow('Fee', '${widget.currencySymbol}0.00'),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.lock, color: Colors.blue, size: 16),
            SizedBox(width: 8),
            Text('Protected by multi-factor authentication',
                style: TextStyle(color: Colors.blue, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildButton() {
    if (_step == 1) {
      return Column(
        children: [
          const SizedBox.shrink(),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: widget.onReversalRequest,
            icon: const Icon(Icons.history_outlined, size: 16),
            label: const Text('Reverse a wrong withdrawal'),
          ),
        ],
      );
    }
    if (_step == 4) return const SizedBox.shrink();
    bool canProceed = _amount > 0;
    if (_step == 2) {
      canProceed = _amount > 0 && _detailsController.text.isNotEmpty;
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: !canProceed
            ? null
            : () {
                if (_step < 3) {
                  setState(() => _step++);
                } else {
                  setState(() => _step = 4);
                }
              },
        child: Text(_step == 3 ? 'Confirm & Withdraw' : 'Next'),
      ),
    );
  }

  Widget _buildPinStep() {
    final authService = context.read<AuthService>();
    return Column(
      children: [
        const Text('Confirm your withdrawal with your 4-digit PIN'),
        const SizedBox(height: 24),
        Pinput(
          length: 4,
          obscureText: true,
          controller: _pinController,
          onCompleted: (pin) async {
            if (authService.verifyPin(pin)) {
              try {
                await authService.updateBalance(-_amount);
                if (!mounted) return;
                authService.logTransaction(
                    TransactionType.withdraw, _amount, _selectedMethod!);
                _handleSuccess();
              } catch (e) {
                _pinController.clear();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString()), backgroundColor: Colors.red));
                // Add notification to _HomeScreenState
                final homeState =
                    context.findAncestorStateOfType<_HomeScreenState>();
                if (homeState != null) {
                  homeState._addNotification(
                      'Transaction Failed', e.toString());
                }
                Navigator.pop(context);
              }
            } else {
              _pinController.clear();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Invalid PIN. Transaction failed.'),
                  backgroundColor: Colors.red));
              Navigator.pop(context);
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _handleSuccess() {
    if (!mounted) return;
    Navigator.pop(context);
    widget.onComplete(widget.money.format(_amount), _selectedMethod!);
    showDialog(
      context: context,
      builder: (context) => _SuccessDialog(
        message:
            'Withdrawal of ${widget.money.format(_amount)} to $_selectedMethod successful.',
      ),
    );
  }
}

class _SecureScanToPayFlow extends StatefulWidget {
  const _SecureScanToPayFlow(
      {required this.money,
      required this.currencySymbol,
      required this.onComplete,
      required this.onReversalRequest});
  final NumberFormat money;
  final String currencySymbol;
  final Function(String, String) onComplete;
  final VoidCallback onReversalRequest;

  @override
  State<_SecureScanToPayFlow> createState() => _SecureScanToPayFlowState();
}

class _SecureScanToPayFlowState extends State<_SecureScanToPayFlow> {
  int _step = 1; // 1: Select Method/Scan, 2: Amount, 3: Confirm, 4: PIN
  String _merchantCode = '';
  double _amount = 0;
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();

  MobileScannerController cameraController = MobileScannerController();
  bool _isCameraActive = false;

  @override
  void dispose() {
    cameraController.dispose();
    _codeController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;
      // Stop scanning once detected to confirm it worked
      cameraController.stop();
      setState(() {
        _merchantCode = code;
        _codeController.text = _merchantCode;
        _isCameraActive = false;
        _step = 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_step == 1) _buildMerchantStep(),
          if (_step == 2) _buildAmountStep(),
          if (_step == 3) _buildReviewStep(),
          if (_step == 4) _buildPinStep(),
          const SizedBox(height: 24),
          _buildButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = 'Scan to Pay';
    if (_step == 2) title = 'Enter Amount';
    if (_step == 3) title = 'Confirm Payment';
    if (_step == 4) title = 'Enter PIN';

    return Row(
      children: [
        if (_step > 1 || _isCameraActive)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_isCameraActive) {
                setState(() => _isCameraActive = false);
              } else {
                setState(() => _step--);
              }
            },
          ),
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildMerchantStep() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _isCameraActive = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Accessing Camera...'),
                  duration: Duration(seconds: 1)),
            );
          },
          child: Container(
            height: 200,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            child: _isCameraActive
                ? Stack(
                    children: [
                      MobileScanner(
                        controller: cameraController,
                        onDetect: _onDetect,
                        errorBuilder: (context, error, child) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 48),
                                const SizedBox(height: 8),
                                Text('Camera error: ${error.errorCode}',
                                    style:
                                        const TextStyle(color: Colors.white)),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _isCameraActive = false),
                                  child: const Text('Retry'),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 8),
                              SizedBox(width: 4),
                              Text('Active',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(128)),
                      const SizedBox(height: 12),
                      const Text('Tap to activate scanner',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.grey))),
              Expanded(child: Divider()),
            ],
          ),
        ),
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Enter Merchant Code',
            hintText: 'e.g. 123456',
            prefixIcon: Icon(Icons.numbers),
          ),
          keyboardType: TextInputType.number,
          onChanged: (val) => setState(() => _merchantCode = val),
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paying Merchant: #$_merchantCode',
            style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 16),
        const Text('Amount to pay',
            style: TextStyle(fontWeight: FontWeight.w500)),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '${widget.currencySymbol} ',
            border: InputBorder.none,
            fillColor: Colors.transparent,
          ),
          onChanged: (val) =>
              setState(() => _amount = double.tryParse(val) ?? 0),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        _QuoteRow('Merchant ID', '#$_merchantCode'),
        _QuoteRow('Amount', widget.money.format(_amount)),
        _QuoteRow('Fee', '${widget.currencySymbol}0.00'),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.verified_user, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Text('Authorized Merchant Payment',
                style: TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildButton() {
    bool canProceed = false;
    if (_step == 1) canProceed = _merchantCode.length >= 4;
    if (_step == 2) canProceed = _amount > 0;
    if (_step == 3) canProceed = true;
    if (_step == 4) return const SizedBox.shrink();

    if (_step == 1) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: !canProceed ? null : () => setState(() => _step = 2),
              child: const Text('Next'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: widget.onReversalRequest,
            icon: const Icon(Icons.history_outlined, size: 16),
            label: const Text('Reverse a wrong payment'),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: !canProceed
            ? null
            : () {
                if (_step < 3) {
                  setState(() => _step++);
                } else {
                  setState(() => _step = 4);
                }
              },
        child: Text(_step == 3 ? 'Confirm & Pay' : 'Next'),
      ),
    );
  }

  Widget _buildPinStep() {
    final authService = context.read<AuthService>();
    return Column(
      children: [
        const Text('Confirm your merchant payment with your 4-digit PIN'),
        const SizedBox(height: 24),
        Pinput(
          length: 4,
          obscureText: true,
          controller: _pinController,
          onCompleted: (pin) async {
            if (authService.verifyPin(pin)) {
              try {
                await authService.updateBalance(-_amount);
                if (!mounted) return;
                authService.logTransaction(
                    TransactionType.pay, _amount, _merchantCode);
                _handleSuccess();
              } catch (e) {
                _pinController.clear();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString()), backgroundColor: Colors.red));
                // Add notification to _HomeScreenState
                final homeState =
                    context.findAncestorStateOfType<_HomeScreenState>();
                if (homeState != null) {
                  homeState._addNotification(
                      'Transaction Failed', e.toString());
                }
                Navigator.pop(context);
              }
            } else {
              _pinController.clear();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Invalid PIN. Transaction failed.'),
                  backgroundColor: Colors.red));
              Navigator.pop(context);
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _handleSuccess() {
    if (!mounted) return;
    Navigator.pop(context);
    widget.onComplete(widget.money.format(_amount), _merchantCode);
    showDialog(
      context: context,
      builder: (context) => _SuccessDialog(
        message:
            'You have successfully paid ${widget.money.format(_amount)} to merchant #$_merchantCode.',
      ),
    );
  }
}

class _SecureReversalFlow extends StatefulWidget {
  final TransactionType type;
  final String currencySymbol;
  final Function(String, String) onComplete;

  const _SecureReversalFlow({
    required this.type,
    required this.currencySymbol,
    required this.onComplete,
  });

  @override
  State<_SecureReversalFlow> createState() => _SecureReversalFlowState();
}

class _SecureReversalFlowState extends State<_SecureReversalFlow> {
  int _step = 1; // 1: Input ID, 2: PIN
  final _idController = TextEditingController();
  final _pinController = TextEditingController();
  TransactionRecord? _foundTransaction;

  @override
  void dispose() {
    _idController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_step == 1) _buildIdStep(),
          if (_step == 2) _buildPinStep(),
          const SizedBox(height: 24),
          if (_step == 1) _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = 'Request Reversal';
    if (_step == 2) title = 'Authorize Reversal';

    return Row(
      children: [
        if (_step > 1)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _step = 1),
          ),
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildIdStep() {
    String label = 'Destination Account Number';
    if (widget.type == TransactionType.pay) label = 'Merchant Code';
    if (widget.type == TransactionType.withdraw) label = 'Account/Phone Number';

    return Column(
      children: [
        const Text(
            'To reverse, please provide the details of the transaction you made by mistake.'),
        const SizedBox(height: 16),
        TextField(
          controller: _idController,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.search),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        const Text(
            'Note: Reversals are only possible within 5 minutes of transaction.',
            style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPinStep() {
    final authService = context.read<AuthService>();
    return Column(
      children: [
        Text(
            'Reversing ${widget.currencySymbol} ${_foundTransaction!.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text('Destination: ${_foundTransaction!.destination}'),
        const SizedBox(height: 24),
        const Text('Enter your 4-digit PIN to confirm reversal'),
        const SizedBox(height: 16),
        Pinput(
          length: 4,
          obscureText: true,
          controller: _pinController,
          onCompleted: (pin) async {
            if (authService.verifyPin(pin)) {
              await authService.reverseTransaction(_foundTransaction!);
              if (!mounted) return;
              Navigator.pop(context);
              widget.onComplete('Reversal Successful',
                  'USh ${(_foundTransaction!.amount).toStringAsFixed(2)} has been refunded to your wallet.');
              _showReversalSuccessDialog();
            } else {
              _pinController.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Invalid PIN. Reversal failed.'),
                    backgroundColor: Colors.red),
              );
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _findAndValidateTransaction,
        child: const Text('Find Transaction'),
      ),
    );
  }

  void _findAndValidateTransaction() {
    final authService = context.read<AuthService>();
    final destination = _idController.text.trim();

    try {
      // Find the most recent transaction matching destination and type
      final tx = authService.recentTransactions.firstWhere(
        (t) =>
            t.destination == destination &&
            t.type == widget.type &&
            !t.isReversed,
      );

      if (authService.canReverse(tx)) {
        setState(() {
          _foundTransaction = tx;
          _step = 2;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Reversal expired (over 5 mins) or already reversed.'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No matching transaction found.'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showReversalSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => const _SuccessDialog(
        message:
            'The transaction has been reversed. Your balance has been updated.',
      ),
    );
  }
}

class _SecureTopupFlow extends StatefulWidget {
  const _SecureTopupFlow(
      {required this.money,
      required this.currencySymbol,
      required this.onComplete});
  final NumberFormat money;
  final String currencySymbol;
  final Function(String, String) onComplete;

  @override
  State<_SecureTopupFlow> createState() => _SecureTopupFlowState();
}

class _SecureTopupFlowState extends State<_SecureTopupFlow> {
  int _step = 1; // 1: Card Details, 2: Amount, 3: Confirm/PIN
  String _cardNumber = '';
  double _amount = 0;
  final _cardController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _cardController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_step == 1) _buildCardStep(),
          if (_step == 2) _buildAmountStep(),
          if (_step == 3) _buildReviewStep(),
          if (_step == 4) _buildPinStep(),
          const SizedBox(height: 24),
          _buildButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = 'Bank Topup';
    if (_step == 2) title = 'Enter Amount';
    if (_step == 3) title = 'Review Topup';
    if (_step == 4) title = 'Bank PIN';

    return Row(
      children: [
        if (_step > 1)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _step--),
          ),
        Text(title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildCardStep() {
    return Column(
      children: [
        const Text('Enter your bank card details to draw funds.'),
        const SizedBox(height: 16),
        TextField(
          controller: _cardController,
          maxLength: 16,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Bank Card Number',
            hintText: 'XXXX XXXX XXXX XXXX',
            prefixIcon: Icon(Icons.credit_card),
            counterText: '', // Hide the standard counter for a cleaner look
          ),
          keyboardType: TextInputType.number,
          onChanged: (val) => setState(() => _cardNumber = val),
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Topping up from card: ${_cardNumber.length > 4 ? _cardNumber.substring(_cardNumber.length - 4) : _cardNumber}',
            style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 16),
        const Text('Amount to draw',
            style: TextStyle(fontWeight: FontWeight.w500)),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '${widget.currencySymbol} ',
            border: InputBorder.none,
            fillColor: Colors.transparent,
          ),
          onChanged: (val) =>
              setState(() => _amount = double.tryParse(val) ?? 0),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      children: [
        _QuoteRow('From Card', _cardNumber),
        _QuoteRow('Amount', widget.money.format(_amount)),
        _QuoteRow('Fee', '${widget.currencySymbol}0.00'),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.lock, color: Colors.blue, size: 16),
            SizedBox(width: 8),
            Text('Bank-grade encryption active',
                style: TextStyle(color: Colors.blue, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildPinStep() {
    return Column(
      children: [
        const Text('Enter your BANK ACCOUNT PIN to authorize'),
        const SizedBox(height: 24),
        Pinput(
          length: 4,
          obscureText: true,
          controller: _pinController,
          onCompleted: (pin) {
            // Simulate bank authorization (PIN 1111 for demo or just accept any for simulation)
            _handleSuccess();
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildButton() {
    bool canProceed = false;
    if (_step == 1) canProceed = _cardNumber.length == 16;
    if (_step == 2) canProceed = _amount > 0;
    if (_step == 3) canProceed = true;
    if (_step == 4) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: !canProceed
            ? null
            : () {
                if (_step < 4) {
                  setState(() => _step++);
                }
              },
        child: Text(_step == 3 ? 'Confirm & Go to PIN' : 'Next'),
      ),
    );
  }

  void _handleSuccess() {
    Navigator.pop(context);
    widget.onComplete(widget.money.format(_amount), _cardNumber);
  }
}

class _FailureDialog extends StatelessWidget {
  const _FailureDialog({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cancel, color: Colors.red, size: 80),
          const SizedBox(height: 16),
          const Text('Failed!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context),
              child: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 16),
          const Text('Success!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MandatoryChangePinSheet extends StatefulWidget {
  final bool isMandatory;
  final Function(String, String) onComplete;
  const _MandatoryChangePinSheet(
      {required this.onComplete, this.isMandatory = true});

  @override
  State<_MandatoryChangePinSheet> createState() =>
      _MandatoryChangePinSheetState();
}

class _MandatoryChangePinSheetState extends State<_MandatoryChangePinSheet> {
  int _step = 1; // 1: Old PIN, 2: New PIN, 3: Confirm PIN
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String _newPin = '';

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_step == 1) _buildOldPinStep(),
          if (_step == 2) _buildNewPinStep(),
          if (_step == 3) _buildConfirmPinStep(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = 'Change Transaction PIN';
    if (widget.isMandatory && _step == 1) title = 'Set Up Security PIN';

    return Row(
      children: [
        if (_step > 1)
          IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _step--)),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (!widget.isMandatory)
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildOldPinStep() {
    final authService = context.read<AuthService>();
    return Column(
      children: [
        const Text('Enter your current 4-digit PIN'),
        const SizedBox(height: 16),
        Pinput(
          length: 4,
          obscureText: true,
          controller: _oldPinController,
          onCompleted: (pin) {
            if (authService.verifyPin(pin)) {
              setState(() => _step = 2);
            } else {
              _oldPinController.clear();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Incorrect current PIN'),
                  backgroundColor: Colors.red));
            }
          },
        ),
        if (widget.isMandatory) ...[
          const SizedBox(height: 12),
          const Text('Default PIN is 0000',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]
      ],
    );
  }

  Widget _buildNewPinStep() {
    return Column(
      children: [
        const Text('Enter your new 4-digit PIN'),
        const SizedBox(height: 16),
        Pinput(
          length: 4,
          obscureText: true,
          controller: _newPinController,
          onCompleted: (pin) {
            _newPin = pin;
            setState(() => _step = 3);
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPinStep() {
    return Column(
      children: [
        const Text('Confirm your new 4-digit PIN'),
        const SizedBox(height: 16),
        Pinput(
          length: 4,
          obscureText: true,
          controller: _confirmPinController,
          onCompleted: (pin) async {
            if (pin == _newPin) {
              final authService = context.read<AuthService>();

              await authService.changePin(pin);
              widget.onComplete('Security Update',
                  'Your transaction PIN has been successfully updated.');

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('PIN updated successfully'),
                    backgroundColor: Colors.green));
              }
            } else {
              _confirmPinController.clear();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('PINs do not match'),
                  backgroundColor: Colors.red));
            }
          },
        ),
      ],
    );
  }
}
