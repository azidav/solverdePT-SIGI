<script setup lang="ts">
import * as XLSX from 'xlsx'

const open = defineModel<boolean>('open', { default: false })
const emit = defineEmits<{ imported: [] }>()

const toast = useToast()

interface ParsedRow {
  name: string
  username: string
  email: string
  employee_no: string
  department: string
  job_title: string
  group: string
}

interface ImportResult {
  created: number
  emailsSent: number
  emailsFailed: number
  errors: { line: number, identifier: string, reason: string }[]
}

const rows = ref<ParsedRow[]>([])
const parseErrors = ref<string[]>([])
const fileKey = ref(0)
const importing = ref(false)
const result = ref<ImportResult | null>(null)

const defaultGroup = ref('')
const sendEmails = ref(true)
const groupOptions = ref<{ label: string, value: string }[]>([])

onMounted(async () => {
  try {
    const roles = await useApiFetch('/api/roles') as { id: number, name: string }[]
    groupOptions.value = roles.map(r => ({ label: r.name, value: r.name }))
  } catch { /* ignora */ }
})

// Procura um valor numa linha testando vários nomes de coluna possíveis
function pick(row: Record<string, unknown>, keys: string[]): string {
  for (const k of Object.keys(row)) {
    const norm = k.trim().toLowerCase()
    if (keys.some(target => norm === target)) return String(row[k] ?? '').trim()
  }
  return ''
}

function onFileChange(e: Event) {
  rows.value = []
  parseErrors.value = []
  result.value = null
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = (ev) => {
    try {
      const wb = XLSX.read(ev.target?.result, { type: 'array' })
      const sheet = wb.Sheets[wb.SheetNames[0]!]!
      const raw = XLSX.utils.sheet_to_json<Record<string, unknown>>(sheet, { defval: '' })

      const parsed: ParsedRow[] = []
      const errs: string[] = []

      raw.forEach((r, i) => {
        const line = i + 2
        const row: ParsedRow = {
          name: pick(r, ['nome', 'name']),
          username: pick(r, ['username', 'utilizador', 'nome de utilizador']),
          email: pick(r, ['email', 'e-mail']),
          employee_no: pick(r, ['nº identificação', 'no identificacao', 'n identificacao', 'numero', 'nº funcionário', 'empregado no.', 'empregado no']),
          department: pick(r, ['departamento', 'unidade']),
          job_title: pick(r, ['função', 'funcao', 'cargo']),
          group: pick(r, ['grupo', 'role', 'perfil'])
        }
        if (!row.name && !row.username && !row.email && !row.employee_no) return // linha vazia
        if (!row.name || !row.username || !row.email || !row.employee_no) {
          errs.push(`Linha ${line}: faltam campos obrigatórios (Nome, Username, Email, Nº Identificação)`)
        }
        parsed.push(row)
      })

      if (parsed.length === 0) errs.push('Nenhuma linha encontrada no ficheiro.')
      rows.value = parsed
      parseErrors.value = errs
    } catch {
      parseErrors.value = ['Erro ao ler o ficheiro. Confirma que é um Excel (.xlsx) válido.']
    }
  }
  reader.readAsArrayBuffer(file)
}

function downloadTemplate() {
  const headers = ['Nome', 'Username', 'Email', 'Nº Identificação', 'Departamento', 'Função', 'Grupo']
  const example = ['Ana Martins', 'ana.martins', 'ana.martins@solverde.pt', 'O0200', 'Casino Online', 'Operadora', 'Funcionário']
  const ws = XLSX.utils.aoa_to_sheet([headers, example])
  ws['!cols'] = [24, 18, 30, 16, 18, 18, 16].map(w => ({ wch: w }))
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, 'Utilizadores')
  XLSX.writeFile(wb, 'modelo-importacao-utilizadores.xlsx')
}

const canImport = computed(() => rows.value.length > 0 && parseErrors.value.length === 0)

async function submit() {
  if (!canImport.value) return
  importing.value = true
  result.value = null
  try {
    const res = await useApiFetch('/api/users/bulk-import', {
      method: 'POST',
      body: { rows: rows.value, default_group: defaultGroup.value || undefined, send_emails: sendEmails.value }
    }) as ImportResult
    result.value = res

    const parts = [`${res.created} criado(s)`]
    if (sendEmails.value) parts.push(`${res.emailsSent} email(s) enviado(s)`)
    if (res.errors.length > 0) parts.push(`${res.errors.length} com erro`)
    toast.add({
      title: 'Importação concluída',
      description: parts.join(' · '),
      color: res.errors.length > 0 ? 'warning' : 'success'
    })

    if (res.created > 0) emit('imported')
    // Permite nova importação
    rows.value = []
    fileKey.value++
  } catch (e: unknown) {
    toast.add({ title: 'Erro na importação', description: (e as { data?: { message?: string } })?.data?.message || 'Erro desconhecido', color: 'error' })
  } finally {
    importing.value = false
  }
}
</script>

<template>
  <UModal v-model:open="open" title="Importar Utilizadores por Excel" :ui="{ content: 'max-w-2xl' }">
    <template #body>
      <div class="space-y-4">
        <div class="flex items-start gap-2 text-sm text-muted">
          <UIcon name="i-lucide-info" class="size-4 shrink-0 mt-0.5" />
          <p>
            Carrega um ficheiro Excel com as colunas <strong>Nome</strong>, <strong>Username</strong>,
            <strong>Email</strong>, <strong>Nº Identificação</strong> (obrigatórias) e, opcionalmente,
            <strong>Departamento</strong>, <strong>Função</strong> e <strong>Grupo</strong>.
            Cada conta é criada em estado pendente de ativação.
          </p>
        </div>

        <UButton
          label="Descarregar modelo (.xlsx)"
          icon="i-lucide-download"
          color="neutral"
          variant="subtle"
          size="sm"
          @click="downloadTemplate"
        />

        <div class="grid sm:grid-cols-2 gap-3">
          <UFormField label="Ficheiro Excel (.xlsx)">
            <input
              :key="fileKey"
              type="file"
              accept=".xlsx,.xls"
              class="text-sm file:mr-3 file:py-1.5 file:px-3 file:rounded-md file:border-0 file:text-sm file:font-medium file:bg-primary/10 file:text-primary hover:file:bg-primary/20 cursor-pointer"
              @change="onFileChange"
            >
          </UFormField>

          <UFormField label="Grupo por defeito (se a coluna Grupo ficar vazia)">
            <USelectMenu
              v-model="defaultGroup"
              :items="groupOptions"
              value-key="value"
              label-key="label"
              placeholder="Nenhum"
              class="w-full"
            />
          </UFormField>
        </div>

        <UCheckbox v-model="sendEmails" label="Enviar email de ativação a cada utilizador" />

        <!-- Erros de leitura -->
        <UAlert
          v-if="parseErrors.length > 0"
          color="error"
          variant="soft"
          icon="i-lucide-alert-circle"
          title="Corrige o ficheiro antes de importar"
        >
          <template #description>
            <ul class="list-disc pl-4 space-y-0.5 text-xs max-h-40 overflow-y-auto">
              <li v-for="(err, i) in parseErrors" :key="i">
                {{ err }}
              </li>
            </ul>
          </template>
        </UAlert>

        <!-- Pré-visualização -->
        <div v-if="rows.length > 0 && parseErrors.length === 0" class="text-sm">
          <p class="text-muted mb-2">
            <strong>{{ rows.length }}</strong> utilizador(es) prontos a importar:
          </p>
          <div class="max-h-48 overflow-y-auto rounded-lg border border-default divide-y divide-default">
            <div v-for="(r, i) in rows.slice(0, 50)" :key="i" class="flex items-center gap-2 px-3 py-1.5 text-xs">
              <span class="font-medium">{{ r.name }}</span>
              <span class="text-muted">· {{ r.username }} · {{ r.email }}</span>
              <UBadge
                :label="r.group || defaultGroup || 'sem grupo'"
                size="xs"
                color="neutral"
                variant="subtle"
                class="ml-auto"
              />
            </div>
          </div>
        </div>

        <!-- Resultado -->
        <UAlert
          v-if="result"
          :color="result.errors.length > 0 ? 'warning' : 'success'"
          variant="soft"
          :icon="result.errors.length > 0 ? 'i-lucide-alert-triangle' : 'i-lucide-check-circle'"
          :title="`${result.created} utilizador(es) criado(s)` + (sendEmails ? ` · ${result.emailsSent} email(s) enviado(s)` : '')"
        >
          <template v-if="result.errors.length > 0" #description>
            <p class="mb-1">
              Linhas com erro:
            </p>
            <ul class="list-disc pl-4 space-y-0.5 text-xs max-h-40 overflow-y-auto">
              <li v-for="(err, i) in result.errors" :key="i">
                Linha {{ err.line }} ({{ err.identifier }}): {{ err.reason }}
              </li>
            </ul>
          </template>
        </UAlert>

        <div class="flex justify-end gap-2 pt-2">
          <UButton
            label="Fechar"
            color="neutral"
            variant="subtle"
            @click="open = false"
          />
          <UButton
            label="Importar"
            icon="i-lucide-upload"
            color="primary"
            :loading="importing"
            :disabled="!canImport"
            @click="submit"
          />
        </div>
      </div>
    </template>
  </UModal>
</template>
