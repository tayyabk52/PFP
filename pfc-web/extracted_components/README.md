# Extracted Components — Sidebar + Browse Page

Two self-contained UI modules extracted from GCEH frontend, ready to drop into any marketplace project.

---

## File Map

```
extracted_components/
│
├── sidebar.css                        ← CSS tokens, hairline utilities, typography
│
├── types/
│   └── listing.ts                     ← All types needed by the Browse page
│
├── lib/
│   ├── utils.ts                       ← cn() utility (clsx + tailwind-merge)
│   └── geo.ts                         ← PostGIS EWKB ↔ {lat,lng} converters
│
├── hooks/
│   └── useMediaQuery.ts               ← useIsMobile / useIsTablet / useIsDesktop
│
├── stores/
│   ├── uiStore.ts                     ← Sidebar collapse + theme state (Zustand)
│   └── listingStore.ts                ← Search filters + results state (Zustand)
│
├── services/
│   └── listingService.ts              ← Data access layer (Supabase)
│
├── components/
│   ├── DashboardSidebar.tsx           ← Sidebar: mobile drawer + desktop collapsible
│   ├── Logo.tsx                       ← Brand logo (Leaf icon + name)
│   ├── ListingCard.tsx                ← Marketplace item card
│   ├── ui/
│   │   ├── sheet.tsx                  ← Radix UI Sheet (mobile drawer)
│   │   ├── button.tsx                 ← shadcn Button
│   │   └── avatar.tsx                 ← shadcn Avatar
│   └── map/
│       └── MapView.tsx                ← Google Maps with custom markers + InfoWindow
│
├── layouts/
│   └── DashboardLayout.tsx            ← Auth-gated wrapper; renders sidebar + Outlet
│
└── pages/
    └── BrowsePage.tsx                 ← Full browse page (filters + list + map)
```

---

## Fonts

Both components use two Google Fonts. Add these to your HTML `<head>`:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700;800&family=Cormorant+Garamond:ital,wght@0,300;0,400;0,600;1,300;1,400&display=swap" rel="stylesheet">
```

| Font | Used as | Role |
|------|---------|------|
| **Syne** | `font-sans` | Body, labels, nav, filter text |
| **Cormorant Garamond** | `font-serif` | Headings, italic accents |

---

## Module 1 — Sidebar

### Behaviour

| Context | Behaviour |
|---------|-----------|
| Mobile `≤767px` | Fixed 56px header with logo + hamburger. Tap to open a left Sheet drawer (75% width, max 384px). |
| Desktop `≥768px` | Fixed left sidebar. Collapses **256px → 64px** via toggle in user badge. State persisted to `localStorage`. |
| Transition | `transition-all duration-200` on width; matching `transition-[margin-left]` on content area. |

### npm dependencies (sidebar)

```jsonc
"@radix-ui/react-avatar": "*",
"@radix-ui/react-dialog": "*",
"@radix-ui/react-slot": "*",
"class-variance-authority": "*",
"clsx": "*",
"lucide-react": "*",
"react-router-dom": "*",
"tailwind-merge": "*",
"zustand": "*"
```

### Adapting the Sidebar

**1. Replace `ROUTES`**
`DashboardSidebar.tsx` imports `ROUTES` from `@/constants`. Swap with your route strings:
```ts
// Before
{ to: ROUTES.DASHBOARD, label: 'Dashboard', icon: LayoutDashboard, end: true },
// After
{ to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard, end: true },
```

**2. Replace `useAuth`**
Minimum shape required by the sidebar:
```ts
const { profile, isModerator, logout, session } = useAuth()
// profile.avatar_url, profile.display_name, session.user.id
```

**3. Remove `NotificationBell`**
The mobile header renders `<NotificationBell userId={userId} />`. This is project-specific.
Either plug in your own or delete the import and JSX line.

**4. Replace `LoadingSpinner`**
`DashboardLayout.tsx` uses `<LoadingSpinner size="lg" />`. Swap or remove.

**5. Fix `uiStore` storage key**
```ts
// uiStore.ts — replace STORAGE_KEYS.THEME with:
name: 'ui-store',
```

**6. Fix `Theme` type**
```ts
// Replace: import type { Theme } from '@/types'
type Theme = 'light' | 'dark'
```

**7. `dashboard-light` CSS class**
Applied on the layout wrapper. Scopes light-theme tokens inside the dashboard even when
the site body is in dark mode. Remove if your project is always light.

---

## Module 2 — Browse Page

### Behaviour

| Context | Behaviour |
|---------|-----------|
| Mobile `≤1023px` | Two tabs at the top: **Directory** / **Map**. Tap Map to reveal the full-screen map. Tap Filters pill in search bar to expand the filter panel. |
| Desktop `≥1024px` | Fixed left panel (440px / 520px on xl) with filters + scrollable results list. Right panel fills remaining width with the live map. |
| Search | Debounced (300ms) keyword search. Results update automatically. |
| Filters | Type tabs (always visible) · Category · Sort · Distance radius slider · Condition (goods only) · Reset button |
| Map sync | Clicking a map marker highlights the corresponding card and scrolls it into view. |
| Empty state | Illustrated empty state with a "Clear All Filters" button when no results match. |

### Layout mechanics

```
Mobile (<lg):
┌───────────────────────────┐  ← calc(100dvh - 3.5rem)
│  [Directory] [Map]  tabs  │    (subtracts 56px fixed mobile header)
├───────────────────────────┤
│  Search  [Filters ●]      │
│  [All][Goods][Services]…  │
│─ filters (collapsible) ───│
│  scrollable results list  │
└───────────────────────────┘
   (Map panel: absolute, h-0, invisible until Map tab is tapped)

Desktop (≥lg):
┌──────────────────┬────────────────────────────┐  ← 100dvh
│  Browse Listings │                            │
│  ─────────────── │                            │
│  [search bar]    │      Google Map            │
│  [type tabs]     │      (flex-1)              │
│  ─ filters ───── │                            │
│  scrollable list │                            │
│  440–520px wide  │                            │
└──────────────────┴────────────────────────────┘
```

### npm dependencies (browse page)

```jsonc
// In addition to sidebar deps above:
"@vis.gl/react-google-maps": "*",   // Google Maps React wrapper
"zustand": "*"                       // already listed above
```

### Environment variable

```env
VITE_GOOGLE_MAPS_API_KEY=your_key_here
```

Enable these APIs in Google Cloud Console:
- Maps JavaScript API
- Places API (optional, for address autocomplete)

Also create a **Map ID** (Maps Platform → Map IDs) and paste it into `MapView.tsx`:
```ts
const MAP_ID = 'YOUR_MAP_ID'
```

### Adapting the Browse Page

**1. Replace `DEFAULT_CENTER` and store defaults**
In both `BrowsePage.tsx` and `listingStore.ts`:
```ts
const DEFAULT_CENTER = { lat: YOUR_LAT, lng: YOUR_LNG }

// listingStore.ts defaultFilters:
lat: YOUR_LAT,
lng: YOUR_LNG,
```

**2. Replace listing types / tabs**
`LISTING_TYPES` drives the type tabs. Rename to match your domain:
```ts
const LISTING_TYPES = [
  { label: 'All',      value: null },
  { label: 'Products', value: 'product' },
  { label: 'Services', value: 'service' },
]
```
Update the `ListingType` union in `types/listing.ts` to match.

**3. Replace `listingService.searchNearby`**
The service calls a Supabase RPC (`search_listings_nearby`). To use a different backend,
replace the function body while keeping the same return type (`ListingSearchResult[]`):
```ts
async searchNearby(params: SearchNearbyParams): Promise<ListingSearchResult[]> {
  const res = await fetch(`/api/items?lat=${params.lat}&lng=${params.lng}&r=${params.radiusKm}`)
  return res.json()
}
```

**4. Replace `listingService.getCategories`**
Returns `CategoryWithChildren[]`. Swap the Supabase query with any tree-shaped category API.

**5. Replace image URL helper**
In `ListingCard.tsx`:
```ts
const STORAGE_BASE_URL = 'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/listings'
// or:
const STORAGE_BASE_URL = 'https://cdn.yourproject.com/images'
```

**6. Remove geo utilities if not using PostGIS**
`parseGeoPoint` in `lib/geo.ts` handles hex EWKB strings from PostGIS.
If your API returns plain `{ lat, lng }` objects, `parseGeoPoint` still works — pass it through unchanged.
If your API returns GeoJSON, it also works. Only remove if your data never needs conversion.

**7. Replace `useAuth` (browse page)**
The page only needs `profile.display_location` (for map center) and `profile.id` (for userId filter).
If your user object has coordinates elsewhere, update the `mapCenter` useMemo:
```ts
const mapCenter = useMemo(() => {
  return { lat: user.lat, lng: user.lng } ?? DEFAULT_CENTER
}, [user])
```

---

## CSS Setup

Copy `sidebar.css` into your global stylesheet (or `@import` it). At minimum you need:

- CSS custom properties (`:root`, `.dark`, `.dashboard-light`)
- Hairline border utilities (`.hairline-b`, `.hairline-t`, `.hairline-r`)
- Font-family declarations

The Browse page uses plain Tailwind classes (white backgrounds, `slate-*` text, `black/10` borders) —
no custom CSS classes beyond the hairlines defined in `sidebar.css`.

---

## Tailwind Config

Standard shadcn/ui color mapping required by the sidebar:

```js
// tailwind.config.js / tailwind.config.ts
theme: {
  extend: {
    colors: {
      background:  'hsl(var(--background))',
      foreground:  'hsl(var(--foreground))',
      primary: {
        DEFAULT:    'hsl(var(--primary))',
        foreground: 'hsl(var(--primary-foreground))',
      },
      muted: {
        DEFAULT:    'hsl(var(--muted))',
        foreground: 'hsl(var(--muted-foreground))',
      },
      accent: {
        DEFAULT:    'hsl(var(--accent))',
        foreground: 'hsl(var(--accent-foreground))',
      },
      destructive: {
        DEFAULT:    'hsl(var(--destructive))',
        foreground: 'hsl(var(--destructive-foreground))',
      },
      border: 'hsl(var(--border))',
      input:  'hsl(var(--input))',
      ring:   'hsl(var(--ring))',
    },
  },
}
```

The Browse page does not use CSS variables — it uses literal Tailwind colors (`white`, `slate-*`, `black/10`) so no extra config is needed for that module.

---

## Wiring it Together (quick-start)

```tsx
// App.tsx / router
import { DashboardLayout } from './layouts/DashboardLayout'
import { BrowsePage }      from './pages/BrowsePage'

<Route element={<DashboardLayout />}>
  <Route path="/browse" element={<BrowsePage />} />
</Route>
```

The `DashboardLayout` renders `<DashboardSidebar />` and the content area that syncs its
left margin with the sidebar's collapsed/expanded state. `<BrowsePage />` fills the remaining
space at `100dvh` on desktop and `calc(100dvh - 3.5rem)` on mobile (accounting for the
fixed mobile header rendered by the sidebar).
