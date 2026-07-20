<script setup lang="ts">
// Página pública (sem sessão) — seleção de sala para o painel de tablet
definePageMeta({ layout: false, title: 'Painéis de Sala' })

interface Room {
  id: number
  name: string
  capacity: number
  location: string | null
  is_occupied: boolean
}

const { data: rooms, status } = useFetch<Room[]>('/api/meeting-rooms', { default: () => [] })
</script>

<template>
  <div class="min-h-screen bg-default p-6 sm:p-10">
    <div class="max-w-4xl mx-auto space-y-8">
      <div class="text-center space-y-2">
        <h1 class="text-3xl font-bold">
          Painéis de Sala
        </h1>
        <p class="text-muted">
          Selecione a sala a apresentar neste dispositivo.
        </p>
      </div>

      <div v-if="status === 'pending'" class="flex justify-center py-12">
        <UIcon name="i-lucide-loader-2" class="size-8 animate-spin text-muted" />
      </div>

      <div v-else-if="rooms.length === 0" class="text-center text-muted py-12">
        Sem salas disponíveis.
      </div>

      <div v-else class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <NuxtLink
          v-for="room in rooms"
          :key="room.id"
          :to="`/painel-salas/${room.id}`"
        >
          <UCard class="hover:ring-2 hover:ring-primary transition-shadow cursor-pointer">
            <div class="flex items-center gap-4 py-2">
              <UIcon name="i-lucide-door-open" class="size-8 text-primary shrink-0" />
              <div class="min-w-0">
                <p class="text-xl font-semibold truncate">
                  {{ room.name }}
                </p>
                <p class="text-sm text-muted">
                  <span v-if="room.location">{{ room.location }} · </span>{{ room.capacity }} lugares
                </p>
              </div>
              <UIcon name="i-lucide-chevron-right" class="size-5 text-muted ml-auto shrink-0" />
            </div>
          </UCard>
        </NuxtLink>
      </div>
    </div>
  </div>
</template>
