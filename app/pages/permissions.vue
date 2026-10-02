<script setup lang="ts">
const route = useRoute()

const tabs = [
  { label: 'Grupos', icon: 'i-lucide-users', value: 'groups' },
  { label: 'Utilizadores', icon: 'i-lucide-user', value: 'users' },
  { label: 'Utilizadores Desativados', icon: 'i-lucide-user-x', value: 'inactive' },
  { label: 'Utilizadores Eliminados', icon: 'i-lucide-trash-2', value: 'deleted' }
]

const TAB_ROUTES: Record<string, string> = {
  groups: '/permissions/groups',
  users: '/permissions/users',
  inactive: '/permissions/users/inactive',
  deleted: '/permissions/users/deleted'
}

const isDetailPage = computed(() =>
  route.path.endsWith('/new') || !!route.params.id
)

const activeTab = computed<string>(() => {
  if (route.path.startsWith('/permissions/users/inactive')) return 'inactive'
  if (route.path.startsWith('/permissions/users/deleted')) return 'deleted'
  if (route.path.startsWith('/permissions/users')) return 'users'
  return 'groups'
})

function onTabChange(value: string | number) {
  navigateTo(TAB_ROUTES[value as string])
}

// Redirect bare /permissions to the default tab
if (import.meta.client && (route.path === '/permissions' || route.path === '/permissions/')) {
  navigateTo('/permissions/groups', { replace: true })
}

// Importação de utilizadores por Excel
const showImport = ref(false)
function onImported() {
  // Recarrega a lista de utilizadores após importar
  if (import.meta.client) reloadNuxtApp({ path: '/permissions/users' })
}
</script>

<template>
  <!-- Detail pages (new / edit): render without the tab shell -->
  <NuxtPage v-if="isDetailPage" />

  <!-- Tab pages: full dashboard panel with route-synced tabs -->
  <UDashboardPanel v-else id="permissions">
    <template #header>
      <UDashboardNavbar title="Grupos & Utilizadores" icon="i-lucide-shield">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>
        <template #right>
          <UButton
            v-if="activeTab === 'groups'"
            icon="i-lucide-plus"
            label="Adicionar Grupo"
            color="primary"
            to="/permissions/groups/new"
          />
          <UButton
            v-if="activeTab === 'users'"
            icon="i-lucide-file-spreadsheet"
            label="Importar Excel"
            color="neutral"
            variant="subtle"
            @click="showImport = true"
          />
          <UButton
            v-if="activeTab === 'users'"
            icon="i-lucide-plus"
            label="Adicionar Utilizador"
            color="primary"
            to="/permissions/users/new"
          />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <UTabs
        :items="tabs"
        :model-value="activeTab"
        class="w-full"
        :ui="{ content: 'hidden' }"
        @update:model-value="onTabChange"
      />
      <NuxtPage />
    </template>
  </UDashboardPanel>

  <PermissionsBulkImportModal v-model:open="showImport" @imported="onImported" />
</template>
