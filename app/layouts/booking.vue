<script setup lang="ts">
const auth = useAuth()
const logged = useCookie('auth.loggedIn')
const isAuthenticated = computed(() => auth.isAuthenticated.value || logged.value === '1')
const userName = computed(() => auth.user.value?.name || auth.user.value?.username || '')

async function logout() {
  await auth.logout()
  navigateTo('/login')
}
</script>

<template>
  <div class="min-h-screen flex flex-col bg-default">
    <header class="border-b border-default bg-default/80 backdrop-blur sticky top-0 z-10">
      <div class="max-w-7xl mx-auto px-4 h-14 flex items-center justify-between gap-4">
        <div class="flex items-center gap-3">
          <NuxtLink to="/" class="flex items-center gap-2 text-highlighted font-semibold">
            <UIcon name="i-lucide-building-2" class="size-5 text-primary" />
            <span class="hidden sm:inline">SolverdePT</span>
          </NuxtLink>
          <span class="text-muted hidden sm:inline">/</span>
          <span class="font-medium text-sm">Salas de Reunião</span>
        </div>

        <div class="flex items-center gap-2">
          <template v-if="isAuthenticated">
            <span class="text-sm text-muted hidden sm:inline">{{ userName }}</span>
            <UButton
              icon="i-lucide-layout-dashboard"
              label="Dashboard"
              to="/"
              size="sm"
              color="neutral"
              variant="ghost"
              class="hidden sm:flex"
            />
            <UButton
              icon="i-lucide-log-out"
              size="sm"
              color="neutral"
              variant="ghost"
              @click="logout"
            />
          </template>
          <template v-else>
            <UButton
              label="Entrar"
              icon="i-lucide-log-in"
              to="/login"
              size="sm"
              color="primary"
              variant="soft"
            />
          </template>
        </div>
      </div>
    </header>

    <main class="flex-1 max-w-7xl mx-auto w-full px-4 py-6">
      <slot />
    </main>
  </div>
</template>
