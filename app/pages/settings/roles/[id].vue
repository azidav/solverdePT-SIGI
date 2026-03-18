<template>
  <div class="space-y-6">
    <!-- Header -->
    <UButton icon="i-lucide-arrow-left" variant="ghost" @click="$router.back()">
      Voltar
    </UButton>

    <!-- Tabs -->
    <UTabs v-model="activeTab" :items="tabs">
      <!-- Detalhes da Role -->
      <template v-if="activeTab === 0" #default>
        <div class="space-y-4" v-if="role">
          <!-- System Role Warning -->
          <UCallout
            v-if="role.is_system"
            icon="i-lucide-info"
            color="blue"
            title="Role de Sistema"
          >
            Este é um role de sistema. Apenas o nome e descrição podem ser modificados.
          </UCallout>

          <!-- Role Details Card -->
          <UCard>
            <template #header>
              <h3 class="text-lg font-semibold">
                Informações do Role
              </h3>
            </template>

            <div class="space-y-4">
              <!-- Name Field -->
              <UFormGroup label="Nome do Role" required>
                <UInput
                  v-model="formData.name"
                  placeholder="Ex: Gestor de Projeto"
                  icon="i-lucide-type"
                />
              </UFormGroup>

              <!-- Description Field -->
              <UFormGroup label="Descrição">
                <UTextarea
                  v-model="formData.description"
                  placeholder="Descrição do role e suas responsabilidades"
                  rows="4"
                />
              </UFormGroup>
            </div>

            <!-- Action Buttons -->
            <template #footer>
              <div class="flex gap-2">
                <UButton
                  color="success"
                  icon="i-lucide-check"
                  :loading="savingRole"
                  @click="submitForm"
                >
                  Guardar Alterações
                </UButton>
                <UButton
                  color="gray"
                  variant="soft"
                  icon="i-lucide-x"
                  @click="$router.back()"
                >
                  Cancelar
                </UButton>
                <UButton
                  v-if="!role.is_system"
                  color="error"
                  variant="soft"
                  icon="i-lucide-trash-2"
                  class="ml-auto"
                  @click="confirmDelete"
                >
                  Eliminar Role
                </UButton>
              </div>
            </template>
          </UCard>
        </div>
      </template>

      <!-- Permissões da Role -->
      <template v-else-if="activeTab === 1" #default>
        <div class="space-y-4">
          <UCard>
            <template #header>
              <h3 class="text-lg font-semibold">
                Atribuir Permissões
              </h3>
            </template>

            <div v-if="Object.keys(groupedPermissions).length > 0" class="space-y-4">
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

              <div class="flex gap-2 pt-4 border-t">
                <UButton
                  color="success"
                  :loading="savingPermissions"
                  @click="savePermissions"
                >
                  Guardar Permissões
                </UButton>
                <UButton variant="soft" color="secondary" @click="cancelPermissions">
                  Cancelar
                </UButton>
              </div>
            </div>

            <div v-else class="text-center py-8 text-gray-500">
              A carregar permissões...
            </div>
          </UCard>
        </div>
      </template>
    </UTabs>

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
            Tem certeza que deseja eliminar o role <span class="font-semibold">{{ role?.name }}</span>?
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
interface Role {
  id: number
  name: string
  description?: string
  is_system?: boolean
}

interface Permission {
  id: number
  code: string
  description: string
  module: string
}

definePageMeta({
  middleware: 'permissions'
})

const router = useRouter()
const route = useRoute()
const toast = useAppToast()

const roleId = computed(() => parseInt(route.params.id as string))
const activeTab = ref(0)
const role = ref<Role | null>(null)
const allPermissions = ref<Permission[]>([])
const selectedPermissions = ref<number[]>([])
const savingPermissions = ref(false)
const savingRole = ref(false)
const showDeleteModal = ref(false)
const deletingRole = ref(false)
const formData = ref({
  name: '',
  description: ''
})

const tabs = [
  { key: 'details', label: 'Detalhes', icon: 'i-lucide-info' },
  { key: 'permissions', label: 'Permissões', icon: 'i-lucide-lock' }
]

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

const loadRole = async () => {
  try {
    const data = await useApiFetch(`/api/roles/${roleId.value}`)
    role.value = data as Role
    formData.value = {
      name: (data as Role).name,
      description: (data as Role).description || ''
    }
  } catch {
    toast.error('Erro ao carregar role')
    router.back()
  }
}

const loadPermissions = async () => {
  try {
    const data = await useApiFetch('/api/permissions')
    allPermissions.value = (data as { flat: Permission[] }).flat || []

    // Load current role's permissions
    const rolePerms = await useApiFetch(`/api/roles/${roleId.value}/permissions`)
    selectedPermissions.value = (rolePerms as Permission[]).map(p => p.id)
  } catch {
    toast.error('Erro ao carregar permissões')
  }
}

const submitForm = async () => {
  savingRole.value = true
  try {
    const updated = await useApiFetch(`/api/roles/${roleId.value}`, {
      method: 'PUT',
      body: formData.value
    })
    role.value = updated as Role
    toast.success('Role atualizado com sucesso')
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : 'Erro ao atualizar role'
    toast.error(msg)
  } finally {
    savingRole.value = false
  }
}

const confirmDelete = () => {
  showDeleteModal.value = true
}

const executeDelete = async () => {
  deletingRole.value = true
  try {
    await useApiFetch(`/api/roles/${roleId.value}`, { method: 'DELETE' })
    toast.success('Role eliminado com sucesso')
    router.push('/settings/roles')
  } catch (error: unknown) {
    const msg = error instanceof Error ? error.message : 'Erro ao eliminar role'
    toast.error(msg)
  } finally {
    deletingRole.value = false
  }
}

const savePermissions = async () => {
  savingPermissions.value = true
  try {
    console.log('[SavePermissions] Sending request to API')
    console.log('[SavePermissions] Role ID:', roleId.value)
    console.log('[SavePermissions] Permission IDs:', selectedPermissions.value)
    console.log('[SavePermissions] Body:', { permissionIds: selectedPermissions.value })

    await useApiFetch(`/api/roles/${roleId.value}/permissions`, {
      method: 'POST',
      body: { permissionIds: selectedPermissions.value }
    })
    toast.success('Permissões guardadas com sucesso')
    await loadPermissions()
  } catch (error: unknown) {
    console.error('[SavePermissions] Error:', error)
    const msg = error instanceof Error ? error.message : 'Erro ao guardar permissões'
    toast.error(msg)
  } finally {
    savingPermissions.value = false
  }
}

const cancelPermissions = () => {
  loadPermissions()
}

onMounted(() => {
  loadRole()
  loadPermissions()
})
</script>
