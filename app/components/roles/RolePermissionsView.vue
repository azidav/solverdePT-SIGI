<template>
  <div class="p-6 space-y-4">
    <h3 class="text-lg font-semibold">
      Permiss\u00f5es da Role
    </h3>

    <div v-if="loading" class="text-center py-8">
      <div class="inline-flex items-center gap-2 text-gray-600">
        <div class="animate-spin">
          \u27f3
        </div>
        A carregar...
      </div>
    </div>

    <div v-else-if="Object.keys(groupedPermissions).length">
      <div
        v-for="(perms, module) in groupedPermissions"
        :key="module"
        class="mb-4"
      >
        <h4 class="font-semibold text-sm mb-2">
          {{ moduleLabels[module] || module }}
        </h4>
        <div class="grid grid-cols-1 gap-2 ml-2">
          <div
            v-for="perm in perms"
            :key="perm.id"
            class="flex items-start gap-2 text-sm"
          >
            <span class="text-green-600">✓</span>
            <div>
              <p class="font-medium">
                {{ perm.description }}
              </p>
              <p class="text-xs text-gray-500">
                {{ perm.code }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-else class="text-center py-8 text-gray-500">
      Nenhuma permiss\u00e3o atribu\u00edda a este role
    </div>

    <div class="pt-4 border-t">
      <UButton
        variant="soft"
        @click="$emit('close')"
      >
        Fechar
      </UButton>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Permission {
  id: number
  code: string
  description: string
  module: string
}

const props = defineProps<{
  roleId: number | null
}>()

defineEmits<{
  close: []
}>()

const loading = ref(false)
const permissions = ref<Permission[]>([])

const moduleLabels: Record<string, string> = {
  VACATION: '🏖️ Férias',
  EQUIPMENT: '🖥️ Equipamentos',
  ROOMS: '🏢 Salas de Reunião',
  SETTINGS: '⚙️ Definições'
}

const groupedPermissions = computed(() => {
  const acc: Record<string, Permission[]> = {}
  permissions.value.forEach((perm) => {
    if (acc[perm.module] === undefined) {
      acc[perm.module] = []
    }
    acc[perm.module]!.push(perm)
  })
  return acc
})

const loadPermissions = async () => {
  if (!props.roleId) return

  loading.value = true
  try {
    const data = await useApiFetch(`/api/roles/${props.roleId}/permissions`)
    permissions.value = data as Permission[]
  } catch {
    console.error('Erro ao carregar permiss\u00f5es')
  } finally {
    loading.value = false
  }
}

watch(
  () => props.roleId,
  () => loadPermissions(),
  { immediate: true }
)
</script>
