<script setup lang="ts">
const route = useRoute()
const { can, canApproveVacation } = useRbac()

const navConfig = computed(() => {
  const p = route.path
  if (p === '/ferias/nova') return { title: 'Novo Pedido de Férias', icon: 'i-lucide-calendar-plus', back: true }
  if (/^\/ferias\/\d+/.test(p)) return { title: 'Detalhe do Pedido', icon: 'i-lucide-file-text', back: true }
  if (p === '/ferias/admin') return { title: 'Administração — Férias', icon: 'i-lucide-shield-check', back: true }
  if (p === '/ferias/equipa') return { title: 'Calendário da Equipa', icon: 'i-lucide-users', back: true }
  if (p === '/ferias/levels') return { title: 'Níveis de Aprovação', icon: 'i-lucide-layers', back: true }
  return { title: 'As Minhas Férias', icon: 'i-lucide-calendar-days', back: false }
})

const isIndex = computed(() => route.path === '/ferias')
const isLevels = computed(() => route.path === '/ferias/levels')

const triggerCreateLevel = useState('ferias-create-level', () => false)
</script>

<template>
  <UDashboardPanel id="ferias">
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
            to="/ferias"
          />
        </template>

        <template v-if="isIndex || isLevels" #right>
          <UButton
            v-if="can('VACATION:CREATE') && isIndex"
            icon="i-lucide-plus"
            label="Novo Pedido"
            to="/ferias/nova"
          />
          <UButton
            v-if="canApproveVacation && isIndex"
            icon="i-lucide-shield-check"
            label="Administração"
            variant="ghost"
            to="/ferias/admin"
          />
          <UButton
            v-if="isLevels && can('VACATION:VIEW_LEVELS')"
            icon="i-lucide-plus"
            label="Novo Nível"
            color="primary"
            @click="triggerCreateLevel = true"
          />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <NuxtPage />
    </template>
  </UDashboardPanel>
</template>
