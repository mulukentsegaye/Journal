# Daily Reflection 🌿

A mindful daily reflection, mood tracking, and introspective journaling application built with **Flutter** and powered by a **Local-First architecture** with **Supabase PostgreSQL** synchronization.

---

## 📁 Repository Structure

```
daily_reflection/
├── db/                     # Supabase PostgreSQL database schemas & documentation
│   ├── schema.sql          # Complete table schema, RLS policies, indexes, and pgvector definitions
│   └── README.md           # Database setup and migration guide
│
├── docs/                   # System design & architecture documentation
│   └── ARCHITECTURE.md     # Local-First sync and data flow architecture
│
├── frontend/               # Flutter cross-platform mobile & desktop application
│   ├── lib/
│   │   ├── core/           # Configuration, theme, constants, and utilities
│   │   │   ├── config/     # SupabaseConfig environment parameters
│   │   │   ├── constants/  # Strings, prompts, and quote collections
│   │   │   ├── services/   # SettingsService & local preferences
│   │   │   ├── theme/      # AppColors, typography, and dark/light themes
│   │   │   └── utils/      # Streak calculation and date utilities
│   │   │
│   │   ├── features/       # Feature-driven modular architecture
│   │   │   ├── auth/       # Supabase GoTrue authentication & Local Guest Mode
│   │   │   ├── freeform/   # Freeform journal editor & notes
│   │   │   ├── history/    # Monthly calendar grid & streak analytics
│   │   │   ├── journal/    # Mindful feed, search, and category filters
│   │   │   ├── reflection/ # 7-step guided daily reflection questionnaire
│   │   │   └── summary/    # Daily completion recap & mindfulness quote
│   │   │
│   │   ├── app.dart        # Main MaterialApp & root navigation
│   │   └── main.dart       # App entry point & initialization
│   │
│   ├── test/               # Unit and widget test suite (100% passing)
│   └── pubspec.yaml        # Flutter dependencies
│
└── .gitignore              # Repository git ignore definitions
```

---

## 🚀 Getting Started

### 1. Prerequisites
* [Flutter SDK](https://flutter.dev) (^3.13.0 or higher)
* [Supabase](https://supabase.com) Account (Free tier)

### 2. Database Setup
1. Open your project on the [Supabase Dashboard](https://supabase.com/dashboard).
2. Go to **SQL Editor** -> **New Query**.
3. Copy and run the script in [`db/schema.sql`](db/schema.sql).

### 3. Run the App
Pass your credentials at launch:
```bash
cd frontend
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Or configure your defaults in [`frontend/lib/core/config/supabase_config.dart`](frontend/lib/core/config/supabase_config.dart).

---

## 🧪 Testing

Run the test suite:
```bash
cd frontend
flutter test
```
Run static analysis:
```bash
cd frontend
flutter analyze
```
