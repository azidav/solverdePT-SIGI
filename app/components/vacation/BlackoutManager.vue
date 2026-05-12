<script setup lang="ts">
interface Blackout {
  id: number
  title: string
  start_date: string
  end_date: string
  reason: string | null
  department: string | null
  created_by_name: string | null
  created_at: string
}

const toast = useToast()
const { can } = useRbac()

const blackouts = ref<Blackout[]>([])
const loading = ref(true)
const open = ref(false)
const showForm = ref(false)
const deleting = ref<number | null>(null)

const form = reactive({ title: '', start_date: '', end_date: '', reason: '', department: '' })

async function loadBlackouts() {
  loading.value = true
  try {
    blackouts.value = await useApiFetch('/api/blackout-dates')
  } catch {
    toast.add({ title: 'Erro ao carregar períodos restritos', color: 'error' })
  } finally {
    loading.value = false
  }
}

async function createBlackout() {
  if (!form.title || !form.start_date || !form.end_date) {
    toast.add({ title: 'Preencha título, data de início e data de fim', color: 'warning' })
    return
  }
  try {
    await useApiFetch('/api/blackout-dates', {
      method: 'POST',
      body: { ...form, department: form.department || null }
    })
    toast.add({ title: 'Período restrito criado', color: 'success' })
    Object.assign(form, { title: '', start_date: '', end_date: '', reason: '', department: '' })
    showForm.value = false
    await loadBlackouts()
  } catch (e: any) {
    toast.add({ title: e.data?.message || 'Erro ao criar período restrito', color: 'error' })
  }
}

async function deleteBlackout(id: number) {
  deleting.value = id
  try {
    await useApiFetch(`/api/blackout-dates/${id}`, { method: 'DELETE' })
    toast.add({ title: 'Período restrito removido', color: 'success' })
    await loadBlackouts()
  } catch {
    toast.add({ title: 'Erro ao remover período restrito', color: 'error' })
  } finally {
    deleting.value = null
  }
}

function formatDate(d: string | null | undefined): string {
  if (!d) return '—'
  const part = d.split('T')[0] ?? d
  const parsed = new Date(part + 'T00:00:00')
  return isNaN(parsed.getTime()) ? '—' : new Intl.DateTimeFormat('pt-PT').format(parsed)
}

onMounted(loadBlackouts)
</script>

<template>
  <UCard :ui="{ body: 'p-0 sm:p-0' }">
    <template #header>
      <div class="flex items-center justify-between gap-2">
        <button class="flex items-center gap-2 flex-1 text-left" @click="open = !open">
          <UIcon name="i-lucide-calendar-x" class="size-4 text-primary" />
          <h3 class="font-semibold">Períodos Restritos</h3>
          <UIcon
            name="i-lucide-chevron-down"
            class="size-4 text-muted transition-transform"
            :class="open ? 'rotate-180' : ''"
          />
        </button>
        <UButton
          v-if="open && can('VACATION:CONFIG_PERIODS')"
          icon="i-lucide-plus"
          label="Novo Período"
          size="sm"
          @click="showForm = !showForm"
        />
      </div>
    </template>

    <div v-if="open" class="p-4 sm:p-6 space-y-4">
    <div v-if="showForm" class="p-4 border border-default rounded-lg space-y-3">
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <UFormField label="Título" required>
          <UInput v-model="form.title" placeholder="ex: Encerramento de Natal" class="w-full" />
        </UFormField>
        <UFormField label="Departamento (opcional)">
          <UInput v-model="form.department" placeholder="Deixar vazio = todos" class="w-full" />
        </UFormField>
        <UFormField label="Data de Início" required>
          <UInput v-model="form.start_date" type="date" class="w-full" />
        </UFormField>
        <UFormField label="Data de Fim" required>
          <UInput v-model="form.end_date" type="date" class="w-full" />
        </UFormField>
      </div>
      <UFormField label="Motivo">
        <UInput v-model="form.reason" placeholder="Motivo opcional" class="w-full" />
      </UFormField>
      <div class="flex gap-2 justify-end">
        <UButton variant="ghost" label="Cancelar" @click="showForm = false" />
        <UButton label="Guardar" @click="createBlackout" />
      </div>
    </div>

    <div v-if="loading" class="text-center py-6 text-muted">A carregar...</div>
    <div v-else-if="blackouts.length === 0" class="text-center py-6 text-muted text-sm">
      Sem períodos restritos definidos.
    </div>
    <div v-else class="space-y-2">
      <div
        v-for="b in blackouts"
        :key="b.id"
        class="flex items-center justify-between p-3 rounded-lg border border-default"
      >
        <div>
          <p class="font-medium text-sm">{{ b.title }}</p>
          <p class="text-xs text-muted">{{ formatDate(b.start_date) }} → {{ formatDate(b.end_date) }}</p>
          <p v-if="b.department" class="text-xs text-muted">Departamento: {{ b.department }}</p>
        </div>
        <UButton
          v-if="can('VACATION:CONFIG_PERIODS')"
          icon="i-lucide-trash-2"
          variant="ghost"
          color="error"
          size="sm"
          :loading="deleting === b.id"
          @click="deleteBlackout(b.id)"
        />
      </div>
    </div>
    </div>
  </UCard>
</template>
