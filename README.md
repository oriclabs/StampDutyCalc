# Vehicle Stamp Duty Calculator

Cross-platform vehicle stamp duty calculator for **Australia** and **New Zealand**. Built with Flutter, supporting iOS, Android, Web, macOS, and Windows.

## Features

- **All AU states & territories** -- NSW, VIC, QLD, SA, WA, ACT, TAS, NT with official rate structures
- **New Zealand** -- annual licensing and ACC levy calculator
- **On-road cost calculator** -- stamp duty + registration + CTP + Luxury Car Tax + dealer delivery
- **Compare states** -- side-by-side duty comparison across all states for the same vehicle
- **Dynamic rates** -- rates loaded from JSON, auto-updated from remote source without app release
- **Date-aware** -- select registration date to use correct historical or current rates
- **Calculation history** -- last 50 calculations saved locally
- **Bookmarks** -- save favourite state + vehicle type combos for one-tap access
- **Quick recalculate** -- adjust price +/- on the result screen without going back
- **Share results** -- copy to clipboard or share as image
- **Dark mode** -- light, dark, or system-auto theme
- **PWA support** -- installable from browser on any platform
- **Accessibility** -- semantic labels, haptic feedback, keyboard support

## Supported Vehicle Types

| State | Categories |
|-------|-----------|
| NSW | Passenger / Non-passenger |
| VIC | Car (Standard / Green / Primary Producer), Motorcycle, Trailer, Non-passenger |
| QLD | Light / Heavy / Special + engine type (cylinders, electric, hybrid) |
| SA | Non-commercial / Commercial + fleet discount |
| WA | Light / Heavy |
| ACT | Passenger / Motorcycle / Trailer / Other + emissions rating (new system from Sep 2025) |
| TAS | Passenger / Commercial / Caravan / Heavy |
| NT | Standard / Electric (with EV concession) |
| NZ | Petrol / Diesel / Electric by engine size |

## Getting Started

```bash
# Clone
git clone https://github.com/Rajbandi/StampDutyCalc.git
cd StampDutyCalc

# Install dependencies
flutter pub get

# Run
flutter run -d chrome      # Web
flutter run -d macos       # macOS
flutter run                # Connected device/emulator
```

## Updating Rates

Rates are stored in `assets/rates/rates.json`. To update:

1. Edit the rate values in `rates.json`
2. Bump the `"version"` field (e.g., `"2026.5"`)
3. Commit and push

The app checks for remote updates from the configured URL in `lib/services/rate_service.dart`. Users get new rates without an app update.

### Adding a new country

Add a new entry to the `countries` array in `rates.json`:

```json
{
  "code": "FJ",
  "name": "Fiji",
  "currency": "FJD",
  "currencySymbol": "$",
  "flag": "fj",
  "states": [...]
}
```

No code changes required -- the app reads fields, rates, and UI structure entirely from JSON.

## Testing

```bash
flutter test test/calculator_test.dart
```

53 tests covering all states, vehicle types, LCT, on-road costs, date-based rate selection, and edge cases.

## Tech Stack

- **Flutter 3.41+** (Dart 3.11+)
- **Provider** for state management
- **Material 3** with saffron theme
- **SharedPreferences** for history, bookmarks, theme, rate caching
- **share_plus** for image sharing

## License

Apache 2.0
