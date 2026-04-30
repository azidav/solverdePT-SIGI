<script setup lang="ts">
import type { NavigationMenuItem } from '@nuxt/ui'

const { can, canManageRoles } = useRbac()

const open = ref(false)

const links = computed(() => {
  const mainLinks: NavigationMenuItem[] = []

  mainLinks.push({
    label: 'Home',
    icon: 'i-lucide-house',
    to: '/',
    onSelect: () => { open.value = false }
  })

  if (can('ROOMS:VIEW')) {
    if (can('ROOMS:MANAGE')) {
      mainLinks.push({
        label: 'Salas de Reunião',
        icon: 'i-lucide-door-open',
        to: '/meeting-rooms',
        defaultOpen: true,
        type: 'trigger',
        children: [
          {
            label: 'Fazer Reserva',
            icon: 'i-lucide-calendar-plus',
            to: '/meeting-rooms',
            exact: true,
            onSelect: () => { open.value = false }
          },
          {
            label: 'Gerir Salas',
            icon: 'i-lucide-settings-2',
            to: '/meeting-rooms/manage',
            onSelect: () => { open.value = false }
          }
        ]
      })
    } else {
      mainLinks.push({
        label: 'Salas de Reunião',
        icon: 'i-lucide-door-open',
        to: '/meeting-rooms',
        onSelect: () => { open.value = false }
      })
    }
  }

  if (can('SETTINGS:VIEW')) {
    const settingsChildren: NavigationMenuItem[] = [{
      label: 'Geral',
      to: '/settings',
      exact: true,
      onSelect: () => { open.value = false }
    }]

    if (canManageRoles.value) {
      settingsChildren.push({
        label: 'Roles & Permissões',
        to: '/permissions',
        onSelect: () => { open.value = false }
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
