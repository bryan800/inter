enum PaymentMethodType {
  card,
  mobileMoney,
  bankTransfer,
}

class PaymentItem {
  const PaymentItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;
}

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.type,
    required this.label,
    required this.description,
    required this.flutterwaveOption,
  });

  final PaymentMethodType type;
  final String label;
  final String description;
  final String flutterwaveOption;
}

class PaymentCountry {
  const PaymentCountry({
    required this.name,
    required this.isoCode,
    required this.dialCode,
    required this.currencyCode,
    required this.supportsMobileMoney,
  });

  final String name;
  final String isoCode;
  final String dialCode;
  final String currencyCode;
  final bool supportsMobileMoney;
}

class PaymentReceipt {
  const PaymentReceipt({
    required this.transactionId,
    required this.amount,
    required this.currencyCode,
    required this.country,
    required this.date,
  });

  final String transactionId;
  final double amount;
  final String currencyCode;
  final String country;
  final DateTime date;
}
