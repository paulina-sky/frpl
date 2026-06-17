# Build Prompt: Personal Perfume Tracker App (iOS, React Native / Expo)

## Overview

Build a personal perfume collection and wishlist tracker for iOS, built with React Native and Expo. The app is designed for use on the go — in boutiques, department stores, at a counter — so interactions must be fast, friction-free, and thumb-friendly. Think of it as Notes.app but for fragrance. The target user is a serious collector who wants to organise lists, capture impressions in the moment, and avoid over-collecting by tracking what they already own.

---

## Tech Stack

- **Framework:** React Native + Expo (iOS only, targeting iPhone)
- **Backend / Database:** Supabase (auth, Postgres, storage for images)
- **Language:** English only
- **Perfume data source:** Kaggle fragrance dataset bundled at build time as a local SQLite database (see Perfume Database section below); manual entry for anything not found
- **No paid or external API integrations** (no Fragrantica, no third-party fragrance API)

---

## Information Architecture

The app has three fixed top-level sections plus user-created ones:

| Section | Description |
|---|---|
| **Owned** | Perfumes the user already possesses |
| **To Try** | Wish list / discovery list |
| **Favourite Notes** | Organised around olfactive preferences, ingredients, accords |

Users can also **create their own top-level categories** (e.g. "Gift Ideas", "Vintage", "Travel Bag").

### Lists

- Each section can contain **multiple named lists**
- Each list can have **up to 2 levels of sub-lists** (max depth: parent → child → grandchild)
- Each list can have a **cover image** (uploaded from camera roll or pasted as a web image URL)
- A perfume may appear in **multiple lists** simultaneously — this is by design

---

## Core Interactions

All interactions must be optimised for one-handed mobile use. Speed and simplicity are the primary UX values.

### List Management
- Create, rename, and delete lists
- Assign a cover image to any list (image upload or URL paste)
- Create sub-lists (max 2 levels deep)

### Perfume Management within a List
- **Add a perfume:** search the local database; if not found, add manually (see Manual Entry below)
- **Drag and drop** to reorder perfumes within a list
- **Sort** by: date added, name, brand name, release date
- **Remove** a perfume from a list (without deleting it globally)
- **Delete** an entire list

### Per-Perfume Tags (Visual Priority)
Each perfume on a list can be tagged with:
- 🔴 **To Get** — highlighted in red; visually elevated in the list
- 🔵 **Travel Size** — highlighted in blue; visually elevated in the list

Tagged items should appear visually distinct from untagged ones, with higher visual weight. They do not need to sort to the top automatically — visual emphasis is sufficient.

---

## Perfume Detail Drawer

Tapping a perfume opens a **contextual drawer** (slides up from the bottom — do not navigate away from the list). The drawer contains:

### Fields
| Field | Type |
|---|---|
| Name | Text (from DB or manual) |
| House / Brand | Text |
| Perfumer | Text |
| Release Year | Year picker |
| Accords | Multi-select tags (e.g. woody, floral, citrus, musky) |
| Notes Pyramid | Three fields: Top / Heart / Base (free text or tag input) |
| Price Paid | Currency field |
| Price Target | Currency field |
| Notes | Free text, multi-line (user's personal impressions, reminders, context) |
| Reminds Me Of | Free text (e.g. "smells like my grandmother's coat", or another perfume name) |
| Photo | Uploaded image or URL paste |

### Similar Scents
- User can link one or more **similar perfumes** to this entry
- The goal is to flag redundancy in the collection — if a user already owns something with a near-identical profile, they should know before buying
- When a user links a similar scent that already exists in their **Owned** list: show a **non-intrusive suggestion** ("You already own something similar") — do not block or warn aggressively, just surface the information

---

## Perfume Database

### Primary source: Kaggle dataset (bundled, offline)

Use the publicly available **Fragrantica dataset on Kaggle** (`olgagmiufana1/fragrantica-com-fragrance-dataset`) as the app's primary perfume catalogue. This dataset contains tens of thousands of perfumes with the following fields already structured and cleaned:

| Field | Notes |
|---|---|
| `name` | Perfume name |
| `brand` | House / brand name |
| `perfumer_1`, `perfumer_2` | Up to two perfumers |
| `year` | Release year |
| `top_notes` | Parsed note list |
| `middle_notes` | Parsed note list |
| `base_notes` | Parsed note list |
| `main_accord_1–5` | Primary scent families / accords |
| `gender` | Marketed gender (men / women / unisex) |
| `rating_value` | Community rating |
| `url` | Source URL (useful for reference, not displayed in-app) |

**Implementation:** At build time, convert the CSV into a **SQLite database** bundled with the app (using `expo-sqlite`). This allows fast full-text search across 10,000+ entries with zero network dependency — the search works completely offline.

The internal schema for the bundled DB should match the drawer fields:

```json
{
  "id": "string",
  "name": "Santal 33",
  "house": "Le Labo",
  "perfumers": ["Frank Voelkl"],
  "release_year": 2011,
  "accords": ["sandalwood", "cedar", "leather", "violet"],
  "notes": {
    "top": ["cardamom", "iris"],
    "heart": ["violet", "ambrette"],
    "base": ["sandalwood", "cedarwood", "leather"]
  },
  "source": "dataset"
}
```

### Search behaviour

When a user adds a perfume to a list, they type a name. The app searches the bundled SQLite DB and returns matches ranked by relevance (name match first, then brand). Results show: name, house, release year.

If the user selects a result, all available fields auto-populate in the detail drawer. The user can edit any pre-filled field.

If no result is found, or the user prefers to enter manually, a clear **"Add manually"** option is always visible at the bottom of search results — never buried.

### Manual entry (fallback)

When a perfume is not in the dataset (obscure, very new, or highly limited releases):

- User taps **"Add manually"** from the search screen
- A simple form appears with all drawer fields available to fill in freely
- Only **name** is required; all other fields are optional
- Photo can be added via image upload or URL paste
- Manually added entries are saved to Supabase and marked with `"source": "manual"` — they are fully editable at any time and indistinguishable from dataset entries in the UI

---

## Visual Design Direction

The designer should propose a visual identity that feels specific to the world of fragrance — not generic lifestyle or beauty app defaults. Some principles to anchor from:

- Fragrance sits at the intersection of **luxury, sensory memory, and obsessive personal taste** — the design should carry that
- The app is used in boutiques and stores, so the UI must be **legible and calm under ambient lighting**, not visually noisy
- The experience should feel **editorial and considered**, but not cold — there's a personal, obsessive quality to collecting perfume that the design can reflect
- Avoid: generic wellness pastel, Pantone-of-the-year dusty rose, cold Notion-clone white, and standard sans-serif brutalism

Suggested axes to explore (pick one and commit):
- A very restrained **warm neutral** base (not cream, something more particular — think aged paper, parchment, milky stone) with one sharp accent colour pulled from something specific in the olfactive world (e.g. amber resin, dried iris, smoked oak)
- **Deep, saturated dark mode** with luminous type — the way a perfume counter looks under boutique lighting
- **High-contrast, typographically-led** design inspired by fragrance advertising from the 80s/90s — lots of negative space, very deliberate type pairings

The signature element should be something that could only belong to this app — not a gradient card or icon grid. Think about how fragrance houses use design to evoke sensation.

Typography: use a **display serif** with real personality for headings and a **clean, compact sans-serif** for UI and data. The type system should feel considered, not defaulted.

---

## Navigation Structure

```
Tab Bar (bottom):
├── Library (sections: Owned / To Try / Favourite Notes / custom)
├── Search (search across all perfumes in all lists)
└── Settings (account, sync status, backup)

Library screen:
├── Section header
├── List cards (with cover image, name, item count)
│   └── Tap → List view (perfumes, sortable, draggable)
│       └── Tap perfume → Detail drawer (slides up)
```

---

## Data & Sync

- **Supabase** for all persistent storage: user lists, perfume entries, drawer fields, images
- Images stored in Supabase Storage; URLs saved to the database
- App should work **offline** with local cache; sync when connection is restored
- Single-user, private — no multi-user features needed at launch

---

## Share Feature

Any list can be shared as a **public read-only link**.

### How it works
- A share icon appears on every list (in the list header or list card context menu)
- Tapping it generates a unique public URL via Supabase and **copies it to the clipboard** automatically
- A brief confirmation toast appears: "Link copied" — no modal, no extra steps
- The user pastes the link anywhere (WhatsApp, iMessage, Notes, email)

### Shared web view
The link opens a **hosted read-only web page** (not requiring the app). Design requirements:

- Clean, minimal layout — optimised for mobile browser but readable on desktop
- Displays: list name, cover image (if set), and each perfume entry with its photo (if available), house/brand, name, and any active tags (To Get / Travel Size)
- Does **not** expose private fields: price paid, price target, personal notes, "Reminds Me Of"
- No login required, no app download prompt
- The visual style should be consistent with the app — same type system, same palette, same editorial quality
- Should feel like a shareable page from a well-designed product, not a database dump

### Technical notes
- Generate a stable UUID-based URL per list (e.g. `/list/abc123`)
- Lists are public-read by default once a link is generated; no expiry needed at launch
- Supabase Row Level Security should allow unauthenticated read access to shared list data only

---

## Quality Bar

- Every interaction on the list screen (add, reorder, tag, delete) should be achievable with **one hand and no more than 2 taps**
- The drawer should open and close with a **swipe gesture**
- Empty states should be friendly and direct — not decorative
- Errors must explain what happened and what to do
- The app must handle a list of 200+ perfumes without visible performance degradation
