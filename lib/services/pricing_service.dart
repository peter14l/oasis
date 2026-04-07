import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
      // Priority 1: IP-based detection (most accurate for travel/VPN)
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final countryCode = data['country_code']?.toString().toUpperCase();
        if (countryCode != null &&
            _countryToCurrency.containsKey(countryCode)) {
          return _countryToCurrency[countryCode]!;
        }
      }
    } catch (e) {
      debugPrint('PPP Detection via IP failed: $e');
    }

    // Priority 2: System Locale (reliable fallback on most OSs)
    return detectCurrency();
  }

  static Currency detectCurrency() {
    try {
      // First check if we have a valid country code from the system locale
      final countryCode =
          PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
      if (countryCode != null && _countryToCurrency.containsKey(countryCode)) {
        return _countryToCurrency[countryCode]!;
      }

      // Additional check for common European countries that might not be in our explicit map
      final languageCode =
          PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      if (['de', 'fr', 'it', 'es', 'nl', 'be', 'at'].contains(languageCode)) {
        return Currency.eur;
      }
    } catch (e) {
      debugPrint('Locale detection failed: $e');
    }

    // Fallback: For desktop apps, try to detect via IP (async call - synchronous for compatibility)
    // This is a best-effort fallback. Callers should use detectPPP() for async IP detection.
    return Currency.usd;
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
