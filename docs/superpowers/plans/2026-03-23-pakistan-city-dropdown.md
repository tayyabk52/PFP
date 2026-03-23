# Pakistan City Dropdown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace free-text city inputs on registration, profile edit, and seller application forms with a styled dropdown of major Pakistani cities plus an "Other..." escape hatch for unlisted cities.

**Architecture:** A static `pakistan_cities.dart` constants file holds ~50 curated city names. A shared `PakistanCityField` StatefulWidget wraps a `DropdownButtonFormField` and conditionally shows a free-text field when "Other..." is selected. Three pages swap their `TextEditingController`-based city fields for this widget.

**Tech Stack:** Flutter, Dart, Riverpod (no new packages required)

**Spec:** `docs/superpowers/specs/2026-03-23-pakistan-city-dropdown-design.md`

---

## File Map

| Action | File | Responsibility |
|---|---|---|
| Create | `lib/core/constants/pakistan_cities.dart` | Static list of ~50 Pakistani cities + `'Other...'` sentinel |
| Create | `lib/core/widgets/pakistan_city_field.dart` | Shared dropdown widget with Other escape hatch |
| Create | `test/core/widgets/pakistan_city_field_test.dart` | Widget tests for `PakistanCityField` |
| Modify | `lib/features/auth/pages/register_page.dart` | Replace `_cityCtrl` + `AuthTextField` with `PakistanCityField` |
| Modify | `lib/features/dashboard/pages/profile_page.dart` | Replace `_cityController` + `TextFormField` with `PakistanCityField` |
| Modify | `lib/features/seller_apply/pages/seller_apply_page.dart` | Replace `_cityCtrl` + `AuthTextField` with `PakistanCityField`; fix two-col layout |

---

## Task 1: Create the city constants file

**Files:**
- Create: `lib/core/constants/pakistan_cities.dart`

- [ ] **Step 1: Create the constants file**

```dart
// lib/core/constants/pakistan_cities.dart

/// Curated list of major Pakistani cities, alphabetically sorted.
/// Used by [PakistanCityField] as the dropdown options.
/// The sentinel value 'Other...' must always be the last entry.
const List<String> kPakistanCities = [
  'Abbottabad',
  'Bahawalpur',
  'Chakwal',
  'Chiniot',
  'Dera Ghazi Khan',
  'Dera Ismail Khan',
  'Faisalabad',
  'Gujranwala',
  'Gujrat',
  'Hafizabad',
  'Hyderabad',
  'Islamabad',
  'Jacobabad',
  'Jhelum',
  'Karachi',
  'Kasur',
  'Khanewal',
  'Khushab',
  'Lahore',
  'Larkana',
  'Layyah',
  'Lodhran',
  'Mansehra',
  'Mardan',
  'Mirpur Khas',
  'Multan',
  'Muzaffarabad',
  'Narowal',
  'Nawabshah',
  'Nowshera',
  'Okara',
  'Peshawar',
  'Quetta',
  'Rahim Yar Khan',
  'Rawalpindi',
  'Sadiqabad',
  'Sahiwal',
  'Sargodha',
  'Sheikhupura',
  'Sialkot',
  'Sukkur',
  'Swabi',
  'Swat',
  'Turbat',
  'Umerkot',
  'Vehari',
  'Wah Cantt',
  'Other...',
];
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/constants/pakistan_cities.dart
git commit -m "feat: add Pakistan cities constants"
```

---

## Task 2: Write tests for PakistanCityField (TDD — failing first)

**Files:**
- Create: `test/core/widgets/pakistan_city_field_test.dart`

- [ ] **Step 1: Create the test file**

```dart
// test/core/widgets/pakistan_city_field_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_app/core/widgets/pakistan_city_field.dart';
import 'package:pfc_app/core/constants/pakistan_cities.dart';

/// Wraps [PakistanCityField] in a minimal [MaterialApp] + [Form].
Widget buildField({
  String? initialValue,
  void Function(String?)? onChanged,
  String label = 'CITY',
  bool required = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Form(
        child: PakistanCityField(
          initialValue: initialValue,
          onChanged: onChanged ?? (_) {},
          label: label,
          required: required,
        ),
      ),
    ),
  );
}

void main() {
  group('PakistanCityField', () {
    testWidgets('renders dropdown with correct label', (tester) async {
      await tester.pumpWidget(buildField(label: 'CITY OF RESIDENCE'));
      expect(find.text('CITY OF RESIDENCE'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('does not show free-text field initially when no initialValue',
        (tester) async {
      await tester.pumpWidget(buildField());
      expect(find.byKey(const Key('city_other_text_field')), findsNothing);
    });

    testWidgets('pre-selects known city from initialValue', (tester) async {
      await tester.pumpWidget(buildField(initialValue: 'Lahore'));
      await tester.pump();
      expect(find.text('Lahore'), findsOneWidget);
      expect(find.byKey(const Key('city_other_text_field')), findsNothing);
    });

    testWidgets(
        'shows Other... selected and free-text field when initialValue is not in list',
        (tester) async {
      await tester.pumpWidget(buildField(initialValue: 'My Custom Town'));
      await tester.pump();
      // Dropdown shows 'Other...'
      expect(find.text('Other...'), findsOneWidget);
      // Free-text field is visible and pre-populated
      expect(find.byKey(const Key('city_other_text_field')), findsOneWidget);
      expect(find.text('My Custom Town'), findsOneWidget);
    });

    testWidgets('emits selected city string via onChanged', (tester) async {
      String? emitted;
      await tester.pumpWidget(buildField(onChanged: (v) => emitted = v));

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select 'Karachi'
      await tester.tap(find.text('Karachi').last);
      await tester.pumpAndSettle();

      expect(emitted, 'Karachi');
    });

    testWidgets('shows free-text field when Other... is selected',
        (tester) async {
      await tester.pumpWidget(buildField());

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Other...').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('city_other_text_field')), findsOneWidget);
    });

    testWidgets('emits trimmed other-text via onChanged when Other... typed',
        (tester) async {
      String? emitted;
      await tester.pumpWidget(buildField(onChanged: (v) => emitted = v));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other...').last);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('city_other_text_field')), '  Turbat  ');
      await tester.pump();

      expect(emitted, 'Turbat');
    });

    testWidgets('emits null when Other... selected but text field is empty',
        (tester) async {
      String? emitted = 'initial';
      await tester.pumpWidget(buildField(onChanged: (v) => emitted = v));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other...').last);
      await tester.pumpAndSettle();

      // Text field is empty — widget should emit null
      expect(emitted, isNull);
    });

    testWidgets(
        'required=true shows error on dropdown when submitted without selection',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PakistanCityField(
              initialValue: null,
              onChanged: (_) {},
              required: true,
            ),
          ),
        ),
      ));

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('City is required'), findsOneWidget);
    });

    testWidgets(
        'required=true shows error on free-text field when Other... selected but empty',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PakistanCityField(
              initialValue: null,
              onChanged: (_) {},
              required: true,
            ),
          ),
        ),
      ));

      // Select Other...
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other...').last);
      await tester.pumpAndSettle();

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Please enter your city'), findsOneWidget);
    });

    testWidgets('required=false does not show error when empty', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PakistanCityField(
              initialValue: null,
              onChanged: (_) {},
              required: false,
            ),
          ),
        ),
      ));

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('City is required'), findsNothing);
    });

    testWidgets(
        'free-text field disappears and Other... text is cleared when a named city is selected after Other...',
        (tester) async {
      String? emitted;
      await tester.pumpWidget(buildField(onChanged: (v) => emitted = v));

      // Select Other... first
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other...').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('city_other_text_field')), findsOneWidget);

      // Now select a named city
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sialkot').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('city_other_text_field')), findsNothing);
      expect(emitted, 'Sialkot');
    });
  });
}
```

- [ ] **Step 2: Run tests — expect all to FAIL (widget doesn't exist yet)**

```bash
flutter test test/core/widgets/pakistan_city_field_test.dart
```

Expected: compilation error — `PakistanCityField` not found. This confirms the test is wired correctly.

- [ ] **Step 3: Commit failing tests**

```bash
git add test/core/widgets/pakistan_city_field_test.dart
git commit -m "test: add failing tests for PakistanCityField"
```

---

## Task 3: Implement PakistanCityField widget

**Files:**
- Create: `lib/core/widgets/pakistan_city_field.dart`

- [ ] **Step 1: Create the widget**

```dart
// lib/core/widgets/pakistan_city_field.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/pakistan_cities.dart';
import '../theme/app_colors.dart';

class PakistanCityField extends StatefulWidget {
  final String? initialValue;
  final void Function(String?) onChanged;
  final String label;
  final bool required;

  const PakistanCityField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.label = 'CITY',
    this.required = false,
  });

  @override
  State<PakistanCityField> createState() => _PakistanCityFieldState();
}

class _PakistanCityFieldState extends State<PakistanCityField> {
  String? _selected;
  String _otherText = '';
  late final TextEditingController _otherCtrl;

  static const _otherSentinel = 'Other...';

  @override
  void initState() {
    super.initState();
    final v = widget.initialValue;
    if (v != null && kPakistanCities.contains(v)) {
      _selected = v;
    } else if (v != null && v.isNotEmpty) {
      _selected = _otherSentinel;
      _otherText = v;
    }
    _otherCtrl = TextEditingController(text: _otherText);
  }

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  void _emitValue() {
    if (_selected == _otherSentinel) {
      final trimmed = _otherText.trim();
      widget.onChanged(trimmed.isEmpty ? null : trimmed);
    } else {
      widget.onChanged(_selected);
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textMuted.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.fromLTRB(0, 14, 8, 12),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selected,
          dropdownColor: AppColors.surfaceContainerLow,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.onBackground,
          ),
          decoration: _decoration('Select city'),
          validator: widget.required
              ? (v) => v == null ? 'City is required' : null
              : null,
          items: kPakistanCities
              .map((city) => DropdownMenuItem(
                    value: city,
                    child: Text(
                      city,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selected = value;
              if (value != _otherSentinel) {
                _otherText = '';
                _otherCtrl.clear();
              }
            });
            _emitValue();
          },
        ),
        if (_selected == _otherSentinel) ...[
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('city_other_text_field'),
            controller: _otherCtrl,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onBackground,
            ),
            decoration: _decoration('Enter your city'),
            validator: widget.required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter your city'
                    : null
                : null,
            onChanged: (value) {
              _otherText = value;
              _emitValue();
            },
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 2: Run tests — expect all to PASS**

```bash
flutter test test/core/widgets/pakistan_city_field_test.dart
```

Expected: all tests pass. If any fail, fix the widget (not the tests) before continuing.

- [ ] **Step 3: Commit**

```bash
git add lib/core/widgets/pakistan_city_field.dart
git commit -m "feat: add PakistanCityField shared widget"
```

---

## Task 4: Wire up register_page.dart

**Files:**
- Modify: `lib/features/auth/pages/register_page.dart`

**Context:** `_cityCtrl` is declared at line 26, disposed at line 52, used in the submit handler at line 127, and rendered as `AuthTextField` around line 485.

- [ ] **Step 1: Remove `_cityCtrl` and add `_selectedCity` state variable**

In `_RegisterPageState`, make these changes:

Remove the declaration:
```dart
final _cityCtrl = TextEditingController();
```

Add in its place (alongside other state fields):
```dart
String? _selectedCity;
```

Remove the dispose call:
```dart
_cityCtrl.dispose();
```

- [ ] **Step 2: Add the import for PakistanCityField**

At the top of the file, add:
```dart
import '../../../core/widgets/pakistan_city_field.dart';
```

- [ ] **Step 3: Replace the AuthTextField for city**

Find (around line 485):
```dart
AuthTextField(
  label: 'City of Residence',
  hint: 'e.g. Lahore',
  controller: _cityCtrl,
  textInputAction: TextInputAction.next,
),
```

Replace with:
```dart
PakistanCityField(
  label: 'CITY OF RESIDENCE',
  initialValue: null,
  onChanged: (v) => setState(() => _selectedCity = v),
),
```

- [ ] **Step 4: Update the submit handler**

Find (around line 127):
```dart
city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
```

Replace with:
```dart
city: _selectedCity,
```

- [ ] **Step 5: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass (no regressions).

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/pages/register_page.dart
git commit -m "feat: use PakistanCityField in registration form"
```

---

## Task 5: Wire up profile_page.dart

**Files:**
- Modify: `lib/features/dashboard/pages/profile_page.dart`

**Context:** `_cityController` declared at line 24, disposed at line 42, populated in `_populateFields()` at line 53, used in read-only guard at line 438, rendered as `TextFormField` around line 500, used in save handler at line 120.

- [ ] **Step 1: Remove `_cityController` and add `_selectedCity` state variable**

Remove the declaration:
```dart
final _cityController = TextEditingController();
```

Add in its place:
```dart
String? _selectedCity;
```

Remove the dispose call:
```dart
_cityController.dispose();
```

- [ ] **Step 2: Add the import**

```dart
import '../../../core/widgets/pakistan_city_field.dart';
```

- [ ] **Step 3: Update `_populateFields()`**

Find (around line 53):
```dart
_cityController.text = profile['city'] as String? ?? '';
```

Replace with:
```dart
_selectedCity = profile['city'] as String?;
```

- [ ] **Step 4: Update the read-only view guard**

Find (around line 438):
```dart
if (_cityController.text.isNotEmpty)
  _readOnlyRow('City', _cityController.text, Icons.location_on_outlined),
```

Replace with:
```dart
if ((_selectedCity ?? '').isNotEmpty)
  _readOnlyRow('City', _selectedCity!, Icons.location_on_outlined),
```

- [ ] **Step 5: Replace the TextFormField for city in the edit form**

Find (around line 500):
```dart
_sectionLabel('CITY'),
const SizedBox(height: 6),
TextFormField(
  controller: _cityController,
  style: GoogleFonts.inter(
      fontSize: 14, color: AppColors.onBackground),
  decoration: _fieldDecoration('Your city'),
),
```

Replace with:
```dart
PakistanCityField(
  initialValue: _selectedCity,
  onChanged: (v) => setState(() => _selectedCity = v),
),
```

- [ ] **Step 6: Update the save handler**

Find (around line 120):
```dart
city: _cityController.text,
```

Replace with:
```dart
city: _selectedCity ?? '',
```

- [ ] **Step 7: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/features/dashboard/pages/profile_page.dart
git commit -m "feat: use PakistanCityField in profile edit form"
```

---

## Task 6: Wire up seller_apply_page.dart

**Files:**
- Modify: `lib/features/seller_apply/pages/seller_apply_page.dart`

**Context:** `_cityCtrl` declared at line 30, disposed at line 78, prefilled in `_prefillFromProfile()` at line 70 (called from `initState`), rendered as `AuthTextField` around line 397, used in submit at line 176. The form uses a two-column layout (`twoCol`) — city must be pulled out of the `fields` list and rendered full-width.

- [ ] **Step 1: Remove `_cityCtrl` and add `_selectedCity` state variable**

Remove the declaration:
```dart
final _cityCtrl = TextEditingController();
```

Add in its place:
```dart
String? _selectedCity;
```

Remove the dispose call:
```dart
_cityCtrl.dispose();
```

- [ ] **Step 2: Add the import**

```dart
import '../../../core/widgets/pakistan_city_field.dart';
```

- [ ] **Step 3: Update `_prefillFromProfile()`**

Find this single line (around line 70):
```dart
if (city != null && city.isNotEmpty) _cityCtrl.text = city;
```

Replace with:
```dart
if (city != null && city.isNotEmpty) _selectedCity = city;
```

Note: this is a plain field assignment (no `setState`). It runs inside `initState`, before the first build. `setState` is not needed — Flutter reads the field value on first render.

- [ ] **Step 4: Replace the AuthTextField for city and fix the two-column layout**

The current form builds `fields` as a list of 4 widgets and uses `twoCol` to arrange them in pairs. City (`fields[3]`) must now always be full-width.

Find the section that builds the fields list and the `twoCol` branch (around lines 365–421). The city `AuthTextField` is the last item in the `fields` list. Restructure as follows:

Remove the city `AuthTextField` from the `fields` list (leave only display name, phone, and WhatsApp as `fields[0]`, `fields[1]`, `fields[2]`).

Add a `cityField` variable before the `twoCol` branch:
```dart
final cityField = PakistanCityField(
  initialValue: _selectedCity,
  onChanged: (v) => setState(() => _selectedCity = v),
  required: true,
);
```

Replace the `twoCol` branch:
```dart
if (twoCol) {
  return Column(
    children: [
      _twoColRow(fields[0], fields[1]),   // Full Legal Name + CNIC Number
      const SizedBox(height: 28),
      fields[2],                           // Phone Number — full-width, no pair
      const SizedBox(height: 28),
      cityField,                           // always full-width
    ],
  );
}
return Column(
  children: [
    ...fields.expand((f) => [f, const SizedBox(height: 28)]),
    cityField,
  ],
);
```

- [ ] **Step 5: Update the submit handler**

Find (around line 176):
```dart
city: _cityCtrl.text,
```

Replace with:
```dart
city: _selectedCity ?? '',
```

- [ ] **Step 6: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/seller_apply/pages/seller_apply_page.dart
git commit -m "feat: use PakistanCityField in seller application form"
```

---

## Task 7: Smoke-test on device / emulator

- [ ] **Step 1: Run the app**

```bash
flutter run
```

- [ ] **Step 2: Verify registration form**
  - Navigate to registration
  - City field shows a dropdown, not a text box
  - Selecting a city works
  - Selecting "Other..." shows a free-text field below
  - Submitting with a selected city saves correctly

- [ ] **Step 3: Verify profile edit form**
  - Log in, go to Dashboard → Profile
  - Edit mode: city shows dropdown pre-selected with existing value (or "Other..." + text for non-standard values)
  - Read-only mode: city row still displays correctly
  - Saving updates the profile

- [ ] **Step 4: Verify seller application form**
  - Navigate to seller application
  - City is required — submitting without it shows "City is required"
  - On wide screens, city is always full-width (not squeezed into a two-column pair)

- [ ] **Step 5: Final commit if any smoke-test fixes were needed**

```bash
git add -A
git commit -m "fix: smoke-test corrections for city dropdown"
```
