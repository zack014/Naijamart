import 'package:flutter_test/flutter_test.dart';
import 'package:naijamart/core/format.dart';

void main() {
  group('naira', () {
    test('formats kobo with grouping and decimals', () {
      expect(naira(1850000), '₦18,500.00');
      expect(naira(99), '₦0.99');
      expect(naira(100000000), '₦1,000,000.00');
    });

    test('can hide decimals', () {
      expect(naira(1850000, showDecimals: false), '₦18,500');
    });
  });

  group('parseNairaToKobo', () {
    test('parses plain, grouped and decimal amounts', () {
      expect(parseNairaToKobo('15000'), 1500000);
      expect(parseNairaToKobo('15,000.5'), 1500050);
      expect(parseNairaToKobo(' 99.99 '), 9999);
    });

    test('rejects invalid input', () {
      expect(parseNairaToKobo(''), isNull);
      expect(parseNairaToKobo('abc'), isNull);
      expect(parseNairaToKobo('0'), isNull);
      expect(parseNairaToKobo('-5'), isNull);
      expect(parseNairaToKobo('1.234'), isNull);
    });
  });

  test('slugify', () {
    expect(slugify('  Premium Leather Bag! '), 'premium-leather-bag');
    expect(slugify('A & B'), 'a-b');
  });

  test('humanize', () {
    expect(humanize('payment_pending'), 'Payment pending');
    expect(humanize('PAID'), 'Paid');
  });

  test('isValidNigerianPhone', () {
    expect(isValidNigerianPhone('0801 234 5678'), isTrue);
    expect(isValidNigerianPhone('+2348012345678'), isTrue);
    expect(isValidNigerianPhone('12345'), isFalse);
  });

  test('isValidEmail', () {
    expect(isValidEmail('a@b.com'), isTrue);
    expect(isValidEmail('a@b'), isFalse);
    expect(isValidEmail('no spaces@b.com'), isFalse);
  });

  test('formatDateTime handles bad input', () {
    expect(formatDateTime(null, fallback: '-'), '-');
    expect(formatDateTime('not a date', fallback: '-'), '-');
    expect(formatDateTime('2026-11-06T14:47:00'), contains('2026'));
  });
}
