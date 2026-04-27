<script setup lang="ts">
import type { DropdownMenuItem } from '@nuxt/ui'
import useAuth from '/composables/useAuth'

defineProps<{
  collapsed?: boolean
}>()

const colorMode = useColorMode()
const appConfig = useAppConfig()
const auth = useAuth()

// derive a display user from the authenticated user, falling back to placeholder
const user = computed(() => {
  const u = auth.user?.value ?? null
  if (u) {
    return {
      name: u.name || u.username,
      avatar: {
        src: (u as any).avatar?.src || undefined,
        alt: u.name || u.username
      }
    }
  }

  return {
    name: 'Unknown',
    avatar: {
      src: '',
      alt: 'Unknown'
    }
  }
})

const items = computed<DropdownMenuItem[][]>(() => ([[{
  type: 'label',
  label: user.value.name,
  avatar: user.value.avatar
}], [{
  label: 'Mudar Password',
  icon: 'i-lucide-key-round',
  to: '/settings/change-password'
}], [{
  label: 'Aparência',
  icon: 'i-lucide-sun-moon',
  children: [{
    label: 'Claro',
    icon: 'i-lucide-sun',
    type: 'checkbox',
    checked: colorMode.value === 'light',
    onSelect(e: Event) {
      e.preventDefault()

      colorMode.preference = 'light'
    }
  }, {
    label: 'Escuro',
    icon: 'i-lucide-moon',
    type: 'checkbox',
    checked: colorMode.value === 'dark',
    onUpdateChecked(checked: boolean) {
      if (checked) {
        colorMode.preference = 'dark'
      }
    },
    onSelect(e: Event) {
      e.preventDefault()
    }
  }]
}], [{
  label: 'Site',
  icon: 'ic:twotone-personal-video',
  to: 'https://www.solverde.pt/',
  target: '_blank'
},  {
  label: 'Log out',
  icon: 'i-lucide-log-out',
  onClick: () => auth.logout()
}]]))
</script>

<template>
  <UDropdownMenu
    :items="items"
    :content="{ align: 'center', collisionPadding: 12 }"
    :ui="{ content: collapsed ? 'w-48' : 'w-(--reka-dropdown-menu-trigger-width)' }"
  >
    <UButton
      v-bind="{
        ...user,
        label: collapsed ? undefined : user?.name,
        trailingIcon: collapsed ? undefined : 'i-lucide-chevrons-up-down'
      }"
      color="neutral"
      variant="ghost"
      block
      :square="collapsed"
      class="data-[state=open]:bg-elevated"
      :ui="{
        trailingIcon: 'text-dimmed'
      }"
    />

    <template #chip-leading="{ item }">
      <div class="inline-flex items-center justify-center shrink-0 size-5">
        <span
          class="rounded-full ring ring-bg bg-(--chip-light) dark:bg-(--chip-dark) size-2"
          :style="{
            '--chip-light': `var(--color-${(item as any).chip}-500)`,
            '--chip-dark': `var(--color-${(item as any).chip}-400)`
          }"
        />
      </div>
    </template>
  </UDropdownMenu>
</template>
