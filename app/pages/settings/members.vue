<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold">Gestão de Utilizadores</h1>
        <p class="text-gray-600 dark:text-gray-400 mt-1">
          Gerencie utilizadores, roles e permissões da SolverdePT
        </p>
      </div>
      <UButton icon="i-lucide-plus" @click="openAddModal" color="green">
        Novo Utilizador
      </UButton>
    </div>

    <!-- Filtros -->
    <div class="flex gap-2">
      <UInput
        v-model="searchQuery"
        placeholder="Pesquisar utilizador..."
        icon="i-lucide-search"
        class="flex-1"
      />
      <UButton
        variant="soft"
        :loading="loading"
        @click="loadUsers"
        icon="i-lucide-refresh-cw"
      >
        Refresho
      </UButton>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="text-center py-8">
      <div class="inline-flex items-center gap-2 text-gray-600">
        <div class="animate-spin">⟳</div>
        A carregar utilizadores...
      </div>
    </div>

    <!-- Utilizadores -->
    <div v-else-if="filteredUsers.length > 0" class="space-y-3">
      <div
        v-for="user in filteredUsers"
        :key="user.id"
        class="border rounded-lg p-4 bg-white dark:bg-slate-950 hover:bg-gray-50 dark:hover:bg-slate-900 transition"
      >
        <div class="flex items-start justify-between">
          <div class="flex-1">
            <div class="flex items-center gap-2">
              <h3 class="font-semibold text-lg">{{ user.name }}</h3>
              <UBadge
                :color="getRoleColor(user.role_name)"
                variant="subtle"
              >
                {{ user.role_name }}
              </UBadge>
              <UBadge :color="getStatusColor(user.status)" variant="subtle">
                {{ getStatusLabel(user.status) }}
              </UBadge>
            </div>
            <p class="text-gray-600 dark:text-gray-400 text-sm mt-1">
              @{{ user.username }} • {{ user.email }}
            </p>
            <p class="text-xs text-gray-500 mt-2">
              Departamento: {{ user.department || 'N/A' }}
            </p>
          </div>

          <div class="flex gap-2 ml-4">
            <UButton
              size="sm"
              variant="soft"
              icon="i-lucide-eye"
              @click="viewUserDetails(user)"
            >
              Ver
            </UButton>
            <UButton
              size="sm"
              variant="soft"
              icon="i-lucide-edit"
              @click="editUser(user)"
            >
              Editar
            </UButton>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty -->
    <div v-else class="text-center py-12">
      <p class="text-gray-600 dark:text-gray-400">Nenhum utilizador encontrado</p>
    </div>

    <!-- Modal: Editar Utilizador -->
    <UModal v-model="showEditModal" :ui="{ width: 'w-full sm:max-w-2xl' }">
      <UserEditModal
        v-if="selectedUser"
        :user="selectedUser"
        :roles="roles"
        @save="saveUser"
        @close="showEditModal = false"
      />
    </UModal>

    <!-- Modal: Detalhes do Utilizador -->
    <UModal v-model="showDetailsModal" :ui="{ width: 'w-full sm:max-w-2xl' }">
      <UserDetailsModal
        v-if="selectedUser"
        :user="selectedUser"
        @close="showDetailsModal = false"
      />
    </UModal>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  middleware: 'auth'
})

const { canManageUsers } = useRbac()
const toast = useAppToast()

const loading = ref(false)
const users = ref<any[]>([])
const roles = ref<any[]>([])
const searchQuery = ref('')
const showEditModal = ref(false)
const showDetailsModal = ref(false)
const selectedUser = ref<any>(null)

const filteredUsers = computed(() => {
  return users.value.filter((user) =>
    user.name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    user.username.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    user.email.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

const loadUsers = async () => {
  loading.value = true
  try {
    const usersData = await useApiFetch('/api/users')
    users.value = usersData || []

    // Enriquecer com nomes de roles
    const rolesData = await useApiFetch('/api/roles')
    roles.value = rolesData || []

    users.value = users.value.map((user) => ({
      ...user,
      role_name: rolesData.find((r: any) => r.id === user.role_id)?.name || 'Sem Role'
    }))
  } catch (error) {
    toast.error('Erro ao carregar utilizadores')
  } finally {
    loading.value = false
  }
}

const openAddModal = () => {
  selectedUser.value = null
  showEditModal.value = true
}

const editUser = (user: any) => {
  selectedUser.value = user
  showEditModal.value = true
}

const viewUserDetails = (user: any) => {
  selectedUser.value = user
  showDetailsModal.value = true
}

const saveUser = async () => {
  await loadUsers()
  showEditModal.value = false
}

const getRoleColor = (role: string): string => {
  const colors: Record<string, string> = {
    'Admin': 'red',
    'Manager': 'orange',
    'Employee': 'blue',
    'Restricted': 'gray'
  }
  return colors[role] || 'gray'
}

const getStatusColor = (status: number): string => {
  const colors: Record<number, string> = {
    1: 'green',
    0: 'yellow',
    '-1': 'red'
  }
  return colors[status] || 'gray'
}

const getStatusLabel = (status: number): string => {
  const labels: Record<number, string> = {
    1: 'Ativo',
    0: 'Pendente',
    '-1': 'Inativo'
  }
  return labels[status] || 'Desconhecido'
}

onMounted(() => {
  if (!canManageUsers.value) {
    toast.error('Sem permissão para gerir utilizadores')
    navigateTo('/settings')
  }
  loadUsers()
})
</script>

