# Database & Backend Setup (Supabase PostgreSQL)

This directory contains the database schema, security policies, and performance indexes for the **Daily Reflection** application.

---

## 1. Quick Setup

1. Open your project on the [Supabase Dashboard](https://supabase.com/dashboard).
2. Navigate to **SQL Editor** -> **New Query**.
3. Copy and paste the entire contents of [`schema.sql`](./schema.sql).
4. Click **Run**.

---

## 2. Schema Structure

### `public.reflections` Table

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `TEXT PRIMARY KEY` | Unique reflection ID generated client-side or UUID. |
| `user_id` | `UUID NOT NULL REFERENCES auth.users(id)` | User ID owning the reflection (default: `auth.uid()`). |
| `date` | `TIMESTAMPTZ NOT NULL` | Date of the daily reflection. |
| `mood` | `TEXT NOT NULL` | User's mood (e.g., *Calm, Grateful, Energized*). |
| `mood_emoji` | `TEXT NOT NULL` | Emoji representing the mood (e.g., 🌿, 🙏, ⚡). |
| `answers` | `JSONB NOT NULL DEFAULT '{}'` | Key-value dictionary of guided prompt answers. |
| `freeform_title` | `TEXT` | Optional title for freeform journal entries. |
| `freeform_note` | `TEXT` | Freeform text or notes. |
| `is_bookmarked` | `BOOLEAN NOT NULL DEFAULT FALSE` | Favorite/bookmarked status. |
| `type` | `TEXT NOT NULL DEFAULT 'guided'` | `guided` or `freeform`. |
| `created_at` | `TIMESTAMPTZ NOT NULL DEFAULT NOW()` | Timestamp of creation. |
| `updated_at` | `TIMESTAMPTZ NOT NULL DEFAULT NOW()` | Automatically updated via trigger. |

---

## 3. Security & Row Level Security (RLS)

All user reflections are private and strictly protected by PostgreSQL Row Level Security (RLS):
* **Select**: `auth.uid() = user_id`
* **Insert**: `auth.uid() = user_id`
* **Update**: `auth.uid() = user_id`
* **Delete**: `auth.uid() = user_id`

---

## 4. Enabling AI Semantic Search (`pgvector`)

When ready to enable AI memory and semantic search:
1. In Supabase Dashboard -> **Database** -> **Extensions** -> Enable `vector`.
2. Run the commented section at the bottom of [`schema.sql`](./schema.sql) to add the `embedding` column and vector similarity function `match_reflections`.
