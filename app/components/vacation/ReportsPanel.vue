<script setup lang="ts">
const toast = useToast()
const { formatDate, TYPE_LABELS, STATUS_LABELS, formatDays } = useVacationUtils()

const currentYear = new Date().getFullYear()

// ── Report 1: Balanço Anual ──────────────────────────────────────────────────
const balanceYear = ref(currentYear)
const loadingBalance = ref(false)

// ── Report 2: Lista de Pedidos ───────────────────────────────────────────────
const requestYear = ref<number | 'all'>('all')
const requestStatus = ref<string>('all')
const requestDept = ref<string>('all')
const loadingRequests = ref(false)

// ── Report 3: Relatório por Colaborador ──────────────────────────────────────
const employeeId = ref<number | null>(null)
const employeeYear = ref<number | 'all'>('all')
const loadingEmployee = ref(false)

// ── Shared select data ────────────────────────────────────────────────────────
const employees = ref<{ id: number, name: string }[]>([])
const departments = ref<string[]>([])

const yearOptions = computed(() =>
  [0, 1, 2].map(i => ({ label: String(currentYear - i), value: currentYear - i }))
)

const statusOptions = [
  { label: 'Todos os estados', value: 'all' },
  { label: 'Pendente',         value: 'pending' },
  { label: 'Aprovado',         value: 'approved' },
  { label: 'Rejeitado',        value: 'rejected' },
  { label: 'Cancelado',        value: 'cancelled' }
]

const deptOptions = computed(() => [
  { label: 'Todos os departamentos', value: 'all' },
  ...departments.value.map(d => ({ label: d, value: d }))
])

const employeeOptions = computed(() =>
  employees.value.map(e => ({ label: e.name, value: e.id }))
)

onMounted(async () => {
  try {
    const users = await useApiFetch('/api/users') as any[]
    employees.value = users.map(u => ({ id: u.id, name: u.name }))
    const depts = [...new Set(users.map((u: any) => u.department).filter(Boolean))] as string[]
    departments.value = depts.sort()
  } catch {}
})

// ── Report 1: Balanço Anual → Excel ─────────────────────────────────────────
async function downloadBalanceExcel() {
  loadingBalance.value = true
  try {
    const rows = await useApiFetch(`/api/reports/annual-balance?year=${balanceYear.value}`) as any[]
    const { utils, writeFile } = await import('xlsx')

    const header = ['Nº Identificação', 'Nome', 'Departamento', 'Dias Base', 'Transitados', 'Bónus Aniversário', 'Utilizados', 'Pendentes', 'Disponíveis']
    const data = rows.map(r => [
      r.employee_no ?? '',
      r.name ?? '',
      r.department ?? '',
      r.base_days ?? 0,
      r.carryover_days ?? 0,
      r.birthday_bonus ?? 0,
      r.used_days ?? 0,
      r.pending_days ?? 0,
      r.available ?? 0
    ])

    const ws = utils.aoa_to_sheet([header, ...data])
    ws['!cols'] = [14, 30, 20, 10, 12, 18, 12, 12, 12].map(w => ({ wch: w }))

    const wb = utils.book_new()
    utils.book_append_sheet(wb, ws, `Balanço ${balanceYear.value}`)
    writeFile(wb, `balanco-ferias-${balanceYear.value}.xlsx`)
    toast.add({ title: 'Excel gerado com sucesso', color: 'success' })
  } catch {
    toast.add({ title: 'Erro ao gerar relatório', color: 'error' })
  } finally {
    loadingBalance.value = false
  }
}

// ── Report 2: Lista de Pedidos → Excel ───────────────────────────────────────
async function downloadRequestsExcel() {
  loadingRequests.value = true
  try {
    const params = new URLSearchParams()
    if (requestYear.value !== 'all')   params.set('year',       String(requestYear.value))
    if (requestStatus.value !== 'all') params.set('status',     requestStatus.value)
    if (requestDept.value !== 'all')   params.set('department', requestDept.value)

    const rows = await useApiFetch(`/api/reports/requests-list?${params}`) as any[]
    const { utils, writeFile } = await import('xlsx')

    const header = ['Colaborador', 'Nº ID', 'Departamento', 'Tipo', 'Início', 'Fim', 'Dias', 'Estado', 'Motivo', 'Aprovado por', 'Data Aprovação']
    const data = rows.map(r => [
      r.employee ?? '',
      r.employee_no ?? '',
      r.department ?? '',
      r.type_name || (r.type ? (TYPE_LABELS[r.type] ?? r.type) : '') || '',
      formatDate(r.start_date),
      formatDate(r.end_date),
      r.days_count ?? 0,
      r.status ? (STATUS_LABELS[r.status] ?? r.status) : '',
      r.reason ?? '',
      r.approved_by ?? '',
      r.approval_date ? formatDate(r.approval_date) : ''
    ])

    const ws = utils.aoa_to_sheet([header, ...data])
    ws['!cols'] = [28, 12, 18, 18, 12, 12, 6, 14, 30, 25, 16].map(w => ({ wch: w }))

    const wb = utils.book_new()
    const sheetName = requestYear.value !== 'all' ? `Pedidos ${requestYear.value}` : 'Pedidos de Férias'
    utils.book_append_sheet(wb, ws, sheetName)
    const filename = `pedidos-ferias${requestYear.value !== 'all' ? '-' + requestYear.value : ''}.xlsx`
    writeFile(wb, filename)
    toast.add({ title: 'Excel gerado com sucesso', color: 'success' })
  } catch {
    toast.add({ title: 'Erro ao gerar relatório', color: 'error' })
  } finally {
    loadingRequests.value = false
  }
}

// ── Report 3: Relatório por Colaborador → PDF ─────────────────────────────────
async function downloadEmployeePdf() {
  if (!employeeId.value) {
    toast.add({ title: 'Selecione um colaborador', color: 'warning' })
    return
  }
  loadingEmployee.value = true
  try {
    const params = new URLSearchParams({ user_id: String(employeeId.value) })
    if (employeeYear.value !== 'all') params.set('year', String(employeeYear.value))

    const data = await useApiFetch(`/api/reports/employee-detail?${params}`) as any

    const { jsPDF } = await import('jspdf')
    const autoTable = (await import('jspdf-autotable')).default
    const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' })

    const primary: [number, number, number] = [0, 193, 106]
    const generated = new Intl.DateTimeFormat('pt-PT', { dateStyle: 'long' }).format(new Date())

    // ── Title ──
    doc.setFontSize(16)
    doc.setFont('helvetica', 'bold')
    doc.setTextColor(...primary)
    doc.text('Relatório de Férias', 14, 18)
    doc.setTextColor(0, 0, 0)
    doc.setFontSize(11)
    doc.setFont('helvetica', 'normal')
    doc.text(data.employee.name, 14, 25)
    doc.setFontSize(8)
    doc.setTextColor(120, 120, 120)
    doc.text(`Gerado em ${generated}`, 14, 30)
    doc.setTextColor(0, 0, 0)

    // ── Employee info ──
    doc.setFontSize(10)
    doc.setFont('helvetica', 'bold')
    doc.text('Informação do Colaborador', 14, 38)

    autoTable(doc, {
      startY: 41,
      body: [
        ['Nº Identificação', data.employee.employee_no ?? '—'],
        ['Departamento',     data.employee.department ?? '—'],
        ['Função',           data.employee.job_title ?? '—'],
        ['Email',            data.employee.email ?? '—'],
        ['Data de Admissão', formatDate(data.employee.hire_date)]
      ],
      theme: 'plain',
      styles: { fontSize: 9, cellPadding: 1.5 },
      columnStyles: { 0: { fontStyle: 'bold', cellWidth: 42, textColor: [80, 80, 80] } }
    })

    // ── Balance table ──
    let cursor = (doc as any).lastAutoTable.finalY + 8
    doc.setFontSize(10)
    doc.setFont('helvetica', 'bold')
    doc.text('Saldo de Férias', 14, cursor)

    autoTable(doc, {
      startY: cursor + 3,
      head: [['Ano', 'Base', 'Transitados', 'Aniversário', 'Utilizados', 'Pendentes', 'Disponíveis']],
      body: data.balances.map((b: any) => [
        b.year, b.base_days, b.carryover_days, b.birthday_bonus,
        b.used_days, b.pending_days, b.available
      ]),
      theme: 'striped',
      headStyles: { fillColor: primary, fontSize: 8, fontStyle: 'bold' },
      styles: { fontSize: 8, halign: 'center' },
      columnStyles: { 0: { halign: 'left', fontStyle: 'bold' } }
    })

    // ── Requests ──
    cursor = (doc as any).lastAutoTable.finalY + 8
    doc.setFontSize(10)
    doc.setFont('helvetica', 'bold')
    doc.text('Histórico de Pedidos', 14, cursor)

    const reqBody: any[] = []
    for (const r of data.requests) {
      reqBody.push([
        `${formatDate(r.start_date)} → ${formatDate(r.end_date)}`,
        r.type_name || (TYPE_LABELS[r.type] ?? r.type),
        formatDays(r.days_count),
        STATUS_LABELS[r.status] ?? r.status
      ])
      for (const s of r.approval_steps ?? []) {
        const statusLabel = s.status === 'approved' ? 'Aprovado' : s.status === 'rejected' ? 'Rejeitado' : s.status === 'skipped' ? 'Escalado' : 'Pendente'
        reqBody.push([{
          content: `↳ ${s.role_name}: ${s.approver ?? '—'} — ${statusLabel}${s.actioned_at ? ' (' + formatDate(s.actioned_at) + ')' : ''}`,
          colSpan: 4,
          styles: { textColor: [100, 100, 100], fontSize: 7, cellPadding: { top: 0.5, right: 2, bottom: 0.5, left: 8 } }
        }])
      }
    }

    autoTable(doc, {
      startY: cursor + 3,
      head: [['Período', 'Tipo', 'Dias', 'Estado']],
      body: reqBody,
      theme: 'striped',
      headStyles: { fillColor: primary, fontSize: 8, fontStyle: 'bold' },
      styles: { fontSize: 8 },
      columnStyles: { 0: { cellWidth: 56 }, 2: { halign: 'center', cellWidth: 14 }, 3: { cellWidth: 22 } }
    })

    // ── Page numbers ──
    const pageCount = doc.getNumberOfPages()
    for (let i = 1; i <= pageCount; i++) {
      doc.setPage(i)
      doc.setFontSize(7)
      doc.setTextColor(160, 160, 160)
      doc.text(`Página ${i} de ${pageCount}`, doc.internal.pageSize.getWidth() - 14, doc.internal.pageSize.getHeight() - 8, { align: 'right' })
    }

    const safeName = data.employee.name.replace(/\s+/g, '-').toLowerCase()
    doc.save(`relatorio-${safeName}${employeeYear.value ? '-' + employeeYear.value : ''}.pdf`)
    toast.add({ title: 'PDF gerado com sucesso', color: 'success' })
  } catch (e) {
    console.error(e)
    toast.add({ title: 'Erro ao gerar PDF', color: 'error' })
  } finally {
    loadingEmployee.value = false
  }
}
</script>

<template>
  <UCard>
    <template #header>
      <div class="flex items-center gap-2">
        <UIcon name="i-lucide-bar-chart-2" class="size-4 text-primary" />
        <h3 class="font-semibold">
          Relatórios de Férias
        </h3>
      </div>
    </template>

    <div class="space-y-6">
      <!-- Report 1: Balanço Anual -->
      <div class="space-y-2">
        <p class="text-sm font-medium">
          Balanço Anual por Colaborador
        </p>
        <p class="text-xs text-muted">
          Exporta o saldo de férias de todos os colaboradores ativos para o ano selecionado.
        </p>
        <div class="flex items-center gap-3 flex-wrap">
          <div class="flex items-center gap-1">
            <UButton
              icon="i-lucide-chevron-left"
              variant="ghost"
              size="sm"
              @click="balanceYear--"
            />
            <span class="font-semibold text-sm w-12 text-center">{{ balanceYear }}</span>
            <UButton
              icon="i-lucide-chevron-right"
              variant="ghost"
              size="sm"
              @click="balanceYear++"
            />
          </div>
          <UButton
            label="Exportar Excel"
            icon="i-lucide-download"
            color="primary"
            variant="soft"
            size="sm"
            :loading="loadingBalance"
            @click="downloadBalanceExcel"
          />
        </div>
      </div>

      <USeparator />

      <!-- Report 2: Lista de Pedidos -->
      <div class="space-y-2">
        <p class="text-sm font-medium">
          Lista de Pedidos de Férias
        </p>
        <p class="text-xs text-muted">
          Exporta todos os pedidos com filtros opcionais de ano, estado e departamento.
        </p>
        <div class="flex items-center gap-3 flex-wrap">
          <USelect
            v-model="requestYear"
            :items="[{ label: 'Todos os anos', value: 'all' }, ...yearOptions]"
            value-key="value"
            label-key="label"
            class="w-44"
          />
          <USelect
            v-model="requestStatus"
            :items="statusOptions"
            value-key="value"
            label-key="label"
            class="w-48"
          />
          <USelect
            v-model="requestDept"
            :items="deptOptions"
            value-key="value"
            label-key="label"
            class="w-52"
          />
          <UButton
            label="Exportar Excel"
            icon="i-lucide-download"
            color="primary"
            variant="soft"
            size="sm"
            :loading="loadingRequests"
            @click="downloadRequestsExcel"
          />
        </div>
      </div>

      <USeparator />

      <!-- Report 3: Relatório por Colaborador -->
      <div class="space-y-2">
        <p class="text-sm font-medium">
          Relatório por Colaborador
        </p>
        <p class="text-xs text-muted">
          Gera um PDF completo com informação, saldo histórico e todos os pedidos do colaborador.
        </p>
        <div class="flex items-center gap-3 flex-wrap">
          <USelectMenu
            v-model="employeeId"
            :items="employeeOptions"
            value-key="value"
            label-key="label"
            placeholder="Selecionar colaborador..."
            searchable
            class="w-64"
          />
          <USelect
            v-model="employeeYear"
            :items="[{ label: 'Todos os anos', value: 'all' }, ...yearOptions]"
            value-key="value"
            label-key="label"
            class="w-44"
          />
          <UButton
            label="Exportar PDF"
            icon="i-lucide-file-down"
            color="primary"
            variant="soft"
            size="sm"
            :loading="loadingEmployee"
            :disabled="!employeeId"
            @click="downloadEmployeePdf"
          />
        </div>
      </div>
    </div>
  </UCard>
</template>
