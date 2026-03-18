# SolverdePT — Project Context & Skills

> **This file provides deep context for AI assistants (GitHub Copilot, Cursor, etc.) working on this codebase.**
> Last updated: 2026-03-16

---

## 1. Project Identity

| Field | Value |
|---|---|
| **Name** | SolverdePT |
| **Type** | Internal Management Platform (Single Tenant) — Holidays, Equipment, Meeting Rooms, Audit |
| **Framework** | **Nuxt 4.2** (Vue 3 Composition API + Nitro server) |
| **UI Library** | **Nuxt UI 4.1.0** (based on Reka UI + Tailwind CSS v4) |
| **Language** | TypeScript (strict, full-stack) |
| **Package Manager** | pnpm 10.19 (workspace mode via `pnpm-workspace.yaml`) |
| **Database** | PostgreSQL 16 (Docker) via `postgres` npm driver |
| **Auth** | JWT (httpOnly cookie) + bcrypt password hashing |
| **State Management** | Pinia 3 |
| **Primary Language (UI)** | Portuguese (pt-PT) — labels, messages, toasts |

---

## 2. Tech Stack in Detail

### 2.1 Frontend

| Dependency | Version | Purpose |
|---|---|---|
| `nuxt` | ^4.2.0 | Full-stack Vue meta-framework |
| `@nuxt/ui` | ^4.1.0 | Component library (UButton, UCard, UDashboardSidebar, UNavigationMenu, UDashboardSearch, UToast, etc.) |
| `@pinia/nuxt` | ^0.11.3 | State management integration |
| `pinia` | ^3.0.4 | Store library |
| `@vueuse/nuxt` | ^13.9.0 | Composition utilities (useColorMode, etc.) |
| `@unovis/vue` + `@unovis/ts` | ^1.6.1 | Data visualization / charts |
| `date-fns` | ^4.1.0 | Date manipulation (parseISO, isValid, format) |
| `zod` | ^4.1.12 | Schema validation |
| `@iconify-json/lucide` | ^1.2.71 | Icon set (primary icons) |
| `@iconify-json/simple-icons` | ^1.2.55 | Brand icon set |
| `tailwind` | ^4.0.0 | Utility CSS (imported via `@nuxt/ui`) |

### 2.2 Backend (Nitro Server Routes — `server/`)

| Dependency | Version | Purpose |
|---|---|---|
| `postgres` | ^3.4.7 | PostgreSQL driver (tagged template SQL) |
| `bcrypt` | ^6.0.0 | Password hashing |
| `jsonwebtoken` | ^9.0.2 | JWT token creation & verification |

### 2.3 Dev Tooling

| Tool | Purpose |
|---|---|
| `@nuxt/eslint` + `eslint` | Linting (stylistic config, no trailing commas, 1tbs brace style) |
| `typescript` ^5.9 | Type checking |
| `vue-tsc` ^3.1 | Vue template type checking |
| Nuxt DevTools | Enabled in development |

### 2.4 Theming

- **Primary color**: `green` (custom Nuxt green palette defined in `app/assets/css/main.css`)
- **Neutral color**: `zinc`
- **Font**: `Public Sans`, sans-serif
- **Dark mode**: Supported via `useColorMode()` (dark bg: `#1b1718`)
- **Tailwind v4** with static theme via `@theme static` block

---

## 3. Architecture Overview

```
┌─────────────────────────────────────────────┐
│                   Browser                    │
│  ┌──────────────────────────────────────┐    │
│  │ Nuxt App (Vue 3 SPA + SSR)          │    │
│  │  ├── pages/        (file-based routing)   │
│  │  ├── layouts/      (UDashboardGroup)      │
│  │  ├── components/   (modals, views)        │
│  │  ├── composables/  (useAuth, usePermissions, etc.) │
│  │  ├── stores/       (Pinia: popup, toast)  │
│  │  ├── middleware/    (auth.global, permissions)     │
│  │  └── utils/        (permissions engine)   │
│  └──────────────────────────────────────┘    │
└──────────────┬──────────────────────────────┘
               │ $fetch / useApiFetch
               ▼
┌─────────────────────────────────────────────┐
│ Nitro Server (server/)                       │
│  ├── api/auth/       (login, logout, change-password) │
│  ├── api/users/    (CRUD + permission checks) │
│  ├── api/vacation-requests/ (CRUD + approval workflow) │
│  ├── api/equipment/ (CRUD + inventory tracking)   │
│  ├── api/meeting-rooms/ (list, reservations)     │
│  ├── api/audit-logs/ (read-only audit trail)     │
│  └── utils/                                  │
│       ├── db.ts    (postgres singleton)      │
│       └── auth.ts  (JWT verify, getUserFromEvent) │
└──────────────┬──────────────────────────────┘
               │ Tagged template SQL (postgres lib)
               ▼
┌─────────────────────────────────────────────┐
│ PostgreSQL 16 (Docker)                       │
│  solverdept_db_2025                          │
│  Tables: users, vacation_requests, equipment,  │
│          meeting_rooms, room_reservations,    │
│          audit_logs                           │
└─────────────────────────────────────────────┘
```

---

## 4. Architecture Model

This is a **single-tenant, role-based access control** platform focused on internal operations.

- All users belong to a single organization (SolverdePT).
- Permissions are managed by admins via `permission` levels.
- No `company_id` scoping required (monolithic data model).
- `getUserFromEvent(event)` reads the JWT from the `auth.token` httpOnly cookie, decodes it, queries the DB for the full user row, and returns it.

### Critical Pattern

```typescript
// Every server API handler starts with:
const currentUser = await getUserFromEvent(event)
if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

// Permissions are managed via currentUser.permission level (no company_id scoping):
if (currentUser.permission > 1) {
  throw createError({ statusCode: 403, message: 'Forbidden - Insufficient permissions' })
}
```

---

## 5. Authentication System

### Flow

1. `POST /api/auth/login` — validates username/password with bcrypt, creates JWT, sets `auth.token` httpOnly cookie.
2. `POST /api/auth/register` — creates a new company, new user (permission 0), sets JWT cookie.
3. `POST /api/auth/logout` — clears cookie.
4. `POST /api/auth/change-password` — validates old password, updates with new hash.

### Client-Side Auth (`useAuth` composable)

- Stores user in `useState('auth.user')` + `useCookie('auth.user')` for SSR hydration.
- Sets a `auth.loggedIn` cookie as a lightweight auth hint for middleware.
- `isAuthenticated` is a computed derived from user state.
- On 401 from any API call, `useApiFetch` automatically shows a "Session expired" toast and logs out.

### Middleware

| Middleware | Scope | Purpose |
|---|---|---|
| `auth.global.ts` | **All routes** | Redirects unauthenticated users to `/login`. Prevents authenticated users from accessing `/login` and `/register`. |
| `permissions.ts` | **Named** (applied per-page) | Checks route-specific permissions (e.g., `/users/accounts` requires `VIEW_ALL_USERS`). |

---

## 6. Permission System (Role-Based Access Control)

### Permission Levels (Hierarchical — lower number = more power)

| Level | Name (PT) | Name (EN) | Description |
|---|---|---|---|
| `0` | Administrador | Admin | Full system access. Can manage users, all modules, system settings, audit logs. |
| `1` | Gestor | Manager | Can manage vacation requests, view equipment inventory, manage meeting room reservations. |
| `2` | Colaborador | Employee | Can request vacations, view own equipment, reserve meeting rooms, view own audit actions. |
| `3` | Restrito | Restricted | Read-only access. Can view own vacation requests and items only. Cannot create or edit anything. |

### Capability Matrix

| Capability | Admin (0) | Manager (1) | Employee (2) | Restricted (3) |
|---|---|---|---|---|
| `VIEW_ALL_USERS` | ✅ | ✅ | ❌ | ❌ |
| `MANAGE_USERS` | ✅ | ❌ | ❌ | ❌ |
| `VIEW_VACATION_REQUESTS` | ✅ | ✅ | ❌ | ❌ |
| `MANAGE_VACATION_REQUESTS` | ✅ | ✅ | ❌ | ❌ |
| `CREATE_VACATION_REQUEST` | ✅ | ✅ | ✅ | ❌ |
| `VIEW_OWN_VACATION_REQUESTS` | ✅ | ✅ | ✅ | ✅ |
| `VIEW_EQUIPMENT_INVENTORY` | ✅ | ✅ | ✅ | ✅ |
| `MANAGE_EQUIPMENT` | ✅ | ✅ | ❌ | ❌ |
| `VIEW_MEETING_ROOMS` | ✅ | ✅ | ✅ | ✅ |
| `RESERVE_MEETING_ROOMS` | ✅ | ✅ | ✅ | ❌ |
| `MANAGE_ROOM_RESERVATIONS` | ✅ | ✅ | ❌ | ❌ |
| `VIEW_AUDIT_LOGS` | ✅ | ❌ | ❌ | ❌ |
| `VIEW_OWN_AUDIT_LOGS` | ✅ | ✅ | ✅ | ✅ |
| `ACCESS_SETTINGS` | ✅ | ❌ | ❌ | ❌ |
| `CHANGE_SYSTEM_SETTINGS` | ✅ | ❌ | ❌ | ❌ |

### Implementation

**Engine** — `app/utils/permissions.ts`:
- `PERMISSIONS` object defines the 4 levels.
- `CAPABILITIES` maps each capability to an array of allowed permission levels.
- `hasPermission(userPermission, capability)` checks if the user's level is in the allowed list.

**Composable** — `app/composables/usePermissions.ts`:
- Wraps the permission engine into reactive Vue computeds.
- Exposes `can('CAPABILITY_NAME')` function and pre-built computeds like `canViewAllUsers`, `isAdmin`, etc.

**Server-Side** — API handlers check `currentUser.permission` directly:
```typescript
if (currentUser.permission > 1) {
  throw createError({ statusCode: 403, message: 'Forbidden - Insufficient permissions' })
}
```

**Navigation** — `app/layouts/default.vue` conditionally shows sidebar items based on `canViewAllUsers`, `canAccessSettings`, `canViewClients`.

---

## 7. Database Schema

### Tables

| Table | Purpose | Key Columns |
|---|---|---|
| `users` | System users (employees) | `id`, `username`, `password`, `name`, `email`, `department`, `permission`, `status` |
| `vacation_requests` | Holiday/vacation requests with approval workflow | `id`, `employee_id`, `start_date`, `end_date`, `status`, `approved_by`, `created_at`, `updated_at` |
| `equipment` | IT hardware and software assets | `id`, `name`, `type`, `serial_number`, `purchase_date`, `status`, `assigned_to`, `notes`, `created_at` |
| `meeting_rooms` | Conference rooms and meeting spaces | `id`, `name`, `capacity`, `location`, `amenities`, `status`, `created_at` |
| `room_reservations` | Meeting room bookings | `id`, `room_id`, `employee_id`, `start_time`, `end_time`, `meeting_title`, `attendees_count`, `created_at` |
| `audit_logs` | Immutable audit trail | `id`, `employee_id`, `action`, `entity_type`, `entity_id`, `changes`, `timestamp` |

### Employee Status Codes

| Code | Meaning (PT) | Meaning (EN) |
|---|---|---|
| `-1` | Apagado | Deleted (soft) |
| `0` | Inativo | Inactive |
| `1` | Ativo | Active |

### Vacation Request Status

`'pending'`, `'approved'`, `'rejected'`, `'cancelled'` — with `approved_by` linking to approving manager.

### Equipment Status

`'available'`, `'in_use'`, `'maintenance'`, `'retired'` — tracks asset lifecycle and availability.

---

## 8. Key Composables

| Composable | File | Purpose |
|---|---|---|
| `useAuth()` | `app/composables/useAuth.ts` | Login, logout, user state, `isAuthenticated` |
| `usePermissions()` | `app/composables/usePermissions.ts` | `can()`, role checks (`isAdmin`, `isManager`, etc.), all `canX` computeds |
| `useApiFetch()` | `app/composables/useApiFetch.ts` | Wrapper over `$fetch` — auto-handles 401 → logout + toast |
| `useAppToast()` | `app/composables/useAppToast.ts` | Wrapper over Nuxt UI `useToast()` — `.success()`, `.error()`, `.warning()`, `.info()` |
| `useToaster()` | `app/composables/useToaster.ts` | Wrapper over Pinia toast store (alternative system) |

---

## 9. Stores (Pinia)

| Store | File | Purpose |
|---|---|---|
| `usePopupStore` | `app/stores/popup.ts` | Universal modal/popup system. Types: `common`, `confirmation`, `delete`. Supports custom Vue components as content (`pageComponent`). |
| `useToastStore` | `app/stores/toast.ts` | Custom toast notification system with auto-remove. |

---

## 10. UI Patterns & Components

### Layout

- **UDashboardGroup** + **UDashboardSidebar** — collapsible, resizable sidebar with navigation.
- **UDashboardSearch** — global search (Cmd+K / Ctrl+K).
- **UNavigationMenu** — vertical navigation with nested items.
- **UserMenu** — user dropdown in sidebar footer.

### Components

| Component | Purpose |
|---|---|
| `UniversalPopup` | Global popup/modal renderer (reads from Pinia popup store) |
| `UniversalToaster` | Global toast renderer |
| `Logo` | Application logo (collapsed/expanded variants) |
| `UserMenu` | User avatar + dropdown (profile, logout) |
| `users/AddModal` | Add employee modal |
| `users/EditModal` | Edit employee modal |
| `users/DeleteModal` | Delete employee confirmation |

### Nuxt UI Components Used

The project leverages Nuxt UI 4.1.0 components extensively:
- `UApp`, `UButton`, `UCard`, `UInput`, `USelect`, `UTextarea`, `UCheckbox`
- `UTable`, `UPagination`, `UBadge`, `UAvatar`
- `UDashboardGroup`, `UDashboardSidebar`, `UDashboardSearch`, `UDashboardSearchButton`
- `UNavigationMenu`, `UModal`, `UToast`
- `UFormField` (form validation integration)
- Icons via Iconify: `i-lucide-*` prefix

---

## 11. API Routes Reference

### Auth (`server/api/auth/`)

| Method | Path | Body | Description |
|---|---|---|---|
| POST | `/api/auth/login` | `{ username, password }` | Login, set JWT cookie |
| POST | `/api/auth/logout` | — | Clear JWT cookie |
| POST | `/api/auth/change-password` | `{ oldPassword, newPassword }` | Change password |

### Users (`server/api/users/`)

| Method | Path | Description |
|---|---|---|
| GET | `/api/users` | List all employees (permission-filtered) |
| GET | `/api/users/[id]` | Get single employee |
| POST | `/api/users` | Create employee (Admin only) |
| PUT | `/api/users/[id]` | Update employee |
| DELETE | `/api/users` | Delete employee(s) |

### Vacation Requests (`server/api/vacation-requests/`)

| Method | Path | Description |
|---|---|---|
| GET | `/api/vacation-requests` | List vacation requests (filtered by permission) |
| POST | `/api/vacation-requests` | Create vacation request |
| PUT | `/api/vacation-requests/[id]` | Update request status (approval) |
| DELETE | `/api/vacation-requests/[id]` | Delete request |

### Equipment (`server/api/equipment/`)

| Method | Path | Description |
|---|---|---|
| GET | `/api/equipment` | List all equipment with status |
| POST | `/api/equipment` | Create equipment record |
| PUT | `/api/equipment/[id]` | Update equipment |
| DELETE | `/api/equipment/[id]` | Delete equipment |

### Meeting Rooms (`server/api/meeting-rooms/`)

| Method | Path | Description |
|---|---|---|
| GET | `/api/meeting-rooms` | List meeting rooms |
| POST | `/api/meeting-rooms/reservations` | Book a meeting room |
| GET | `/api/meeting-rooms/[id]/availability` | Check room availability |
| DELETE | `/api/meeting-rooms/reservations/[id]` | Cancel reservation |

### Audit Logs (`server/api/audit-logs/`)

| Method | Path | Description |
|---|---|---|
| GET | `/api/audit-logs` | List audit logs (Admin only) |
| GET | `/api/audit-logs/my` | List personal audit actions |

---

## 12. File Conventions & Patterns

### Naming

- **Pages**: kebab-case (`vacation-requests/`, `equipment/`, `meeting-rooms/`, `change-password.vue`)
- **Components**: PascalCase (`AddModal.vue`, `DeleteModal.vue`)
- **Composables**: camelCase with `use` prefix (`useAuth.ts`, `usePermissions.ts`)
- **API routes**: Nuxt file-based routing (`index.get.ts`, `[id].put.ts`, `index.post.ts`)
- **Stores**: camelCase (`popup.ts`, `toast.ts`)

### Server API Pattern

Every API handler follows this structure:
```typescript
import sql from '~~/server/utils/db'
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  // 1. Authenticate
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) throw createError({ statusCode: 401, message: 'Unauthorized' })

  // 2. Authorize (check permission level)
  if (currentUser.permission > 1) {
    throw createError({ statusCode: 403, message: 'Forbidden - Insufficient permissions' })
  }

  // 3. Validate input
  const body = await readBody(event)

  // 4. Execute query
  const result = await sql`
    SELECT * FROM table
    WHERE employee_id = ${currentUser.id}
  `

  // 5. Return result
  return result
})
```

### SQL Driver

Uses `postgres` (porsager/postgres) with tagged template literals:
```typescript
// Simple query
await sql`SELECT * FROM employees WHERE id = ${id}`

// Dynamic IN clause
await sql`SELECT * FROM vacation_requests WHERE id IN ${sql(arrayOfIds)}`

// Unsafe (for dynamic WHERE — use carefully)
await sql`SELECT * FROM equipment ${sql.unsafe(dynamicWhere)}`
```

---

## 13. Development Setup

### Prerequisites

- Node.js 20+
- pnpm 10+
- Docker (for PostgreSQL)

### Quick Start

```bash
# 1. Start database
cd db && docker-compose up -d

# 2. Install dependencies
pnpm install

# 3. Set environment variables
#    DATABASE_URL=postgres://azidav:passw0rd@localhost:5432/solverdept_db_2025
#    JWT_SECRET=your-secret-key

# 4. Start dev server
pnpm dev
```

### Available Scripts

| Script | Command | Description |
|---|---|---|
| `pnpm dev` | `nuxt dev` | Start development server |
| `pnpm build` | `nuxt build` | Build for production |
| `pnpm preview` | `nuxt preview` | Preview production build |
| `pnpm lint` | `eslint .` | Run ESLint |
| `pnpm typecheck` | `nuxt typecheck` | Run TypeScript checks |

---

## 14. Important Rules for AI Assistants

1. **No `company_id` scoping required** — this is a single-tenant application. All queries naturally scope to the single organization.
2. **Use `usePermissions()` composable** in Vue components for permission checks, never raw permission numbers.
3. **Use `hasPermission()` or direct `currentUser.permission` checks** in server API handlers.
4. **Use Nuxt UI 4.1 components** — prefer `UButton`, `UCard`, `UTable`, `UInput`, etc. Do NOT use old Nuxt UI 2.x or 3.x APIs.
5. **Prefer Nuxt UI components over custom components** — always use Nuxt UI first (UCard, UCheckbox, UButton, UInput, etc.). Only create custom wrapper components if Nuxt UI doesn't provide the functionality. This keeps the UI consistent and maintainable.
6. **All user-facing text should be in Portuguese (pt-PT)** — button labels, toast messages, error messages, form labels.
7. **Use `useApiFetch()`** instead of raw `$fetch` for API calls from the client — it handles 401 automatically.
8. **Use `useAppToast()`** for toast notifications (wraps Nuxt UI's `useToast()`).
9. **Use `usePopupStore()`** for modals/popups — never create inline modal state.
10. **Follow the tagged template SQL pattern** — never concatenate user input into SQL strings.
11. **Permission checks are two-layered**: frontend (hide UI) + backend (reject API calls). Always implement both.
12. **Four core modules**: vacation management, equipment tracking, meeting room reservations, audit logging. Organize code and API routes around these.
13. **Soft deletes**: Use `status = -1` for deleted employees rather than hard deletes to maintain audit trail integrity.
