<script setup lang="ts">
interface LevelMember {
  id: number
  name: string
  username: string
  email: string
  birthday?: string | null
}

interface Level {
  id: number
  name: string
  parent_id: number | null
  members: LevelMember[]
}

interface Absence {
  id: number
  employee_id: number
  type: string
  start_date: string
  end_date: string
  days_count: number
  employee_name: string
  employee_first_name: string
  department: string | null
}

const toast = useToast()
const { user } = useAuth()
const { can } = useRbac()
const { formatDays } = useVacationUtils()

interface UserBalance {
  base_days: number
  birthday_bonus: number
  carryover_days: number
  used_days: number
  pending_days: number
  employee_name: string
}

const absences = ref<Absence[]>([])
const levels = ref<Level[]>([])
const birthdayEnabled = ref(false)
const loading = ref(true)
const userBalance = ref<UserBalance | null>(null)
const loadingBalance = ref(false)

const today = new Date()
const currentYear = ref(today.getFullYear())
const currentMonth = ref(today.getMonth() + 1)

const selectedLevelIds = ref<number[]>([])
const selectedUserId = ref<number | null>(null)

// Only root-level approvers (no parent) can see another user's balance
const isTopLevelApprover = computed(() => {
  const myId = user.value?.id
  if (!myId) return false
  return levels.value.some(l => l.parent_id === null && l.members.some(m => m.id === myId))
})

const balanceTotalAllowed = computed(() => userBalance.value
  ? Number(userBalance.value.base_days) + Number(userBalance.value.birthday_bonus) +
    Number(userBalance.value.carryover_days)
  : 0
)
const balanceAvailable = computed(() =>
  balanceTotalAllowed.value - Number(userBalance.value?.used_days ?? 0) - Number(userBalance.value?.pending_days ?? 0)
)

async function loadUserBalance() {
  if (!selectedUserId.value || !isTopLevelApprover.value) { userBalance.value = null; return }
  loadingBalance.value = true
  try {
    userBalance.value = await useApiFetch(
      `/api/vacation-requests/balance?user_id=${selectedUserId.value}&year=${currentYear.value}`
    ) as UserBalance
  } catch {
    userBalance.value = null
  } finally {
    loadingBalance.value = false
  }
}

// ── Month navigation ────────────────────────────────────────────────────────

const monthLabel = computed(() =>
  new Intl.DateTimeFormat('pt-PT', { month: 'long', year: 'numeric' }).format(
    new Date(currentYear.value, currentMonth.value - 1, 1)
  )
)

const monthKey = computed(() =>
  `${currentYear.value}-${String(currentMonth.value).padStart(2, '0')}`
)

const daysInMonth = computed(() => new Date(currentYear.value, currentMonth.value, 0).getDate())
const calendarDays = computed(() => Array.from({ length: daysInMonth.value }, (_, i) => i + 1))

function prevMonth() {
  const prevYear = currentYear.value
  if (currentMonth.value === 1) { currentMonth.value = 12; currentYear.value-- }
  else currentMonth.value--
  loadAbsences()
  if (currentYear.value !== prevYear) loadUserBalance()
}

function nextMonth() {
  const prevYear = currentYear.value
  if (currentMonth.value === 12) { currentMonth.value = 1; currentYear.value++ }
  else currentMonth.value++
  loadAbsences()
  if (currentYear.value !== prevYear) loadUserBalance()
}

// ── Filters ─────────────────────────────────────────────────────────────────

function getSubtreeIds(rootId: number): number[] {
  const result = [rootId]
  for (const l of levels.value) {
    if (l.parent_id === rootId) result.push(...getSubtreeIds(l.id))
  }
  return result
}

// Level IDs the current user is allowed to view (null = unrestricted)
const allowedLevelIds = computed<number[] | null>(() => {
  if (can('VACATION:VIEW_ALL_TEAM')) return null
  const myId = user.value?.id
  if (!myId) return []
  const myLevel = levels.value.find(l => l.members.some(m => m.id === myId))
  return myLevel ? getSubtreeIds(myLevel.id) : []
})

const levelOptions = computed(() => {
  const allowed = allowedLevelIds.value
  return levels.value
    .filter(l => allowed === null || allowed.includes(l.id))
    .map(l => ({ label: l.name, value: l.id }))
})

const usersInSelectedLevel = computed<LevelMember[]>(() => {
  const allowed = allowedLevelIds.value
  const seen = new Set<number>()
  const all: LevelMember[] = []

  // Start from explicitly selected levels, or fall back to all allowed levels
  let source = levels.value.filter(l => allowed === null || allowed.includes(l.id))
  if (selectedLevelIds.value.length > 0) {
    source = source.filter(l => selectedLevelIds.value.includes(l.id))
  }

  for (const l of source) {
    for (const m of l.members) {
      if (!seen.has(m.id)) { seen.add(m.id); all.push(m) }
    }
  }
  return all.sort((a, b) => a.name.localeCompare(b.name))
})

const userOptions = computed(() => [
  { label: 'Todos os utilizadores', value: null },
  ...usersInSelectedLevel.value.map(u => ({ label: u.name, value: u.id }))
])

// Reset user filter when level selection changes
watch(selectedLevelIds, () => {
  selectedUserId.value = null
  loadAbsences()
})

watch(selectedUserId, () => {
  loadAbsences()
  loadUserBalance()
})

// ── Calendar rows ─────────────────────────────────────────────────────────────

// One row per user: either filtered subset or all users in level
const calendarUsers = computed<LevelMember[]>(() => {
  const base = usersInSelectedLevel.value
  if (selectedUserId.value !== null) {
    return base.filter(u => u.id === selectedUserId.value)
  }
  return base
})

// Map employee_id → list of absences
const absencesByUser = computed(() => {
  const map = new Map<number, Absence[]>()
  for (const a of absences.value) {
    if (!map.has(a.employee_id)) map.set(a.employee_id, [])
    map.get(a.employee_id)!.push(a)
  }
  return map
})

const COLORS = ['bg-blue-500', 'bg-purple-500', 'bg-orange-500', 'bg-teal-500', 'bg-pink-500', 'bg-indigo-500', 'bg-rose-500', 'bg-cyan-500']
const userColorMap = computed(() => {
  const map = new Map<number, string>()
  calendarUsers.value.forEach((u, i) => { map.set(u.id, COLORS[i % COLORS.length]!) })
  return map
})

// ── Date helpers ─────────────────────────────────────────────────────────────

function parseLocalDate(dateStr: string): Date {
  const part = dateStr.split('T')[0] ?? dateStr
  return new Date(part + 'T00:00:00')
}

function isUserAbsent(userId: number, day: number): boolean {
  const userAbsences = absencesByUser.value.get(userId) ?? []
  const d = new Date(currentYear.value, currentMonth.value - 1, day)
  return userAbsences.some(a => {
    const start = parseLocalDate(a.start_date)
    const end = parseLocalDate(a.end_date)
    return d >= start && d <= end
  })
}

function isWeekend(day: number): boolean {
  const d = new Date(currentYear.value, currentMonth.value - 1, day)
  return d.getDay() === 0 || d.getDay() === 6
}

function isBirthday(member: LevelMember, day: number): boolean {
  if (!birthdayEnabled.value || !member.birthday) return false
  const bday = parseLocalDate(member.birthday)
  return bday.getMonth() + 1 === currentMonth.value && bday.getDate() === day
}

// ── Data loading ─────────────────────────────────────────────────────────────

async function loadAbsences() {
  loading.value = true
  try {
    const params = new URLSearchParams({ month: monthKey.value })
    if (selectedLevelIds.value.length > 0) params.set('level_ids', selectedLevelIds.value.join(','))
    if (selectedUserId.value !== null) params.set('user_id', String(selectedUserId.value))
    const res = await useApiFetch(`/api/vacation-requests/team-calendar?${params}`) as { items: Absence[], birthdayEnabled: boolean }
    absences.value = res.items ?? []
    birthdayEnabled.value = res.birthdayEnabled ?? false
  } catch {
    toast.add({ title: 'Erro ao carregar calendário', color: 'error' })
  } finally {
    loading.value = false
  }
}

async function loadLevels() {
  try {
    const data = await useApiFetch('/api/approval-levels') as Level[]
    levels.value = data

    // Pre-select the logged-in user's own level (always within allowed set)
    const myId = user.value?.id
    if (myId) {
      const myLevel = data.find(l => l.members.some(m => m.id === myId))
      if (myLevel) selectedLevelIds.value = [myLevel.id]
    }
  } catch {
    // levels stay empty — filters won't show
  }
}

onMounted(async () => {
  await loadLevels()
  await loadAbsences()
})
</script>

<template>
  <UCard>
    <template #header>
      <div class="flex items-center justify-between flex-wrap gap-3">
        <h3 class="font-semibold capitalize">
          {{ monthLabel }}
        </h3>
        <div class="flex gap-1">
          <UButton icon="i-lucide-chevron-left" variant="ghost" size="sm" @click="prevMonth" />
          <UButton icon="i-lucide-chevron-right" variant="ghost" size="sm" @click="nextMonth" />
        </div>
      </div>
    </template>

    <!-- Filters -->
    <div class="flex gap-3 flex-wrap mb-4">
      <USelectMenu
        v-model="selectedLevelIds"
        :items="levelOptions"
        value-key="value"
        label-key="label"
        multiple
        placeholder="Todos os níveis"
        class="w-56"
      />
      <USelect
        v-model="selectedUserId"
        :items="userOptions"
        value-key="value"
        label-key="label"
        placeholder="Todos os utilizadores"
        class="w-52"
      />
    </div>

    <!-- Per-user balance summary (top-level approvers + single user selected) -->
    <div v-if="selectedUserId !== null && isTopLevelApprover" class="mb-4">
      <div v-if="loadingBalance" class="flex justify-center py-4">
        <UIcon name="i-lucide-loader-2" class="size-4 animate-spin text-muted" />
      </div>
      <template v-else-if="userBalance">
        <p class="text-xs text-muted mb-2 font-medium">
          {{ userBalance.employee_name }} — {{ currentYear }}
        </p>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <UCard>
            <div class="text-center">
              <p class="text-xl font-bold text-primary">{{ formatDays(balanceTotalAllowed) }}</p>
              <p class="text-xs text-muted">Total</p>
            </div>
          </UCard>
          <UCard>
            <div class="text-center">
              <p class="text-xl font-bold text-green-500">{{ formatDays(balanceAvailable) }}</p>
              <p class="text-xs text-muted">Disponíveis</p>
            </div>
          </UCard>
          <UCard>
            <div class="text-center">
              <p class="text-xl font-bold text-yellow-500">{{ formatDays(Number(userBalance.pending_days)) }}</p>
              <p class="text-xs text-muted">Em aprovação</p>
            </div>
          </UCard>
          <UCard>
            <div class="text-center">
              <p class="text-xl font-bold text-muted">{{ formatDays(Number(userBalance.used_days)) }}</p>
              <p class="text-xs text-muted">Utilizados</p>
            </div>
          </UCard>
        </div>
        <div v-if="Number(userBalance.carryover_days) > 0" class="mt-2">
          <UBadge
            icon="i-lucide-arrow-right"
            :label="`+${formatDays(Number(userBalance.carryover_days))} dia${Number(userBalance.carryover_days) !== 1 ? 's' : ''} transitados`"
            color="warning"
            variant="subtle"
            size="xs"
          />
        </div>
      </template>
    </div>

    <div v-if="loading" class="text-center py-8 text-muted">
      A carregar...
    </div>
    <div v-else>
      <div v-if="calendarUsers.length === 0" class="text-center py-8 text-sm text-muted">
        Nenhum utilizador encontrado.
      </div>
      <div v-else class="overflow-x-auto">
        <table class="w-full text-xs border-collapse min-w-[600px]">
          <thead>
            <tr>
              <th class="text-left p-2 font-medium text-muted w-32">Colaborador</th>
              <th
                v-for="day in calendarDays"
                :key="day"
                class="p-1 text-center w-7"
                :class="isWeekend(day) ? 'text-muted' : 'text-default'"
              >
                {{ day }}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="member in calendarUsers"
              :key="member.id"
              class="border-t border-default"
            >
              <td class="p-2 font-medium truncate max-w-32">
                {{ member.name.split(' ')[0] }}
              </td>
              <td
                v-for="day in calendarDays"
                :key="day"
                class="p-0.5 relative"
              >
                <div
                  v-if="isUserAbsent(member.id, day)"
                  class="h-5 rounded-sm"
                  :class="[userColorMap.get(member.id), isWeekend(day) ? 'opacity-30' : 'opacity-80']"
                  :title="`${member.name} — ausente`"
                />
                <div
                  v-else-if="isBirthday(member, day)"
                  class="h-5 rounded-sm flex items-center justify-center text-[10px]"
                  :class="isWeekend(day) ? 'opacity-40' : ''"
                  title="Aniversário 🎂"
                >
                  🎂
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </UCard>
</template>
