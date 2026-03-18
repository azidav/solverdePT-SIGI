<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold">
          Gestão de Roles
        </h1>
        <p class="text-gray-600 dark:text-gray-400 mt-1">
          Crie e configure roles (grupos de permissões) para a SolverdePT
        </p>
      </div>
      <UButton
        icon="i-lucide-plus"
        size="lg"
        color="success"
        @click="createNewRole"
      >
        Novo Role
      </UButton>
    </div>

    <!-- Search and Filter -->
    <UCard class="bg-white dark:bg-slate-950">
      <div class="flex gap-2">
        <UInput
          v-model="searchQuery"
          icon="i-lucide-search"
          placeholder="Pesquisar role..."
          class="flex-1"
        />
        <UButton
          icon="i-lucide-refresh-cw"
          color="gray"
          variant="soft"
          :loading="loading"
          @click="loadRoles"
        />
      </div>
    </UCard>

    <!-- Loading State -->
    <div v-if="loading" class="flex justify-center py-12">
      <div class="text-center">
        <div class="inline-flex items-center gap-3">
          <UIcon name="i-lucide-loader" class="w-5 h-5 animate-spin" />
          <span class="text-gray-600 dark:text-gray-400">A carregar roles...</span>
        </div>
      </div>
    </div>

    <!-- Roles Grid -->
    <div v-else-if="filteredRoles.length > 0" class="grid gap-3 md:grid-cols-1 lg:grid-cols-2">
      <UCard
        v-for="role in filteredRoles"
        :key="role.id"
        class="hover:shadow-md transition-shadow"
      >
        <template #header>
          <div class="flex items-center justify-between">
            <h3 class="font-bold text-lg">
              {{ role.name }}
            </h3>
            <UBadge
              v-if="role.is_system"
              variant="subtle"
              color="blue"
            >
              Sistema
            </UBadge>
          </div>
        </template>

        <div class="space-y-3">
          <div>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              {{ role.description || 'Sem descrição' }}
            </p>
            <p class="text-xs text-gray-500 mt-2">
              Criado em {{ formatDate(role.created_at) }}
            </p>
          </div>

          <div class="flex gap-2 pt-3 border-t">
            <UButton
              size="sm"
              color="primary"
              variant="soft"
              icon="i-lucide-edit"
              @click="editRole(role.id)"
            >
              Editar
            </UButton>
            <UButton
              v-if="!role.is_system"
              size="sm"
              color="error"
              variant="soft"
              icon="i-lucide-trash-2"
              @click="confirmDeleteRole(role.id, role.name)"
            >
              Eliminar
            </UButton>
          </div>
        </div>
      </UCard>
    </div>

    <!-- Empty State -->
    <div v-else class="flex justify-center py-12">
      <div class="text-center">
        <UIcon name="i-lucide-inbox" class="w-12 h-12 text-gray-400 mx-auto mb-3" />
        <p class="text-gray-600 dark:text-gray-400">
          Nenhum role encontrado
        </p>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <UModal v-model="showDeleteModal">
      <UCard class="mx-auto w-full max-w-sm">
        <template #header>
          <p class="text-lg font-semibold">
            Confirmar Eliminação
          </p>
        </template>

        <div class="space-y-4">
          <p class="text-gray-600 dark:text-gray-400">
            Tem certeza que deseja eliminar o role <span class="font-semibold">{{ roleToDelete.name }}</span>?
          </p>
          <p class="text-sm text-yellow-600 dark:text-yellow-400">
            ⚠️ Esta ação não pode ser desfeita.
          </p>
        </div>

        <template #footer>
          <div class="flex gap-2">
            <UButton
              color="error"
              :loading="deletingRole"
              @click="executeDelete"
            >
              Eliminar
            </UButton>
            <UButton
              color="gray"
              variant="soft"
              @click="showDeleteModal = false"
            >
              Cancelar
            </UButton>
          </div>
        </template>
      </UCard>
    </UModal>
  </div>
</template>

<script setup lang="ts">
interface IRole {
  id: number
  name: string
  description?: string
  is_system: boolean
  created_at?: string
}

definePageMeta({
  middleware: 'permissions'
})

const router = useRouter()
const toast = useAppToast()

const loading = ref(false)
const roles = ref<IRole[]>([])
const searchQuery = ref('')
const showDeleteModal = ref(false)
const deletingRole = ref(false)
const roleToDelete = ref<{ id: number; name: string }>({ id: 0, name: '' })

const filteredRoles = computed(() => {
  return roles.value.filter(role =>
    role.name.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

const loadRoles = async () => {
  loading.value = true
  try {
    const data = await useApiFetch('/api/roles')
    roles.value = data as IRole[]
  } catch {
    toast.error('Erro ao carregar roles')
  } finally {
    loading.value = false
  }
}

const createNewRole = () => {
  router.push('/settings/roles/new')
}

const editRole = (roleId: number) => {
  router.push(`/settings/roles/${roleId}`)
}

const confirmDeleteRole = (roleId: number, roleName: string) => {
  roleToDelete.value = { id: roleId, name: roleName }
  showDeleteModal.value = true
}

const executeDelete = async () => {
  deletingRole.value = true
  try {
    await useApiFetch(`/api/roles/${roleToDelete.value.id}`, {
      method: 'DELETE'
    })
    toast.success('Role eliminado com sucesso')
    showDeleteModal.value = false
    await loadRoles()
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : 'Erro ao eliminar role'
    toast.error(msg)
  } finally {
    deletingRole.value = false
  }
}

const formatDate = (date: string | undefined) => {
  if (!date) return '-'
  return new Date(date).toLocaleDateString('pt-PT')
}

onMounted(() => {
  loadRoles()
})
</script>
