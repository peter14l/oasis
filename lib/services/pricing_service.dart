import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

enum Currency { usd, inr, eur, gbp }

class PricingPlan {
  final String name;
  final double price;
  final String symbol;
  final Currency currency;

  PricingPlan({
    required this.name,
    required this.price,
    required this.symbol,
    required this.currency,
  });
}

class PricingService {
  static final Map<Currency, Map<String, dynamic>> _pricingData = {
    Currency.usd: {'symbol': '\$', 'pro': 4.99},
    Currency.inr: {'symbol': '₹', 'pro': 149.0},
    Currency.eur: {'symbol': '€', 'pro': 4.99},
    Currency.gbp: {'symbol': '£', 'pro': 4.49},
  };

  static final Map<String, Currency> _countryToCurrency = {
    'IN': Currency.inr,
    'GB': Currency.gbp,
    'DE': Currency.eur,
    'FR': Currency.eur,
    'IT': Currency.eur,
    'ES': Currency.eur,
    'US': Currency.usd,
  };

  static Future<Currency> detectPPP() async {
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final countryCode = data['country_code'];
        return _countryToCurrency[countryCode] ?? Currency.usd;
      }
    } catch (e) {
      debugPrint('PPP Detection failed: $e');
    }
    
    // Fallback to locale detection
    return detectCurrency();
  }

  static Currency detectCurrency() {
    try {
      final locale = PlatformDispatcher.instance.locale.countryCode;

      switch (locale) {
        case 'IN':
          return Currency.inr;
        case 'GB':
          return Currency.gbp;
        case 'DE':
        case 'FR':
        case 'IT':
        case 'ES':
          return Currency.eur;
        default:
          return Currency.usd;
      }
    } catch (e) {
      return Currency.usd;
    }
  }

  static List<PricingPlan> getPlans(Currency currency) {
    final data = _pricingData[currency]!;
    return [
      PricingPlan(
        name: 'Pro',
        price: data['pro'],
        symbol: data['symbol'],
        currency: currency,
      ),
    ];
  }
}
