# Pakistan City Dropdown — Design Spec

**Date:** 2026-03-23
**Status:** Approved

---

## Problem

City of residence is a free-text field in three forms (registration, profile edit, seller application). This allows arbitrary input, polluting the database with inconsistent values ("Lhr", "lahore", "LAHORE", unknown strings).

## Goal

Replace free-text city input with a controlled dropdown of major Pakistani cities, while still allowing users to enter an unlisted city via an "Other..." escape hatch.

---

## Affected Pages

| Page | File | Current Input |
|---|---|---|
| Registration | `lib/features/auth/pages/register_page.dart` | `AuthTextField` with `_cityCtrl` |
| Profile Edit | `lib/features/dashboard/pages/profile_page.dart` | `TextFormField` with `_cityController` |
| Seller Application | `lib/features/seller_apply/pages/seller_apply_page.dart` | `AuthTextField` with `_cityCtrl` |

---

## Approach

**Static curated list + "Other..." escape hatch.**

- A `const List<String>` of ~50 major Pakistani cities lives in `lib/core/constants/pakistan_cities.dart`, sorted alphabetically.
- The list ends with a sentinel value `'Other...'`.
- A single shared widget `PakistanCityField` (`lib/core/widgets/pakistan_city_field.dart`) encapsulates the full interaction: dropdown + conditional free-text field.

No new pub.dev packages required.

---

## City List

`lib/core/constants/pakistan_cities.dart` — approximately 50 entries covering all provinces and major population centres, alphabetically sorted, with `'Other...'` as the last item.

Representative entries: Abbottabad, Bahawalpur, Faisalabad, Gujranwala, Gujrat, Hyderabad, Islamabad, Karachi, Kasur, Khanewal, Lahore, Larkana, Mardan, Mirpur Khas, Multan, Muzaffarabad, Nawabshah, Okara, Peshawar, Quetta, Rahimyar Khan, Rawalpindi, Sahiwal, Sargodha, Sheikhupura, Sialkot, Sukkur, Wah Cantt, and others.

---

## Shared Widget: `PakistanCityField`

**Location:** `lib/core/widgets/pakistan_city_field.dart`

**Type:** `StatefulWidget`

**Interface:**
```dart
PakistanCityField({
  required String? initialValue,   // pre-selects from list or sets Other+text
  required void Function(String?) onChanged,  // called with city string or null
  String? Function(String?)? validator,       // optional form validation
  bool required = false,           // if true, validator blocks empty submission
})
```

**Internal state:**
- `String? _selected` — the chosen dropdown value (one of the city list items, or `'Other...'`)
- `String? _otherText` — the manually typed city when `_selected == 'Other...'`

**Initialisation logic:**
- If `initialValue` is in the curated list → `_selected = initialValue`
- If `initialValue` is non-null and not in the list → `_selected = 'Other...'`, `_otherText = initialValue`
- If `initialValue` is null → `_selected = null`

**What `onChanged` emits:**
- `_selected != 'Other...'` → emits `_selected`
- `_selected == 'Other...'` → emits `_otherText` (the typed string, may be empty)
- Dropdown cleared → emits `null`

**Layout:**
1. Uppercase label "CITY OF RESIDENCE" (or "CITY" depending on context — passed as optional `label` param, defaulting to `'CITY'`)
2. `DropdownButtonFormField<String>` styled to match `AuthTextField`: `surfaceContainerLow` fill, `UnderlineInputBorder`, transparent enabled border, `AppColors.primary` focused underline (1.5px), Inter 15px medium text
3. When `_selected == 'Other...'`, a second `TextFormField` appears below (same styling) with hint "Enter your city" — this is the free-text fallback

**Styling constants** (inline, matching `AuthTextField`):
- Fill: `AppColors.surfaceContainerLow`
- Text: `GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.onBackground)`
- Label: `GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.0, color: AppColors.textSecondary)`
- Borders: same `UnderlineInputBorder` pattern as `AuthTextField`

---

## Page Changes

### register_page.dart
- Remove `_cityCtrl` (`TextEditingController`)
- Add `String? _selectedCity` state variable
- Replace `AuthTextField` for city with `PakistanCityField(initialValue: null, onChanged: (v) => setState(() => _selectedCity = v))`
- Update submit handler: use `_selectedCity` instead of `_cityCtrl.text.trim()`

### profile_page.dart
- Remove `_cityController` (`TextEditingController`)
- Add `String? _selectedCity` initialised from `profile['city']` in `_init()`
- Replace `TextFormField` for city with `PakistanCityField(initialValue: _selectedCity, onChanged: (v) => setState(() => _selectedCity = v))`
- Update save handler: use `_selectedCity ?? ''` instead of `_cityController.text`

### seller_apply_page.dart
- Remove `_cityCtrl` (`TextEditingController`)
- Add `String? _selectedCity` initialised from `profile['city']` in `_initFromProfile()`
- Replace `AuthTextField` for city with `PakistanCityField(initialValue: _selectedCity, onChanged: (v) => setState(() => _selectedCity = v), required: true)`
- Update submit handler: use `_selectedCity ?? ''` instead of `_cityCtrl.text`

---

## Validation

- Registration: city is optional (matches existing behaviour — no validator currently)
- Profile edit: city is optional (matches existing behaviour)
- Seller application: city is required — `PakistanCityField` with `required: true` blocks submission if empty

When `_selected == 'Other...'` and `_otherText` is empty, the validator treats it the same as no city selected.

---

## Data Integrity

- Cities from the curated list are stored as-is (canonical spelling)
- "Other..." cities are stored as typed by the user (trimmed)
- Existing profile rows with non-canonical city strings will pre-select "Other..." on next profile load — no migration needed

---

## Files Created / Modified

| Action | File |
|---|---|
| Create | `lib/core/constants/pakistan_cities.dart` |
| Create | `lib/core/widgets/pakistan_city_field.dart` |
| Modify | `lib/features/auth/pages/register_page.dart` |
| Modify | `lib/features/dashboard/pages/profile_page.dart` |
| Modify | `lib/features/seller_apply/pages/seller_apply_page.dart` |
