# Multi-Tenant Architecture Guide

## Overview
This application uses a **Multi-Tenant SaaS Architecture** where multiple companies (clinics) share the same codebase and database, but each company's data is completely isolated from others.

## How It Works

### Database Structure
Every main table has a `company_id` column that links records to a specific company:
- `companies` - Stores company/clinic information
- `users` - Each user belongs to one company
- `clients` - Each patient belongs to one company
- `roles` - Roles are company-specific
- `subroles` - Subroles are company-specific
- `sessions` - Sessions belong to one company

### Authentication Flow
1. User logs in with username/password
2. System fetches their `company_id` from the `users` table
3. JWT token is created (but doesn't store `company_id` - it's fetched fresh on each request)
4. All API requests automatically filter by the user's `company_id`

## Critical Implementation Patterns

### 1. Reading Data (SELECT queries)
**Always filter by `company_id`** to ensure users only see their company's data.

```typescript
// ✅ CORRECT
const clients = await sql`
  SELECT * FROM clients 
  WHERE company_id = ${currentUser.company_id}
`

// ❌ WRONG - This would show all companies' data!
const clients = await sql`
  SELECT * FROM clients
`
```

### 2. Creating Data (INSERT queries)
**Always include `company_id`** when inserting new records.

```typescript
// ✅ CORRECT
await sql`
  INSERT INTO sessions (user_id, session_date, company_id)
  VALUES (${userId}, ${date}, ${currentUser.company_id})
`

// ❌ WRONG - Record wouldn't belong to any company!
await sql`
  INSERT INTO sessions (user_id, session_date)
  VALUES (${userId}, ${date})
`
```

### 3. Updating/Deleting Data
**Always verify `company_id`** in the WHERE clause to prevent cross-company modifications.

```typescript
// ✅ CORRECT
await sql`
  UPDATE sessions 
  SET status = 'completed'
  WHERE id = ${sessionId} AND company_id = ${currentUser.company_id}
`

// ❌ WRONG - Could modify another company's record!
await sql`
  UPDATE sessions 
  SET status = 'completed'
  WHERE id = ${sessionId}
`
```

### 4. Getting Current User
Always use `getUserFromEvent()` which returns the user object including `company_id`:

```typescript
import { getUserFromEvent } from '~~/server/utils/auth'

export default defineEventHandler(async (event) => {
  const currentUser = await getUserFromEvent(event)
  if (!currentUser) {
    throw createError({ statusCode: 401, message: 'Unauthorized' })
  }
  
  // Now you have access to:
  // - currentUser.id
  // - currentUser.company_id
  // - currentUser.permission
  // - currentUser.username
})
```

## Database Migration

### Initial Setup
Run the migration file to add `company_id` to all tables:

```bash
# Connect to your database and run:
psql -U your_user -d your_database -f db/multi_tenant_migration.sql
```

### What the Migration Does
1. Creates `companies` table
2. Inserts a default company (ID: 1)
3. Adds `company_id` column to all main tables
4. Migrates existing data to company ID 1
5. Creates indexes for performance

## User Registration Flow

When a new user registers (`/api/auth/register`):
1. Creates a **NEW company** automatically
2. Creates the user as **Super Admin** (permission: 0) of that company
3. The user can then invite other users to their company

## Common Pitfalls to Avoid

### ❌ DON'T: Use JOINs without filtering
```typescript
// BAD - Could leak data across companies
const data = await sql`
  SELECT * FROM sessions s
  LEFT JOIN clients c ON s.client_id = c.id
`
```

### ✅ DO: Filter both tables
```typescript
// GOOD - Both tables filtered by company_id
const data = await sql`
  SELECT * FROM sessions s
  LEFT JOIN clients c ON s.client_id = c.id
  WHERE s.company_id = ${currentUser.company_id}
  AND c.company_id = ${currentUser.company_id}
`
```

### ❌ DON'T: Forget company_id in subqueries
```typescript
// BAD
const count = await sql`
  SELECT COUNT(*) FROM users WHERE role_id = ${roleId}
`
```

### ✅ DO: Include company_id everywhere
```typescript
// GOOD
const count = await sql`
  SELECT COUNT(*) FROM users 
  WHERE role_id = ${roleId} AND company_id = ${currentUser.company_id}
`
```

## Testing Multi-Tenancy

### Manual Testing Checklist
1. Register two different users (they get different companies)
2. Create data as User A
3. Login as User B
4. Verify User B **cannot see** User A's data
5. Verify User B **cannot modify** User A's data (even if they guess the ID)

### Example Test
```typescript
// As Company 1 user, create a client
POST /api/clients
{ name: "John Doe", process_number: "001" }
// Returns: { id: 5, company_id: 1, ... }

// As Company 2 user, try to access it
GET /api/clients/5
// Should return: 404 Not Found (even though it exists!)
```

## Security Principles

1. **Defense in Depth**: Always filter by `company_id`, even if you think the data is safe
2. **Never Trust IDs**: Users can guess/manipulate IDs in URLs - always verify ownership
3. **Audit Regularly**: Periodically search your codebase for queries missing `company_id`
4. **Index Performance**: All `company_id` columns should be indexed

## Adding New Tables

When adding a new table to the system:

1. **Add `company_id` column**:
```sql
CREATE TABLE new_table (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255),
  company_id INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

2. **Add index**:
```sql
CREATE INDEX idx_new_table_company ON new_table(company_id);
```

3. **Update API endpoints** to follow the patterns above

## Performance Considerations

### Indexes
All `company_id` columns should have indexes:
```sql
CREATE INDEX idx_users_company ON users(company_id);
CREATE INDEX idx_clients_company ON clients(company_id);
CREATE INDEX idx_sessions_company ON sessions(company_id);
```

### Query Optimization
Since `company_id` is in almost every WHERE clause, the database can efficiently use these indexes.

## Future Enhancements

### Subdomain Support (Optional)
The `companies` table has a `subdomain` column for future use:
- `company-a.yourapp.com` → Company A's data
- `company-b.yourapp.com` → Company B's data

### Company Branding (Optional)
The `companies` table includes:
- `logo_url` - Custom company logo
- `primary_color` - Brand color customization

## File Locations

- Migration: `db/multi_tenant_migration.sql`
- Auth utilities: `server/utils/auth.ts`
- API endpoints: `server/api/**/*.ts`
- This guide: `MULTI_TENANT_GUIDE.md`

## Quick Reference

```typescript
// Get current user (includes company_id)
const currentUser = await getUserFromEvent(event)

// Read data
WHERE company_id = ${currentUser.company_id}

// Write data
INSERT INTO table (..., company_id) VALUES (..., ${currentUser.company_id})

// Update/Delete data
WHERE id = ${id} AND company_id = ${currentUser.company_id}
```

## Support

If you find a query missing `company_id` filtering, it's a **security bug** and should be fixed immediately.

Use this search to find potential issues:
```bash
# Search for SQL queries that might be missing company_id
grep -r "FROM users" server/api/
grep -r "FROM clients" server/api/
grep -r "FROM sessions" server/api/
```

Then manually verify each result includes `company_id` filtering.
