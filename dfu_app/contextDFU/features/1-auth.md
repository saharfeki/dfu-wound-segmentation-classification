## : Feature 1: Authentication & Patient Context

### Overview

Single-clinic thesis demo. Clinicians authenticate via Supabase Auth and manage a list of patients, each patient acting as a container for that patient's DFU analysis history (image captures, AI results, clinical notes over time).

### Stack

- **Auth**: Supabase Auth (email + password)
- **Database**: Supabase Postgres
- **Backend**: FastAPI (Python), validates Supabase JWTs on protected routes
- **Client**: Flutter (mobile + web), using `supabase_flutter` SDK

### Data Model (Postgres)

sql

```sql
-- Clinicians (mirrors Supabase auth.users, extended with app-specific fields)
create table clinicians (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null default 'clinician', -- 'clinician' | 'admin'
  created_at timestamptz not null default now()
);

-- Patients (single-clinic scope — no clinic_id needed for v1 demo)
create table patients (
  id uuid primary key default gen_random_uuid(),
  external_ref text, -- optional free-form patient identifier/MRN
  full_name text not null,
  date_of_birth date,
  diabetes_type text, -- 'type_1' | 'type_2' | null
  foot_laterality text, -- 'left' | 'right' | 'bilateral' | null
  created_by uuid not null references clinicians(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_patients_created_by on patients(created_by);
create index idx_patients_full_name on patients(full_name);

### Row-Level Security (RLS)

```sql
alter table clinicians enable row level security;
alter table patients enable row level security;

-- Clinicians can read their own row
create policy "clinicians_read_own" on clinicians
  for select using (auth.uid() = id);

-- Any authenticated clinician can read/write patients (single-clinic demo — no per-clinician isolation)
create policy "patients_read_all" on patients
  for select using (auth.role() = 'authenticated');

create policy "patients_insert_own" on patients
  for insert with check (auth.uid() = created_by);

create policy "patients_update_all" on patients
  for update using (auth.role() = 'authenticated');```

### Backend (FastAPI)

- Middleware: extract `Authorization: Bearer <jwt>` header, verify against Supabase JWT secret, attach `clinician_id` to request context. Reject with 401 if missing/invalid.
- Endpoints:
  - `GET /patients` — list patients, optional `?search=` query param (matches `full_name` or `external_ref`), paginated
  - `POST /patients` — create patient, body: `{full_name, external_ref?, date_of_birth?, diabetes_type?, foot_laterality?}`
  - `GET /patients/{id}` — patient detail (used by history timeline in Feature 6)
  - `PATCH /patients/{id}` — update patient fields

All routes require a valid JWT. No admin-only routes needed yet (single role sufficient for demo; `role` field exists on `clinicians` for future use).

### Flutter Client

#### Screens

1. **Login screen** — email + password fields, "Sign in" button, calls `supabase.auth.signInWithPassword()`. On success, navigate to Patient List. On failure, show inline error (invalid credentials).
2. **Patient List screen**
   - Search bar (filters by name/external\_ref, debounced, calls `GET /patients?search=`)
   - List of patient cards: name, DOB, last analysis date (if available)
   - Floating action button → "New Patient" form
   - Tap a patient → navigate to Patient Detail / History (Feature 6)
3. **New Patient form** — fields matching the data model (`full_name` required, rest optional), "Save" calls `POST /patients`, then navigates to the new patient's detail screen

#### State/session handling

- Store Supabase session token via `supabase_flutter`'s built-in session persistence (handles refresh automatically)
- On app launch, check for existing session — if valid, skip Login and go straight to Patient List
- Logout action clears session, returns to Login screen

### Acceptance Criteria

- Clinician can sign in with email/password and reach the Patient List
- Invalid credentials show a clear error, no navigation occurs
- Patient List loads and displays all patients, searchable by name
- Clinician can create a new patient with just a name (all other fields optional)
- New patient appears in the list immediately after creation
- All `/patients` API calls fail with 401 if the JWT is missing or expired
- Session persists across app restarts (no re-login required until token expiry/logout)

### Out of Scope for v1

- Multi-clinic isolation (`clinic_id`) — noted in schema comments as a future addition
- Role-based permission enforcement beyond schema (`admin` role exists but has no special routes yet)
- Password reset flow, email verification, SSO