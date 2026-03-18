<template>
  <div class="p-6 space-y-4">
    <h3 class="text-lg font-semibold">
      {{ isEditMode ? `Editar ${user.name}` : 'Novo Utilizador' }}
    </h3>

    <form @submit.prevent="submitForm" class="space-y-4">
      <!-- Nome -->
      <UFormGroup label="Nome Completo*" name="name">
        <UInput v-model="formData.name" placeholder="João Silva" />
      </UFormGroup>

      <!-- Username -->
      <UFormGroup label="Utilizador*" name="username" :error="errors.username">
        <UInput
          v-model="formData.username"
          placeholder="joao.silva"
          :disabled="isEditMode"
        />
      </UFormGroup>

      <!-- Email -->
      <UFormGroup label="Email*" name="email">
        <UInput v-model="formData.email" type="email" placeholder="joao@solverdept.pt" />
      </UFormGroup>

      <!-- Departamento -->
      <UFormGroup label="Departamento" name="department">
        <UInput v-model="formData.department" placeholder="Ex: IT, Vendas, RH" />
      </UFormGroup>

      <!-- Role -->
      <UFormGroup label="Role*" name="role_id" :error="errors.role_id">
        <USelect
          v-model="formData.role_id"
          :options="roles"
          option-attribute="name"
          value-attribute="id"
          placeholder="Selecione um role"
        />
      </UFormGroup>

      <!-- Status -->
      <UFormGroup label="Status*" name="status">
        <USelect
          v-model="formData.status"
          :options="statusOptions"
          option-attribute="label"
          value-attribute="value"
        />
      </UFormGroup>

      <!-- Password (apenas para novo utilizador) -->
      <UFormGroup v-if="!isEditMode" label="Password*" name="password" :error="errors.password">
        <UInput
          v-model="formData.password"
          type="password"
          placeholder="••••••••"
        />
      </UFormGroup>

      <!-- Botões -->
      <div class="flex gap-2 pt-4 border-t">
        <UButton type="submit" :loading="loading" color="green">
          {{ isEditMode ? 'Guardar' : 'Criar' }}
        </UButton>
        <UButton variant="soft" color="gray" @click="$emit('close')">
          Cancelar
        </UButton>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  user?: any
  roles: any[]
}>()

const emit = defineEmits<{
  save: []
  close: []
}>()

const loading = ref(false)
const errors = ref<Record<string, string>>({})

const statusOptions = [
  { label: 'Ativo', value: 1 },
  { label: 'Pendente', value: 0 },
  { label: 'Inativo', value: -1 }
]

const isEditMode = computed(() => !!props.user?.id)

const formData = ref({
  name: props.user?.name || '',
  username: props.user?.username || '',
  email: props.user?.email || '',
  department: props.user?.department || '',
  role_id: props.user?.role_id || null,
  status: props.user?.status || 1,
  password: ''
})

const submitForm = async () => {
  errors.value = {}

  if (!formData.value.name.trim()) errors.value.name = 'Nome obrigatório'
  if (!formData.value.username.trim()) errors.value.username = 'Utilizador obrigatório'
  if (!formData.value.email.trim()) errors.value.email = 'Email obrigatório'
  if (!formData.value.role_id) errors.value.role_id = 'Role obrigatório'
  if (!isEditMode.value && !formData.value.password) errors.value.password = 'Password obrigatória'

  if (Object.keys(errors.value).length > 0) return

  loading.value = true
  try {
    const toast = useAppToast()

    if (isEditMode.value) {
      await useApiFetch(`/api/users/${props.user.id}`, {
        method: 'PUT',
        body: {
          name: formData.value.name,
          email: formData.value.email,
          department: formData.value.department,
          role_id: formData.value.role_id,
          status: formData.value.status
        }
      })
      toast.success('Utilizador atualizado com sucesso')
    } else {
      await useApiFetch('/api/users', {
        method: 'POST',
        body: formData.value
      })
      toast.success('Utilizador criado com sucesso')
    }

    emit('save')
  } catch (error: any) {
    const toast = useAppToast()
    toast.error(error.message || 'Erro ao guardar utilizador')
  } finally {
    loading.value = false
  }
}
</script>
