<script setup lang="ts">
import type { NavigationMenuItem } from '@nuxt/ui'

const route = useRoute()
const { can, canManageRoles, canManageUsers } = useRbac()

const open = ref(false)

const links = computed(() => {
  const mainLinks: NavigationMenuItem[] = []

  // Home - sempre visível
  mainLinks.push({
    label: 'Home',
    icon: 'i-lucide-house',
    to: '/',
    onSelect: () => {
      open.value = false
    }
  })

  // Settings - apenas com permissão SETTINGS:VIEW
  if (can('SETTINGS:VIEW')) {
    const settingsChildren: NavigationMenuItem[] = [{
      label: 'Geral',
      to: '/settings',
      exact: true,
      onSelect: () => {
        open.value = false
      }
    }]

    // Roles & Permissões - requer SETTINGS:MANAGE_ROLES
    if (canManageRoles.value) {
      settingsChildren.push({
        label: 'Roles & Permissões',
        to: '/permissions',
        onSelect: () => {
          open.value = false
        }
      })

      settingsChildren.push({
        label: 'Audit Logs',
        to: '/audit-logs',
        onSelect: () => { open.value = false }
      })

    }

    mainLinks.push({
      label: 'Settings',
      to: '/settings',
      icon: 'i-lucide-settings',
      defaultOpen: true,
      type: 'trigger',
      children: settingsChildren
    })
  }

  return [[...mainLinks]] as NavigationMenuItem[][]
})

const groups = computed(() => [{
  id: 'links',
  label: 'Navegação',
  items: links.value.flat()
}])
</script>

<template>
  <UDashboardGroup unit="rem">
    <UDashboardSidebar
      id="default"
      v-model:open="open"
      collapsible
      resizable
      class="bg-elevated/25"
      :ui="{ footer: 'lg:border-t lg:border-default' }"
    >
      <template #header="{ collapsed }">
        <Logo :collapsed="collapsed" />
      </template>

      <template #default="{ collapsed }">
        <UDashboardSearchButton :collapsed="collapsed" class="bg-transparent ring-default" />

        <UNavigationMenu
          :collapsed="collapsed"
          :items="links[0]"
          orientation="vertical"
          tooltip
          popover
        />
      </template>

      <template #footer="{ collapsed }">
        <UserMenu :collapsed="collapsed" />
      </template>
    </UDashboardSidebar>

    <UDashboardSearch :groups="groups" />

    <slot />

  </UDashboardGroup>
</template>
