<script setup lang="ts">
const route = useRoute()

const navConfig = computed(() => {
  const p = route.path
  if (p.endsWith('/new')) return { title: 'Nova Sala de Reunião', icon: 'i-lucide-door-open', back: '/meeting-rooms/manage' }
  if (route.params.id) return { title: 'Editar Sala', icon: 'i-lucide-door-open', back: '/meeting-rooms/manage' }
  return { title: 'Gerir Salas de Reunião', icon: 'i-lucide-settings-2', back: '/meeting-rooms' }
})

const isIndex = computed(() => route.path === '/meeting-rooms/manage')
</script>

<template>
  <UDashboardPanel id="rooms-manage">
    <template #header>
      <UDashboardNavbar
        :title="navConfig.title"
        :icon="navConfig.icon"
      >
        <template #leading>
          <UDashboardSidebarCollapse v-if="!navConfig.back" />
          <UButton
            v-if="navConfig.back"
            icon="i-lucide-arrow-left"
            variant="ghost"
            :to="navConfig.back"
          />
        </template>

        <template v-if="isIndex" #right>
          <UButton
            label="Nova Sala"
            icon="i-lucide-plus"
            color="primary"
            to="/meeting-rooms/manage/new"
          />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <NuxtPage />
    </template>
  </UDashboardPanel>
</template>
