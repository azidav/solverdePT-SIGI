<script setup lang="ts">
import type { IGroup, IUser } from '~/types/permissions'

definePageMeta({
  title: 'Editar Grupo'
})

const route = useRoute()
const toast = useToast()
const loading = ref(true)
const group = ref<IGroup | null>(null)
const users = ref<IUser[]>([])

onMounted(async () => {
  try {
    const [groupsData, usersData] = await Promise.all([
      useApiFetch('/api/roles'),
      useApiFetch('/api/users')
    ])

    const id = parseInt(route.params.id as string)
    group.value = (groupsData as IGroup[]).find(g => g.id === id) || null

    if (!group.value) {
      toast.add({ title: 'Erro', description: 'Grupo não encontrado', color: 'error' })
      navigateTo('/permissions/groups')
      return
    }

    users.value = (usersData as IUser[]).map(u => ({
      ...u,
      first_name: u.name?.split(' ')[0] || '',
      last_name: u.name?.split(' ').slice(1).join(' ') || '',
      modified_at: '',
      modified_by: '',
      roles: u.roles || []
    }))
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar dados', color: 'error' })
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <UDashboardPanel id="groups-edit">
    <template #header>
      <UDashboardNavbar :title="group?.name || 'Editar Grupo'">
        <template #leading>
          <UButton
            icon="i-lucide-arrow-left"
            color="neutral"
            variant="ghost"
            @click="navigateTo('/permissions/groups')"
          />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div v-if="loading" class="flex items-center justify-center py-16">
        <UIcon name="i-lucide-loader-2" class="size-6 animate-spin text-primary" />
      </div>

      <div v-else-if="group" class="p-6">
        <UCard>
          <template #header>
            <div class="flex items-center gap-2">
              <UIcon name="i-lucide-users" class="size-5 text-primary" />
              <h2 class="font-semibold">
                Informações do Grupo
              </h2>
              <UBadge v-if="group.is_system" color="info" variant="subtle" size="xs">Sistema</UBadge>
            </div>
          </template>
          <PermissionsGroupForm
            :group="group"
            :users="users"
            @saved="navigateTo('/permissions/groups')"
            @cancel="navigateTo('/permissions/groups')"
          />
        </UCard>
      </div>
    </template>
  </UDashboardPanel>
</template>
