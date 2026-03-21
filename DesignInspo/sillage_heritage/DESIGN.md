# Design System Specification: The Olfactory Archive

## 1. Overview & Creative North Star: "The Digital Curator"
This design system rejects the "commodity marketplace" aesthetic in favor of a high-end editorial experience. Our Creative North Star is **The Digital Curator**. We treat every fragrance listing like a museum acquisition and every community discussion like a private salon.

To move beyond "standard" UI, this system breaks the rigid grid through **intentional asymmetry** and **tonal depth**. We avoid the boxed-in look of traditional templates by using overlapping elements—such as a product image bleeding slightly over a container edge—and a typography scale that favors dramatic contrast between serif display headers and functional sans-serif utility text.

---

## 2. Color & Atmospheric Theory
Our palette evokes heritage through a "Dark Mode" leaning primary set, using the depth of Emerald and Charcoal to create an atmosphere of luxury.

### The Palette (Material Tokens)
*   **Primary (Deep Emerald):** `#003527` – The anchor of the brand. Use for primary actions and hero backgrounds.
*   **Secondary (Charcoal):** `#555f70` – Used for supporting UI elements and metadata.
*   **Tertiary (Gold Accent):** `#3e2b00` / `tertiary_fixed_dim: #e9c176` – Used sparingly for "Verified" badges, luxury accents, and high-level calls to action.
*   **Surface Hierarchy:** 
    *   `surface`: `#f9f9fc` (The canvas)
    *   `surface_container_low`: `#f3f3f6` (Sectioning)
    *   `surface_container_highest`: `#e2e2e5` (Deepest indentation/Nested elements)

### The "No-Line" Rule
**Explicit Instruction:** Do not use 1px solid borders to section content. Boundaries must be defined solely through background color shifts. For example, a marketplace grid should sit on `surface`, while individual cards use `surface_container_lowest` (`#ffffff`) to create a natural, borderless lift.

### Glass & Gradient Rule
To prevent a "flat" digital feel, use **Glassmorphism** for floating headers or navigation bars. Apply `surface` at 80% opacity with a `20px` backdrop-blur. For primary CTAs, apply a subtle linear gradient from `primary` (`#003527`) to `primary_container` (`#064e3b`) at a 135-degree angle to provide a velvet-like texture.

---

## 3. Typography: Editorial Authority
We pair the historical weight of **Noto Serif** with the modern precision of **Inter**.

*   **Display (L/M/S):** `notoSerif`. Use for fragrance names and major section headers. The large scale (`3.5rem` for Display-LG) creates a "Vogue-style" editorial impact.
*   **Headline & Title:** `notoSerif`. Reserved for storytelling and category titles.
*   **Body (L/M/S):** `inter`. All functional text, descriptions, and marketplace data. The clean lines of Inter ensure legibility against the sophisticated backdrop.
*   **Label:** `inter` (Uppercase with 0.05rem letter spacing). Used for "Notes," "Sillage," and "Longevity" metrics to provide a technical, encyclopedic feel.

---

## 4. Elevation & Depth: Tonal Layering
We move away from the "shadow-heavy" web. This design system uses **Tonal Layering** to convey hierarchy.

*   **The Layering Principle:** Depth is achieved by stacking. A `surface_container_low` section represents the floor. A `surface_container_lowest` card sitting on top creates a "soft lift."
*   **Ambient Shadows:** If a card requires a floating state (e.g., on hover), use a shadow color tinted with `on_surface` (`#1a1c1e`) at 5% opacity, with a blur radius of `32px`. It should feel like a soft glow, not a hard drop.
*   **The Ghost Border:** If a boundary is strictly required for accessibility (e.g., input fields), use `outline_variant` (`#bfc9c3`) at **15% opacity**. Never use 100% opaque borders.

---

## 5. Components & Signature Patterns

### Marketplace Cards
*   **Constraint:** No borders. No dividers.
*   **Style:** Use `surface_container_lowest`. The fragrance bottle image should have a subtle `2.5` (0.85rem) padding.
*   **Layout:** Asymmetric. Place the price in a `label-md` format in the top right, and the fragrance name in `title-lg` (Noto Serif) at the bottom left.

### Encyclopedia Data Tables
*   **Constraint:** Zero vertical lines.
*   **Style:** Headers in `label-sm` (Inter, Bold). 
*   **Row Separation:** Use a subtle background toggle between `surface` and `surface_container_low`. 

### Trust Badges (The "Gold" Standard)
*   **Style:** Use `tertiary_container` (`#5a4000`) with `on_tertiary_fixed` (`#261900`) text.
*   **Shape:** `full` (9999px) pill shape. These badges represent the heritage and trustworthiness of the community.

### Inputs & Fields
*   **Style:** `surface_container_low` fill. No border. On focus, transition the background to `surface_container_highest` and add a 1px "Ghost Border" of `primary`.

### Buttons
*   **Primary:** `primary` background, `on_primary` text. `DEFAULT` (0.25rem) roundedness for a sharp, professional look.
*   **Secondary:** `surface_container_high` background. No border.
*   **Tertiary:** Transparent background, `primary` text, underlined only on hover.

---

## 6. Do’s and Don'ts

### Do:
*   **Use White Space as a Tool:** Use the `16` (5.5rem) spacing token between major editorial sections to allow the design to breathe.
*   **Embrace Asymmetry:** Let images of fragrance bottles break the container's vertical alignment slightly to create a high-fashion look.
*   **Layer Surfaces:** Place `surface_container_highest` elements inside `surface_container_low` to create "wells" of information (ideal for technical fragrance notes).

### Don’t:
*   **Don't use Dividers:** Never use a horizontal rule (`<hr>`) to separate content. Use a `1.5` or `2` spacing jump or a background color shift.
*   **Don't Over-round:** Stick to `DEFAULT` (0.25rem) or `none` for cards and buttons. Avoid the "bubbly" look of `xl` or `full` except for status chips.
*   **Don't Use Pure Black:** Always use `on_background` (`#1a1c1e`) for text to maintain a soft, premium legibility.