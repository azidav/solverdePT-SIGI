<script setup lang="ts">
definePageMeta({ title: 'Novo Pedido de Férias' })

interface Blackout {
  id: number
  title: string
  start_date: string
  end_date: string
}

interface Balance {
  birthday_bonus: number
  birthday: string | null
}

const toast = useToast()
const router = useRouter()
const { formatDate, localDateStr, formatDaysLabel } = useVacationUtils()

const todayStr = localDateStr()

const form = reactive({
  start_date: '',
  end_date: '',
  type: 'annual',
  reason: '',
  include_weekends: false,
  half_day: false
})

// When half_day is toggled, lock end_date to start_date
watch(() => form.half_day, (v) => {
  if (v && form.start_date) form.end_date = form.start_date
})

const blackouts = ref<Blackout[]>([])
const balance = ref<Balance | null>(null)
const submitting = ref(false)
const previewDays = ref<number | null>(null)
const previewLoading = ref(false)

// Birthday day-off option
const useBirthdayDay = ref(false)
const birthdayDate = ref('')

// Pre-fill birthday date from account when checkbox is ticked
watch(useBirthdayDay, (checked) => {
  if (checked && balance.value?.birthday) {
    const part = balance.value.birthday.split('T')[0] ?? balance.value.birthday
    // Use this year's birthday
    const [, mmdd] = part.split('-')
    birthdayDate.value = `${new Date().getFullYear()}-${mmdd}`
  } else {
    birthdayDate.value = ''
  }
})

const showBirthdayOption = computed(() =>
  form.type === 'annual' && (balance.value?.birthday_bonus ?? 0) > 0
)

interface VacationType {
  id: number
  name: string
  code: string
  uses_balance: boolean
  requires_approval_chain: boolean
}

const vacationTypes = ref<VacationType[]>([])
const TYPE_OPTIONS = computed(() =>
  vacationTypes.value.map(t => ({ label: t.name, value: t.code }))
)

// Blackouts that overlap the currently selected range
const overlappingBlackouts = computed(() => {
  if (!form.start_date || !form.end_date) return []
  const s = new Date(form.start_date + 'T00:00:00')
  const e = new Date(form.end_date + 'T00:00:00')
  return blackouts.value.filter((b) => {
    const bs = new Date(b.start_date + 'T00:00:00')
    const be = new Date(b.end_date + 'T00:00:00')
    return s <= be && e >= bs
  })
})

async function loadBlackouts() {
  try {
    blackouts.value = await useApiFetch('/api/blackout-dates') as Blackout[]
  } catch {}
}

async function loadBalance() {
  try {
    balance.value = await useApiFetch('/api/vacation-requests/balance') as Balance
  } catch {}
}

// Debounced preview: fetch working days from server whenever both dates are valid
let previewTimer: ReturnType<typeof setTimeout> | null = null

watch([() => form.start_date, () => form.end_date, () => form.include_weekends, () => form.half_day], ([start, end]) => {
  previewDays.value = null
  if (previewTimer) clearTimeout(previewTimer)
  if (!start || !end || start > end) return

  previewTimer = setTimeout(async () => {
    previewLoading.value = true
    try {
      const params = new URLSearchParams({
        start_date: start as string,
        end_date: end as string,
        include_weekends: String(form.include_weekends),
        half_day: String(form.half_day)
      })
      const res = await useApiFetch(`/api/vacation-requests/preview?${params}`) as { days_count: number }
      previewDays.value = res.days_count
    } catch {
      previewDays.value = null
    } finally {
      previewLoading.value = false
    }
  }, 400)
})

async function submit() {
  if (!form.start_date || (!form.half_day && !form.end_date)) {
    toast.add({ title: 'Selecione as datas de início e fim', color: 'warning' })
    return
  }
  if (!form.half_day && form.start_date > form.end_date) {
    toast.add({ title: 'A data de início não pode ser posterior à data de fim', color: 'warning' })
    return
  }
  if (overlappingBlackouts.value.length > 0) {
    toast.add({ title: 'O período selecionado inclui datas bloqueadas', color: 'warning' })
    return
  }

  submitting.value = true
  try {
    const submitBody = { ...form, reason: form.reason || undefined }
    if (form.half_day) submitBody.end_date = form.start_date

    const res = await useApiFetch('/api/vacation-requests', {
      method: 'POST',
      body: submitBody
    }) as { days_count: number }

    // Also submit birthday day-off as a separate request
    if (useBirthdayDay.value && birthdayDate.value) {
      await useApiFetch('/api/vacation-requests', {
        method: 'POST',
        body: { type: 'birthday', start_date: birthdayDate.value, end_date: birthdayDate.value }
      })
    }

    const extra = useBirthdayDay.value ? ' + 1 dia de aniversário' : ''
    toast.add({ title: `Pedido submetido — ${formatDaysLabel(res.days_count)}${extra}`, color: 'success' })
    router.push('/ferias')
  } catch (e: unknown) {
    toast.add({ title: (e as { data?: { message?: string } })?.data?.message || 'Erro ao submeter pedido', color: 'error' })
  } finally {
    submitting.value = false
  }
}

async function loadTypes() {
  try {
    vacationTypes.value = await useApiFetch('/api/vacation-types') as VacationType[]
    if (vacationTypes.value.length > 0 && !form.type) {
      form.type = vacationTypes.value[0]!.code
    }
  } catch {}
}

// Current type settings (used to gate balance/chain logic in the server,
// but also used client-side to hide the "include weekends" toggle for non-balance types)
const currentTypeSettings = computed(() =>
  vacationTypes.value.find(t => t.code === form.type)
)

onMounted(() => {
  loadTypes()
  loadBlackouts()
  loadBalance()
})
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar title="Novo Pedido de Férias">
        <template #leading>
          <UDashboardSidebarCollapse />
          <UButton
            icon="i-lucide-arrow-left"
            variant="ghost"
            to="/ferias"
          />
        </template>
      </UDashboardNavbar>
    </template>

    <div class="p-4 max-w-lg mx-auto space-y-4">
      <UCard>
        <div class="space-y-4">
          <!-- Type -->
          <UFormField label="Tipo de Ausência" required>
            <USelect
              v-model="form.type"
              :items="TYPE_OPTIONS"
              class="w-full"
            />
          </UFormField>

          <!-- Half day toggle -->
          <UCheckbox
            v-model="form.half_day"
            label="Meio dia"
          />

          <!-- Dates -->
          <div :class="form.half_day ? 'grid-cols-1' : 'grid grid-cols-2 gap-3'">
            <div :class="form.half_day ? '' : 'grid grid-cols-2 gap-3'">
              <UFormField label="Data de Início" required>
                <UInput
                  v-model="form.start_date"
                  type="date"
                  :min="todayStr"
                  class="w-full"
                />
              </UFormField>
              <UFormField v-if="!form.half_day" label="Data de Fim" required>
                <UInput
                  v-model="form.end_date"
                  type="date"
                  :min="form.start_date || todayStr"
                  class="w-full"
                />
              </UFormField>
            </div>
          </div>

          <!-- Include weekends (only for multi-day types that use balance) -->
          <UCheckbox
            v-if="!form.half_day && currentTypeSettings?.uses_balance !== false"
            v-model="form.include_weekends"
            label="Incluir fins de semana"
          />

          <!-- Days preview -->
          <div
            v-if="form.start_date && form.end_date && form.start_date <= form.end_date"
            class="flex items-center gap-2 rounded-lg border border-default px-3 py-2 text-sm"
          >
            <UIcon
              v-if="previewLoading"
              name="i-lucide-loader-2"
              class="size-4 animate-spin text-muted"
            />
            <template v-else-if="previewDays !== null">
              <UIcon name="i-lucide-calendar-check" class="size-4 text-primary" />
              <span class="font-semibold">{{ formatDaysLabel(previewDays) }}</span>
              <span v-if="previewDays === 0" class="text-error-500 text-xs">
                — nenhum dia útil no período
              </span>
            </template>
          </div>

          <!-- Blackout warning when selection overlaps -->
          <UAlert
            v-if="overlappingBlackouts.length > 0"
            icon="i-lucide-calendar-x"
            color="error"
            variant="soft"
            title="Período bloqueado"
          >
            <template #description>
              <p>
                O período selecionado coincide com:
              </p>
              <ul class="mt-1 list-disc pl-4 space-y-0.5">
                <li v-for="b in overlappingBlackouts" :key="b.id">
                  <span class="font-medium">{{ b.title }}</span>
                  ({{ formatDate(b.start_date) }} → {{ formatDate(b.end_date) }})
                </li>
              </ul>
            </template>
          </UAlert>

          <!-- Blackout info (all periods, when no overlap) -->
          <div
            v-else-if="blackouts.length > 0"
            class="text-xs text-muted space-y-0.5"
          >
            <p class="flex items-center gap-1 font-medium">
              <UIcon name="i-lucide-info" class="size-3" /> Períodos restritos:
            </p>
            <p
              v-for="b in blackouts"
              :key="b.id"
              class="pl-4"
            >
              {{ b.title }} — {{ formatDate(b.start_date) }} → {{ formatDate(b.end_date) }}
            </p>
          </div>

          <!-- Birthday day-off (only shown for annual leave when bonus is available) -->
          <div
            v-if="showBirthdayOption"
            class="rounded-lg border border-default p-3 space-y-3"
          >
            <UCheckbox
              v-model="useBirthdayDay"
              label="Solicitar o meu dia de aniversário como folga (+1 dia disponível)"
            />
            <div v-if="useBirthdayDay" class="pl-6">
              <UFormField label="Data do dia de aniversário">
                <UInput
                  v-model="birthdayDate"
                  type="date"
                  class="w-full"
                />
              </UFormField>
              <p class="text-xs text-muted mt-1">
                Será submetido como um pedido separado de 1 dia.
              </p>
            </div>
          </div>

          <!-- Reason -->
          <UFormField label="Motivo (opcional)">
            <UTextarea
              v-model="form.reason"
              placeholder="Descreva o motivo do pedido..."
              :rows="3"
              class="w-full"
            />
          </UFormField>

          <div class="flex justify-end gap-2">
            <UButton
              variant="ghost"
              label="Cancelar"
              to="/ferias"
            />
            <UButton
              label="Submeter Pedido"
              icon="i-lucide-send"
              :loading="submitting"
              :disabled="overlappingBlackouts.length > 0 || previewDays === 0"
              @click="submit"
            />
          </div>
        </div>
      </UCard>
    </div>
  </UDashboardPanel>
</template>
