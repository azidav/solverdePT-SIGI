<template>
  <div class="space-y-6">
    <!-- Header -->
    <UButton icon="i-lucide-arrow-left" variant="ghost" @click="$router.back()">
      Voltar
    </UButton>

    <div>
      <h1 class="text-2xl font-bold">
        Criar Novo Role
      </h1>
      <p class="text-gray-600 dark:text-gray-400 mt-1">
        Define o nome, descrição e permissões do novo role
      </p>
    </div>

    <!-- Form -->
    <UCard>
      <template #header>
        <h3 class="text-lg font-semibold">
          Novo Role
        </h3>
      </template>

      <form class="space-y-6" @submit.prevent="submitForm">
        <!-- Nome -->
        <UFormGroup label="Nome da Role*" name="name" :error="errors.name">
          <UInput
            v-model="formData.name"
            placeholder="Ex: Marketing Manager, IT Support"
          />
        </UFormGroup>

        <!-- Descrição -->
        <UFormGroup label="Descrição" name="description">
          <UTextarea
            v-model="formData.description"
            placeholder="Descrição da role..."
            :rows="3"
          />
        </UFormGroup>

        <!-- Permissões -->
        <div class="border-t pt-6">
          <h4 class="font-semibold mb-4">
            Atribuir Permissões
          </h4>

          <div v-if="loadingPermissions" class="text-center py-8 text-gray-500">
            <div class="flex justify-center gap-2">
              <div class="inline-block w-2 h-2 bg-gray-400 rounded-full animate-bounce" />
              <div class="inline-block w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0.1s" />
              <div class="inline-block w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0.2s" />
            </div>
            A carregar permissões...
          </div>

          <div v-else-if="Object.keys(groupedPermissions).length > 0" class="space-y-4">
            <!-- Permissions by module -->
            <div
              v-for="(perms, module) in groupedPermissions"
              :key="module"
              class="border rounded-lg p-4 bg-white dark:bg-slate-950"
            >
              <!-- Module header -->
              <div class="flex items-center gap-3 mb-4 pb-3 border-b">
                <UCheckbox
                  :model-value="isModuleFullySelected(module)"
                  :indeterminate="isModulePartiallySelected(module)"
                  @update:model-value="toggleAllInModule(module)"
                />
                <span class="font-semibold text-sm">{{ moduleLabels[module] || module }}</span>
                <span class="text-xs text-gray-500 ml-auto">
                  {{ getModuleSelectedCount(module) }} / {{ perms.length }}
                </span>
              </div>

              <!-- Permissions in module -->
              <div class="space-y-2">
                <div
                  v-for="permission in perms"
                  :key="permission.id"
                  class="flex items-start gap-3 p-2 hover:bg-gray-50 dark:hover:bg-slate-800 rounded"
                >
                  <UCheckbox
                    :model-value="selectedPermissions.includes(permission.id)"
                    @update:model-value="togglePermission(permission.id, $event as boolean)"
                  />
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium">
                      {{ permission.description }}
                    </p>
                    <p class="text-xs text-gray-500">
                      {{ permission.code }}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-else class="text-center py-8 text-yellow-600 dark:text-yellow-400 bg-yellow-50 dark:bg-yellow-900/20 rounded">
            ⚠️ Nenhuma permissão disponível
          </div>
        </div>

        <!-- Botões -->
        <div class="flex gap-2 pt-4 border-t">
          <UButton
            type="submit"
            :loading="loading"
            color="success"
          >
            Criar Role com Permissões
          </UButton>
          <UButton
            color="secondary"
            @click="$router.back()"
          >
            Cancelar
          </UButton>
        </div>
      </form>
    </UCard>
  </div>
</template>

<script setup lang="ts">
interface RoleFormData {
  name: string
  description: string
}

interface Permission {
  id: number
  code: string
  description: string
  module: string
}

interface PermissionsResponse {
  flat: Permission[]
  grouped: Record<string, Permission[]>
}

interface NewRole {
  id: number
  name: string
  description?: string
}

definePageMeta({
  middleware: 'permissions'
})

const router = useRouter()
const toast = useAppToast()
const loading = ref(false)
const errors = ref<Record<string, string>>({})
const allPermissions = ref<Permission[]>([])
const selectedPermissions = ref<number[]>([])
const loadingPermissions = ref(true)

const formData = ref<RoleFormData>({
  name: '',
  description: ''
})

const moduleLabels: Record<string, string> = {
  VACATION: '🏖️ Férias',
  EQUIPMENT: '🖥️ Equipamentos',
  ROOMS: '🏢 Salas de Reunião',
  SETTINGS: '⚙️ Definições'
}

const groupedPermissions = computed(() => {
  const grouped: Record<string, Permission[]> = {}
  allPermissions.value.forEach((perm) => {
    const module = perm.module
    if (!grouped[module]) {
      grouped[module] = []
    }
    grouped[module].push(perm)
  })
  return grouped
})

const togglePermission = (id: number, selected: boolean) => {
  if (selected) {
    if (!selectedPermissions.value.includes(id)) {
      selectedPermissions.value.push(id)
    }
  } else {
    selectedPermissions.value = selectedPermissions.value.filter(p => p !== id)
  }
}

const isModuleFullySelected = (module: string): boolean => {
  const perms = groupedPermissions.value[module] || []
  return perms.length > 0 && perms.every(p => selectedPermissions.value.includes(p.id))
}

const isModulePartiallySelected = (module: string): boolean => {
  const perms = groupedPermissions.value[module] || []
  const count = perms.filter(p => selectedPermissions.value.includes(p.id)).length
  return count > 0 && count < perms.length
}

const toggleAllInModule = (module: string) => {
  const perms = groupedPermissions.value[module] || []
  const isFullySelected = isModuleFullySelected(module)

  if (isFullySelected) {
    selectedPermissions.value = selectedPermissions.value.filter(
      id => !perms.some(p => p.id === id)
    )
  } else {
    const idsToAdd = perms
      .filter(p => !selectedPermissions.value.includes(p.id))
      .map(p => p.id)
    selectedPermissions.value.push(...idsToAdd)
  }
}

const getModuleSelectedCount = (module: string): number => {
  const perms = groupedPermissions.value[module] || []
  return perms.filter(p => selectedPermissions.value.includes(p.id)).length
}

// Carregar permissões ao montar
onMounted(async () => {
  loadingPermissions.value = true
  try {
    const response = await $fetch('/api/permissions')
    if (response && typeof response === 'object') {
      const data = response as unknown as PermissionsResponse
      if (data.flat && Array.isArray(data.flat)) {
        allPermissions.value = data.flat as Permission[]
      } else {
        toast.warning('Formato de permissões inválido')
      }
    }
  } catch (error) {
    console.error('Erro ao carregar permissões:', error)
    toast.error('Erro ao carregar permissões')
  } finally {
    loadingPermissions.value = false
  }
})

const submitForm = async () => {
  errors.value = {}

  if (!formData.value.name.trim()) {
    errors.value.name = 'Nome é obrigatório'
    return
  }

  loading.value = true
  try {
    // Criar role
    const newRole = await useApiFetch('/api/roles', {
      method: 'POST',
      body: formData.value
    }) as NewRole

    // Atribuir permissões se selecionadas
    if (selectedPermissions.value.length > 0) {
      await useApiFetch(`/api/roles/${newRole.id}/permissions`, {
        method: 'POST',
        body: {
          permissionIds: selectedPermissions.value
        }
      })
    }

    toast.success('Role criado com permissões atribuídas com sucesso')
    router.push('/settings/roles')
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : 'Erro ao criar role'
    toast.error(msg)
  } finally {
    loading.value = false
  }
}
</script>
