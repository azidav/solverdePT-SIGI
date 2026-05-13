<script setup lang="ts">
interface VacationType {
  id: number
  name: string
  code: string
  uses_balance: boolean
  requires_approval_chain: boolean
  is_active: boolean
  sort_order: number
}

const toast = useToast()
const types = ref<VacationType[]>([])
const loading = ref(true)
const saving = ref(false)

const showForm = ref(false)
const editingId = ref<number | null>(null)
const form = reactive({ name: '', uses_balance: true, requires_approval_chain: true })

async function load() {
  loading.value = true
  try {
    types.value = await useApiFetch('/api/vacation-types?active=false') as VacationType[]
  } catch {
    toast.add({ title: 'Erro ao carregar tipos', color: 'error' })
  } finally {
    loading.value = false
  }
}

function openAdd() {
  editingId.value = null
  form.name = ''
  form.uses_balance = true
  form.requires_approval_chain = true
  showForm.value = true
}

function openEdit(t: VacationType) {
  editingId.value = t.id
  form.name = t.name
  form.uses_balance = t.uses_balance
  form.requires_approval_chain = t.requires_approval_chain
  showForm.value = true
}

function cancelForm() {
  showForm.value = false
  editingId.value = null
}

async function save() {
  if (!form.name.trim()) return
  saving.value = true
  try {
    if (editingId.value) {
      await useApiFetch(`/api/vacation-types/${editingId.value}`, {
        method: 'PUT',
        body: { name: form.name, uses_balance: form.uses_balance, requires_approval_chain: form.requires_approval_chain }
      })
      toast.add({ title: 'Tipo atualizado', color: 'success' })
    } else {
      await useApiFetch('/api/vacation-types', {
        method: 'POST',
        body: { name: form.name, uses_balance: form.uses_balance, requires_approval_chain: form.requires_approval_chain }
      })
      toast.add({ title: 'Tipo criado', color: 'success' })
    }
    showForm.value = false
    await load()
  } catch (e: unknown) {
    toast.add({ title: (e as any)?.data?.message || 'Erro ao guardar', color: 'error' })
  } finally {
    saving.value = false
  }
}

async function toggleActive(t: VacationType) {
  try {
    await useApiFetch(`/api/vacation-types/${t.id}`, { method: 'PUT', body: { is_active: !t.is_active } })
    await load()
  } catch {
    toast.add({ title: 'Erro ao atualizar', color: 'error' })
  }
}

async function remove(t: VacationType) {
  try {
    await useApiFetch(`/api/vacation-types/${t.id}`, { method: 'DELETE' })
    toast.add({ title: 'Tipo eliminado', color: 'success' })
    await load()
  } catch (e: unknown) {
    toast.add({ title: (e as any)?.data?.message || 'Erro ao eliminar', color: 'error' })
  }
}

onMounted(load)
</script>

<template>
  <div class="space-y-3">
    <!-- List -->
    <div v-if="loading" class="flex justify-center py-6">
      <UIcon name="i-lucide-loader-2" class="size-5 animate-spin text-muted" />
    </div>

    <div v-else class="space-y-2">
      <div
        v-for="t in types"
        :key="t.id"
        class="flex items-center gap-3 p-3 rounded-lg border border-default"
        :class="!t.is_active ? 'opacity-50' : ''"
      >
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium">
            {{ t.name }}
          </p>
          <div class="flex gap-1.5 mt-1 flex-wrap">
            <UBadge
              :label="t.uses_balance ? 'Usa saldo' : 'Sem saldo'"
              :color="t.uses_balance ? 'info' : 'neutral'"
              variant="subtle"
              size="xs"
            />
            <UBadge
              :label="t.requires_approval_chain ? 'Cadeia de aprovação' : 'Aprovação livre'"
              :color="t.requires_approval_chain ? 'warning' : 'success'"
              variant="subtle"
              size="xs"
            />
          </div>
        </div>
        <div class="flex gap-1 shrink-0">
          <UButton
            icon="i-lucide-pencil"
            variant="ghost"
            size="xs"
            @click="openEdit(t)"
          />
          <UButton
            :icon="t.is_active ? 'i-lucide-eye-off' : 'i-lucide-eye'"
            variant="ghost"
            size="xs"
            :color="t.is_active ? 'neutral' : 'success'"
            @click="toggleActive(t)"
          />
          <UButton
            v-if="t.code !== 'annual'"
            icon="i-lucide-trash-2"
            variant="ghost"
            size="xs"
            color="error"
            @click="remove(t)"
          />
        </div>
      </div>

      <div v-if="types.length === 0" class="text-center py-4 text-sm text-muted">
        Nenhum tipo configurado.
      </div>
    </div>

    <!-- Add/Edit form -->
    <div
      v-if="showForm"
      class="rounded-lg border border-default p-4 space-y-3 bg-elevated/30"
    >
      <UFormField :label="editingId ? 'Editar tipo' : 'Novo tipo'" name="name">
        <UInput
          v-model="form.name"
          class="w-full"
          placeholder="Ex: Baixa Médica, Licença Parental..."
          autofocus
        />
      </UFormField>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div class="rounded-lg border border-default p-3 space-y-1">
          <UCheckbox
            v-model="form.uses_balance"
            label="Usa saldo de férias"
          />
          <p class="text-xs text-muted pl-6">
            Deduz dias do saldo disponível do colaborador.
          </p>
        </div>
        <div class="rounded-lg border border-default p-3 space-y-1">
          <UCheckbox
            v-model="form.requires_approval_chain"
            label="Segue cadeia de aprovação"
          />
          <p class="text-xs text-muted pl-6">
            Se desativado, notifica todos os níveis e qualquer um pode aprovar.
          </p>
        </div>
      </div>

      <div class="flex gap-2 justify-end">
        <UButton
          label="Cancelar"
          variant="ghost"
          size="sm"
          @click="cancelForm"
        />
        <UButton
          :label="editingId ? 'Guardar' : 'Criar'"
          color="primary"
          size="sm"
          :loading="saving"
          :disabled="!form.name.trim()"
          @click="save"
        />
      </div>
    </div>

    <UButton
      v-if="!showForm"
      label="Adicionar tipo"
      icon="i-lucide-plus"
      variant="soft"
      size="sm"
      @click="openAdd"
    />
  </div>
</template>
