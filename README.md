# NaijaMart Flutter Storefront

NaijaMart is the Flutter customer-facing application for the NaijaMart e-commerce API.

## Requirements

- Flutter SDK compatible with Dart 3.4 or newer
- A running NaijaMart FastAPI backend
- Android Studio / Android SDK for Android builds, or Xcode for iOS builds

## Install dependencies

Run these commands from the folder containing `pubspec.yaml`:

```powershell
flutter pub get
```

## Configure the API address

The default API URL is `http://127.0.0.1:8000`, which works for Flutter desktop and Flutter web when the FastAPI server is running on the same computer.

For an Android emulator, run:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For a physical Android phone, use your computer's LAN IP address, for example:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

Replace the example LAN IP with your computer's actual local network IP. The phone and computer must be on the same network, and the backend firewall must allow the API port.

For iOS Simulator, the default `http://127.0.0.1:8000` address normally works.

## Run the app

With the backend running in a separate terminal:

```powershell
flutter run
```

To run in Chrome:

```powershell
flutter run -d chrome
```

To run on a connected Android device:

```powershell
flutter devices
flutter run -d <device-id> --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Use `10.0.2.2` only for the Android emulator. A physical phone needs the computer's LAN IP.

## Backend

This ZIP contains the Flutter frontend. It does not contain the Python backend source. The app expects the existing FastAPI service to provide these routes:

- `GET /products`
- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `PUT /cart/items`
- `POST /checkout`
- `GET /orders`
- `POST /admin/products`
- `PATCH /admin/products/{product_id}`
- `GET /admin/orders`

Open the backend's Swagger page at `http://127.0.0.1:8000/docs` to inspect its available routes.

## Current frontend features

- NaijaMart storefront with orange/coral visual styling
- Backend-loaded product catalogue, category filtering and search
- Product detail pages and stock display
- Local favourites and cart state
- Checkout request to the backend with Paystack / bank-transfer selection
- Customer order history from the backend
- Admin product creation and admin order listing screens
- Email/password sign-in and registration
- Light, dark and system appearance selection
- Configurable support phone via `--dart-define=SUPPORT_PHONE=...`

## Important integration notes

This is an improved MVP frontend, not a fully audited production marketplace.

- The checkout screen submits the order to the backend. Paystack checkout opens the authorization URL returned by the backend when one is supplied.
- The backend must verify payment server-side and must not trust a client-side success result.
- The current backend cart API shown in the supplied code has no delete-item route. Removing an item locally may leave a stale server-side cart item until the backend adds a delete endpoint or a cart replacement endpoint.
- Cloudflare R2 presigned upload and Firebase Cloud Messaging are not wired into this Flutter UI yet. Firebase platform configuration (`google-services.json`, iOS `GoogleService-Info.plist`, and Firebase initialization) is required before push notifications can run.
- Admin screens require a JWT belonging to an account whose backend role is `admin`. Hiding a screen in Flutter is not a security boundary; the API must enforce roles.
- Android cleartext HTTP is enabled for local development. Use HTTPS and disable cleartext traffic in production.
- Set real support contact details and legal policy URLs before release.
- Run `flutter analyze` and `flutter test` in an environment with the Flutter SDK before publishing.

## Project structure

```text
naijamart/
  android/
  ios/
  lib/
    core/
    data/
    models/
    providers/
    screens/
    services/
    widgets/
    app.dart
    main.dart
  pubspec.yaml
  README.md
```
