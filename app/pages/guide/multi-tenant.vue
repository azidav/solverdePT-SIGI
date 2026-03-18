<template>
  <div class="min-h-screen bg-gray-50">
    <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <!-- Navigation -->
      <div class="mb-8">
        <NuxtLink
          to="/guide"
          class="inline-flex items-center text-blue-600 hover:text-blue-800 font-medium mb-4"
        >
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          Back to Guides
        </NuxtLink>
      </div>

      <!-- Content -->
      <article class="bg-white rounded-lg shadow-lg p-8 prose prose-blue max-w-none">
        <h1>Multi-Tenant Architecture Guide</h1>

        <div class="bg-blue-50 border-l-4 border-blue-500 p-4 my-6">
          <p class="font-semibold text-blue-900 mb-2">Overview</p>
          <p class="text-blue-800 mb-0">
            This application uses a <strong>Multi-Tenant SaaS Architecture</strong> where multiple companies (clinics) share the same codebase and database, but each company's data is completely isolated from others.
          </p>
        </div>

        <h2>How It Works</h2>

        <h3>Database Structure</h3>
        <p>Every main table has a <code>company_id</code> column that links records to a specific company:</p>
        <ul>
          <li><code>companies</code> - Stores company/clinic information</li>
          <li><code>users</code> - Each user belongs to one company</li>
          <li><code>clients</code> - Each patient belongs to one company</li>
          <li><code>roles</code> - Roles are company-specific</li>
          <li><code>subroles</code> - Subroles are company-specific</li>
          <li><code>sessions</code> - Sessions belong to one company</li>
        </ul>

        <h3>Authentication Flow</h3>
        <ol>
          <li>User logs in with username/password</li>
          <li>System fetches their <code>company_id</code> from the <code>users</code> table</li>
          <li>JWT token is created (but doesn't store <code>company_id</code> - it's fetched fresh on each request)</li>
          <li>All API requests automatically filter by the user's <code>company_id</code></li>
        </ol>

        <h2>Critical Implementation Patterns</h2>

        <h3>1. Reading Data (SELECT queries)</h3>
        <p><strong>Always filter by <code>company_id</code></strong> to ensure users only see their company's data.</p>

        <div class="bg-green-50 border border-green-200 rounded p-4 my-4">
          <p class="font-semibold text-green-900 mb-2">✅ CORRECT</p>
          <pre class="bg-green-100 p-3 rounded overflow-x-auto"><code>const clients = await sql`
  SELECT * FROM clients
  WHERE company_id = ${currentUser.company_id}
`</code></pre>
        </div>

        <div class="bg-red-50 border border-red-200 rounded p-4 my-4">
          <p class="font-semibold text-red-900 mb-2">❌ WRONG - This would show all companies' data!</p>
          <pre class="bg-red-100 p-3 rounded overflow-x-auto"><code>const clients = await sql`
  SELECT * FROM clients
`</code></pre>
        </div>

        <h3>2. Creating Data (INSERT queries)</h3>
        <p><strong>Always include <code>company_id</code></strong> when inserting new records.</p>

        <div class="bg-green-50 border border-green-200 rounded p-4 my-4">
          <p class="font-semibold text-green-900 mb-2">✅ CORRECT</p>
          <pre class="bg-green-100 p-3 rounded overflow-x-auto"><code>await sql`
  INSERT INTO sessions (user_id, session_date, company_id)
  VALUES (${userId}, ${date}, ${currentUser.company_id})
`</code></pre>
        </div>

        <div class="bg-red-50 border border-red-200 rounded p-4 my-4">
          <p class="font-semibold text-red-900 mb-2">❌ WRONG - Record wouldn't belong to any company!</p>
          <pre class="bg-red-100 p-3 rounded overflow-x-auto"><code>await sql`
  INSERT INTO sessions (user_id, session_date)
  VALUES (${userId}, ${date})
`</code></pre>
        </div>

        <h3>3. Updating/Deleting Data</h3>
        <p><strong>Always verify <code>company_id</code></strong> in the WHERE clause to prevent cross-company modifications.</p>

        <div class="bg-green-50 border border-green-200 rounded p-4 my-4">
          <p class="font-semibold text-green-900 mb-2">✅ CORRECT</p>
          <pre class="bg-green-100 p-3 rounded overflow-x-auto"><code>await sql`
  UPDATE sessions
  SET status = 'completed'
  WHERE id = ${sessionId} AND company_id = ${currentUser.company_id}
`</code></pre>
        </div>

        <div class="bg-red-50 border border-red-200 rounded p-4 my-4">
          <p class="font-semibold text-red-900 mb-2">❌ WRONG - Could modify another company's record!</p>
          <pre class="bg-red-100 p-3 rounded overflow-x-auto"><code>await sql`
  UPDATE sessions
  SET status = 'completed'
  WHERE id = ${sessionId}
`</code></pre>
        </div>

        <h3>4. Getting Current User</h3>
        <p>Always use <code>getUserFromEvent()</code> which returns the user object including <code>company_id</code>:</p>

        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>import { getUserFromEvent } from '~~/server/utils/auth'

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
})</code></pre>

        <h2>Database Migration</h2>

        <h3>Initial Setup</h3>
        <p>Run the migration file to add <code>company_id</code> to all tables:</p>

        <pre class="bg-gray-900 text-green-400 p-4 rounded overflow-x-auto"><code># Connect to your database and run:
psql -U your_user -d your_database -f db/multi_tenant_migration.sql</code></pre>

        <h3>What the Migration Does</h3>
        <ol>
          <li>Creates <code>companies</code> table</li>
          <li>Inserts a default company (ID: 1)</li>
          <li>Adds <code>company_id</code> column to all main tables</li>
          <li>Migrates existing data to company ID 1</li>
          <li>Creates indexes for performance</li>
        </ol>

        <h2>User Registration Flow</h2>
        <p>When a new user registers (<code>/api/auth/register</code>):</p>
        <ol>
          <li>Creates a <strong>NEW company</strong> automatically</li>
          <li>Creates the user as <strong>Super Admin</strong> (permission: 0) of that company</li>
          <li>The user can then invite other users to their company</li>
        </ol>

        <h2>Common Pitfalls to Avoid</h2>

        <div class="bg-yellow-50 border-l-4 border-yellow-500 p-4 my-6">
          <p class="font-semibold text-yellow-900 mb-2">⚠️ DON'T: Use JOINs without filtering</p>
          <pre class="bg-yellow-100 p-3 rounded overflow-x-auto"><code>// BAD - Could leak data across companies
const data = await sql`
  SELECT * FROM sessions s
  LEFT JOIN clients c ON s.client_id = c.id
`</code></pre>
        </div>

        <div class="bg-green-50 border-l-4 border-green-500 p-4 my-6">
          <p class="font-semibold text-green-900 mb-2">✅ DO: Filter both tables</p>
          <pre class="bg-green-100 p-3 rounded overflow-x-auto"><code>// GOOD - Both tables filtered by company_id
const data = await sql`
  SELECT * FROM sessions s
  LEFT JOIN clients c ON s.client_id = c.id
  WHERE s.company_id = ${currentUser.company_id}
  AND c.company_id = ${currentUser.company_id}
`</code></pre>
        </div>

        <h2>Testing Multi-Tenancy</h2>

        <h3>Manual Testing Checklist</h3>
        <ol>
          <li>Register two different users (they get different companies)</li>
          <li>Create data as User A</li>
          <li>Login as User B</li>
          <li>Verify User B <strong>cannot see</strong> User A's data</li>
          <li>Verify User B <strong>cannot modify</strong> User A's data (even if they guess the ID)</li>
        </ol>

        <h3>Example Test</h3>
        <pre class="bg-gray-100 p-4 rounded overflow-x-auto"><code>// As Company 1 user, create a client
POST /api/clients
{ name: "John Doe", process_number: "001" }
// Returns: { id: 5, company_id: 1, ... }

// As Company 2 user, try to access it
GET /api/clients/5
// Should return: 404 Not Found (even though it exists!)</code></pre>

        <h2>Security Principles</h2>
        <ol>
          <li><strong>Defense in Depth</strong>: Always filter by <code>company_id</code>, even if you think the data is safe</li>
          <li><strong>Never Trust IDs</strong>: Users can guess/manipulate IDs in URLs - always verify ownership</li>
          <li><strong>Audit Regularly</strong>: Periodically search your codebase for queries missing <code>company_id</code></li>
          <li><strong>Index Performance</strong>: All <code>company_id</code> columns should be indexed</li>
        </ol>

        <h2>Quick Reference</h2>

        <div class="bg-blue-50 border border-blue-200 rounded p-4 my-4">
          <pre class="bg-blue-100 p-3 rounded overflow-x-auto"><code>// Get current user (includes company_id)
const currentUser = await getUserFromEvent(event)

// Read data
WHERE company_id = ${currentUser.company_id}

// Write data
INSERT INTO table (..., company_id)
VALUES (..., ${currentUser.company_id})

// Update/Delete data
WHERE id = ${id} AND company_id = ${currentUser.company_id}</code></pre>
        </div>

        <div class="bg-red-50 border-l-4 border-red-500 p-4 my-6">
          <p class="font-semibold text-red-900 mb-2">🔒 Security Alert</p>
          <p class="text-red-800 mb-0">
            If you find a query missing <code>company_id</code> filtering, it's a <strong>security bug</strong> and should be fixed immediately.
          </p>
        </div>

        <h2>File Locations</h2>
        <ul>
          <li>Migration: <code>db/multi_tenant_migration.sql</code></li>
          <li>Auth utilities: <code>server/utils/auth.ts</code></li>
          <li>API endpoints: <code>server/api/**/*.ts</code></li>
        </ul>
      </article>

      <!-- Bottom Navigation -->
      <div class="mt-8">
        <NuxtLink
          to="/guide"
          class="inline-flex items-center text-blue-600 hover:text-blue-800 font-medium"
        >
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          Back to Guides
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: false
})
</script>

<style scoped>
/* Custom styles for code blocks */
pre {
  font-size: 0.875rem;
  line-height: 1.5;
}

code {
  font-family: 'Monaco', 'Menlo', 'Consolas', monospace;
}

/* Prose styles for better readability */
.prose {
  color: #374151;
}

.prose h1 {
  color: #111827;
  font-size: 2.25rem;
  font-weight: 800;
  margin-bottom: 1rem;
}

.prose h2 {
  color: #1f2937;
  font-size: 1.875rem;
  font-weight: 700;
  margin-top: 2rem;
  margin-bottom: 1rem;
}

.prose h3 {
  color: #374151;
  font-size: 1.5rem;
  font-weight: 600;
  margin-top: 1.5rem;
  margin-bottom: 0.75rem;
}

.prose code {
  background-color: #f3f4f6;
  padding: 0.125rem 0.25rem;
  border-radius: 0.25rem;
  font-size: 0.875em;
  color: #be123c;
}

.prose pre code {
  background-color: transparent;
  padding: 0;
  color: inherit;
}

.prose ul, .prose ol {
  margin-top: 0.5rem;
  margin-bottom: 1rem;
}

.prose li {
  margin-top: 0.25rem;
  margin-bottom: 0.25rem;
}

.prose p {
  margin-top: 0.75rem;
  margin-bottom: 0.75rem;
}

.prose strong {
  font-weight: 600;
  color: #111827;
}
</style>
