<template>
  <div class="p-6 space-y-6">
    <!-- Header -->
    <div>
      <h3 class="text-lg font-semibold">{{ user.name }}</h3>
      <p class="text-gray-600 dark:text-gray-400">@{{ user.username }}</p>
    </div>

    <!-- Informações Básicas -->
    <div class="grid grid-cols-2 gap-4">
      <div>
        <p class="text-xs text-gray-600 dark:text-gray-400 font-semibold uppercase">Email</p>
        <p class="text-sm mt-1">{{ user.email }}</p>
      </div>
      <div>
        <p class="text-xs text-gray-600 dark:text-gray-400 font-semibold uppercase">Departamento</p>
        <p class="text-sm mt-1">{{ user.department || '-' }}</p>
      </div>
      <div>
        <p class="text-xs text-gray-600 dark:text-gray-400 font-semibold uppercase">Role</p>
        <div class="mt-1">
          <UBadge color="blue" variant="subtle">{{ user.role_name }}</UBadge>
        </div>
      </div>
      <div>
        <p class="text-xs text-gray-600 dark:text-gray-400 font-semibold uppercase">Status</p>
        <div class="mt-1">
          <UBadge :color="getStatusColor(user.status)" variant="subtle">
            {{ getStatusLabel(user.status) }}
          </UBadge>
        </div>
      </div>
    </div>

    <!-- Permissões -->
    <div class="border-t pt-4" v-if="permissions.length">
      <h4 class="font-semibold mb-3">Permissões ({{ permissions.length }})</h4>

      <div
        v-for="(perms, module) in groupedPermissions"
        :key="module"
        class="mb-4"
      >
        <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          {{ moduleLabels[module] || module }}
        </p>
        <div class="flex flex-wrap gap-2 ml-2">
          <UBadge
            v-for="perm in perms"
            :key="perm.id"
            variant="soft"
            color="gray"
            class="text-xs"
          >
            {{ perm.description }}
          </UBadge>
        </div>
      </div>
    </div>

    <!-- Sem permissões -->
    <div v-else class="border-t pt-4">
      <p class="text-sm text-gray-500">Nenhuma permissão atribuída</p>
    </div>

    <!-- Botão Fechar -->
    <div class="pt-4 border-t">
      <UButton @click="$emit('close')" variant="soft" color="gray" class="w-full">
        Fechar
      </UButton>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  user: any
}>()

const emit = defineEmits<{
  close: []
}>()

const permissions = ref<any[]>([])

const moduleLabels: Record<string, string> = {
  VACATION: '🏖️ Férias',
  EQUIPMENT: '🖥️ Equipamentos',
  ROOMS: '🏢 Salas de Reunião',
  SETTINGS: '⚙️ Definições'
}

const groupedPermissions = computed(() => {
  return permissions.value.reduce(
    (acc: Record<string, any[]>, perm) => {
      if (!acc[perm.module]) {
        acc[perm.module] = []
      }
      acc[perm.module].push(perm)
      return acc
    },
    {}
  )
})

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

onMounted(async () => {
  if (props.user?.role_id) {
    try {
      permissions.value = await useApiFetch(`/api/roles/${props.user.role_id}/permissions`)
    } catch (error) {
      console.error('Erro ao carregar permissões:', error)
    }
  }
})
</script>
