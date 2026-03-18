<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'
import { computed } from 'vue'

interface User {
  id: number
  username: string
  name: string
  email: string
  role_id: number | null
  subrole_id: number | null
  permission: number
  gender: string | null
  date_of_birth: string | null
  notes: string | null
  status: number
}

const props = defineProps<{
  user: User | null
  open: boolean
}>()

const emit = defineEmits(['update:open', 'updated'])

const toast = useAppToast()

// Fetch roles and subroles
const roles = ref<any[]>([])
const subroles = ref<any[]>([])
const loadingRoles = ref(true)

onMounted(async () => {
  try {
    const rolesData = await useApiFetch('/api/roles', { method: 'GET' })
    roles.value = Array.isArray(rolesData) ? rolesData : []
  } catch (error) {
    console.error('Erro ao carregar cargos:', error)
  } finally {
    loadingRoles.value = false
  }
})

const schema = z.object({
  name: z.string().min(2, 'Nome obrigatório'),
  email: z.string().email('Email inválido'),
  role_id: z.number().optional(),
  subrole_id: z.number().optional(),
  permission: z.number().min(0).max(4, 'Permissão deve estar entre 0 e 4'),
  gender: z.string().optional(),
  date_of_birth: z.string().optional(),
  notes: z.string().optional(),
  status: z.number()
})

type Schema = z.output<typeof schema>

const state = reactive<Partial<Schema>>({
  name: undefined,
  email: undefined,
  role_id: undefined,
  subrole_id: undefined,
  permission: 3,
  gender: undefined,
  date_of_birth: undefined,
  notes: undefined,
  status: 1
})

// Bridge prop open to a local v-model binding for UModal
const isOpen = computed({
  get: () => props.open,
  set: (val: boolean) => emit('update:open', val)
})

watch(() => props.user, (newUser) => {
  if (newUser) {
    state.name = newUser.name
    state.email = newUser.email
    state.role_id = newUser.role_id || undefined
    state.subrole_id = newUser.subrole_id || undefined
    state.permission = newUser.permission
    state.gender = newUser.gender || undefined
    state.date_of_birth = newUser.date_of_birth ? newUser.date_of_birth.split('T')[0] : undefined
    state.notes = newUser.notes || undefined
    state.status = newUser.status

    // Load subroles if role is set
    if (newUser.role_id) {
      loadSubroles(newUser.role_id)
    }
  }
}, { immediate: true })

const roleOptions = computed(() =>
  roles.value.map(r => ({ label: r.name, value: r.id }))
)

const subroleOptions = computed(() => {
  if (!state.role_id) return []
  return subroles.value
    .filter(sr => sr.role_id === state.role_id)
    .map(sr => ({ label: sr.name, value: sr.id }))
})

async function loadSubroles(roleId: number) {
  try {
    const subrolesData = await useApiFetch(`/api/subroles?role_id=${roleId}`, { method: 'GET' })
    subroles.value = Array.isArray(subrolesData) ? subrolesData : []
  } catch (error) {
    console.error('Erro ao carregar sub-cargos:', error)
  }
}

// Watch role changes to fetch subroles
watch(() => state.role_id, async (newRoleId) => {
  state.subrole_id = undefined
  if (!newRoleId) {
    subroles.value = []
    return
  }
  await loadSubroles(newRoleId)
})

const permissionOptions = [
  { label: 'Admin (0)', value: 0 },
  { label: 'Gestor (1)', value: 1 },
  { label: 'Supervisor (2)', value: 2 },
  { label: 'Utilizador (3)', value: 3 },
  { label: 'Convidado (4)', value: 4 }
]

const genderOptions = [
  { label: 'Masculino', value: 'M' },
  { label: 'Feminino', value: 'F' },
  { label: 'Outro', value: 'O' }
]

const statusOptions = [
  { label: 'Ativo', value: 1 },
  { label: 'Pendente', value: 0 },
  { label: 'Inativo', value: -1 }
]

async function onSubmit(event: FormSubmitEvent<Schema>) {
  if (!props.user) return

  try {
    await useApiFetch(`/api/users/${props.user.id}`, {
      method: 'PUT',
      body: event.data
    })

    toast.success('Utilizador atualizado com sucesso', 'Sucesso')

    emit('updated')
    isOpen.value = false
  } catch (error: unknown) {
    let message = 'Erro ao atualizar utilizador'
    if (typeof error === 'object' && error) {
      const maybe = error as Record<string, unknown>
      const fromMessage = typeof maybe['message'] === 'string' ? maybe['message'] as string : undefined
      const data = maybe['data'] as Record<string, unknown> | undefined
      const dataMsg = typeof data?.message === 'string' ? data.message : undefined
      message = dataMsg || fromMessage || message
    }
    toast.error(message, 'Erro')
  }
}
</script>

<template>
  <UModal v-model:open="isOpen" title="Editar Utilizador" :description="`Editar informações de ${user?.name}`">
    <template #body>
      <UForm
        :schema="schema"
        :state="state"
        class="space-y-4"
        @submit="onSubmit"
      >
        <UFormField label="Nome Completo" name="name" required>
          <UInput v-model="state.name" placeholder="João Silva" />
        </UFormField>

        <UFormField label="Email" name="email" required>
          <UInput v-model="state.email" type="email" placeholder="joao.silva@exemplo.com" />
        </UFormField>

        <UFormField label="Cargo" name="role_id">
          <USelect
            v-model="state.role_id"
            :items="roleOptions"
            :loading="loadingRoles"
            placeholder="Selecionar cargo..."
          />
        </UFormField>

        <UFormField label="Sub-cargo" name="subrole_id">
          <USelect
            v-model="state.subrole_id"
            :items="subroleOptions"
            :disabled="!state.role_id"
            placeholder="Selecionar sub-cargo..."
          />
        </UFormField>

        <UFormField label="Nível de Permissão" name="permission" required>
          <USelect
            v-model="state.permission"
            :items="permissionOptions"
            placeholder="Selecionar permissão..."
          />
        </UFormField>

        <UFormField label="Estado" name="status" required>
          <USelect
            v-model="state.status"
            :items="statusOptions"
            placeholder="Selecionar estado..."
          />
        </UFormField>

        <UFormField label="Género" name="gender">
          <USelect
            v-model="state.gender"
            :items="genderOptions"
            placeholder="Selecionar género..."
          />
        </UFormField>

        <UFormField label="Data de Nascimento" name="date_of_birth">
          <UInput v-model="state.date_of_birth" type="date" />
        </UFormField>

        <UFormField label="Notas" name="notes">
          <UTextarea v-model="state.notes" placeholder="Notas adicionais..." />
        </UFormField>

        <div class="flex justify-end gap-2">
          <UButton
            label="Cancelar"
            color="neutral"
            variant="subtle"
            @click="isOpen = false"
          />
          <UButton
            type="submit"
            label="Atualizar"
            color="primary"
            variant="solid"
          />
        </div>
      </UForm>
    </template>
  </UModal>
</template>
