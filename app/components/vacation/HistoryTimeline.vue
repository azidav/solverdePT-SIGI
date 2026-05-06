<script setup lang="ts">
interface HistoryEntry {
  id: number
  actor_name: string | null
  old_status: string | null
  new_status: string
  step_order: number | null
  comment: string | null
  actioned_at: string
}

defineProps<{ history: HistoryEntry[] }>()

const STATUS_LABELS: Record<string, string> = {
  pending: 'Pendente',
  approved: 'Aprovado',
  rejected: 'Rejeitado',
  cancelled: 'Cancelado'
}

const STATUS_COLORS: Record<string, string> = {
  pending: 'text-yellow-500',
  approved: 'text-green-500',
  rejected: 'text-red-500',
  cancelled: 'text-gray-400'
}

const STEP_ICONS: Record<string, string> = {
  pending: 'i-lucide-clock',
  approved: 'i-lucide-check-circle',
  rejected: 'i-lucide-x-circle',
  cancelled: 'i-lucide-ban'
}

function formatDate(dateStr: string): string {
  return new Intl.DateTimeFormat('pt-PT', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(dateStr))
}
</script>

<template>
  <div class="space-y-4">
    <div v-if="history.length === 0" class="text-muted text-sm text-center py-4">
      Sem histórico de ações.
    </div>
    <div
      v-for="(entry, index) in history"
      :key="entry.id"
      class="flex gap-3"
    >
      <div class="flex flex-col items-center">
        <UIcon
          :name="STEP_ICONS[entry.new_status] || 'i-lucide-circle'"
          class="size-5 shrink-0 mt-0.5"
          :class="STATUS_COLORS[entry.new_status]"
        />
        <div v-if="index < history.length - 1" class="w-px flex-1 bg-default mt-1" />
      </div>
      <div class="pb-4 flex-1">
        <div class="flex items-center gap-2 flex-wrap">
          <span class="font-medium text-sm">{{ entry.actor_name || 'Sistema' }}</span>
          <UBadge
            :label="STATUS_LABELS[entry.new_status] || entry.new_status"
            :color="entry.new_status === 'approved' ? 'success' : entry.new_status === 'rejected' ? 'error' : entry.new_status === 'cancelled' ? 'neutral' : 'warning'"
            variant="subtle"
            size="sm"
          />
          <span v-if="entry.old_status" class="text-xs text-muted">
            ({{ STATUS_LABELS[entry.old_status] || entry.old_status }} → {{ STATUS_LABELS[entry.new_status] || entry.new_status }})
          </span>
        </div>
        <p v-if="entry.comment" class="text-sm text-muted mt-1 italic">"{{ entry.comment }}"</p>
        <p class="text-xs text-muted mt-0.5">{{ formatDate(entry.actioned_at) }}</p>
      </div>
    </div>
  </div>
</template>
