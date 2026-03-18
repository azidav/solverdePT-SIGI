<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

const open = ref(false)
const toast = useAppToast()
const emit = defineEmits(['created'])

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
  username: z.string().min(3, 'Nome de utilizador deve ter pelo menos 3 caracteres'),
  password: z.string().min(6, 'Senha deve ter pelo menos 6 caracteres'),
  name: z.string().min(2, 'Nome obrigatório'),
  email: z.string().email('Email inválido'),
  role_id: z.number().optional(),
  subrole_id: z.number().optional(),
  permission: z.number().min(0).max(4, 'Permissão deve estar entre 0 e 4'),
  gender: z.string().optional(),
  date_of_birth: z.string().optional(),
  notes: z.string().optional()
})

type Schema = z.output<typeof schema>

const state = reactive<Partial<Schema>>({
  username: undefined,
  password: undefined,
  name: undefined,
  email: undefined,
  role_id: undefined,
  subrole_id: undefined,
  permission: 3,
  gender: undefined,
  date_of_birth: undefined,
  notes: undefined
})

const roleOptions = computed(() =>
  roles.value.map(r => ({ label: r.name, value: r.id }))
)

const subroleOptions = computed(() => {
  if (!state.role_id) return []
  return subroles.value
    .filter(sr => sr.role_id === state.role_id)
    .map(sr => ({ label: sr.name, value: sr.id }))
})

// Watch role changes to fetch subroles
watch(() => state.role_id, async (newRoleId) => {
  state.subrole_id = undefined
  if (!newRoleId) {
    subroles.value = []
    return
  }
  try {
    const subrolesData = await useApiFetch(`/api/subroles?role_id=${newRoleId}`, { method: 'GET' })
    subroles.value = Array.isArray(subrolesData) ? subrolesData : []
  } catch (error) {
    console.error('Erro ao carregar sub-cargos:', error)
  }
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

async function onSubmit(event: FormSubmitEvent<Schema>) {
  try {
    await useApiFetch('/api/users', {
      method: 'POST',
      body: event.data
    })

    toast.success('Utilizador criado com sucesso', 'Sucesso')

    emit('created')
    open.value = false

    // Reset form
    Object.assign(state, {
      username: undefined,
      password: undefined,
      name: undefined,
      email: undefined,
      role_id: undefined,
      subrole_id: undefined,
      permission: 3,
      gender: undefined,
      date_of_birth: undefined,
      notes: undefined
    })
  } catch (error: unknown) {
    let message = 'Erro ao criar utilizador'
    if (typeof error === 'object' && error) {
      const maybe = error as Record<string, unknown>
      const fromMessage = typeof maybe.message === 'string' ? maybe.message : undefined
      const data = maybe['data'] as Record<string, unknown> | undefined
      const dataMsg = typeof data?.message === 'string' ? data.message : undefined
      message = dataMsg || fromMessage || message
    }
    toast.error(message, 'Erro')
  }
}
</script>

<template>
  <UModal v-model:open="open" title="Novo Utilizador" description="Criar um novo utilizador">
    <UButton label="Novo Utilizador" icon="i-lucide-plus" />

    <template #body>
      <UForm
        :schema="schema"
        :state="state"
        class="space-y-4"
        @submit="onSubmit"
      >
        <UFormField label="Nome de Utilizador" name="username" required>
          <UInput v-model="state.username" placeholder="nome.utilizador" />
        </UFormField>

        <UFormField label="Senha" name="password" required>
          <UInput v-model="state.password" type="password" placeholder="••••••••" />
        </UFormField>

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
            @click="open = false"
          />
          <UButton
            type="submit"
            label="Criar Utilizador"
            color="primary"
            variant="solid"
          />
        </div>
      </UForm>
    </template>
  </UModal>
</template>
