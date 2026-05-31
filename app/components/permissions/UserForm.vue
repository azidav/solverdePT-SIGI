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
  birthday?: string | null
  employee_no?: string | null
  role_id: number | null
  role_name?: string
  status: number
  roles?: { id: number, name: string }[]
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

const baseSchema = {
  first_name: z.string().min(2, 'Primeiro nome deve ter pelo menos 2 caracteres'),
  last_name: z.string().min(2, 'Último nome deve ter pelo menos 2 caracteres'),
  email: z.email('Email inválido'),
  job_title: z.string().optional(),
  birthday: z.string().optional(),
  employee_no: z.string().min(1, 'Nº de identificação obrigatório')
}

const createSchema = z.object({
  ...baseSchema,
  username: z.string().min(3, 'Username deve ter pelo menos 3 caracteres')
})

const editSchema = z.object({
  ...baseSchema,
  username: z.string().optional(),
  employee_no: z.string().optional()
})

const schema = computed(() => isEditMode.value ? editSchema : createSchema)

type CreateSchema = z.output<typeof createSchema>

const state = reactive<Partial<CreateSchema>>({
  first_name: '',
  last_name: '',
  username: '',
  email: '',
  job_title: '',
  birthday: '',
  employee_no: ''
})

const assignedGroups = ref<IGroup[]>([])

const availableGroups = computed(() =>
  props.groups.filter(g => !assignedGroups.value.some(ag => ag.id === g.id))
)

const showGroupModal = ref(false)
const groupModalSearch = ref('')
const selectedInModal = ref<number[]>([])

const filteredAvailableGroups = computed(() => {
  const q = groupModalSearch.value.toLowerCase()
  if (!q) return availableGroups.value
  return availableGroups.value.filter(g => g.name.toLowerCase().includes(q))
})

function openGroupModal() {
  selectedInModal.value = []
  groupModalSearch.value = ''
  showGroupModal.value = true
}

function toggleGroupInModal(groupId: number) {
  if (selectedInModal.value.includes(groupId)) {
    selectedInModal.value = selectedInModal.value.filter(id => id !== groupId)
  } else {
    selectedInModal.value.push(groupId)
  }
}

function confirmGroupModal() {
  const toAdd = availableGroups.value.filter(g => selectedInModal.value.includes(g.id))
  toAdd.forEach(g => assignedGroups.value.push(g))
  showGroupModal.value = false
}

function removeGroup(groupId: number) {
  assignedGroups.value = assignedGroups.value.filter(g => g.id !== groupId)
}

function datePart(d: string | null | undefined): string {
  return d ? (d.split('T')[0] ?? '') : ''
}

function initUserData() {
  assignedGroups.value = []
  selectedInModal.value = []
  showGroupModal.value = false

  if (props.user) {
    state.first_name = props.user.first_name || props.user.name?.split(' ')[0] || ''
    state.last_name = props.user.last_name || props.user.name?.split(' ').slice(1).join(' ') || ''
    state.username = props.user.username || ''
    state.email = props.user.email || ''
    state.job_title = props.user.job_title || ''
    state.birthday = datePart(props.user.birthday)
    state.employee_no = props.user.employee_no || ''

    if (props.user.roles && Array.isArray(props.user.roles) && props.user.roles.length > 0) {
      assignedGroups.value = props.user.roles.map((r) => {
        const fullGroup = props.groups.find(g => g.id === r.id)
        return fullGroup || { id: r.id, name: r.name, description: '' }
      })
    } else if (props.user.role_id) {
      const group = props.groups.find(g => g.id === props.user!.role_id)
      if (group) assignedGroups.value = [group]
    }
  } else {
    state.first_name = ''
    state.last_name = ''
    state.username = ''
    state.email = ''
    state.job_title = ''
    state.birthday = ''
    state.employee_no = ''
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function onSubmit(event?: FormSubmitEvent<any>) {
  if (!event) return
  loading.value = true
  if (assignedGroups.value.length === 0) {
    toast.add({ title: 'Grupo obrigatório', description: 'O utilizador deve ter pelo menos um grupo associado.', color: 'error' })
    loading.value = false
    return
  }

  try {
    const fullName = `${event.data.first_name} ${event.data.last_name}`.trim()

    const body: Record<string, unknown> = {
      name: fullName,
      email: event.data.email,
      job_title: event.data.job_title || null,
      birthday: event.data.birthday || null,
      employee_no: event.data.employee_no || null
    }

    let userId = props.user?.id

    if (!isEditMode.value) {
      body.username = event.data.username
      body.status = 1
      body.permission = 3

      const result = await useApiFetch('/api/users', { method: 'POST', body }) as { id: number }
      userId = result.id
    } else {
      await useApiFetch(`/api/users/${userId}`, { method: 'PUT', body })
    }

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

watch(() => props.user, () => {
  initUserData()
}, { immediate: true })

onMounted(() => {
  initUserData()
})
</script>

<template>
  <!-- eslint-disable-next-line @typescript-eslint/no-explicit-any -->
  <UForm
    :schema="(schema as any)"
    :state="state"
    class="space-y-4"
    @submit="onSubmit"
  >
    <!-- Linha 1: First name / Last name -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <UFormField
        class="w-full"
        label="Primeiro Nome"
        name="first_name"
        required
      >
        <UInput
          v-model="state.first_name"
          class="w-full"
          placeholder="João"
        />
      </UFormField>

      <UFormField
        class="w-full"
        label="Último Nome"
        name="last_name"
        required
      >
        <UInput
          v-model="state.last_name"
          class="w-full"
          placeholder="Silva"
        />
      </UFormField>
    </div>

    <!-- Linha 2: Username / Email -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <UFormField
        class="w-full"
        label="Username"
        name="username"
        :required="!isEditMode"
      >
        <UInput
          v-model="state.username"
          class="w-full"
          placeholder="joao.silva"
          :disabled="isEditMode"
        />
      </UFormField>

      <UFormField
        class="w-full"
        label="Email"
        name="email"
        required
      >
        <UInput
          v-model="state.email"
          class="w-full"
          type="email"
          placeholder="joao.silva@solverde.pt"
        />
      </UFormField>
    </div>

    <!-- Linha 3: Job title / Birthday -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <UFormField
        label="Cargo / Função"
        name="job_title"
      >
        <UInput
          v-model="state.job_title"
          class="w-full"
          placeholder="Ex: Desenvolvedor, Gestor de Projeto..."
        />
      </UFormField>

      <UFormField
        label="Data de Nascimento"
        name="birthday"
      >
        <UInput
          v-model="state.birthday"
          type="date"
          class="w-full"
        />
      </UFormField>
    </div>

    <!-- Linha 4: Employee number -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <UFormField
        label="Nº de Identificação"
        name="employee_no"
        :required="!isEditMode"
      >
        <UInput
          v-model="state.employee_no"
          class="w-full"
          placeholder="Ex: 1234 ou EMP001"
          :disabled="isEditMode"
        />
      </UFormField>
    </div>

    <!-- Secção: Associar Grupos -->
    <UCard :ui="{ root: assignedGroups.length === 0 ? 'ring-1 ring-error-500' : '' }">
      <template #header>
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <UIcon name="i-lucide-shield" class="size-4 text-primary" />
            <h3 class="font-semibold text-sm">
              Grupos Associados
            </h3>
          </div>
          <UButton
            size="xs"
            variant="soft"
            icon="i-lucide-plus"
            label="Adicionar"
            :disabled="availableGroups.length === 0"
            @click="openGroupModal"
          />
        </div>
      </template>

      <div class="space-y-3">
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

        <p v-else class="text-sm text-error-500 flex items-center gap-1">
          <UIcon name="i-lucide-alert-circle" class="size-4 shrink-0" />
          Obrigatório — adicione pelo menos um grupo.
        </p>
      </div>
    </UCard>

    <!-- Botões -->
    <div class="flex justify-end gap-2 pt-2">
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

  <!-- Modal: Selecionar Grupos -->
  <UModal
    v-model:open="showGroupModal"
    title="Selecionar Grupos"
    :ui="{ content: 'max-w-md' }"
  >
    <template #body>
      <div class="space-y-3">
        <UInput
          v-model="groupModalSearch"
          icon="i-lucide-search"
          placeholder="Pesquisar por nome..."
          autofocus
        />

        <div class="max-h-64 overflow-y-auto divide-y divide-default rounded-lg border border-default">
          <div
            v-for="group in filteredAvailableGroups"
            :key="group.id"
            class="flex items-center gap-3 px-3 py-2.5 hover:bg-elevated/50 cursor-pointer transition-colors"
            @click="toggleGroupInModal(group.id)"
          >
            <UCheckbox
              :model-value="selectedInModal.includes(group.id)"
              @click.stop
              @update:model-value="toggleGroupInModal(group.id)"
            />
            <UIcon name="i-lucide-shield" class="size-4 text-primary shrink-0" />
            <span class="text-sm font-medium">{{ group.name }}</span>
          </div>

          <div v-if="filteredAvailableGroups.length === 0" class="px-3 py-6 text-center text-sm text-muted">
            Nenhum grupo disponível.
          </div>
        </div>

        <div class="flex items-center justify-between pt-1">
          <span class="text-sm text-muted">{{ selectedInModal.length }} selecionado(s)</span>
          <div class="flex gap-2">
            <UButton
              label="Cancelar"
              color="neutral"
              variant="subtle"
              @click="showGroupModal = false"
            />
            <UButton
              label="Adicionar"
              color="primary"
              icon="i-lucide-plus"
              :disabled="selectedInModal.length === 0"
              @click="confirmGroupModal"
            />
          </div>
        </div>
      </div>
    </template>
  </UModal>
</template>
