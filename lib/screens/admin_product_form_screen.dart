import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/errors.dart';
import '../core/format.dart';
import '../core/launcher.dart';
import '../models/product.dart';
import '../providers/catalogue_provider.dart';
import '../providers/orders_provider.dart';
import '../services/store_api.dart';
import '../widgets/ui.dart';

/// Create a product, or edit [product] when given.
class AdminProductFormScreen extends ConsumerStatefulWidget {
  const AdminProductFormScreen({super.key, this.product});
  final Product? product;

  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState
    extends ConsumerState<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _slug = TextEditingController(text: widget.product?.slug ?? '');
  late final _description =
      TextEditingController(text: widget.product?.description ?? '');
  late final _price = TextEditingController(
      text: widget.product == null ? '' : _koboToField(widget.product!.priceKobo));
  late final _quantity = TextEditingController(
      text: widget.product == null ? '' : '${widget.product!.quantity}');
  late final _imageUrl =
      TextEditingController(text: widget.product?.imageUrl ?? '');
  late String _category = _initialCategory();

  bool _saving = false;
  bool _dirty = false;
  bool _slugEdited = false;
  String? _error;

  bool get _isEdit => widget.product != null;

  String _initialCategory() {
    final existing = widget.product?.category;
    if (existing != null && AppConfig.categories.contains(existing)) return existing;
    return existing == null ? AppConfig.categories.first : 'Other';
  }

  static String _koboToField(int kobo) {
    final whole = kobo ~/ 100;
    final cents = kobo % 100;
    return cents == 0 ? '$whole' : '$whole.${cents.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    // New products: keep the URL slug in step with the name until edited.
    if (!_isEdit) _name.addListener(_syncSlug);
  }

  @override
  void dispose() {
    _name.removeListener(_syncSlug);
    for (final c in [_name, _slug, _description, _price, _quantity, _imageUrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncSlug() {
    if (_slugEdited) return;
    final generated = slugify(_name.text);
    if (_slug.text != generated) _slug.text = generated;
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final kobo = parseNairaToKobo(_price.text)!;
    final quantity = int.parse(_quantity.text.trim());

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final api = ref.read(storeApiProvider);
      final existing = widget.product;

      if (existing == null) {
        await api.createProduct(
          name: _name.text,
          slug: _slug.text,
          description: _description.text,
          category: _category,
          priceKobo: kobo,
          quantity: quantity,
          imageUrl: _imageUrl.text,
        );
      } else {
        final changes = <String, dynamic>{
          if (_name.text.trim() != existing.name) 'name': _name.text.trim(),
          if (_slug.text.trim() != existing.slug && _slug.text.trim().isNotEmpty)
            'slug': _slug.text.trim(),
          if (_description.text.trim() != existing.description)
            'description': _description.text.trim(),
          if (_category != existing.category) 'category': _category,
          if (kobo != existing.priceKobo) 'price_kobo': kobo,
          if (quantity != existing.quantity) 'quantity': quantity,
          if (_imageUrl.text.trim() != existing.imageUrl)
            'image_url': _imageUrl.text.trim(),
        };
        if (changes.isNotEmpty) await api.updateProduct(existing.id, changes);
      }

      ref.invalidate(adminProductsProvider);
      ref.read(catalogueProvider.notifier).refresh(keepItems: true);

      if (!mounted) return;
      showAppSnack(context, _isEdit ? 'Product updated.' : 'Product published.');
      _dirty = false;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = ApiException.from(error).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required.' : null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final previewUri = safeHttpsUri(_imageUrl.text.trim());

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await confirmAction(
          context,
          title: 'Discard changes?',
          message: 'Your edits have not been saved.',
          confirmLabel: 'Discard',
          destructive: true,
        );
        if (discard && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Edit product' : 'Add product')),
        body: ContentWidth(
          maxWidth: 640,
          child: Form(
            key: _formKey,
            onChanged: () {
              if (!_dirty) setState(() => _dirty = true);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!, style: TextStyle(color: scheme.error)),
                  ),
                  const SizedBox(height: 14),
                ],
                _field(
                  controller: _name,
                  label: 'Product name',
                  hint: 'e.g. Premium Leather Handbag',
                  icon: Icons.shopping_bag_outlined,
                  capitalization: TextCapitalization.words,
                  validator: (v) => _required(v, 'Product name'),
                ),
                _field(
                  controller: _slug,
                  label: 'URL slug',
                  hint: 'Generated from the name',
                  icon: Icons.link_rounded,
                  onChanged: (_) => _slugEdited = true,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Slug is required.';
                    if (!RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(value)) {
                      return 'Use lowercase letters, numbers and hyphens only.';
                    }
                    return null;
                  },
                ),
                _field(
                  controller: _description,
                  label: 'Description',
                  hint: 'Describe the product…',
                  icon: Icons.notes_rounded,
                  maxLines: 4,
                  capitalization: TextCapitalization.sentences,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 2),
                  child: Text('Category',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in AppConfig.categories)
                      ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        showCheckmark: false,
                        selectedColor: scheme.primary,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _category == c ? scheme.onPrimary : scheme.onSurface,
                        ),
                        onSelected: (_) => setState(() {
                          _category = c;
                          _dirty = true;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        controller: _price,
                        label: 'Price (₦)',
                        hint: '15000',
                        icon: Icons.payments_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => parseNairaToKobo(v ?? '') == null
                            ? 'Enter a price above ₦0'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        controller: _quantity,
                        label: 'Stock',
                        hint: '20',
                        icon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          return (n == null || n < 0) ? 'Enter 0 or more' : null;
                        },
                      ),
                    ),
                  ],
                ),
                _field(
                  controller: _imageUrl,
                  label: 'Image URL',
                  hint: 'https://example.com/image.jpg',
                  icon: Icons.image_outlined,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return null;
                    return safeHttpsUri(value) == null
                        ? 'Enter a valid https:// link'
                        : null;
                  },
                ),
                if (previewUri != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: AppImage(url: previewUri.toString()),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: scheme.onPrimary),
                        )
                      : Icon(_isEdit ? Icons.save_outlined : Icons.publish_rounded),
                  label: Text(_saving
                      ? 'Saving…'
                      : (_isEdit ? 'Save changes' : 'Publish product')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }
}
