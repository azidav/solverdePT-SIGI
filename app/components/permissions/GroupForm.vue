<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

interface IGroup {
  id?: number
  name: string
  description: string
  is_system?: boolean
  users?: { id: number; name: string; email: string }[]
}

interface IUser {
  id: number
  username: string
  name: string
  email: string
  roles?: { id: number; name: string }[]
}

interface IPermission {
  id: number
  code: string
  description: string
  module: string
  action: string
}

const props = defineProps<{
  group?: IGroup | null
  users: IUser[]
}>()

const emit = defineEmits<{
  cancel: []
  saved: []
}>()

const toast = useToast()
const loading = ref(false)

const isEditMode = computed(() => !!props.group?.id)

// ===== PERMISSÕES =====
const allPermissions = ref<IPermission[]>([])
const selectedPermissions = ref<number[]>([])
const loadingPermissions = ref(false)

// Labels para os módulos
const moduleLabels: Record<string, string> = {
  VACATION: 'Férias',
  EQUIPMENT: 'Equipamentos',
  ROOMS: 'Salas de Reunião',
  SETTINGS: 'Definições'
}

const moduleIcons: Record<string, string> = {
  VACATION: 'i-lucide-palm-tree',
  EQUIPMENT: 'i-lucide-monitor',
  ROOMS: 'i-lucide-door-open',
  SETTINGS: 'i-lucide-settings'
}

// Agrupar permissões por módulo
const groupedPermissions = computed(() => {
  const grouped: Record<string, IPermission[]> = {}
  allPermissions.value.forEach((perm) => {
    if (!grouped[perm.module]) {
      grouped[perm.module] = []
    }
    grouped[perm.module]!.push(perm)
  })
  return grouped
})

// Toggle uma permissão individual
function togglePermission(id: number, selected: boolean) {
  if (selected) {
    if (!selectedPermissions.value.includes(id)) {
      selectedPermissions.value.push(id)
    }
  } else {
    selectedPermissions.value = selectedPermissions.value.filter(p => p !== id)
  }
}

// Verificar se módulo está totalmente selecionado
function isModuleFullySelected(module: string): boolean {
  const perms = groupedPermissions.value[module] || []
  return perms.length > 0 && perms.every(p => selectedPermissions.value.includes(p.id))
}

// Verificar se módulo está parcialmente selecionado
function isModulePartiallySelected(module: string): boolean {
  const perms = groupedPermissions.value[module] || []
  const count = perms.filter(p => selectedPermissions.value.includes(p.id)).length
  return count > 0 && count < perms.length
}

// Toggle todas as permissões de um módulo
function toggleAllInModule(module: string) {
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

// Contagem de permissões selecionadas por módulo
function getModuleSelectedCount(module: string): number {
  const perms = groupedPermissions.value[module] || []
  return perms.filter(p => selectedPermissions.value.includes(p.id)).length
}

// Carregar todas as permissões disponíveis
async function loadPermissions() {
  loadingPermissions.value = true
  try {
    const data = await useApiFetch('/api/permissions') as { flat: IPermission[] }
    allPermissions.value = data.flat || []

    // Se estamos a editar, carregar permissões atuais do grupo
    if (props.group?.id) {
      const rolePerms = await useApiFetch(`/api/roles/${props.group.id}/permissions`) as IPermission[]
      selectedPermissions.value = rolePerms.map(p => p.id)
    }
  } catch (error) {
    console.error('Erro ao carregar permissões:', error)
  } finally {
    loadingPermissions.value = false
  }
}

// Schema de validação
const schema = z.object({
  name: z.string().min(2, 'Nome deve ter pelo menos 2 caracteres'),
  description: z.string().optional()
})

type Schema = z.output<typeof schema>

// Estado do formulário
const state = reactive<Partial<Schema>>({
  name: props.group?.name || '',
  description: props.group?.description || ''
})

// Utilizadores associados a este grupo
const assignedUsers = ref<{ id: number; name: string; email: string }[]>([])
const availableUsers = ref<{ id: number; name: string; email: string }[]>([])
const showUserSelect = ref(false)
const selectedUserId = ref<number | undefined>(undefined)

// Carregar utilizadores associados ao grupo
function loadAssignedUsers() {
  if (props.group?.id && props.group?.users) {
    // Carregar utilizadores do grupo (vem da API)
    assignedUsers.value = [...props.group.users]
    // Utilizadores disponíveis = todos menos os já associados
    const assignedIds = new Set(assignedUsers.value.map(u => u.id))
    availableUsers.value = props.users
      .filter(u => !assignedIds.has(u.id))
      .map(u => ({ id: u.id, name: u.name, email: u.email }))
  } else {
    assignedUsers.value = []
    availableUsers.value = props.users.map(u => ({ id: u.id, name: u.name, email: u.email }))
  }
}

// Adicionar utilizador ao grupo
function addUser(user: { id: number; name: string; email: string }) {
  assignedUsers.value.push(user)
  availableUsers.value = availableUsers.value.filter(u => u.id !== user.id)
  showUserSelect.value = false
  selectedUserId.value = undefined
}

// Handler para quando o utilizador seleciona do dropdown
function handleUserSelect(userId: number) {
  const user = availableUsers.value.find(u => u.id === userId)
  if (user) {
    addUser(user)
  }
}

// Remover utilizador do grupo
function removeUser(userId: number) {
  const user = assignedUsers.value.find(u => u.id === userId)
  if (user) {
    assignedUsers.value = assignedUsers.value.filter(u => u.id !== userId)
    availableUsers.value.push(user)
  }
}

// Opções para o select de utilizadores
const userSelectItems = computed(() =>
  availableUsers.value.map(u => ({
    label: `${u.name} (${u.email})`,
    value: u.id
  }))
)

// Submeter formulário
async function onSubmit(event: FormSubmitEvent<Schema>) {
  loading.value = true
  try {
    const endpoint = isEditMode.value ? `/api/roles/${props.group!.id}` : '/api/roles'
    const method = isEditMode.value ? 'PUT' : 'POST'

    const result = await useApiFetch(endpoint, {
      method,
      body: event.data
    }) as { id: number }

    const groupId = isEditMode.value ? props.group!.id! : result.id

    // Guardar permissões do grupo
    await useApiFetch(`/api/roles/${groupId}/permissions`, {
      method: 'POST',
      body: { permissionIds: selectedPermissions.value }
    })

    // Atualizar associações de utilizadores via user-roles API
    const originalUsers = props.group?.users || []
    const originalUserIds = originalUsers.map(u => u.id)
    const newUserIds = assignedUsers.value.map(u => u.id)

    // Para cada utilizador que foi adicionado ou removido, precisamos atualizar os seus roles
    const allAffectedUserIds = new Set([...originalUserIds, ...newUserIds])

    for (const userId of allAffectedUserIds) {
      const wasInGroup = originalUserIds.includes(userId)
      const isInGroup = newUserIds.includes(userId)

      if (wasInGroup !== isInGroup) {
        // Buscar os roles atuais do utilizador
        const user = props.users.find(u => u.id === userId)
        const currentRoleIds = user?.roles?.map(r => r.id) || []

        let newRoleIds: number[]
        if (isInGroup) {
          // Adicionar este grupo aos roles do utilizador
          newRoleIds = [...currentRoleIds, groupId]
        } else {
          // Remover este grupo dos roles do utilizador
          newRoleIds = currentRoleIds.filter(id => id !== groupId)
        }

        await useApiFetch('/api/user-roles', {
          method: 'POST',
          body: { user_id: userId, role_ids: newRoleIds }
        })
      }
    }

    toast.add({
      title: 'Sucesso',
      description: isEditMode.value ? 'Grupo atualizado com sucesso' : 'Grupo criado com sucesso',
      color: 'success'
    })

    emit('saved')
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Erro ao guardar grupo'
    toast.add({ title: 'Erro', description: message, color: 'error' })
  } finally {
    loading.value = false
  }
}

// Watch para atualizar quando o grupo muda
watch(() => props.group, () => {
  state.name = props.group?.name || ''
  state.description = props.group?.description || ''
  loadAssignedUsers()
  loadPermissions()
}, { immediate: true })

onMounted(() => {
  loadAssignedUsers()
  loadPermissions()
})
</script>

<template>
  <UForm
    :schema="schema"
    :state="state"
    class="space-y-4"
    @submit="onSubmit"
  >
    <!-- Nome -->
    <UFormField label="Nome" name="name" required>
      <UInput
        v-model="state.name"
        placeholder="Ex: Administradores, Editores..."
        :disabled="group?.is_system"
      />
    </UFormField>

    <!-- Descrição -->
    <UFormField label="Descrição" name="description">
      <UTextarea
        v-model="state.description"
        placeholder="Descrição do grupo e suas permissões..."
        :rows="3"
      />
    </UFormField>

    <!-- Info de grupo do sistema -->
    <div v-if="group?.is_system" class="p-3 bg-info-50 dark:bg-info-900/20 rounded-lg border border-info-200 dark:border-info-800">
      <p class="text-sm text-info-700 dark:text-info-300 flex items-center gap-2">
        <UIcon name="i-lucide-info" class="size-4" />
        Este é um grupo de sistema e não pode ser eliminado.
      </p>
    </div>

    <!-- Secção: Associar Utilizadores -->
    <div class="space-y-3 pt-4 border-t border-default">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <UIcon name="i-lucide-users" class="size-4 text-primary" />
          <span class="font-medium">Utilizadores Associados</span>
        </div>
        <UButton
          size="xs"
          variant="soft"
          icon="i-lucide-plus"
          label="Adicionar"
          :disabled="availableUsers.length === 0"
          @click="showUserSelect = !showUserSelect"
        />
      </div>

      <!-- Select para adicionar utilizadores -->
      <div v-if="showUserSelect && availableUsers.length > 0" class="space-y-2">
        <USelect
          v-model="selectedUserId"
          :items="userSelectItems"
          placeholder="Selecionar utilizador..."
          @update:model-value="handleUserSelect"
        />
      </div>

      <!-- Lista de utilizadores associados com badges -->
      <div v-if="assignedUsers.length > 0" class="flex flex-wrap gap-2">
        <UBadge
          v-for="user in assignedUsers"
          :key="user.id"
          color="primary"
          variant="subtle"
          size="lg"
          class="pr-1"
        >
          <span class="mr-1">{{ user.name }}</span>
          <UButton
            icon="i-lucide-x"
            color="primary"
            variant="link"
            size="xs"
            :padded="false"
            @click="removeUser(user.id)"
          />
        </UBadge>
      </div>

      <p v-else class="text-sm text-muted">
        Nenhum utilizador associado a este grupo.
      </p>

      <!-- Aviso ao criar novo grupo -->
      <div v-if="!isEditMode && assignedUsers.length > 0" class="p-3 bg-warning-50 dark:bg-warning-900/20 rounded-lg border border-warning-200 dark:border-warning-800">
        <p class="text-sm text-warning-700 dark:text-warning-300 flex items-center gap-2">
          <UIcon name="i-lucide-info" class="size-4" />
          Os utilizadores serão associados após criar o grupo.
        </p>
      </div>
    </div>

    <!-- Secção: Matriz de Permissões -->
    <div class="space-y-3 pt-4 border-t border-default">
      <div class="flex items-center gap-2 mb-4">
        <UIcon name="i-lucide-shield-check" class="size-4 text-primary" />
        <span class="font-medium">Permissões do Grupo</span>
      </div>

      <!-- Loading state -->
      <div v-if="loadingPermissions" class="flex items-center justify-center py-8">
        <UIcon name="i-lucide-loader-2" class="size-6 animate-spin text-primary" />
        <span class="ml-2 text-sm text-muted">A carregar permissões...</span>
      </div>

      <!-- Matriz de Permissões por Módulo -->
      <div v-else-if="Object.keys(groupedPermissions).length > 0" class="space-y-4">
        <div
          v-for="(perms, module) in groupedPermissions"
          :key="module"
          class="border border-default rounded-lg overflow-hidden"
        >
          <!-- Header do Módulo -->
          <div class="flex items-center gap-3 px-4 py-3 bg-elevated">
            <UCheckbox
              :model-value="isModuleFullySelected(module as string)"
              :indeterminate="isModulePartiallySelected(module as string)"
              @update:model-value="toggleAllInModule(module as string)"
            />
            <UIcon :name="moduleIcons[module as string] || 'i-lucide-folder'" class="size-5 text-primary" />
            <span class="font-semibold text-sm flex-1">{{ moduleLabels[module as string] || module }}</span>
            <UBadge color="neutral" variant="subtle" size="xs">
              {{ getModuleSelectedCount(module as string) }} / {{ perms.length }}
            </UBadge>
          </div>

          <!-- Tabela de Permissões -->
          <div class="divide-y divide-default">
            <div
              v-for="permission in perms"
              :key="permission.id"
              class="flex items-center gap-3 px-4 py-2.5 hover:bg-elevated/50 transition-colors"
            >
              <UCheckbox
                :model-value="selectedPermissions.includes(permission.id)"
                @update:model-value="togglePermission(permission.id, $event as boolean)"
              />
              <div class="flex-1 min-w-0">
                <p class="text-sm">{{ permission.description }}</p>
              </div>
              <code class="text-xs text-muted bg-muted px-1.5 py-0.5 rounded">
                {{ permission.action }}
              </code>
            </div>
          </div>
        </div>
      </div>

      <p v-else class="text-sm text-muted text-center py-4">
        Nenhuma permissão disponível.
      </p>
    </div>

    <!-- Botões -->
    <div class="flex justify-end gap-2 pt-4">
      <UButton
        label="Cancelar"
        color="neutral"
        variant="subtle"
        @click="emit('cancel')"
      />
      <UButton
        type="submit"
        :label="isEditMode ? 'Guardar Alterações' : 'Criar Grupo'"
        color="primary"
        :loading="loading"
      />
    </div>
  </UForm>
</template>
