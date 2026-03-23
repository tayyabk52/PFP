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
  required String? initialValue,              // pre-selects from list or sets Other+text
  required void Function(String?) onChanged,  // emits city string or null (never empty string)
  String label = 'CITY',                      // uppercase label above the field
  bool required = false,                      // if true, blocks empty submission
})
```

**Internal state:**
- `String? _selected` — the chosen dropdown value (one of the city list items, or `'Other...'`)
- `String _otherText` — the manually typed city when `_selected == 'Other...'`, initialised to `''`

**Initialisation logic (in `initState`):**
- If `initialValue` is in the curated list → `_selected = initialValue`
- If `initialValue` is non-null and not in the list → `_selected = 'Other...'`, `_otherText = initialValue`
- If `initialValue` is null → `_selected = null`

**What `onChanged` emits — always `String?`, never empty string:**
- `_selected` is a curated city → emits `_selected`
- `_selected == 'Other...'` and `_otherText.trim()` is non-empty → emits `_otherText.trim()`
- `_selected == 'Other...'` and `_otherText.trim()` is empty → emits `null`
- Dropdown cleared → emits `null`

This ensures pages never receive `''`; they only receive a meaningful city string or `null`.

**Layout:**
1. Uppercase label rendered from the `label` parameter (e.g., `'CITY'` or `'CITY OF RESIDENCE'`)
2. `DropdownButtonFormField<String>` — see Styling section
3. When `_selected == 'Other...'`, an additional `TextFormField` appears immediately below with hint "Enter your city" and key `const Key('city_other_text_field')` — same styling as below

**Styling** (both the dropdown and the "Other..." text field, matching `AuthTextField`):
- Fill: `AppColors.surfaceContainerLow`
- Text: `GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.onBackground)`
- Label text: `GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.0, color: AppColors.textSecondary)`, followed by `SizedBox(height: 8)` before the field (matches `AuthTextField`)
- `contentPadding`: `EdgeInsets.fromLTRB(0, 14, 8, 12)` — left = 0, matching `AuthTextField` so the city field aligns horizontally with name, phone, and password fields on the same form. The dropdown arrow sits in the suffix area and does not require extra left padding.
- `border` / `enabledBorder`: `UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent))`
- `focusedBorder`: `UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 1.5))`
- `errorBorder`: `UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error, width: 1))`
- `focusedErrorBorder`: `UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error, width: 1.5))`
- `errorStyle`: `GoogleFonts.inter(fontSize: 11, color: AppColors.error)`
- `dropdownColor`: `AppColors.surfaceContainerLow` — prevents a jarring white popup on the dark-toned palette
- `DropdownMenuItem` text style: `GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.onBackground)` — matches the selected value text

**Validation:**
- The `DropdownButtonFormField` validator: when `required == true`, returns `'City is required'` if `_selected` is null.
- The "Other..." `TextFormField` validator (only shown when `_selected == 'Other...'`): when `required == true`, returns `'Please enter your city'` if `_otherText.trim()` is empty.
- When `required == false`, both validators return `null` (no error).
- Error messages surface on the specific field that is empty, so the user knows exactly what to fill in.

**Key for conditional field:**
The free-text fallback field uses `const Key('city_other_text_field')` to ensure Flutter cleans up and recreates its state cleanly when it appears/disappears rather than recycling stale form validation state.

---

## Page Changes

### register_page.dart
- Remove `_cityCtrl` (`TextEditingController`) and its `dispose()` call
- Add `String? _selectedCity` field to the `State` class
- Replace `AuthTextField` for city with:
  ```dart
  PakistanCityField(
    label: 'CITY OF RESIDENCE',
    initialValue: null,
    onChanged: (v) => setState(() => _selectedCity = v),
  )
  ```
- Update submit handler: use `city: _selectedCity` instead of `city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim()`

### profile_page.dart
- Remove `_cityController` (`TextEditingController`) and its `dispose()` call
- Add `String? _selectedCity` field to the `State` class
- In `_populateFields(Map<String, dynamic>? profile)` (the existing method at ~line 49), set `_selectedCity = profile['city'] as String?` — this method is called inside `build()` via a `ref.listen` / `AsyncValue` pattern so `setState` is safe there
- Update the read-only view guard (~line 438): change `_cityController.text.isNotEmpty` → `(_selectedCity ?? '').isNotEmpty`
- Replace `TextFormField` for city with:
  ```dart
  PakistanCityField(
    initialValue: _selectedCity,
    onChanged: (v) => setState(() => _selectedCity = v),
  )
  ```
- Update save handler: use `city: _selectedCity ?? ''` instead of `city: _cityController.text`

### seller_apply_page.dart
- Remove `_cityCtrl` (`TextEditingController`) and its `dispose()` call
- Add `String? _selectedCity` field to the `State` class
- In `_prefillFromProfile()` (the existing method called from `initState`), set `_selectedCity = profile['city'] as String?` as a **plain field assignment, not wrapped in `setState`**. `initState` runs before the first build; `setState` from `initState` throws. Since `_selectedCity` is declared as a field, assigning it before the first build is sufficient — Flutter will read the correct value on first render.
- Replace `AuthTextField` for city with:
  ```dart
  PakistanCityField(
    initialValue: _selectedCity,
    onChanged: (v) => setState(() => _selectedCity = v),
    required: true,
  )
  ```
- Update submit handler: use `city: _selectedCity ?? ''` instead of `city: _cityCtrl.text`

**Two-column layout note (seller_apply_page.dart):**
The existing form has 4 fields (`fields[0..3]`) laid out as two `_twoColRow` pairs. City is currently `fields[3]`, paired with phone (`fields[2]`).

After the refactor, `PakistanCityField` conditionally grows to show a second text field below the dropdown when "Other..." is selected. Pairing it in a column alongside phone would cause unequal heights and potential overflow. City must always be full-width.

Remove city from the `fields` list (leaving `fields[0..2]` for display name, phone number, and WhatsApp). Build the layout as follows:

```dart
if (twoCol) {
  return Column(children: [
    _twoColRow(fields[0], fields[1]),   // display name + phone number
    const SizedBox(height: 28),
    fields[2],                           // WhatsApp — full-width, no pair
    const SizedBox(height: 28),
    cityField,                           // PakistanCityField — always full-width
  ]);
}
// Single-column: all fields + cityField at end, each separated by SizedBox(height: 28)
```

---

## Validation Summary

| Page | City required? | Error message |
|---|---|---|
| Registration | No | — |
| Profile edit | No | — |
| Seller application | Yes | "City is required" (dropdown) / "Please enter your city" (Other text field) |

---

## Data Integrity

- Cities from the curated list are stored as-is (canonical spelling)
- "Other..." cities are stored as typed by the user (trimmed); never stored as empty string
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
