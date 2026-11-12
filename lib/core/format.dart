/// Formats an amount in kobo as Nigerian naira, e.g. `₦18,500.00`.
String naira(int kobo, {bool showDecimals = true}) {
  final negative = kobo < 0;
  final abs = kobo.abs();
  final whole = (abs ~/ 100).toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  final cents = (abs % 100).toString().padLeft(2, '0');
  final body = showDecimals ? '$whole.$cents' : whole;
  return '${negative ? '-' : ''}₦$body';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

/// `6 Nov 2026, 2:47 PM` in the device's local time. Returns [fallback]
/// when [raw] is missing or unparsable.
String formatDateTime(Object? raw, {String fallback = ''}) {
  if (raw == null) return fallback;
  final parsed = DateTime.tryParse('$raw');
  if (parsed == null) return fallback;
  final d = parsed.toLocal();
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final suffix = d.hour >= 12 ? 'PM' : 'AM';
  return '${d.day} ${_months[d.month - 1]} ${d.year}, $hour12:$minute $suffix';
}

/// Turns `payment_pending` into `Payment pending`.
String humanize(String value) {
  final cleaned = value.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  if (cleaned.isEmpty) return cleaned;
  return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
}

/// Lower-case URL slug: `Premium Leather Bag!` -> `premium-leather-bag`.
String slugify(String input) => input
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// Parses a naira amount typed by a person (`15,000.50`) into kobo.
/// Returns null when the text is not a positive, finite amount.
int? parseNairaToKobo(String input) {
  final cleaned = input.trim().replaceAll(',', '');
  if (cleaned.isEmpty) return null;
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(cleaned)) return null;
  final parts = cleaned.split('.');
  final whole = int.tryParse(parts[0]);
  if (whole == null) return null;
  final cents = parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0;
  final kobo = whole * 100 + cents;
  return kobo > 0 ? kobo : null;
}

/// Nigerian mobile numbers: 0801 234 5678, +234 801 234 5678, 2348012345678.
bool isValidNigerianPhone(String input) {
  final digits = input.replaceAll(RegExp(r'[\s\-()]'), '');
  return RegExp(r'^(\+234|234|0)[789][01]\d{8}$').hasMatch(digits);
}

bool isValidEmail(String input) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(input.trim());
