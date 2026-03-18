<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

definePageMeta({
  title: 'Editar Utilizador'
})

const route = useRoute()
const router = useRouter()
const toast = useToast()

const userId = computed(() => route.params.id as string)

// Fetch user data
const user = ref<any>(null)
const loadingUser = ref(true)

// Fetch roles and subroles
const roles = ref<any[]>([])
const subroles = ref<any[]>([])
const loadingRoles = ref(true)

onMounted(async () => {
  try {
    const [userData, rolesData] = await Promise.all([
      useApiFetch(`/api/users/${userId.value}`, { method: 'GET' }),
      useApiFetch('/api/roles', { method: 'GET' })
    ])

    user.value = userData
    roles.value = Array.isArray(rolesData) ? rolesData : []

    // Populate form with user data
    if (user.value) {
      state.name = user.value.name
      state.email = user.value.email
      state.role_id = user.value.role_id || undefined
      state.subrole_id = user.value.subrole_id || undefined
      state.permission = user.value.permission
      state.gender = user.value.gender || undefined
      state.date_of_birth = user.value.date_of_birth ? user.value.date_of_birth.split('T')[0] : undefined
      state.notes = user.value.notes || undefined
      state.status = user.value.status

      // Load subroles if role is set
      if (user.value.role_id) {
        await loadSubroles(user.value.role_id)
      }
    }
  } catch (error) {
    console.error('Erro ao carregar dados:', error)
    toast.add({
      title: 'Erro',
      description: 'Erro ao carregar utilizador',
      color: 'error'
    })
    router.push('/users/accounts')
  } finally {
    loadingUser.value = false
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
  try {
    await useApiFetch(`/api/users/${userId.value}`, {
      method: 'PUT',
      body: event.data
    })

    toast.add({
      title: 'Sucesso',
      description: 'Utilizador atualizado com sucesso',
      color: 'success'
    })

    router.push('/users/accounts')
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Erro ao atualizar utilizador'
    toast.add({
      title: 'Erro',
      description: message,
      color: 'error'
    })
  }
}
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar :title="`Editar Utilizador${user ? ': ' + user.name : ''}`">
        <template #leading>
          <UButton
          icon="i-lucide-arrow-left"
          variant="ghost"
          size="sm"
          to="/users/accounts"
          />
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <UCard v-if="!loadingUser">
        <UForm
          :schema="schema"
          :state="state"
          class="space-y-4"
          @submit="onSubmit"
        >
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
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
          </div>

          <UFormField label="Notas" name="notes">
            <UTextarea v-model="state.notes" placeholder="Notas adicionais..." :rows="4" />
          </UFormField>

          <div class="flex justify-end gap-2 pt-4">
            <UButton
              label="Cancelar"
              color="neutral"
              variant="subtle"
              to="/users/accounts"
            />
            <UButton
              type="submit"
              label="Atualizar Utilizador"
              color="primary"
              variant="solid"
            />
          </div>
        </UForm>
      </UCard>

      <div v-else class="flex items-center justify-center p-8">
        <UIcon name="i-lucide-loader-2" class="size-8 animate-spin text-primary" />
      </div>
    </template>
  </UDashboardPanel>
</template>
