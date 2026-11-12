
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/crash_reporter.dart';
import '../core/errors.dart';
import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'demo_data.dart';

final storeApiProvider =
    Provider<StoreApi>((ref) => StoreApi(ref.watch(apiClientProvider)));

/// Typed access to the NaijaMart backend. Every method throws
/// [ApiException] with a message that is safe to show to a customer.
class StoreApi {
  StoreApi(this.client);
  final ApiClient client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (error, stack) {
      final mapped = ApiException.from(error);

      // Expected client errors (bad password, validation) are not crashes.
      if (mapped.statusCode == null || mapped.statusCode! >= 500) {
        CrashReporter.record(error, stack);
      }

      throw mapped;
    }
  }

  Map<String, dynamic> _map(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Expected a JSON object.');
  }

  List<Map<String, dynamic>> _list(Object? data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    throw const FormatException('Expected a JSON list.');
  }

  // ---- Catalogue ---------------------------------------------------------

  Future<List<Product>> products({
    String query = '',
    String category = '',
    int offset = 0,
    int limit = AppConfig.pageSize,
  }) {
    if (AppConfig.useDemoData) {
      return Future.value(
        filterDemoProducts(
          query: query,
          category: category,
          offset: offset,
          limit: limit,
        ),
      );
    }

    return _guard(() async {
      final response = await client.dio.get<dynamic>(
        '/products',
        queryParameters: {
          if (query.isNotEmpty) 'q': query,
          if (category.isNotEmpty) 'category': category,
          'offset': offset,
          'limit': limit,
        },
      );

      return _list(response.data).map(Product.fromJson).toList();
    });
  }

  // ---- Auth --------------------------------------------------------------

  Future<AppUser> login(String email, String password) => _guard(() async {
        final response = await client.dio.post<dynamic>(
          '/auth/login',
          data: {
            'email': email.trim(),
            'password': password,
          },
        );

        await client.saveToken(
          _map(response.data)['access_token'] as String,
        );

        return _fetchUser();
      });

  Future<AppUser> register(String name, String email, String password) =>
      _guard(() async {
        final response = await client.dio.post<dynamic>(
          '/auth/register',
          data: {
            'full_name': name.trim(),
            'email': email.trim(),
            'password': password,
          },
        );

        await client.saveToken(
          _map(response.data)['access_token'] as String,
        );

        return _fetchUser();
      });

  Future<AppUser> currentUser() => _guard(_fetchUser);

  Future<AppUser> _fetchUser() async {
    final response = await client.dio.get<dynamic>('/auth/me');
    return AppUser.fromJson(_map(response.data));
  }

  Future<void> logout() => client.clearToken();

  /// Permanently deletes the signed-in customer's account.
  Future<void> deleteAccount() => _guard(() async {
        await client.dio.delete<dynamic>('/auth/me');
        await client.clearToken();
      });

  // ---- Cart & checkout ---------------------------------------------------

  Future<void> updateCartItem(int productId, int quantity) =>
      _guard(() async {
        await client.dio.put<dynamic>(
          '/cart/items',
          data: {
            'product_id': productId,
            'quantity': quantity,
          },
        );
      });

  Future<CheckoutResult> checkout({
    required String deliveryAddress,
    required String paymentMethod,
  }) =>
      _guard(() async {
        final response = await client.dio.post<dynamic>(
          '/checkout',
          data: {
            'delivery_address': deliveryAddress.trim(),
            'payment_method': paymentMethod,
          },
        );

        return CheckoutResult.fromJson(_map(response.data));
      });

  // ---- Payment verification ---------------------------------------------

  /// Verifies a Paystack transaction using the order reference.
  ///
  /// The backend independently checks the transaction with Paystack.
  Future<Map<String, dynamic>> verifyPaystack(String reference) =>
      _guard(() async {
        final cleanReference = reference.trim();

        if (cleanReference.isEmpty) {
          throw const FormatException('Order reference is missing.');
        }

        final response = await client.dio.post<dynamic>(
          '/payments/paystack/verify/$cleanReference',
        );

        return _map(response.data);
      });

  /// Verifies a Flutterwave transaction using its transaction ID.
  ///
  /// The transaction ID must come from the actual Flutterwave payment
  /// response or verified callback. Never invent or guess this ID.
  Future<Map<String, dynamic>> verifyFlutterwave({
    required String reference,
    required String transactionId,
  }) =>
      _guard(() async {
        final cleanReference = reference.trim();
        final cleanTransactionId = transactionId.trim();

        if (cleanReference.isEmpty) {
          throw const FormatException('Order reference is missing.');
        }

        if (cleanTransactionId.isEmpty) {
          throw const FormatException('Flutterwave transaction ID is missing.');
        }

        final response = await client.dio.post<dynamic>(
          '/payments/flutterwave/verify/$cleanReference',
          data: {
            'transaction_id': cleanTransactionId,
          },
        );

        return _map(response.data);
      });

  // ---- Orders ------------------------------------------------------------

  Future<List<Order>> orders() => _guard(() async {
        final response = await client.dio.get<dynamic>('/orders');
        return _list(response.data).map(Order.fromJson).toList();
      });

  // ---- Admin -------------------------------------------------------------

  Future<List<Order>> adminOrders() => _guard(() async {
        final response = await client.dio.get<dynamic>('/admin/orders');
        return _list(response.data).map(Order.fromJson).toList();
      });

  Future<Product> createProduct({
    required String name,
    required String slug,
    required String description,
    required String category,
    required int priceKobo,
    required int quantity,
    String imageUrl = '',
  }) =>
      _guard(() async {
        final response = await client.dio.post<dynamic>(
          '/admin/products',
          data: {
            'name': name.trim(),
            'slug': slug.trim(),
            'description': description.trim(),
            'category': category.trim(),
            'price_kobo': priceKobo,
            'quantity': quantity,
            'image_url': imageUrl.trim(),
          },
        );

        return Product.fromJson(_map(response.data));
      });

  Future<Product> updateProduct(
    int id,
    Map<String, dynamic> changes,
  ) =>
      _guard(() async {
        final response = await client.dio.patch<dynamic>(
          '/admin/products/$id',
          data: changes,
        );

        return Product.fromJson(_map(response.data));
      });
}
