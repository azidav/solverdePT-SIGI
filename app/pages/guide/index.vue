<template>
  <div class="min-h-screen bg-gray-50">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <!-- Header -->
      <div class="mb-8">
        <h1 class="text-4xl font-bold text-gray-900 mb-4">Developer Guide</h1>
        <p class="text-lg text-gray-600">
          Technical documentation and implementation guides for the SolverdePT platform
        </p>
      </div>

      <!-- Guide Cards -->
      <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        <!-- Multi-Tenant Architecture -->
        <NuxtLink
          to="/guide/multi-tenant"
          class="block p-6 bg-white rounded-lg shadow hover:shadow-lg transition-shadow border border-gray-200"
        >
          <div class="flex items-center mb-4">
            <div class="p-2 bg-blue-100 rounded-lg">
              <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
              </svg>
            </div>
            <h2 class="ml-3 text-xl font-semibold text-gray-900">Multi-Tenant Architecture</h2>
          </div>
          <p class="text-gray-600">
            Learn how the multi-tenant system works, implementation patterns, and security best practices.
          </p>
          <div class="mt-4 flex items-center text-blue-600 font-medium">
            Read guide
            <svg class="ml-1 w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
            </svg>
          </div>
        </NuxtLink>

        <!-- UI Components -->
        <NuxtLink
          to="/guide/api-development"
          class="block p-6 bg-white rounded-lg shadow hover:shadow-lg transition-shadow border border-gray-200"
        >
          <div class="flex items-center mb-4">
            <div class="p-2 bg-green-100 rounded-lg">
              <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
              </svg>
            </div>
            <h2 class="ml-3 text-xl font-semibold text-gray-900">UI Components</h2>
          </div>
          <p class="text-gray-600">
            Learn how to use the Toaster notification system and Popup modal system with practical examples.
          </p>
          <div class="mt-4 flex items-center text-green-600 font-medium">
            Read guide
            <svg class="ml-1 w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </div>
        </NuxtLink>

        <!-- Database Schema -->
        <NuxtLink
          to="/guide/database"
          class="block p-6 bg-white rounded-lg shadow hover:shadow-lg transition-shadow border border-gray-200"
        >
          <div class="flex items-center mb-4">
            <div class="p-2 bg-purple-100 rounded-lg">
              <svg class="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" />
              </svg>
            </div>
            <h2 class="ml-3 text-xl font-semibold text-gray-900">Database Schema</h2>
          </div>
          <p class="text-gray-600">
            Complete database schema documentation, relationships, and migration guides.
          </p>
          <div class="mt-4 flex items-center text-purple-600 font-medium">
            Coming soon
            <svg class="ml-1 w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
          </div>
        </NuxtLink>

        <!-- Component Library -->
        <NuxtLink
          to="/guide/components"
          class="block p-6 bg-white rounded-lg shadow hover:shadow-lg transition-shadow border border-gray-200"
        >
          <div class="flex items-center mb-4">
            <div class="p-2 bg-pink-100 rounded-lg">
              <svg class="w-6 h-6 text-pink-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
              </svg>
            </div>
            <h2 class="ml-3 text-xl font-semibold text-gray-900">Component Library</h2>
          </div>
          <p class="text-gray-600">
            Reusable Vue components, popup system, toaster notifications, and form elements.
          </p>
          <div class="mt-4 flex items-center text-pink-600 font-medium">
            Coming soon
            <svg class="ml-1 w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
          </div>
        </NuxtLink>

        <!-- Authentication & Authorization -->
        <NuxtLink
          to="/guide/auth"
          class="block p-6 bg-white rounded-lg shadow hover:shadow-lg transition-shadow border border-gray-200"
        >
          <div class="flex items-center mb-4">
            <div class="p-2 bg-yellow-100 rounded-lg">
              <svg class="w-6 h-6 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            </div>
            <h2 class="ml-3 text-xl font-semibold text-gray-900">Authentication & Authorization</h2>
          </div>
          <p class="text-gray-600">
            User authentication flow, JWT tokens, permissions system, and role-based access control.
          </p>
          <div class="mt-4 flex items-center text-yellow-600 font-medium">
            Coming soon
            <svg class="ml-1 w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
          </div>
        </NuxtLink>

        <!-- Deployment -->
        <NuxtLink
          to="/guide/deployment"
          class="block p-6 bg-white rounded-lg shadow hover:shadow-lg transition-shadow border border-gray-200"
        >
          <div class="flex items-center mb-4">
            <div class="p-2 bg-red-100 rounded-lg">
              <svg class="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01" />
              </svg>
            </div>
            <h2 class="ml-3 text-xl font-semibold text-gray-900">Deployment</h2>
          </div>
          <p class="text-gray-600">
            Production deployment guide, environment variables, Docker setup, and CI/CD pipelines.
          </p>
          <div class="mt-4 flex items-center text-red-600 font-medium">
            Coming soon
            <svg class="ml-1 w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
            </svg>
          </div>
        </NuxtLink>
      </div>

      <!-- Back to Home -->
      <div class="mt-12">
        <NuxtLink
          to="/"
          class="inline-flex items-center text-blue-600 hover:text-blue-800 font-medium"
        >
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          Back to Home
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
