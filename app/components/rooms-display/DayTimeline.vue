<script setup lang="ts">
// Timeline vertical do dia para o painel de sala (tablet).
// Blocos posicionados por minutos; linha vermelha acompanha a hora atual.

interface Reservation {
  id: number
  meeting_title: string
  booker_name: string | null
  start_time: string
  end_time: string
}

const props = defineProps<{
  reservations: Reservation[]
  dayStart: string // "08:00"
  dayEnd: string // "22:00"
  now: Date
  isToday: boolean
}>()

const PX_PER_MIN = 1.5

function parseHM(hm: string): number {
  const [h, m] = hm.split(':').map(Number)
  return (h ?? 0) * 60 + (m ?? 0)
}

const dayStartMin = computed(() => parseHM(props.dayStart))
const dayEndMin = computed(() => parseHM(props.dayEnd))
const totalHeight = computed(() => (dayEndMin.value - dayStartMin.value) * PX_PER_MIN)

const hours = computed(() => {
  const list: { label: string, top: number }[] = []
  const firstHour = Math.ceil(dayStartMin.value / 60)
  const lastHour = Math.floor(dayEndMin.value / 60)
  for (let h = firstHour; h <= lastHour; h++) {
    list.push({ label: `${String(h).padStart(2, '0')}:00`, top: (h * 60 - dayStartMin.value) * PX_PER_MIN })
  }
  return list
})

function minutesOf(d: Date): number {
  return d.getHours() * 60 + d.getMinutes()
}

const fmtTime = new Intl.DateTimeFormat('pt-PT', { hour: '2-digit', minute: '2-digit' })

// Blocos das reservas com posição/estado calculados (clamp ao horário visível)
const blocks = computed(() => {
  const nowMs = props.now.getTime()
  const nextUpcoming = props.isToday
    ? props.reservations
      .filter(r => new Date(r.start_time).getTime() > nowMs)
      .sort((a, b) => new Date(a.start_time).getTime() - new Date(b.start_time).getTime())[0]
    : undefined

  return props.reservations.map((r) => {
    const start = new Date(r.start_time)
    const end = new Date(r.end_time)
    const startMin = Math.max(minutesOf(start), dayStartMin.value)
    const endMin = Math.min(minutesOf(end), dayEndMin.value)
    const isCurrent = props.isToday && start.getTime() <= nowMs && nowMs < end.getTime()
    return {
      id: r.id,
      title: r.meeting_title,
      booker: r.booker_name,
      time: `${fmtTime.format(start)} – ${fmtTime.format(end)}`,
      top: (startMin - dayStartMin.value) * PX_PER_MIN,
      height: Math.max((endMin - startMin) * PX_PER_MIN, 24),
      isCurrent,
      isNext: !isCurrent && r.id === nextUpcoming?.id
    }
  })
})

// Linha da hora atual
const nowMin = computed(() => minutesOf(props.now))
const showNowLine = computed(() =>
  props.isToday && nowMin.value >= dayStartMin.value && nowMin.value <= dayEndMin.value
)
const nowTop = computed(() => (nowMin.value - dayStartMin.value) * PX_PER_MIN)
const nowLabel = computed(() => fmtTime.format(props.now))

const nowLineEl = ref<HTMLElement | null>(null)
onMounted(() => {
  nextTick(() => nowLineEl.value?.scrollIntoView({ block: 'center', behavior: 'smooth' }))
})
</script>

<template>
  <div class="relative flex">
    <!-- Coluna das horas -->
    <div class="relative w-14 shrink-0" :style="{ height: `${totalHeight}px` }">
      <span
        v-for="h in hours"
        :key="h.label"
        class="absolute right-2 -translate-y-1/2 text-xs text-muted tabular-nums"
        :style="{ top: `${h.top}px` }"
      >{{ h.label }}</span>
    </div>

    <!-- Grelha + reservas -->
    <div class="relative flex-1 border-l border-default" :style="{ height: `${totalHeight}px` }">
      <!-- Linhas de hora -->
      <div
        v-for="h in hours"
        :key="h.label"
        class="absolute inset-x-0 border-t border-default/60"
        :style="{ top: `${h.top}px` }"
      />

      <!-- Estado vazio -->
      <div
        v-if="reservations.length === 0"
        class="absolute inset-0 flex items-center justify-center"
      >
        <p class="text-lg text-muted">
          Sem reservas para este dia
        </p>
      </div>

      <!-- Blocos de reserva -->
      <div
        v-for="b in blocks"
        :key="b.id"
        class="absolute left-2 right-2 rounded-lg px-3 py-1.5 overflow-hidden border"
        :class="b.isCurrent
          ? 'bg-primary text-inverted border-primary'
          : b.isNext
            ? 'bg-primary/10 border-primary ring-1 ring-primary'
            : 'bg-elevated border-default'"
        :style="{ top: `${b.top}px`, height: `${b.height}px` }"
      >
        <div class="flex items-center gap-2 flex-wrap">
          <p class="font-semibold text-sm truncate">
            {{ b.title }}
          </p>
          <UBadge
            v-if="b.isCurrent"
            label="A decorrer"
            color="neutral"
            variant="solid"
            size="sm"
          />
          <UBadge
            v-else-if="b.isNext"
            label="A seguir"
            color="primary"
            variant="subtle"
            size="sm"
          />
        </div>
        <p class="text-xs truncate" :class="b.isCurrent ? 'text-inverted/80' : 'text-muted'">
          {{ b.time }}<span v-if="b.booker"> · {{ b.booker }}</span>
        </p>
      </div>

      <!-- Linha da hora atual -->
      <div
        v-if="showNowLine"
        ref="nowLineEl"
        class="absolute inset-x-0 z-10 pointer-events-none"
        :style="{ top: `${nowTop}px` }"
      >
        <div class="relative border-t-2 border-error">
          <span class="absolute -top-2.5 -left-1 bg-error text-inverted text-[10px] font-bold px-1.5 py-0.5 rounded tabular-nums">
            {{ nowLabel }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
