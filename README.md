# Daily Reflection 🌿

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Database%20%26%20Auth-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20iOS%20%7C%20Web-blue?style=for-the-badge)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

A mindful, privacy-first daily reflection, mood tracking, and introspective journaling application built with **Flutter**, powered by a **Local-First Architecture**, **AES-256 Client-Side End-to-End Encryption (E2EE)**, and seamless **Supabase Cloud Synchronization**.

---

## ✨ Features at a Glance

### 🧘 Mindful Journaling & Reflection
* **7-Step Guided Evening Flow**: Thoughtfully structured prompts guiding you through gratitude, self-awareness, daily wins, and lessons learned.
* **Freeform Journaling**: Flexible open-ended writing mode with live word counts, mood selection, and custom reflection dates.
* **📸 Daily Moment Photos & Lightbox Showcase**: Attach photos to captures, with interactive pinch-to-zoom full-screen lightbox viewing.
* **Mood & Energy Tracking**: Visual mood tags, intuitive color palettes, and emotional trend tracking.

### 🔐 Zero-Knowledge Security & Privacy
* **Client-Side E2EE (AES-256-CBC)**: Reflection titles, notes, and question responses are encrypted on-device before syncing to the cloud using PBKDF2-HMAC-SHA256 deterministic key derivation.
* **App PIN & Security Lock**: Secure 4-digit PIN protection with PBKDF2 hashing, biometric support, and rate-limiting lockout protection against brute force.
* **Privacy-Safe Telemetry**: Sentry crash reporting with zero-knowledge error sanitization ensuring private reflections are never sent in crash traces.

### 🔄 Local-First & Multi-Device Cloud Sync
* **Instant 0ms UI Latency**: All changes write immediately to local device cache via background Dart isolates (`compute`).
* **Reliable Cloud Sync**: Automatic synchronization with Supabase PostgreSQL, exponential backoff retries, and background sync upon app resume.
* **Live Sync Status Indicator**: Real-time cloud status chips (`Synced`, `Syncing`, `Pending sync`, `Offline`) with 1-tap manual force sync.
* **Multi-Device Support**: Access the same encrypted journal seamlessly on your Android Phone and Windows PC.
* **Offline & Guest Mode**: Complete offline usability with full functionality without requiring an account.

### 📊 Analytics, Keepsakes & Onboarding
* **Interactive Onboarding**: Mindful first-time welcome tour introducing key concepts, re-accessible at any time from settings.
* **Habit & Streak Tracking**: Automatic streak calculation, completion milestones, and monthly calendar visualizations.
* **PDF Keepsake Export**: Generate clean, printable PDF records of your reflections for archiving and offline backup.

---

## 🏗️ Architecture & Tech Stack

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter UI Layer                     │
│  (TodayPage | JournalPage | ReflectionPage | Summary)   │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│              State & Service Repository                 │
│         (ReflectionService - ChangeNotifier)            │
└────────────────────────────┬────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
┌───────────────────────────┐ ┌───────────────────────────┐
│   DatabaseService Cache   │ │ EncryptionService (E2EE)  │
│  (SharedPreferences/Disk) │ │ (AES-256-CBC + PBKDF2)    │
└───────────────────────────┘ └─────────────┬─────────────┘
                                            │
                                            ▼
                              ┌───────────────────────────┐
                              │  Supabase Cloud Database  │
                              │ (PostgreSQL + RLS Auth)   │
                              └───────────────────────────┘
```

| Layer | Technology / Library | Description |
|---|---|---|
| **UI Framework** | Flutter SDK (^3.13+) / Dart | Cross-platform UI for Android, Windows, iOS, and Web |
| **State Management** | `ChangeNotifier` / `ListenableBuilder` | Reactive, lightweight state management |
| **Local Storage** | `shared_preferences`, `flutter_secure_storage` | High-speed local cache & encrypted seed store |
| **Concurrency** | Dart Isolates via `compute()` | Background JSON serialization off the UI thread |
| **Cryptography** | `encrypt`, `crypto` | AES-256-CBC, PBKDF2-HMAC-SHA256 (100,000 iterations) |
| **Cloud Backend** | `supabase_flutter` | Auth, PostgreSQL database, Row Level Security (RLS) |
| **Export** | `pdf`, `printing` | Monthly reflection keepsakes and printouts |
| **Telemetry** | `sentry_flutter` | Privacy-sanitized crash reporting and monitoring |

---

## 📁 Project Structure

```
daily_reflection/
├── db/                                # Supabase SQL schemas & migrations
│   ├── schema.sql                     # Table schemas, RLS policies, triggers, indexes
│   └── README.md                      # Database setup instructions
│
├── frontend/                          # Flutter client application
│   ├── lib/
│   │   ├── core/                      # Application core infrastructure
│   │   │   ├── config/                # Supabase & Sentry configuration
│   │   │   ├── constants/             # Prompts, quotes, and static assets
│   │   │   ├── services/              # Encryption, Settings, Security, Notifications, Crash
│   │   │   ├── theme/                 # AppColors, typography, themes, smooth transitions
│   │   │   └── utils/                 # CryptoUtils, StreakCalculator
│   │   │
│   │   ├── features/                  # Modular feature-driven domains
│   │   │   ├── auth/                  # Supabase Auth, Guest Mode, AuthGate
│   │   │   ├── freeform/              # Freeform writing canvas & photo attachments
│   │   │   ├── history/               # Calendar grid & streak history
│   │   │   ├── journal/               # Unified journal feed, search, and filters
│   │   │   ├── onboarding/            # First-time user welcome experience
│   │   │   ├── reflection/            # 7-step guided questionnaire & database service
│   │   │   ├── settings/              # Settings, Security PIN, PDF export, tour
│   │   │   ├── summary/               # Daily recap, quote card, photo showcase
│   │   │   └── today/                 # Daily prompt, mood check-in, yesterday's summary
│   │   │
│   │   ├── shared/                    # Shared widgets (PhotoViewerDialog, AppShell)
│   │   ├── app.dart                   # Root MaterialApp & routing
│   │   └── main.dart                  # Application initialization
│   │
│   ├── test/                          # Unit & integration test suites (30+ tests)
│   └── pubspec.yaml                   # Flutter dependencies
│
└── README.md                          # Project documentation
```

---

## 🚀 Getting Started

### 1. Prerequisites
* [Flutter SDK](https://flutter.dev) (v3.13.0 or higher)
* [Git](https://git-scm.com)
* [Supabase Account](https://supabase.com) (Free tier)

### 2. Clone the Repository
```bash
git clone https://github.com/your-username/daily_reflection.git
cd daily_reflection
```

### 3. Setup the Cloud Database (Supabase)
1. Log in to your [Supabase Dashboard](https://supabase.com/dashboard) and open/create a project.
2. In the left navigation, click **SQL Editor** -> **New Query**.
3. Copy the entire contents of [`db/schema.sql`](db/schema.sql) into the query editor and click **Run**.
   *(This creates the `reflections` table, performance indexes, and strict Row Level Security policies).*

### 4. Configure & Run the App

#### Option A: Run with Environment Variables (Recommended)
```bash
cd frontend
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

#### Option B: Configure Defaults
Edit [`frontend/lib/core/config/supabase_config.dart`](frontend/lib/core/config/supabase_config.dart) and set your default project credentials directly.

---

## 📦 Building Release Binaries

### Android (APK)
```bash
cd frontend
flutter build apk --release
```
*Output:* `frontend/build/app/outputs/flutter-apk/app-release.apk`

### Windows Desktop (.exe)
```bash
cd frontend
flutter build windows --release
```
*Output:* `frontend/build/windows/x64/runner/Release/daily_reflection.exe`

---

## 🧪 Testing & Code Quality

Run the comprehensive unit and service test suite (30+ tests covering PBKDF2 encryption, PIN security, notification scheduling, and onboarding):
```bash
cd frontend
flutter test
```

Run static analysis to ensure 0 lint warnings:
```bash
cd frontend
flutter analyze
```

---

## 🔒 Security Architecture

```
[User Text Input]
       │
       ▼
[PBKDF2-HMAC-SHA256] ──> (Deterministic 256-bit Account Key)
       │
       ▼
[AES-256-CBC Encryption] ──> enc:aes256:<iv>:<ciphertext>
       │
       ▼
[Supabase Cloud Database] (Stores Ciphertext Only)
```

1. **Deterministic Key Derivation**: Keys are derived locally using `PBKDF2-HMAC-SHA256` (100,000 iterations) scoped to the authenticated user ID.
2. **Zero-Knowledge**: Plaintext journal entries never leave the device. Even database administrators cannot read your reflections.
3. **Cross-Device Decryption**: Logging in with your account on any device derives the exact same cryptographic key, allowing seamless synchronization and decryption.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
