import 'dart:ui';
import 'package:flutter/foundation.dart';

enum Currency {
  USD,
  INR,
  EUR,
  GBP,
}

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
    Currency.USD: {'symbol': '\$', 'plus': 4.99, 'pro': 9.99},
    Currency.INR: {'symbol': '₹', 'plus': 149.0, 'pro': 299.0},
    Currency.EUR: {'symbol': '€', 'plus': 4.99, 'pro': 9.99},
    Currency.GBP: {'symbol': '£', 'plus': 4.49, 'pro': 8.99},
  };

  static Currency detectCurrency() {
    final locale = PlatformDispatcher.instance.locale.countryCode;
    
    switch (locale) {
      case 'IN':
        return Currency.INR;
      case 'GB':
        return Currency.GBP;
      case 'DE':
      case 'FR':
      case 'IT':
      case 'ES':
        return Currency.EUR;
      default:
        return Currency.USD;
    }
  }

  static List<PricingPlan> getPlans(Currency currency) {
    final data = _pricingData[currency]!;
    return [
      PricingPlan(
        name: 'Plus',
        price: data['plus'],
        symbol: data['symbol'],
        currency: currency,
      ),
      PricingPlan(
        name: 'Pro',
        price: data['pro'],
        symbol: data['symbol'],
        currency: currency,
      ),
    ];
  }
}
