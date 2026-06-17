# FRPL — Setup Guide
## From prototype to live app on your phone in ~20 minutes

---

### What's already done
- The full app UI is built (`FRPL.dc.html`)
- The perfume catalogue is ready (`data/perfumes.json` — 24,063 fragrances)
- Your Supabase credentials are wired into the app

---

### Step 1 — Run the database schema (5 min)

1. Go to [supabase.com](https://supabase.com) → your project
2. Click **SQL Editor** → **New query**
3. Paste the entire contents of `setup/schema.sql`
4. Click **Run**

You'll get 4 tables (`profiles`, `categories`, `lists`, `list_entries`) with row-level security.
Default categories (Owned / To Try / Favourite Notes) are created automatically when you first sign in.

---

### Step 2 — Configure auth redirect URLs (2 min)

1. In Supabase: **Authentication** → **URL Configuration**
2. Set **Site URL** to your deployed app URL (e.g. `https://frpl.vercel.app`)
3. Under **Redirect URLs**, add:
   - `https://your-app.vercel.app/**`
   - `http://localhost:3000/**` (for local testing)

> If you haven't deployed yet, you can add the URL after Step 3 and update it.

---

### Step 3 — Deploy (5 min)

**Option A — Vercel (recommended)**
1. Go to [vercel.com](https://vercel.com) → New Project
2. Drag and drop your project folder (or connect GitHub)
3. Deploy → copy the URL

**Option B — Netlify**
1. Go to [netlify.com](https://netlify.com) → Add new site → Deploy manually
2. Drag and drop the project folder
3. Deploy → copy the URL

> The `data/perfumes.json` file (12 MB) will be served as a static asset and cached by the service worker after the first load. Subsequent opens are instant.

---

### Step 4 — Install on your iPhone (2 min)

1. Open the deployed URL in **iPhone Safari** (must be Safari, not Chrome)
2. Tap the **Share** icon (box with arrow)
3. Tap **Add to Home Screen**
4. Name it `FRPL` → tap **Add**
5. Launch from your home screen — it opens full-screen with no browser chrome

---

### Step 5 — Sign in

1. Enter your email → tap **Send magic link**
2. Check your inbox → tap the link
3. You're signed in — your default categories are ready, start adding perfumes

---

### Notes

- **Catalogue**: 24,063 fragrances from Fragrantica via Kaggle. For personal use only — do not make the app public.
- **Images**: bottle photos load from Fragrantica's CDN (`fimgs.net`). They work fine in a personal/private context.
- **Offline**: after the first load, the catalogue and app shell are cached. You can browse and view your library offline; adding/editing requires a connection.
- **Sync**: your lists sync to Supabase in real time across any device you sign in on.
- **Personal notes, prices**: shown in the perfume drawer when opened from a list. Editing is the next feature to build.

---

### Architecture summary

| Layer | What | Where |
|---|---|---|
| Catalogue | 24k perfumes (read-only) | Local JSON, cached by service worker |
| User data | Lists, entries, categories | Supabase Postgres (your account) |
| Auth | Magic link (passwordless) | Supabase Auth |
| Hosting | Static files | Vercel / Netlify |
| App format | PWA (installable) | iPhone Safari → Add to Home Screen |
