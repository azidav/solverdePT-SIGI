<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

definePageMeta({ middleware: ['rooms-layout'] })

interface Room {
  id: number
  name: string
  description: string | null
  image_url: string | null
  capacity: number
  location: string | null
  amenities: string | null
  is_occupied: boolean
  current_reservation: { id: number, meeting_title: string, booker_name: string, end_time: string } | null
}

interface Reservation {
  id: number
  room_id: number
  room_name: string
  meeting_title: string
  description: string | null
  start_time: string
  end_time: string
  booker_name: string
  user_id: number | null
  is_guest: boolean
  booking_token: string | null
  token_expires_at: string | null
}

interface RoomsConfig {
  slot_duration: number
  booking_start: string
  booking_end: string
  outlook_default_body: string
}

const auth = useAuth()
const logged = useCookie('auth.loggedIn')
const isAuthenticated = computed(() => auth.isAuthenticated.value || logged.value === '1')

const toast = useToast()
const { saveToken, getToken, getValidTokenIds, removeToken } = useGuestToken()

const myPermissions = ref<string[]>([])
const canManage = computed(() => myPermissions.value.includes('ROOMS:MANAGE'))
const canCancelAny = computed(() => myPermissions.value.includes('ROOMS:CANCEL_ANY'))

const roomsConfig = ref<RoomsConfig>({ slot_duration: 30, booking_start: '08:00', booking_end: '22:00', outlook_default_body: '' })

function localDateStr(d = new Date()) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

const todayStr = localDateStr()

const allTimeSlots = computed(() => {
  const slots: { label: string, value: string }[] = []
  const [startH, startM] = roomsConfig.value.booking_start.split(':').map(Number)
  const [endH, endM] = roomsConfig.value.booking_end.split(':').map(Number)
  const startTotal = (startH || 8) * 60 + (startM || 0)
  const endTotal = (endH || 22) * 60 + (endM || 0)
  const interval = roomsConfig.value.slot_duration || 30

  for (let t = startTotal; t <= endTotal; t += interval) {
    const h = Math.floor(t / 60).toString().padStart(2, '0')
    const m = (t % 60).toString().padStart(2, '0')
    slots.push({ label: `${h}:${m}`, value: `${h}:${m}` })
  }
  return slots
})

function timeStrToMin(t: string): number {
  const [h, m] = t.split(':').map(Number)
  return (h ?? 0) * 60 + (m ?? 0)
}

// Reservations loaded for the date currently open in the modal (may differ from selectedDate)
const modalReservations = ref<Reservation[]>([])

const startTimeSlots = computed(() => {
  let slots = allTimeSlots.value

  // Filter past slots when booking for today
  if (form.date === todayStr) {
    const now = new Date()
    const currentMinutes = now.getHours() * 60 + now.getMinutes()
    const interval = roomsConfig.value.slot_duration || 30
    const nextSlot = Math.ceil(currentMinutes / interval) * interval
    slots = slots.filter(s => timeStrToMin(s.value) >= nextSlot)
  }

  // Filter out slots that fall inside an existing reservation for this room
  const roomRes = modalReservations.value.filter(r => r.room_id === selectedRoom.value?.id)
  return slots.filter((slot) => {
    const slotMin = timeStrToMin(slot.value)
    return !roomRes.some((r) => {
      const rStartMin = new Date(r.start_time).getHours() * 60 + new Date(r.start_time).getMinutes()
      const rEndMin = new Date(r.end_time).getHours() * 60 + new Date(r.end_time).getMinutes()
      return slotMin >= rStartMin && slotMin < rEndMin
    })
  })
})

const endTimeSlots = computed(() => {
  if (!form.start_time) return allTimeSlots.value
  const startMin = timeStrToMin(form.start_time)
  const minEnd = startMin + (roomsConfig.value.slot_duration || 30)

  // End time cannot extend into the next reservation — find its start as the hard cap
  const roomRes = modalReservations.value.filter(r => r.room_id === selectedRoom.value?.id)
  let maxEndMin = Infinity
  roomRes.forEach((r) => {
    const rStartMin = new Date(r.start_time).getHours() * 60 + new Date(r.start_time).getMinutes()
    if (rStartMin > startMin) maxEndMin = Math.min(maxEndMin, rStartMin)
  })

  return allTimeSlots.value.filter((s) => {
    const slotMin = timeStrToMin(s.value)
    return slotMin >= minEnd && slotMin <= maxEndMin
  })
})

// True when no bookings are possible: past date OR today with no slots left
const isPastDate = computed(() => {
  if (selectedDate.value < todayStr) return true
  if (selectedDate.value === todayStr) {
    const now = new Date()
    const currentMinutes = now.getHours() * 60 + now.getMinutes()
    const interval = roomsConfig.value.slot_duration || 30
    const nextSlot = Math.ceil(currentMinutes / interval) * interval
    const [endH, endM] = roomsConfig.value.booking_end.split(':').map(Number)
    const endTotal = (endH || 22) * 60 + (endM || 0)
    return nextSlot > endTotal
  }
  return false
})

const rooms = ref<Room[]>([])
const reservations = ref<Reservation[]>([])
const loadingRooms = ref(false)
const loadingReservations = ref(false)
const selectedRoom = ref<Room | null>(null)
const myTokenIds = ref<number[]>([])
const selectedDate = ref(localDateStr())
const showModal = ref(false)
const saving = ref(false)

// Sync modalReservations when the modal opens so slot filtering is accurate
watch(showModal, (open) => {
  if (open) modalReservations.value = [...reservations.value]
})

const schema = z.object({
  meeting_title: z.string().min(2, 'Título obrigatório'),
  description: z.string().optional(),
  date: z.string().min(1, 'Data obrigatória'),
  start_time: z.string().min(1, 'Hora de início obrigatória'),
  end_time: z.string().min(1, 'Hora de fim obrigatória'),
  guest_name: z.string().optional()
})
type Schema = z.output<typeof schema>

const form = reactive<Schema>({
  meeting_title: '',
  description: '',
  date: localDateStr(),
  start_time: '',
  end_time: '',
  guest_name: ''
})

const roomReservations = computed(() =>
  reservations.value.filter(r => r.room_id === selectedRoom.value?.id)
)

function fmtDateFull(iso: string) {
  return new Date(iso).toLocaleDateString('pt-PT', { weekday: 'long', day: 'numeric', month: 'long' })
}

async function loadRooms() {
  loadingRooms.value = true
  try {
    const data = await $fetch('/api/meeting-rooms') as Room[]
    rooms.value = data
    if (!selectedRoom.value && data.length > 0) {
      selectedRoom.value = data[0]!
    } else if (selectedRoom.value) {
      const updated = data.find(r => r.id === selectedRoom.value!.id)
      if (updated) selectedRoom.value = updated
    }
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar salas', color: 'error' })
  } finally {
    loadingRooms.value = false
  }
}

async function loadReservations() {
  loadingReservations.value = true
  try {
    reservations.value = await $fetch(`/api/room-reservations?date=${selectedDate.value}`) as Reservation[]
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar reservas', color: 'error' })
  } finally {
    loadingReservations.value = false
  }
}

async function loadPermissions() {
  if (!isAuthenticated.value) return
  try {
    const resp = await $fetch('/api/users/me/permissions', { credentials: 'include' }) as { permissionCodes: string[] }
    myPermissions.value = resp.permissionCodes || []
  } catch {
    myPermissions.value = []
  }
}

function openBooking() {
  form.meeting_title = ''
  form.description = ''
  form.date = selectedDate.value
  form.start_time = ''
  form.end_time = ''
  form.guest_name = ''
  showModal.value = true
}

// When the modal date changes: reload reservations for that date and clear invalid times
watch(() => form.date, async (newDate) => {
  if (newDate) {
    try {
      modalReservations.value = await $fetch(`/api/room-reservations?date=${newDate}`) as Reservation[]
    } catch { /* silent — slot filtering stays best-effort; backend always validates */ }
  }
  if (form.start_time) {
    const valid = startTimeSlots.value.some(s => s.value === form.start_time)
    if (!valid) {
      form.start_time = ''
      form.end_time = ''
    }
  }
})

watch(() => form.start_time, () => {
  if (!form.end_time) return
  const valid = endTimeSlots.value.some(s => s.value === form.end_time)
  if (!valid) form.end_time = ''
})

async function onSubmit(event: FormSubmitEvent<Schema>) {
  if (!selectedRoom.value) return
  saving.value = true
  try {
    const startDt = new Date(`${event.data.date}T${event.data.start_time}`)
    const endDt = new Date(`${event.data.date}T${event.data.end_time}`)

    const body: Record<string, unknown> = {
      room_id: selectedRoom.value.id,
      meeting_title: event.data.meeting_title,
      description: event.data.description || null,
      start_time: startDt.toISOString(),
      end_time: endDt.toISOString()
    }
    if (!isAuthenticated.value) body.guest_name = event.data.guest_name

    const result = await $fetch('/api/room-reservations', {
      method: 'POST',
      body,
      credentials: 'include'
    }) as { id: number, booking_token?: string, token_expires_at?: string }

    if (result.booking_token && result.token_expires_at) {
      saveToken(result.id, {
        token: result.booking_token,
        expires_at: result.token_expires_at,
        room_id: selectedRoom.value.id,
        meeting_title: event.data.meeting_title
      })
      myTokenIds.value = getValidTokenIds()
    }

    toast.add({ title: 'Reserva criada', description: `"${selectedRoom.value.name}" reservada com sucesso`, color: 'success' })
    showModal.value = false
    await Promise.all([loadRooms(), loadReservations()])
  } catch (err: unknown) {
    const msg = (err as { data?: { message?: string } })?.data?.message || 'Erro ao criar reserva'
    toast.add({ title: 'Erro', description: msg, color: 'error' })
  } finally {
    saving.value = false
  }
}

async function cancelReservation(r: Reservation) {
  try {
    const body: Record<string, unknown> = {}
    if (!isAuthenticated.value) {
      const token = getToken(r.id)
      if (!token) {
        toast.add({ title: 'Expirado', description: 'O prazo de cancelamento de 10 minutos expirou', color: 'error' })
        return
      }
      body.booking_token = token
    }

    await $fetch(`/api/room-reservations/${r.id}`, { method: 'DELETE', body, credentials: 'include' })

    if (!isAuthenticated.value) {
      removeToken(r.id)
      myTokenIds.value = getValidTokenIds()
    }

    toast.add({ title: 'Reserva cancelada', color: 'success' })
    await Promise.all([loadRooms(), loadReservations()])
  } catch (err: unknown) {
    const msg = (err as { data?: { message?: string } })?.data?.message || 'Erro ao cancelar'
    toast.add({ title: 'Erro', description: msg, color: 'error' })
  }
}

watch(selectedDate, loadReservations)

onMounted(async () => {
  myTokenIds.value = getValidTokenIds()
  const [config] = await Promise.all([
    $fetch('/api/rooms-config') as Promise<RoomsConfig>,
    loadRooms(),
    loadReservations(),
    loadPermissions()
  ])
  roomsConfig.value = config
})
</script>

<template>
  <!-- AUTHENTICATED: full dashboard with sidebar -->
  <UDashboardPanel v-if="isAuthenticated" id="meeting-rooms">
    <template #header>
      <UDashboardNavbar title="Salas de Reunião" icon="i-lucide-door-open">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>
        <template #right>
          <div class="flex items-center gap-2">
            <p class="hidden sm:block text-sm text-muted">
              {{ fmtDateFull(selectedDate) }}
            </p>
            <UInput
              v-model="selectedDate"
              type="date"
              icon="i-lucide-calendar"
              size="sm"
            />
            <UButton
              v-if="canManage"
              label="Gerir Salas"
              icon="i-lucide-settings"
              size="sm"
              color="neutral"
              variant="soft"
              to="/meeting-rooms/manage"
            />
          </div>
        </template>
      </UDashboardNavbar>
    </template>
    <template #body>
      <div class="p-4 sm:p-6">
        <MeetingRoomsView
          :rooms="rooms"
          :selected-room="selectedRoom"
          :room-reservations="roomReservations"
          :loading-rooms="loadingRooms"
          :loading-reservations="loadingReservations"
          :is-authenticated="isAuthenticated"
          :can-cancel-any="canCancelAny"
          :auth-user-id="auth.user.value?.id ?? null"
          :my-token-ids="myTokenIds"
          :is-past-date="isPastDate"
          :outlook-default-body="roomsConfig.outlook_default_body"
          @update:selected-room="selectedRoom = $event"
          @open-booking="openBooking"
          @cancel-reservation="cancelReservation"
        />
      </div>
    </template>
  </UDashboardPanel>

  <!-- GUEST: booking layout (simple header provided by booking.vue) -->
  <div v-else class="space-y-4">
    <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="text-xl font-bold">
          Salas de Reunião
        </h1>
        <p class="text-sm text-muted">
          {{ fmtDateFull(selectedDate) }}
        </p>
      </div>
      <div class="flex items-center gap-2">
        <UInput
          v-model="selectedDate"
          type="date"
          icon="i-lucide-calendar"
          size="sm"
          class="flex-1 sm:flex-none"
        />
        <UButton
          v-if="canManage"
          label="Gerir Salas"
          icon="i-lucide-settings"
          size="sm"
          color="neutral"
          variant="soft"
          to="/meeting-rooms/manage"
        />
      </div>
    </div>

    <MeetingRoomsView
      :rooms="rooms"
      :selected-room="selectedRoom"
      :room-reservations="roomReservations"
      :loading-rooms="loadingRooms"
      :loading-reservations="loadingReservations"
      :is-authenticated="isAuthenticated"
      :can-cancel-any="canCancelAny"
      :auth-user-id="auth.user.value?.id ?? null"
      :my-token-ids="myTokenIds"
      :is-past-date="isPastDate"
      @update:selected-room="selectedRoom = $event"
      @open-booking="openBooking"
      @cancel-reservation="cancelReservation"
    />
  </div>

  <UModal
    v-model:open="showModal"
    :title="`Reservar · ${selectedRoom?.name}`"
    :ui="{ content: 'max-w-md' }"
  >
    <template #body>
      <UForm :schema="schema" :state="form" class="space-y-4" @submit="onSubmit">
        <UFormField label="Título da Reunião" name="meeting_title" required>
          <UInput
            v-model="form.meeting_title"
            placeholder="Ex: Reunião de equipa"
            class="w-full"
          />
        </UFormField>

        <UFormField label="Descrição" name="description">
          <UTextarea
            v-model="form.description"
            placeholder="Assunto, agenda ou notas opcionais..."
            class="w-full"
            :rows="2"
          />
        </UFormField>

        <UFormField label="Data" name="date" required>
          <UInput
            v-model="form.date"
            type="date"
            :min="todayStr"
            class="w-full"
          />
        </UFormField>

        <div class="grid grid-cols-2 gap-3">
          <UFormField label="Hora início" name="start_time" required>
            <USelect
              v-model="form.start_time"
              :items="startTimeSlots"
              placeholder="Selecionar..."
              class="w-full"
            />
          </UFormField>
          <UFormField label="Hora fim" name="end_time" required>
            <USelect
              v-model="form.end_time"
              :items="endTimeSlots"
              placeholder="Selecionar..."
              :disabled="!form.start_time"
              class="w-full"
            />
          </UFormField>
        </div>

        <UFormField v-if="!isAuthenticated" label="O seu nome" name="guest_name" required>
          <UInput
            v-model="form.guest_name"
            placeholder="Nome para identificação"
            class="w-full"
          />
        </UFormField>

        <UAlert
          v-if="!isAuthenticated"
          icon="i-lucide-info"
          color="warning"
          variant="soft"
          title="Reserva como visitante"
          description="Poderá cancelar esta reserva durante 10 minutos após a criação."
        />

        <div class="flex justify-end gap-2 pt-1">
          <UButton label="Cancelar" color="neutral" variant="subtle" @click="showModal = false" />
          <UButton type="submit" label="Confirmar Reserva" color="primary" :loading="saving" />
        </div>
      </UForm>
    </template>
  </UModal>
</template>
