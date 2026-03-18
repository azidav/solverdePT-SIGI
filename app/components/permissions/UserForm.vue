<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

interface IGroup {
  id: number
  name: string
  description: string
}

interface IUser {
  id?: number
  username: string
  name: string
  first_name: string
  last_name: string
  email: string
  job_title?: string
  role_id: number | null
  role_name?: string
  status: number
  roles?: { id: number; name: string }[]
}

const props = defineProps<{
  user?: IUser | null
  groups: IGroup[]
}>()

const emit = defineEmits<{
  cancel: []
  saved: []
}>()

const toast = useToast()
const loading = ref(false)

const isEditMode = computed(() => !!props.user?.id)

// Schema de validação
const baseSchema = {
  first_name: z.string().min(2, 'Primeiro nome deve ter pelo menos 2 caracteres'),
  last_name: z.string().min(2, 'Último nome deve ter pelo menos 2 caracteres'),
  email: z.string().email('Email inválido'),
  job_title: z.string().optional()
}

const createSchema = z.object({
  ...baseSchema,
  username: z.string().min(3, 'Username deve ter pelo menos 3 caracteres'),
  password: z.string().min(6, 'Password deve ter pelo menos 6 caracteres')
})

const editSchema = z.object({
  ...baseSchema,
  username: z.string().optional()
})

const schema = computed(() => isEditMode.value ? editSchema : createSchema)

type CreateSchema = z.output<typeof createSchema>
type EditSchema = z.output<typeof editSchema>

// Estado do formulário
const state = reactive<Partial<CreateSchema>>({
  first_name: '',
  last_name: '',
  username: '',
  email: '',
  password: '',
  job_title: ''
})

// Grupos associados ao utilizador
const assignedGroups = ref<IGroup[]>([])
const showGroupSelect = ref(false)
const selectedGroupId = ref<number | undefined>(undefined)

// Grupos disponíveis (não associados)
const availableGroups = computed(() =>
  props.groups.filter(g => !assignedGroups.value.some(ag => ag.id === g.id))
)

// Opções para o select de grupos
const groupSelectItems = computed(() =>
  availableGroups.value.map(g => ({
    label: g.name,
    value: g.id
  }))
)

// Adicionar grupo
function addGroup(groupId: number) {
  const group = props.groups.find(g => g.id === groupId)
  if (group && !assignedGroups.value.some(g => g.id === groupId)) {
    assignedGroups.value.push(group)
  }
  showGroupSelect.value = false
  selectedGroupId.value = undefined
}

// Handler para quando o utilizador seleciona do dropdown
function handleGroupSelect(groupId: number) {
  if (groupId) {
    addGroup(groupId)
  }
}

// Remover grupo
function removeGroup(groupId: number) {
  assignedGroups.value = assignedGroups.value.filter(g => g.id !== groupId)
}

// Inicializar dados do utilizador
function initUserData() {
  // Limpar sempre primeiro
  assignedGroups.value = []
  selectedGroupId.value = undefined
  showGroupSelect.value = false

  if (props.user) {
    state.first_name = props.user.first_name || props.user.name?.split(' ')[0] || ''
    state.last_name = props.user.last_name || props.user.name?.split(' ').slice(1).join(' ') || ''
    state.username = props.user.username || ''
    state.email = props.user.email || ''
    state.job_title = props.user.job_title || ''

    // Carregar grupos associados (múltiplos roles)
    if (props.user.roles && Array.isArray(props.user.roles) && props.user.roles.length > 0) {
      assignedGroups.value = props.user.roles.map(r => {
        const fullGroup = props.groups.find(g => g.id === r.id)
        return fullGroup || { id: r.id, name: r.name, description: '' }
      })
    } else if (props.user.role_id) {
      // Fallback para role_id único (compatibilidade)
      const group = props.groups.find(g => g.id === props.user!.role_id)
      if (group) {
        assignedGroups.value = [group]
      }
    }
  } else {
    state.first_name = ''
    state.last_name = ''
    state.username = ''
    state.email = ''
    state.password = ''
    state.job_title = ''
  }
}

// Submeter formulário
async function onSubmit(event: FormSubmitEvent<CreateSchema | EditSchema>) {
  loading.value = true
  try {
    const fullName = `${event.data.first_name} ${event.data.last_name}`.trim()

    const body: Record<string, unknown> = {
      name: fullName,
      email: event.data.email
    }

    let userId = props.user?.id

    if (!isEditMode.value) {
      body.username = (event.data as CreateSchema).username
      body.password = (event.data as CreateSchema).password
      body.status = 1
      body.permission = 3 // Default: Utilizador

      // Criar utilizador primeiro
      const result = await useApiFetch('/api/users', { method: 'POST', body }) as { id: number }
      userId = result.id
    } else {
      // Atualizar utilizador
      await useApiFetch(`/api/users/${userId}`, { method: 'PUT', body })
    }

    // Atualizar roles (múltiplos)
    if (userId) {
      const roleIds = assignedGroups.value.map(g => g.id)
      await useApiFetch('/api/user-roles', {
        method: 'POST',
        body: { user_id: userId, role_ids: roleIds }
      })
    }

    toast.add({
      title: 'Sucesso',
      description: isEditMode.value ? 'Utilizador atualizado com sucesso' : 'Utilizador criado com sucesso',
      color: 'success'
    })

    emit('saved')
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Erro ao guardar utilizador'
    toast.add({ title: 'Erro', description: message, color: 'error' })
  } finally {
    loading.value = false
  }
}

// Watch para atualizar quando o utilizador muda
watch(() => props.user, () => {
  initUserData()
}, { immediate: true })

onMounted(() => {
  initUserData()
})
</script>

<template>
  <UForm
    :schema="schema"
    :state="state"
    class="space-y-4"
    @submit="onSubmit"
  >
    <!-- Linha 1: First name / Last name -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <UFormField label="Primeiro Nome" name="first_name" required>
        <UInput
          v-model="state.first_name"
          placeholder="João"
        />
      </UFormField>

      <UFormField label="Último Nome" name="last_name" required>
        <UInput
          v-model="state.last_name"
          placeholder="Silva"
        />
      </UFormField>
    </div>

    <!-- Linha 2: Username / Email -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <UFormField label="Username" name="username" :required="!isEditMode">
        <UInput
          v-model="state.username"
          placeholder="joao.silva"
          :disabled="isEditMode"
        />
      </UFormField>

      <UFormField label="Email" name="email" required>
        <UInput
          v-model="state.email"
          type="email"
          placeholder="joao.silva@solverdept.com"
        />
      </UFormField>
    </div>

    <!-- Password (apenas para novo utilizador) -->
    <div v-if="!isEditMode" class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <UFormField label="Password" name="password" required>
        <UInput
          v-model="state.password"
          type="password"
          placeholder="••••••••"
        />
      </UFormField>
    </div>

    <!-- Linha 3: Job title -->
    <UFormField label="Cargo / Função" name="job_title">
      <UInput
        v-model="state.job_title"
        placeholder="Ex: Desenvolvedor, Gestor de Projeto..."
      />
    </UFormField>

    <!-- Secção: Associar Grupos -->
    <div class="space-y-3 pt-4 border-t border-default">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <UIcon name="i-lucide-shield" class="size-4 text-primary" />
          <span class="font-medium">Grupos Associados</span>
        </div>
        <UButton
          size="xs"
          variant="soft"
          icon="i-lucide-plus"
          label="Adicionar"
          :disabled="availableGroups.length === 0"
          @click="showGroupSelect = !showGroupSelect"
        />
      </div>

      <!-- Select para adicionar grupos -->
      <div v-if="showGroupSelect && availableGroups.length > 0">
        <USelect
          v-model="selectedGroupId"
          :items="groupSelectItems"
          placeholder="Selecionar grupo..."
          @update:model-value="handleGroupSelect"
        />
      </div>

      <!-- Lista de grupos associados com badges -->
      <div v-if="assignedGroups.length > 0" class="flex flex-wrap gap-2">
        <UBadge
          v-for="group in assignedGroups"
          :key="group.id"
          color="primary"
          variant="subtle"
          size="lg"
          class="pr-1"
        >
          <span class="mr-1">{{ group.name }}</span>
          <UButton
            icon="i-lucide-x"
            color="primary"
            variant="link"
            size="xs"
            :padded="false"
            @click="removeGroup(group.id)"
          />
        </UBadge>
      </div>

      <p v-else class="text-sm text-muted">
        Nenhum grupo associado. Adicione grupos para definir as permissões do utilizador.
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
        :label="isEditMode ? 'Guardar Alterações' : 'Criar Utilizador'"
        color="primary"
        :loading="loading"
      />
    </div>
  </UForm>
</template>
