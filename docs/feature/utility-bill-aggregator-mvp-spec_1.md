# Utility Bill Aggregator — MVP Feature Specification

**App Name (working title):** বিলবাক্স (BilBax)
**Version:** MVP 1.0
**Platform:** Flutter (Android-first)
**Design Decision:** No in-app payment processing. App redirects to official utility payment URLs. Firebase for auth/sync. SQLite for local data persistence.

---

## Core Design Principles

- **Zero payment risk** — app never touches money, never holds credentials
- **Offline-first** — core features work without internet
- **One-tap access** — deepest any bill should be is 2 taps from home
- **Local-first data** — SQLite on device, Firebase sync for multi-device (optional)

---

## Architecture Summary

```
Flutter App
├── SQLite (sqflite)          → Bill accounts, payment history, reminders
├── Firebase Auth             → User identity (phone OTP)
├── Firestore                 → Cloud sync for multi-device (optional login)
├── Firebase Cloud Messaging  → Due date push notifications
├── url_launcher              → Redirect to bKash / utility portal URLs
└── shared_preferences        → App settings, theme, onboarding state
```

No custom backend. No payment processing. No API keys to secure.

---

## Feature List

---

### Feature 1: Bill Account Management

**Purpose:** User links their utility account numbers once. App remembers them forever.

#### 1.1 Add a Bill Account

User taps "Add Bill" and fills a simple form:

| Field | Type | Required | Notes |
|---|---|---|---|
| Utility type | Dropdown | ✅ | DESCO, DPDC, WASA, Titas, Internet, BTCL |
| Account number | Text | ✅ | Consumer/account number from the bill paper |
| Nickname | Text | ❌ | e.g. "Home", "Office", "Mayer Bari" |
| Area / Zone | Text | ❌ | e.g. "Dhanmondi", "Mirpur-10" |
| Typical due date | Number (1–31) | ❌ | Day of month bill is usually due |

**Stored in SQLite locally:**
```
table: bill_accounts
- id (INTEGER PRIMARY KEY)
- utility_type (TEXT)         -- "desco", "dpdc", "wasa", "titas", "internet", "btcl"
- account_number (TEXT)
- nickname (TEXT)
- area (TEXT)
- typical_due_day (INTEGER)
- payment_url (TEXT)          -- Pre-configured redirect URL for this utility
- is_active (BOOLEAN)
- created_at (DATETIME)
- last_paid_at (DATETIME)
```

#### 1.2 Supported Utilities at Launch

| Utility | Type | Redirect Destination |
|---|---|---|
| DESCO | Electricity (Dhaka North) | DESCO self-service portal / bKash bill pay |
| DPDC | Electricity (Dhaka South) | DPDC self-service portal / bKash bill pay |
| WASA | Water | WASA online payment page |
| Titas Gas | Gas | Titas online bill portal |
| Internet (generic) | ISP | User manually enters their ISP's payment URL |
| BTCL | Landline | BTCL online portal |

#### 1.3 Edit / Delete Bill Account

- Tap any bill card → Edit icon → update any field
- Long press → Delete → confirmation dialog
- Deleted accounts move to "archived" (soft delete, restorable for 30 days)

#### 1.4 Multiple Accounts Per Utility

- No limit on number of accounts
- A landlord can add DESCO accounts for 10 different flats
- Each has its own nickname, account number, and due date

---

### Feature 2: Home Dashboard

**Purpose:** Single screen showing all bills, their status, and due dates at a glance.

#### 2.1 Bill Card

Each linked bill shows as a card:

```
┌─────────────────────────────────────────────┐
│  ⚡ DESCO                    🏠 Home         │
│  Account: 1234567890                         │
│                                              │
│  📅 Due: ১৫ অক্টোবর (১২ days left)         │
│  💰 Last paid: ৳ ১,২৪০  •  ১ Sep 2026      │
│                                              │
│  [Pay Now →]                                 │
└─────────────────────────────────────────────┘
```

**Card states:**

| State | Indicator | Condition |
|---|---|---|
| Upcoming | Blue border | Due in 7+ days |
| Due Soon | Amber border + badge | Due in 1–6 days |
| Overdue | Red border + badge | Past due date |
| Recently Paid | Green checkmark | Paid within last 5 days |
| No data | Grey | No payment history yet |

#### 2.2 Dashboard Layout

- Bills sorted by urgency: Overdue → Due Soon → Upcoming → Recently Paid
- Pull to refresh
- FAB: "+ Add Bill" shortcut
- Summary strip at top: "৳ X,XXX total due this month" (sum of last known amounts)
- Filter chips: All | Electricity | Water | Gas | Internet

#### 2.3 Monthly Summary Card

Pinned at top of dashboard:

```
┌─────────────────────────────────────────────┐
│  অক্টোবর ২০২৬                              │
│  ৬টি বিল  •  আনুমানিক ৳ ৪,৮৫০             │
│  ████████░░  ৪টি পরিশোধিত                  │
└─────────────────────────────────────────────┘
```

---

### Feature 3: Pay Now — Redirect Flow

**This is the core UX decision. No in-app payment. Simple redirect.**

#### 3.1 "Pay Now" Button Behavior

When user taps "Pay Now" on any bill card:

**Step 1 — Payment method bottom sheet appears:**
```
┌─────────────────────────────────────────────┐
│  DESCO বিল পরিশোধ করুন                     │
│  Account: 1234567890                         │
│                                              │
│  কোথায় পরিশোধ করবেন?                      │
│                                              │
│  [🟠 bKash]    [🔴 Nagad]    [🔵 DESCO App] │
│                                              │
│  [Rocket]      [Bank Transfer]               │
│                                              │
│  বাতিল                                      │
└─────────────────────────────────────────────┘
```

**Step 2 — Tapping any option:**
- App calls `url_launcher` to open the corresponding deep link or URL
- For bKash: opens bKash app (if installed) or bKash bill pay web URL
- For Nagad: opens Nagad app (if installed) or Nagad web portal
- For utility portal: opens official website in Chrome Custom Tab

**Step 3 — Back in app:**
- User returns to the app after completing payment externally
- App shows: "পরিশোধ করেছেন?" (Did you pay?)
- Two buttons: **"হ্যাঁ, পরিশোধ করেছি"** / **"না, পরে করব"**
- If confirmed: app prompts manual payment log

#### 3.2 Payment URL Configuration

Pre-configured URLs per utility × payment method, fetched from **Firebase Remote Config** on app launch — so if a URL changes, you update it in Firebase without a new app release:

```dart
// lib/config/payment_urls.dart

const Map<String, Map<String, String>> paymentUrls = {
  'desco': {
    'bkash':   'https://pay.bkash.com/bill/desco',
    'nagad':   'https://nagad.com.bd/bill/desco',
    'portal':  'https://selfservice.desco.org.bd',
    'rocket':  'https://www.dutchbanglabank.com/rocket',
  },
  'dpdc': {
    'bkash':   'https://pay.bkash.com/bill/dpdc',
    'nagad':   'https://nagad.com.bd/bill/dpdc',
    'portal':  'https://ebill.dpdc.org.bd',
    'rocket':  'https://www.dutchbanglabank.com/rocket',
  },
  'wasa': {
    'bkash':   'https://pay.bkash.com/bill/wasa',
    'portal':  'https://bill.dhakawasa.gov.bd',
  },
  'titas': {
    'bkash':   'https://pay.bkash.com/bill/titas',
    'portal':  'https://ebill.titasgas.org.bd',
  },
};
```

#### 3.3 App Not Installed Fallback

```dart
if (await canLaunchUrl(bkashDeepLink)) {
  launchUrl(bkashDeepLink);              // Open bKash app
} else {
  launchUrl(bkashWebUrl,                 // Open bKash web in Chrome Custom Tab
    mode: LaunchMode.inAppBrowserView);
}
```

---

### Feature 4: Manual Payment History Log

**Purpose:** Since the app doesn't process payments, users manually log when they've paid. This builds the history that powers reminders and analytics.

#### 4.1 Log a Payment

After user confirms "হ্যাঁ, পরিশোধ করেছি":

**Quick log form (3 fields max):**
```
Amount paid:    ৳ [________]
Transaction ID: [________]   (optional — copy from bKash/Nagad SMS)
Payment date:   [Today ▼]
```

Tap "সংরক্ষণ করুন" → saved to SQLite instantly.

**SQLite table:**
```
table: payment_history
- id (INTEGER PRIMARY KEY)
- bill_account_id (INTEGER FK)
- amount (REAL)
- transaction_id (TEXT)          -- optional, from bKash/Nagad confirmation SMS
- payment_date (DATE)
- payment_method (TEXT)          -- "bkash", "nagad", "portal", "rocket"
- note (TEXT)                    -- optional free text
- created_at (DATETIME)
```

#### 4.2 History Screen

- Per-bill history: tap any bill → "ইতিহাস" tab → chronological payment list
- All bills history: top-level History tab → grouped by month
- Shows: date, amount, method, transaction ID
- Export: "CSV ডাউনলোড" → generates CSV shareable via WhatsApp/email

#### 4.3 Edit / Delete History Entry

- Tap any entry → edit amount, date, transaction ID
- Long press → delete with confirmation
- Useful for correcting mistakes in manual logging

---

### Feature 5: Due Date Reminders

**Purpose:** Push notifications before each bill is due. Fully local — no server needed.

#### 5.1 Reminder Configuration

Per bill account, user sets:
- **Reminder timing:** 7 days before / 3 days before / 1 day before / On due date (multi-select)
- **Notification time:** default 9:00 AM (user-configurable)
- **Enable/disable:** toggle per bill

#### 5.2 How It Works

- Uses `flutter_local_notifications` — entirely on-device, no server
- On app launch, reminders re-scheduled for next 30 days based on due dates
- Firebase Cloud Messaging used only as a fallback for users who clear app data

**Notification content:**
```
🔔 DESCO বিল মনে করিয়ে দিচ্ছি
আপনার বিল ৩ দিনের মধ্যে পরিশোধ করুন।
Account: 1234567890 | আনুমানিক: ৳ ১,২৪০
[পরিশোধ করুন →]
```

Tapping notification → opens app → bill card highlighted → "Pay Now" pre-opened.

#### 5.3 Smart Due Date Estimation

If user hasn't manually set a due date:
- After 3 payment history entries, app suggests: "আপনার DESCO বিল সাধারণত ১৫ তারিখে আসে — রিমাইন্ডার সেট করবেন?"
- Logic: median of past payment dates per bill account

---

### Feature 6: Spending Analytics

**Purpose:** Simple monthly utility spend overview — powered entirely by local SQLite data.

#### 6.1 Monthly Spend Chart

- Bar chart: last 6 months total utility spend
- Breakdown by utility type (stacked or pie)
- This month vs last month comparison: "আগের মাসের চেয়ে ৳ ৩৪০ বেশি"

#### 6.2 Per-Bill Trends

Tap any bill → Analytics tab:
- Line chart: bill amount over last 12 payments
- Anomaly flag: "⚠️ এই মাসের বিল গড়ের চেয়ে ৪০% বেশি — মিটার চেক করুন"
  - Triggered when latest amount > 30% above 3-payment rolling average
- Average monthly cost shown

#### 6.3 Annual Summary

- Total utility spend for the calendar year
- Highest bill month
- Most expensive utility
- Exportable as CSV

**All analytics computed locally from SQLite — no server, no API, works offline.**

---

### Feature 7: User Accounts (Firebase Auth)

**Purpose:** Optional sign-in so users don't lose data if they change phones.

#### 7.1 Sign In Options

- **Phone OTP** (primary — most common in BD)
- **Google Sign-In** (secondary)
- **Guest mode** — full app usable without account; data stays local only

#### 7.2 What Firebase Handles

| Data | Storage | Notes |
|---|---|---|
| User identity | Firebase Auth | Phone number / Google account |
| Bill accounts | SQLite primary + Firestore backup | Sync on sign-in |
| Payment history | SQLite primary + Firestore backup | Sync on sign-in |
| Reminder settings | SQLite only | Device-local |
| App preferences | shared_preferences | Device-local |
| Payment URLs | Firebase Remote Config | Updated without app release |

#### 7.3 Sync Behavior

- On sign-in: pull Firestore data → merge with local SQLite (no overwrite)
- On payment logged: push to Firestore silently in background
- On bill added/edited: push to Firestore silently in background
- Conflict resolution: last-write-wins (simple, acceptable for MVP)

#### 7.4 Guest Mode

- All features fully functional in guest mode
- Data in SQLite only — lost if app is uninstalled
- "Sign in to back up your data" banner shown in Settings

---

### Feature 8: Landlord / Multi-Property View

**Purpose:** Serves landlords managing bills for multiple flats — no separate product needed.

#### 8.1 Property Groups

Users create named groups and assign bill accounts to them:

```
My Properties
├── 📍 Flat 4B — Mirpur
│   ├── ⚡ DESCO (account: 111222333)
│   ├── 💧 WASA (account: 444555666)
│   └── 🔥 Titas (account: 777888999)
│
└── 📍 Flat 2A — Dhanmondi
    ├── ⚡ DPDC (account: 123456789)
    └── 🌐 Internet — Amber IT
```

**SQLite tables:**
```
table: property_groups
- id (INTEGER PRIMARY KEY)
- name (TEXT)                   -- "Flat 4B — Mirpur"
- address (TEXT)
- icon (TEXT)                   -- emoji key
- created_at (DATETIME)

-- bill_accounts gets one new column:
- property_group_id (INTEGER FK, nullable)   -- null = personal/ungrouped
```

#### 8.2 Group Dashboard

Tap a property group → shows all bills for that property with combined monthly total. Useful for landlords tracking per-flat utility costs.

#### 8.3 Quick Pay All

Within a group: "সব বিল পরিশোধ করুন" → opens each bill's payment method sheet one by one in sequence.

---

### Feature 9: App Settings

| Setting | Options | Default |
|---|---|---|
| Language | বাংলা / English | বাংলা |
| Theme | Light / Dark / System | System |
| Default payment method | bKash / Nagad / Portal | bKash |
| Reminder default time | Time picker | 9:00 AM |
| Notification sound | On / Off | On |
| Backup / sync | On / Off | On (if signed in) |
| Export data | CSV | — |
| Clear all data | Confirmation dialog | — |
| About / Version | — | — |

---

## MVP Scope Boundaries

### ✅ In Scope

- Add / edit / delete bill accounts (6 utility types)
- Home dashboard with urgency-sorted bill cards
- Pay Now → redirect to bKash / Nagad / portal via url_launcher
- Manual payment confirmation and history logging
- Due date push reminders (flutter_local_notifications — no server)
- Spending analytics from local SQLite data
- Anomaly detection on bill amounts (local logic, no AI)
- Multi-property / landlord grouping
- Firebase phone OTP + Google auth (optional)
- SQLite-first storage with Firestore background sync
- CSV export of payment history
- Firebase Remote Config for payment URLs (no release needed to update URLs)

### ❌ Out of Scope (V2)

- In-app payment SDK (bKash / Nagad / SSLCommerz)
- Automatic bill amount fetching (scraping utility portals)
- Web dashboard for landlords
- Bill splitting / tenant management
- Bank account or card linking
- iOS app (Android first)
- Multiple user profiles per device
- Custom backend / Django

---

## Flutter Package Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Local database
  sqflite: ^2.3.3
  path: ^1.9.0

  # Firebase
  firebase_core: ^3.4.0
  firebase_auth: ^5.2.0
  cloud_firestore: ^5.3.0
  firebase_messaging: ^15.1.0
  firebase_remote_config: ^5.1.0

  # Auth
  google_sign_in: ^6.2.1

  # Notifications
  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4

  # Redirect to payment apps
  url_launcher: ^6.3.0

  # UI / Charts
  fl_chart: ^0.68.0
  shimmer: ^3.0.0
  intl: ^0.19.0              # Bangla date formatting

  # State management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

  # Local preferences
  shared_preferences: ^2.3.2

  # Export
  csv: ^6.0.0
  path_provider: ^2.1.4
  share_plus: ^10.0.0

  # Utils
  uuid: ^4.4.2
  connectivity_plus: ^6.0.5
```

---

## Screen Map

```
App Launch
└── Onboarding (first time only)
    └── Sign In / Skip (Guest mode)

Home (BottomNav Tab 1)
├── Monthly summary card
├── Bill cards (sorted by urgency)
├── Filter chips
├── Pay Now → Payment Method Sheet → url_launcher → External App
├── "Did you pay?" prompt → Manual Log Form
└── Add Bill FAB

History (BottomNav Tab 2)
├── All payments grouped by month
├── Filter by utility
└── Per-bill detail → Edit / Delete entry

Analytics (BottomNav Tab 3)
├── Monthly spend bar chart (6 months)
├── Utility breakdown pie
├── Per-bill trend on tap
└── CSV export

Properties (BottomNav Tab 4)
├── Property group list
├── Group detail → bills for that property
├── Group total this month
└── Quick Pay All

Settings (via profile icon)
├── Account (sign in / sign out / guest)
├── Notification settings per bill
├── Default payment method
├── Language / Theme
└── Export / Clear data
```

---

## Data Flow Diagram

```
User taps "Pay Now"
        │
        ▼
Payment Method Sheet
(bKash / Nagad / Portal / Rocket)
        │
        ▼
url_launcher opens external app or Chrome Custom Tab
        │
        ▼  (user pays externally, returns to app)
        │
"পরিশোধ করেছেন?" prompt
        │
   YES  │  NO
   ─────┤──────
   ▼         ▼
Manual     Dismiss
Log Form
(amount, txn ID, date)
   │
   ▼
SQLite: payment_history INSERT
   │
   ▼
Firestore sync (background, silent)
   │
   ▼
Dashboard updates (card → "Recently Paid" ✅)
   │
   ▼
Next reminder rescheduled (local notification)
```

---

## Build Order (8-Day MVP Sprint)

| Day | Focus | Output |
|---|---|---|
| 1 | Project setup, SQLite schema, BLoC structure, Firebase init | Runnable shell app |
| 2 | Add / edit / delete bill accounts, property groups | Bill management working |
| 3 | Home dashboard, bill cards, status logic, filter chips | Dashboard live |
| 4 | Pay Now flow, url_launcher, Remote Config for URLs | Redirect working end-to-end |
| 5 | Manual payment log, history screen, edit/delete | History working |
| 6 | Local notifications, reminder scheduling, smart due date | Reminders working |
| 7 | Analytics charts, anomaly detection, CSV export | Analytics working |
| 8 | Firebase auth (phone OTP + Google), Firestore sync, QA | MVP complete |
