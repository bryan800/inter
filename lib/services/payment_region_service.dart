import '../models/payment_models.dart';

class PaymentRegionService {
  static const countries = [
    PaymentCountry(
      name: 'United States',
      isoCode: 'US',
      dialCode: '+1',
      currencyCode: 'USD',
      supportsMobileMoney: false,
    ),
    PaymentCountry(
      name: 'Canada',
      isoCode: 'CA',
      dialCode: '+1',
      currencyCode: 'CAD',
      supportsMobileMoney: false,
    ),
    PaymentCountry(
      name: 'Mexico',
      isoCode: 'MX',
      dialCode: '+52',
      currencyCode: 'MXN',
      supportsMobileMoney: false,
    ),
    PaymentCountry(
      name: 'Uganda',
      isoCode: 'UG',
      dialCode: '+256',
      currencyCode: 'UGX',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Kenya',
      isoCode: 'KE',
      dialCode: '+254',
      currencyCode: 'KES',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Nigeria',
      isoCode: 'NG',
      dialCode: '+234',
      currencyCode: 'NGN',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Ghana',
      isoCode: 'GH',
      dialCode: '+233',
      currencyCode: 'GHS',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'South Africa',
      isoCode: 'ZA',
      dialCode: '+27',
      currencyCode: 'ZAR',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Tanzania',
      isoCode: 'TZ',
      dialCode: '+255',
      currencyCode: 'TZS',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Rwanda',
      isoCode: 'RW',
      dialCode: '+250',
      currencyCode: 'RWF',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Algeria',
      isoCode: 'DZ',
      dialCode: '+213',
      currencyCode: 'USD',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Angola',
      isoCode: 'AO',
      dialCode: '+244',
      currencyCode: 'USD',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Benin',
      isoCode: 'BJ',
      dialCode: '+229',
      currencyCode: 'USD',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Botswana',
      isoCode: 'BW',
      dialCode: '+267',
      currencyCode: 'USD',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Cameroon',
      isoCode: 'CM',
      dialCode: '+237',
      currencyCode: 'USD',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Egypt',
      isoCode: 'EG',
      dialCode: '+20',
      currencyCode: 'USD',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Ethiopia',
      isoCode: 'ET',
      dialCode: '+251',
      currencyCode: 'USD',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Morocco',
      isoCode: 'MA',
      dialCode: '+212',
      currencyCode: 'USD',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Senegal',
      isoCode: 'SN',
      dialCode: '+221',
      currencyCode: 'USD',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Zambia',
      isoCode: 'ZM',
      dialCode: '+260',
      currencyCode: 'USD',
      supportsMobileMoney: true,
    ),
    PaymentCountry(
      name: 'Zimbabwe',
      isoCode: 'ZW',
      dialCode: '+263',
      currencyCode: 'USD',
      supportsMobileMoney: true,
    ),
  ];

  static List<PaymentMethodOption> methodsFor(PaymentCountry country) {
    return [
      const PaymentMethodOption(
        type: PaymentMethodType.card,
        label: 'Card',
        description: 'Visa or Mastercard',
        flutterwaveOption: 'card',
      ),
      if (country.supportsMobileMoney)
        const PaymentMethodOption(
          type: PaymentMethodType.mobileMoney,
          label: 'Mobile Money',
          description: 'MTN MoMo, Airtel Money, or M-Pesa where available',
          flutterwaveOption: 'mobilemoney',
        ),
      const PaymentMethodOption(
        type: PaymentMethodType.bankTransfer,
        label: 'Bank transfer',
        description: 'Supported local and international bank rails',
        flutterwaveOption: 'bank transfer',
      ),
    ];
  }

  static bool isAfricanCountry(PaymentCountry country) {
    return !['US', 'CA', 'MX'].contains(country.isoCode);
  }
}
