<script setup lang="ts">
import * as XLSX from 'xlsx'

definePageMeta({ title: 'Administração — Férias' })

interface Request {
  id: number
  type: string
  start_date: string
  end_date: string
  days_count: number
  status: string
  employee_name: string
  department: string | null
  created_at: string
  current_approval_step: number
}

const toast = useToast()
const { can, canApproveVacation } = useRbac()
const { STATUS_LABELS, STATUS_COLORS, TYPE_LABELS, formatDate, formatDaysLabel } = useVacationUtils()

const requests = ref<Request[]>([])
const loading = ref(true)
const filterStatus = ref('pending')
const page = ref(1)
const total = ref(0)
const limit = 20

async function loadRequests() {
  loading.value = true
  try {
    const params = new URLSearchParams({
      page: String(page.value),
      limit: String(limit),
      ...(filterStatus.value ? { status: filterStatus.value } : {})
    })
    const res = await useApiFetch(`/api/vacation-requests?${params}`) as any
    requests.value = res.data ?? []
    total.value = res.pagination?.total ?? 0
  } catch {
    toast.add({ title: 'Erro ao carregar pedidos', color: 'error' })
  } finally {
    loading.value = false
  }
}

watch([filterStatus, page], loadRequests)

const STATUS_FILTER_OPTIONS = [
  ...Object.entries(STATUS_LABELS).map(([k, v]) => ({ key: k, label: v })),
  { key: '', label: 'Todos' }
]

// ── Balance upload ────────────────────────────────────────────────────────────

interface UploadRow {
  employee_no: string
  ferias_do_ano: number
  saldo_actual: number
}

const uploadYear = ref(new Date().getFullYear())
const uploadRows = ref<UploadRow[]>([])
const uploadErrors = ref<string[]>([])
const uploading = ref(false)
const uploadFileKey = ref(0)

function onFileChange(e: Event) {
  uploadRows.value = []
  uploadErrors.value = []
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = (ev) => {
    try {
      const wb = XLSX.read(ev.target?.result, { type: 'binary' })
      const sheet = wb.Sheets[wb.SheetNames[0]!]!
      const raw = XLSX.utils.sheet_to_json<Record<string, unknown>>(sheet, { defval: '' })

      const rows: UploadRow[] = []
      const errs: string[] = []

      raw.forEach((row, i) => {
        const empNo = String(row['Empregado No.'] ?? row['Empregado No'] ?? '').trim()
        const feriasDdoAno = parseFloat(String(row['Férias do Ano'] ?? row['Ferias do Ano'] ?? 0))
        const saldoActual = parseFloat(String(row['Saldo Actual'] ?? row['Saldo Atual'] ?? 0))

        if (!empNo) { errs.push(`Linha ${i + 2}: Nº de identificação em falta`); return }
        if (isNaN(feriasDdoAno) || isNaN(saldoActual)) { errs.push(`Linha ${i + 2}: Valores numéricos inválidos`); return }
        rows.push({ employee_no: empNo, ferias_do_ano: feriasDdoAno, saldo_actual: saldoActual })
      })

      uploadRows.value = rows
      uploadErrors.value = errs
    } catch {
      uploadErrors.value = ['Erro ao ler o ficheiro. Certifique-se que é um ficheiro Excel válido.']
    }
  }
  reader.readAsBinaryString(file)
}

async function submitUpload() {
  if (uploadRows.value.length === 0) return
  uploading.value = true
  try {
    const res = await useApiFetch('/api/vacation-requests/upload-balances', {
      method: 'POST',
      body: { year: uploadYear.value, rows: uploadRows.value }
    }) as { updated: number, notFound: string[] }

    let msg = `${res.updated} colaborador(es) atualizado(s).`
    if (res.notFound.length > 0) msg += ` Não encontrado(s): ${res.notFound.join(', ')}`

    toast.add({ title: 'Upload concluído', description: msg, color: res.notFound.length > 0 ? 'warning' : 'success' })
    uploadRows.value = []
    uploadFileKey.value++
  } catch (e: unknown) {
    toast.add({ title: 'Erro no upload', description: (e as any)?.data?.message || 'Erro desconhecido', color: 'error' })
  } finally {
    uploading.value = false
  }
}

onMounted(loadRequests)
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar title="Administração — Férias">
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

    <div class="p-4 space-y-4 overflow-y-auto">
      <!-- Balance upload -->
      <UCard v-if="can('VACATION:IMPORT_BALANCES')">
        <template #header>
          <div class="flex items-center gap-2">
            <UIcon name="i-lucide-upload" class="size-4 text-primary" />
            <h3 class="font-semibold">
              Importar Saldos de Férias
            </h3>
          </div>
        </template>

        <div class="space-y-4">
          <div class="flex items-center gap-3 flex-wrap">
            <UFormField label="Ano">
              <div class="flex items-center gap-1">
                <UButton icon="i-lucide-chevron-left" variant="ghost" size="sm" @click="uploadYear--" />
                <span class="font-semibold text-sm w-12 text-center">{{ uploadYear }}</span>
                <UButton icon="i-lucide-chevron-right" variant="ghost" size="sm" @click="uploadYear++" />
              </div>
            </UFormField>

            <UFormField label="Ficheiro Excel (.xlsx)">
              <input
                :key="uploadFileKey"
                type="file"
                accept=".xlsx,.xls"
                class="text-sm file:mr-3 file:py-1.5 file:px-3 file:rounded-md file:border-0 file:text-sm file:font-medium file:bg-primary/10 file:text-primary hover:file:bg-primary/20 cursor-pointer"
                @change="onFileChange"
              />
            </UFormField>

            <UButton
              v-if="uploadRows.length > 0"
              label="Importar"
              icon="i-lucide-check"
              color="primary"
              :loading="uploading"
              class="self-end"
              @click="submitUpload"
            />
          </div>

          <!-- Parse errors -->
          <UAlert
            v-if="uploadErrors.length > 0"
            color="error"
            variant="soft"
            icon="i-lucide-alert-circle"
            title="Erros no ficheiro"
          >
            <template #description>
              <ul class="list-disc pl-4 space-y-0.5 text-xs">
                <li v-for="(err, i) in uploadErrors" :key="i">{{ err }}</li>
              </ul>
            </template>
          </UAlert>

          <!-- Preview table -->
          <div v-if="uploadRows.length > 0" class="overflow-x-auto">
            <p class="text-xs text-muted mb-2">
              {{ uploadRows.length }} linha(s) para importar — ano {{ uploadYear }}
            </p>
            <table class="w-full text-xs border-collapse">
              <thead>
                <tr class="bg-elevated">
                  <th class="text-left p-2 border border-default">Nº Identificação</th>
                  <th class="text-right p-2 border border-default">Férias do Ano</th>
                  <th class="text-right p-2 border border-default">Saldo Actual</th>
                  <th class="text-right p-2 border border-default">Dias Extra</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(r, i) in uploadRows" :key="i" class="border-b border-default">
                  <td class="p-2 border border-default font-medium">{{ r.employee_no }}</td>
                  <td class="p-2 border border-default text-right">{{ r.ferias_do_ano }}</td>
                  <td class="p-2 border border-default text-right">{{ r.saldo_actual }}</td>
                  <td class="p-2 border border-default text-right font-semibold text-primary">
                    +{{ Math.max(0, r.saldo_actual - r.ferias_do_ano) }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </UCard>

      <!-- Blackout Manager -->
      <VacationBlackoutManager v-if="can('VACATION:CONFIG_PERIODS')" />

      <!-- Requests list -->
      <UCard>
        <template #header>
          <div class="flex items-center justify-between flex-wrap gap-2">
            <h3 class="font-semibold">
              Pedidos de Férias
            </h3>
            <div class="flex gap-1 flex-wrap">
              <UButton
                v-for="opt in STATUS_FILTER_OPTIONS"
                :key="opt.key"
                size="xs"
                :variant="filterStatus === opt.key ? 'solid' : 'ghost'"
                :label="opt.label"
                @click="filterStatus = opt.key; page = 1"
              />
            </div>
          </div>
        </template>

        <div v-if="loading" class="flex justify-center py-8">
          <UIcon name="i-lucide-loader-2" class="size-5 animate-spin text-muted" />
        </div>
        <div v-else-if="requests.length === 0" class="text-center py-8 text-sm text-muted">
          Sem pedidos.
        </div>
        <div v-else class="space-y-2">
          <div
            v-for="r in requests"
            :key="r.id"
            class="flex items-center justify-between gap-3 p-3 rounded-lg border border-default hover:bg-elevated/50 transition-colors cursor-pointer"
            @click="navigateTo(`/ferias/${r.id}`)"
          >
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 flex-wrap">
                <span class="font-medium text-sm">{{ r.employee_name }}</span>
                <UBadge
                  :label="STATUS_LABELS[r.status] || r.status"
                  :color="STATUS_COLORS[r.status]"
                  variant="subtle"
                  size="sm"
                />
              </div>
              <p class="text-xs text-muted mt-0.5">
                {{ TYPE_LABELS[r.type] || r.type }} ·
                {{ formatDate(r.start_date) }} → {{ formatDate(r.end_date) }}
                ({{ formatDaysLabel(r.days_count) }})
              </p>
            </div>
            <UIcon name="i-lucide-chevron-right" class="size-4 text-muted shrink-0" />
          </div>
        </div>

        <template v-if="total > limit" #footer>
          <div class="flex justify-center">
            <UPagination
              v-model:page="page"
              :total="total"
              :page-size="limit"
            />
          </div>
        </template>
      </UCard>

      <!-- Team Calendar -->
      <VacationTeamCalendar v-if="canApproveVacation" />
    </div>
  </UDashboardPanel>
</template>
