# PrimeFit — Flutter App

Matches the Figma design for: Landing Page → Login Page → Member Dashboard → QR Check-In.

## Folder structure

```
lib/
  main.dart                        # App entry point
  theme/
    app_theme.dart                 # Colors, gradients, ThemeData
  widgets/
    prime_fit_logo.dart            # Reusable circular badge + wordmark
    member_sidebar.dart            # Left nav used inside the member portal
    dashboard_view.dart            # Dashboard tab content
    qr_checkin_view.dart           # Check-In tab content (functional demo scan)
    placeholder_view.dart          # "Coming soon" content for unbuilt tabs
  screens/
    landing_page.dart              # Public marketing page (hero, about, mission, pricing, contact)
    login_page.dart                # Member sign-in screen
    member_portal_screen.dart      # Shell: sidebar + swaps between Dashboard/Check-In/placeholders
```

## How the flow works

1. **Landing page** (`landing_page.dart`) is the app's home screen. "Sign In", "Join Now" and
   "Get Started" all push `LoginPage`.
2. **Login page** (`login_page.dart`) validates that the fields aren't empty, then replaces
   itself with `MemberPortalScreen` (no backend — this is a front-end demo login).
3. **Member portal** (`member_portal_screen.dart`) shows the sidebar from `member_sidebar.dart`
   and swaps the main content:
   - **Dashboard** → `dashboard_view.dart` (fully built, matches the screenshot)
   - **Check-In** → `qr_checkin_view.dart` (fully built — generates a real scannable QR code
     with `qr_flutter`, and has a "Demo: simulate front-desk scan" button that actually
     deducts a session credit and updates "Last Check-In" live)
   - **Progress / Programs / Membership / Profile** → `placeholder_view.dart` ("coming soon"
     — swap these out later with real screens)
   - **Logout** in the sidebar returns to the Landing page.

## Setup

1. Copy the `lib/` folder and `pubspec.yaml` into your existing Flutter project (or create a
   new one with `flutter create primefit` and replace its `lib/` + `pubspec.yaml`).
2. Install dependencies:
   ```
   flutter pub get
   ```
3. Run it:
   ```
   flutter run -d chrome   # or any connected device/emulator
   ```

## Notes

- The only external package used is `qr_flutter`, which renders the real QR code on the
  Check-In page.
- Layouts are responsive (desktop sidebar vs. mobile drawer + app bar) using `LayoutBuilder`/
  `MediaQuery` breakpoints around 760–900px.
- All data shown (member name, credits, pricing, etc.) is currently hardcoded as default
  widget parameters so you can see the exact design — wire these up to real state/APIs
  whenever you're ready.
