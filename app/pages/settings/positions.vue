<script setup lang="ts">
definePageMeta({ title: 'Posições' })

interface Position {
  id: number
  name: string
  description: string | null
  parent_id: number | null
  parent_name: string | null
  depth: number
  children_count: number
  users_count: number
}

const toast = useToast()

const positions = ref<Position[]>([])
const loading = ref(true)
const saving = ref(false)
const deleting = ref<number | null>(null)
const editingId = ref<number | null>(null)

const form = reactive({
  name: '',
  description: '',
  parent_id: null as number | null
})

const isEditing = computed(() => editingId.value !== null)

// Options for parent selector — exclude the position being edited and its descendants
const parentOptions = computed(() => {
  const editing = editingId.value

  const excluded = new Set<number>()
  if (editing !== null) {
    // Mark the editing node and all its descendants as excluded
    const markDescendants = (id: number) => {
      excluded.add(id)
      positions.value
        .filter((p) => p.parent_id === id)
        .forEach((p) => markDescendants(p.id))
    }
    markDescendants(editing)
  }

  return [
    { label: '— Sem pai (nível de topo) —', value: null },
    ...positions.value
      .filter((p) => !excluded.has(p.id))
      .map((p) => ({
        label: ' '.repeat(p.depth * 3) + p.name,
        value: p.id
      }))
  ]
})

async function loadPositions() {
  loading.value = true
  try {
    positions.value = await useApiFetch('/api/positions')
  } catch {
    toast.add({ title: 'Erro ao carregar posições', color: 'error' })
  } finally {
    loading.value = false
  }
}

function startCreate() {
  editingId.value = null
  form.name = ''
  form.description = ''
  form.parent_id = null
}

function startEdit(pos: Position) {
  editingId.value = pos.id
  form.name = pos.name
  form.description = pos.description || ''
  form.parent_id = pos.parent_id
}

function cancelForm() {
  editingId.value = null
  form.name = ''
  form.description = ''
  form.parent_id = null
}

async function savePosition() {
  if (!form.name.trim()) {
    toast.add({ title: 'O nome é obrigatório', color: 'warning' })
    return
  }

  saving.value = true
  try {
    const body = { name: form.name.trim(), description: form.description || null, parent_id: form.parent_id }

    if (isEditing.value) {
      await useApiFetch(`/api/positions/${editingId.value}`, { method: 'PUT', body })
      toast.add({ title: 'Posição atualizada', color: 'success' })
    } else {
      await useApiFetch('/api/positions', { method: 'POST', body })
      toast.add({ title: 'Posição criada', color: 'success' })
    }

    cancelForm()
    await loadPositions()
  } catch (e: any) {
    toast.add({ title: e.data?.message || 'Erro ao guardar posição', color: 'error' })
  } finally {
    saving.value = false
  }
}

async function deletePosition(pos: Position) {
  if (pos.children_count > 0) {
    toast.add({ title: 'Elimine as subposições primeiro', color: 'warning' })
    return
  }
  if (pos.users_count > 0) {
    toast.add({ title: 'Reatribua os utilizadores desta posição primeiro', color: 'warning' })
    return
  }

  deleting.value = pos.id
  try {
    await useApiFetch(`/api/positions/${pos.id}`, { method: 'DELETE' })
    toast.add({ title: 'Posição eliminada', color: 'success' })
    if (editingId.value === pos.id) cancelForm()
    await loadPositions()
  } catch (e: any) {
    toast.add({ title: e.data?.message || 'Erro ao eliminar posição', color: 'error' })
  } finally {
    deleting.value = null
  }
}

onMounted(loadPositions)
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar title="Posições">
        <template #leading>
          <UButton icon="i-lucide-arrow-left" variant="ghost" to="/settings" />
        </template>
      </UDashboardNavbar>
    </template>

    <div class="p-4 space-y-4 max-w-2xl mx-auto">
      <!-- Create / Edit form -->
      <UCard>
        <template #header>
          <h3 class="font-semibold">{{ isEditing ? 'Editar Posição' : 'Nova Posição' }}</h3>
        </template>

        <div class="space-y-3">
          <UFormField label="Nome" required>
            <UInput v-model="form.name" placeholder="ex: Diretor de Tecnologia" class="w-full" />
          </UFormField>

          <UFormField label="Posição Pai">
            <USelect
              v-model="form.parent_id"
              :items="parentOptions"
              value-key="value"
              label-key="label"
              class="w-full"
              placeholder="— Sem pai (nível de topo) —"
            />
          </UFormField>

          <UFormField label="Descrição">
            <UInput v-model="form.description" placeholder="Descrição opcional" class="w-full" />
          </UFormField>

          <div class="flex gap-2 justify-end">
            <UButton v-if="isEditing" variant="ghost" label="Cancelar" @click="cancelForm" />
            <UButton
              :label="isEditing ? 'Guardar Alterações' : 'Criar Posição'"
              :loading="saving"
              @click="savePosition"
            />
          </div>
        </div>
      </UCard>

      <!-- Positions tree -->
      <UCard>
        <template #header>
          <h3 class="font-semibold">Hierarquia de Posições</h3>
        </template>

        <div v-if="loading" class="text-center py-6 text-muted">A carregar...</div>
        <div v-else-if="positions.length === 0" class="text-center py-6 text-sm text-muted">
          Sem posições criadas. Comece por criar uma acima.
        </div>
        <div v-else class="divide-y divide-default">
          <div
            v-for="pos in positions"
            :key="pos.id"
            class="flex items-center justify-between py-2.5 gap-3"
            :style="{ paddingLeft: `${pos.depth * 1.5 + 0.75}rem` }"
          >
            <div class="flex items-center gap-2 min-w-0 flex-1">
              <!-- Tree connector indicator -->
              <UIcon
                v-if="pos.depth > 0"
                name="i-lucide-corner-down-right"
                class="size-3.5 shrink-0 text-muted"
              />
              <UIcon
                name="i-lucide-briefcase"
                class="size-4 shrink-0"
                :class="pos.depth === 0 ? 'text-primary' : 'text-muted'"
              />
              <div class="min-w-0">
                <p class="text-sm font-medium truncate">{{ pos.name }}</p>
                <p v-if="pos.description" class="text-xs text-muted truncate">{{ pos.description }}</p>
                <div class="flex gap-2 mt-0.5">
                  <span v-if="pos.children_count > 0" class="text-xs text-muted">
                    {{ pos.children_count }} subposição{{ pos.children_count !== 1 ? 'ões' : '' }}
                  </span>
                  <span v-if="pos.users_count > 0" class="text-xs text-muted">
                    {{ pos.users_count }} utilizador{{ pos.users_count !== 1 ? 'es' : '' }}
                  </span>
                </div>
              </div>
            </div>

            <div class="flex gap-1 shrink-0">
              <UButton
                icon="i-lucide-pencil"
                variant="ghost"
                size="sm"
                :color="editingId === pos.id ? 'primary' : 'neutral'"
                @click="startEdit(pos)"
              />
              <UButton
                icon="i-lucide-trash-2"
                variant="ghost"
                size="sm"
                color="error"
                :loading="deleting === pos.id"
                :disabled="pos.children_count > 0 || pos.users_count > 0"
                @click="deletePosition(pos)"
              />
            </div>
          </div>
        </div>
      </UCard>
    </div>
  </UDashboardPanel>
</template>
