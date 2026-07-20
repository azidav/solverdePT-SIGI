<script setup lang="ts">
definePageMeta({ title: 'Detalhe do Pedido' })

interface LevelMember {
  id: number
  name: string
}

interface Step {
  id: number
  step_order: number
  role_name: string
  level_id: number | null
  level_members?: LevelMember[]
  status: string
  approver_id: number | null
  approver_name?: string | null
  comment: string | null
  actioned_at: string | null
}

interface RequestDetail {
  id: number
  type: string
  start_date: string
  end_date: string
  days_count: number
  half_day: boolean
  half_day_period: string | null
  status: string
  reason: string | null
  current_approval_step: number
  employee_name: string
  employee_no?: string | null
  department: string | null
  created_at: string
  history: any[]
  steps: Step[]
  can_act: boolean
  can_undo: boolean
  processed_externally: boolean
}

const route = useRoute()
const toast = useToast()
const { can } = useRbac()
const { STATUS_LABELS, STATUS_COLORS, TYPE_LABELS, formatDate, formatDateTime, formatDays, formatHalfDayPeriod } = useVacationUtils()

const STEP_STATUS_LABELS: Record<string, string> = {
  pending: 'Aguarda',
  approved: 'Aprovado',
  rejected: 'Rejeitado',
  skipped: 'Escalado'
}

const request = ref<RequestDetail | null>(null)
const loading = ref(true)
const actioning = ref(false)

// Separate comment fields for each action
const approveComment = ref('')
const rejectComment = ref('')

// Which inline form is open
const activeForm = ref<'approve' | 'reject' | null>(null)

// Cancel confirmation
const showCancelModal = ref(false)

function toggleForm(form: 'approve' | 'reject') {
  activeForm.value = activeForm.value === form ? null : form
}

async function loadRequest() {
  loading.value = true
  try {
    const [detail, levels] = await Promise.all([
      useApiFetch(`/api/vacation-requests/${route.params.id}`),
      useApiFetch('/api/approval-levels').catch(() => [])
    ])
    const req = detail as RequestDetail
    const levelsMap: Record<number, LevelMember[]> = {}
    ;(levels as any[]).forEach((l: any) => { levelsMap[l.id] = l.members ?? [] })

    if (req.steps) {
      req.steps = req.steps.map(s => ({
        ...s,
        level_members: s.level_id ? (levelsMap[s.level_id] ?? []) : []
      }))
    }
    request.value = req
  } catch {
    toast.add({ title: 'Erro ao carregar pedido', color: 'error' })
  } finally {
    loading.value = false
  }
}

async function approve() {
  actioning.value = true
  try {
    await useApiFetch(`/api/vacation-requests/${route.params.id}/approve`, {
      method: 'PUT',
      body: { comment: approveComment.value || undefined }
    })
    toast.add({ title: 'Pedido aprovado', color: 'success' })
    approveComment.value = ''
    activeForm.value = null
    await loadRequest()
  } catch (e: unknown) {
    toast.add({ title: (e as { data?: { message?: string } })?.data?.message || 'Erro ao aprovar', color: 'error' })
  } finally {
    actioning.value = false
  }
}

async function reject() {
  actioning.value = true
  try {
    await useApiFetch(`/api/vacation-requests/${route.params.id}/reject`, {
      method: 'PUT',
      body: { comment: rejectComment.value || undefined }
    })
    toast.add({ title: 'Pedido rejeitado', color: 'success' })
    rejectComment.value = ''
    activeForm.value = null
    await loadRequest()
  } catch (e: unknown) {
    toast.add({ title: (e as { data?: { message?: string } })?.data?.message || 'Erro ao rejeitar', color: 'error' })
  } finally {
    actioning.value = false
  }
}


async function cancelRequest() {
  actioning.value = true
  try {
    await useApiFetch(`/api/vacation-requests/${request.value!.id}`, { method: 'DELETE' })
    toast.add({ title: 'Pedido cancelado', color: 'success' })
    showCancelModal.value = false
    await loadRequest()
  } catch (e: unknown) {
    toast.add({ title: (e as { data?: { message?: string } })?.data?.message || 'Erro ao cancelar', color: 'error' })
  } finally {
    actioning.value = false
  }
}

const showUndoModal = ref(false)

// PDF do pedido aprovado
const downloadingPdf = ref(false)

// Data de aceitação = data do último passo aprovado; se auto-aprovado (sem
// passos), a entrada do histórico com estado 'approved'; senão created_at.
function resolveApprovedAt(): string {
  const req = request.value!
  const approvedSteps = (req.steps ?? [])
    .filter(s => s.status === 'approved' && s.actioned_at)
    .map(s => s.actioned_at as string)
  if (approvedSteps.length > 0) {
    return approvedSteps.sort().at(-1)!
  }
  const approvedHistory = (req.history ?? [])
    .filter((h: { new_status?: string, actioned_at?: string }) => h.new_status === 'approved' && h.actioned_at)
    .map((h: { actioned_at: string }) => h.actioned_at)
  if (approvedHistory.length > 0) {
    return approvedHistory.sort().at(-1)!
  }
  return req.created_at
}

async function downloadPdf() {
  if (!request.value) return
  downloadingPdf.value = true
  try {
    await generateVacationRequestPdf({ ...request.value, approved_at: resolveApprovedAt() })
  } catch {
    toast.add({ title: 'Erro ao gerar PDF', color: 'error' })
  } finally {
    downloadingPdf.value = false
  }
}

async function undoApproval() {
  actioning.value = true
  try {
    await useApiFetch(`/api/vacation-requests/${route.params.id}/undo-approval`, { method: 'PUT' })
    toast.add({ title: 'Aprovação revertida', description: 'O pedido voltou ao estado pendente.', color: 'success' })
    showUndoModal.value = false
    await loadRequest()
  } catch (e: unknown) {
    toast.add({ title: (e as { data?: { message?: string } })?.data?.message || 'Erro ao reverter aprovação', color: 'error' })
  } finally {
    actioning.value = false
  }
}

async function toggleProcessedExternally(value: boolean) {
  try {
    await useApiFetch(`/api/vacation-requests/${route.params.id}/process-external`, {
      method: 'PUT',
      body: { processed: value }
    })
    if (request.value) request.value.processed_externally = value
    toast.add({
      title: value ? 'Registado como processado' : 'Marcado como não processado',
      color: 'success'
    })
  } catch (e: unknown) {
    toast.add({ title: (e as { data?: { message?: string } })?.data?.message || 'Erro ao atualizar estado', color: 'error' })
  }
}

onMounted(loadRequest)
</script>

<template>
  <div class="p-4 overflow-y-auto">
      <div v-if="loading" class="flex justify-center py-12">
        <UIcon name="i-lucide-loader-2" class="size-6 animate-spin text-muted" />
      </div>

      <template v-else-if="request">
        <div class="grid grid-cols-1 lg:grid-cols-[1fr_360px] gap-4 items-start">
          <!-- Left column: summary, chain, actions -->
          <div class="space-y-4">
            <!-- Summary card -->
            <UCard>
              <div class="space-y-3">
                <div class="flex items-start justify-between flex-wrap gap-2">
                  <div>
                    <h2 class="font-semibold">
                      {{ TYPE_LABELS[request.type] || request.type }}
                    </h2>
                    <p class="text-sm text-muted">
                      {{ request.employee_name }}
                      <span v-if="request.department"> · {{ request.department }}</span>
                    </p>
                  </div>
                  <UBadge
                    :label="STATUS_LABELS[request.status] || request.status"
                    :color="STATUS_COLORS[request.status]"
                    variant="subtle"
                  />
                </div>

                <div class="grid grid-cols-2 gap-3 text-sm">
                  <div>
                    <p class="text-xs text-muted">
                      Período
                    </p>
                    <p>
                      {{ formatDate(request.start_date) }} → {{ formatDate(request.end_date) }}
                      <span v-if="request.half_day && request.half_day_period" class="text-muted">({{ formatHalfDayPeriod(request.half_day_period) }})</span>
                    </p>
                  </div>
                  <div>
                    <p class="text-xs text-muted">
                      Dias úteis
                    </p>
                    <p class="font-semibold">
                      {{ formatDays(request.days_count) }}
                    </p>
                  </div>
                  <div v-if="request.reason" class="col-span-2">
                    <p class="text-xs text-muted">
                      Motivo
                    </p>
                    <p>{{ request.reason }}</p>
                  </div>
                  <div>
                    <p class="text-xs text-muted">
                      Submetido em
                    </p>
                    <p>{{ formatDateTime(request.created_at) }}</p>
                  </div>
                </div>

                <!-- Cancel own pending request -->
                <div v-if="request.status === 'pending' || request.status === 'approved'" class="flex justify-end gap-2 pt-1">
                  <UButton
                    v-if="request.status === 'approved'"
                    icon="i-lucide-file-down"
                    label="Descarregar PDF"
                    variant="outline"
                    size="sm"
                    :loading="downloadingPdf"
                    @click="downloadPdf"
                  />
                  <UButton
                    v-if="request.status === 'pending'"
                    icon="i-lucide-x"
                    label="Cancelar Pedido"
                    color="error"
                    variant="ghost"
                    size="sm"
                    @click="showCancelModal = true"
                  />
                  <UButton
                    v-if="request.can_undo"
                    icon="i-lucide-rotate-ccw"
                    label="Reverter Aprovação"
                    color="warning"
                    variant="ghost"
                    size="sm"
                    @click="showUndoModal = true"
                  />
                </div>
              </div>
            </UCard>

            <!-- RH: external processing -->
            <UCard v-if="can('VACATION:RH') && request.status === 'approved'">
              <div class="flex items-center gap-3">
                <UCheckbox
                  :model-value="request.processed_externally"
                  @update:model-value="toggleProcessedExternally"
                />
                <div>
                  <p class="text-sm font-medium">
                    Pedido processado para a plataforma externa
                  </p>
                  <p class="text-xs text-muted mt-0.5">
                    Marque após registar as férias no sistema externo de RH.
                  </p>
                </div>
                <UBadge
                  v-if="request.processed_externally"
                  color="success"
                  variant="subtle"
                  icon="i-lucide-check-circle"
                  label="Processado"
                  class="ml-auto shrink-0"
                />
              </div>
            </UCard>

            <!-- Approval chain -->
            <UCard v-if="request.steps && request.steps.length > 0">
              <template #header>
                <h3 class="font-semibold">
                  Cadeia de Aprovação
                </h3>
              </template>
              <div class="space-y-2">
                <div
                  v-for="step in request.steps"
                  :key="step.id"
                  class="flex items-center gap-3 p-2.5 rounded-lg"
                  :class="step.step_order === request.current_approval_step && request.status === 'pending'
                    ? 'bg-primary/5 border border-primary/20'
                    : ''"
                >
                  <UIcon
                    :name="step.status === 'approved'
                      ? 'i-lucide-check-circle'
                      : step.status === 'rejected'
                        ? 'i-lucide-x-circle'
                        : step.status === 'skipped'
                          ? 'i-lucide-skip-forward'
                          : 'i-lucide-clock'"
                    class="size-5 shrink-0"
                    :class="step.status === 'approved'
                      ? 'text-green-500'
                      : step.status === 'rejected'
                        ? 'text-red-500'
                        : step.status === 'skipped'
                          ? 'text-orange-400'
                          : 'text-yellow-500'"
                  />
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium">
                      Nível {{ step.step_order }} — {{ step.role_name }}
                    </p>
                    <p
                      v-if="step.level_members && step.level_members.length > 0"
                      class="text-xs text-muted mt-0.5"
                    >
                      {{ step.level_members.map(m => m.name.split(' ')[0]).join(', ') }}
                    </p>
                    <p v-if="step.comment" class="text-xs text-muted italic mt-0.5">
                      "{{ step.comment }}"
                    </p>
                    <p v-if="step.actioned_at" class="text-xs text-muted">
                      {{ formatDateTime(step.actioned_at) }}
                    </p>
                  </div>
                  <UBadge
                    :label="STEP_STATUS_LABELS[step.status] || step.status"
                    :color="step.status === 'approved'
                      ? 'success'
                      : step.status === 'rejected'
                        ? 'error'
                        : step.status === 'skipped'
                          ? 'warning'
                          : 'neutral'"
                    variant="subtle"
                    size="sm"
                  />
                </div>
              </div>
            </UCard>

            <!-- Approver actions -->
            <UCard v-if="request.can_act">
              <template #header>
                <h3 class="font-semibold">
                  Ação de Aprovação
                </h3>
              </template>

              <div class="space-y-3">
                <div class="flex gap-2 flex-wrap">
                  <UButton
                    icon="i-lucide-check"
                    label="Aprovar"
                    color="success"
                    :variant="activeForm === 'approve' ? 'solid' : 'outline'"
                    @click="toggleForm('approve')"
                  />
                  <UButton
                    icon="i-lucide-x"
                    label="Rejeitar"
                    color="error"
                    :variant="activeForm === 'reject' ? 'solid' : 'outline'"
                    @click="toggleForm('reject')"
                  />
                </div>

                <div
                  v-if="activeForm === 'approve'"
                  class="space-y-3 rounded-lg border border-success-200 bg-success-50 dark:bg-success-950/30 p-3"
                >
                  <UFormField label="Comentário (opcional)">
                    <UTextarea v-model="approveComment" placeholder="Adicione um comentário opcional..." :rows="2" class="w-full" />
                  </UFormField>
                  <div class="flex gap-2 justify-end">
                    <UButton label="Cancelar" variant="ghost" size="sm" @click="activeForm = null" />
                    <UButton label="Confirmar Aprovação" color="success" icon="i-lucide-check" size="sm" :loading="actioning" @click="approve" />
                  </div>
                </div>

                <div
                  v-if="activeForm === 'reject'"
                  class="space-y-3 rounded-lg border border-error-200 bg-error-50 dark:bg-error-950/30 p-3"
                >
                  <UFormField label="Motivo da Rejeição">
                    <UTextarea v-model="rejectComment" placeholder="Explique o motivo da rejeição..." :rows="2" class="w-full" />
                  </UFormField>
                  <div class="flex gap-2 justify-end">
                    <UButton label="Cancelar" variant="ghost" size="sm" @click="activeForm = null" />
                    <UButton label="Confirmar Rejeição" color="error" icon="i-lucide-x" size="sm" :loading="actioning" @click="reject" />
                  </div>
                </div>

              </div>
            </UCard>
          </div>

          <!-- Right column: decision history -->
          <div>
            <UCard>
              <template #header>
                <h3 class="font-semibold">
                  Histórico de Decisões
                </h3>
              </template>
              <VacationHistoryTimeline :history="request.history" />
            </UCard>
          </div>
        </div>
      </template>
  </div>

  <!-- Undo approval modal -->
  <UModal
    v-model:open="showUndoModal"
    title="Reverter Aprovação"
    :ui="{ content: 'max-w-sm' }"
  >
    <template #body>
      <div class="space-y-4">
        <p class="text-sm">
          Tem a certeza que pretende reverter a aprovação? O pedido voltará ao estado <strong>pendente</strong> e terá de ser aprovado novamente.
        </p>
        <div class="flex justify-end gap-2">
          <UButton label="Cancelar" color="neutral" variant="subtle" @click="showUndoModal = false" />
          <UButton
            label="Reverter"
            color="warning"
            icon="i-lucide-rotate-ccw"
            :loading="actioning"
            @click="undoApproval"
          />
        </div>
      </div>
    </template>
  </UModal>

  <!-- Cancel confirmation modal -->
  <UModal
    v-model:open="showCancelModal"
    title="Cancelar Pedido"
    :ui="{ content: 'max-w-sm' }"
  >
    <template #body>
      <div class="space-y-4">
        <p class="text-sm">
          Tem a certeza que pretende cancelar este pedido de férias? Esta ação não pode ser desfeita.
        </p>
        <div class="flex justify-end gap-2">
          <UButton
            label="Não, manter"
            color="neutral"
            variant="subtle"
            @click="showCancelModal = false"
          />
          <UButton
            label="Sim, cancelar"
            color="error"
            icon="i-lucide-x"
            :loading="actioning"
            @click="cancelRequest"
          />
        </div>
      </div>
    </template>
  </UModal>
</template>
