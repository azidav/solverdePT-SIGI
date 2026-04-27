<script setup lang="ts">
import type { IGroup, IUser } from '~/types/permissions'

definePageMeta({
  title: 'Editar Utilizador'
})

const route = useRoute()
const toast = useToast()
const loading = ref(true)
const user = ref<IUser | null>(null)
const groups = ref<IGroup[]>([])

onMounted(async () => {
  try {
    const id = parseInt(route.params.id as string)
    const [userData, groupsData] = await Promise.all([
      useApiFetch(`/api/users/${id}`),
      useApiFetch('/api/roles')
    ])

    const raw = userData as IUser & { updated_at?: string }
    user.value = {
      ...raw,
      first_name: raw.name?.split(' ')[0] || '',
      last_name: raw.name?.split(' ').slice(1).join(' ') || '',
      modified_at: raw.updated_at || '',
      modified_by: '',
      roles: raw.roles || []
    }

    groups.value = groupsData as IGroup[]
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar dados', color: 'error' })
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <UDashboardPanel id="users-edit">
    <template #header>
      <UDashboardNavbar :title="user?.name || 'Editar Utilizador'">
        <template #leading>
          <UButton
            icon="i-lucide-arrow-left"
            color="neutral"
            variant="ghost"
            @click="navigateTo('/permissions/users')"
          />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div v-if="loading" class="flex items-center justify-center py-16">
        <UIcon name="i-lucide-loader-2" class="size-6 animate-spin text-primary" />
      </div>

      <div v-else-if="user" class="p-6">
        <UCard>
          <template #header>
            <div class="flex items-center gap-2">
              <UIcon name="i-lucide-user-cog" class="size-5 text-primary" />
              <h2 class="font-semibold">
                Informações do Utilizador
              </h2>
            </div>
          </template>
          <PermissionsUserForm
            :user="user"
            :groups="groups"
            @saved="navigateTo('/permissions/users')"
            @cancel="navigateTo('/permissions/users')"
          />
        </UCard>
      </div>
    </template>
  </UDashboardPanel>
</template>
