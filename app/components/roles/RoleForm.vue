<template>
  <UCard>
    <template #header>
      <h3 class="text-lg font-semibold">
        {{ isEditMode ? 'Editar Role' : 'Novo Role' }}
      </h3>
    </template>

    <form class="space-y-4" @submit.prevent="submitForm">
      <!-- Nome -->
      <UFormGroup label="Nome da Role*" name="name" :error="errors.name">
        <UInput v-model="formData.name" placeholder="Ex: IT, Recursos Humanos" />
      </UFormGroup>

      <!-- Descrição -->
      <UFormGroup label="Descrição" name="description">
        <UTextarea
          v-model="formData.description"
          placeholder="Descrição da role..."
          :rows="3"
        />
      </UFormGroup>

      <!-- Info de role sistema -->
      <div v-if="isEditMode && role?.is_system" class="p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
        <p class="text-sm text-blue-700 dark:text-blue-300">
          ℹ️ Esta é uma role de sistema e não pode ser eliminada.
        </p>
      </div>

      <!-- Botões -->
      <div class="flex gap-2 pt-4">
        <UButton
          type="submit"
          :loading="loading"
          color="success"
        >
          {{ isEditMode ? 'Guardar Alterações' : 'Criar Role' }}
        </UButton>
        <UButton
          color="secondary"
          @click="$emit('cancel')"
        >
          Cancelar
        </UButton>
        <UButton
          v-if="isEditMode && !role?.is_system"
          color="error"
          variant="soft"
          class="ml-auto"
          @click="confirmDelete"
        >
          Eliminar
        </UButton>
      </div>
    </form>
  </UCard>
</template>

<script setup lang="ts">
type Role = {
  id?: number
  name: string
  description: string
  is_system?: boolean
}

const props = defineProps<{
  role?: Role
}>()

const emit = defineEmits<{
  submit: [data: Omit<Role, 'is_system'>]
  cancel: []
  delete: [id: number]
}>()

const loading = ref(false)
const errors = ref<Record<string, string>>({})

const isEditMode = computed(() => !!props.role?.id)

const formData = ref<Omit<Role, 'is_system'>>({
  name: props.role?.name || '',
  description: props.role?.description || ''
})

const submitForm = async () => {
  errors.value = {}

  if (!formData.value.name.trim()) {
    errors.value.name = 'Nome é obrigatório'
    return
  }

  loading.value = true
  try {
    emit('submit', formData.value)
  } finally {
    loading.value = false
  }
}

const confirmDelete = () => {
  const confirmed = confirm(`Tem certeza que quer eliminar o role "${props.role?.name}"?`)
  if (confirmed && props.role?.id) {
    emit('delete', props.role.id)
  }
}

watch(
  () => props.role,
  (newRole) => {
    if (newRole) {
      formData.value = {
        name: newRole.name,
        description: newRole.description
      }
    }
  }
)
</script>
