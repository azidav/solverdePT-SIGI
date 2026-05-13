<script setup lang="ts">
definePageMeta({ layout: 'default', title: 'Gerir Salas de Reunião' })

interface Room {
  id: number
  name: string
  description: string | null
  capacity: number
  location: string | null
  amenities: string | null
  image_url: string | null
  status: string
  created_at: string
}

const toast = useToast()
const loading = ref(false)
const rooms = ref<Room[]>([])

const showDeleteModal = ref(false)
const roomToDelete = ref<{ id: number; name: string } | null>(null)

async function loadRooms() {
  loading.value = true
  try {
    rooms.value = await useApiFetch('/api/meeting-rooms?all=true') as Room[]
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar salas', color: 'error' })
  } finally {
    loading.value = false
  }
}

async function toggleStatus(room: Room) {
  const newStatus = room.status === 'active' ? 'inactive' : 'active'
  try {
    await useApiFetch(`/api/meeting-rooms/${room.id}`, { method: 'PUT', body: { status: newStatus } })
    toast.add({
      title: 'Sucesso',
      description: `Sala "${room.name}" ${newStatus === 'active' ? 'ativada' : 'desativada'}`,
      color: 'success'
    })
    await loadRooms()
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao alterar estado', color: 'error' })
  }
}

function confirmDelete(room: Room) {
  roomToDelete.value = { id: room.id, name: room.name }
  showDeleteModal.value = true
}

async function executeDelete() {
  if (!roomToDelete.value) return
  try {
    await useApiFetch(`/api/meeting-rooms/${roomToDelete.value.id}`, { method: 'DELETE' })
    toast.add({ title: 'Sala eliminada', color: 'success' })
    showDeleteModal.value = false
    await loadRooms()
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Erro ao eliminar sala'
    toast.add({ title: 'Erro', description: msg, color: 'error' })
  }
}

function getRowItems(room: Room) {
  return [
    { type: 'label' as const, label: 'Ações' },
    {
      label: 'Editar',
      icon: 'i-lucide-edit',
      onSelect: () => navigateTo(`/meeting-rooms/manage/${room.id}`)
    },
    { type: 'separator' as const },
    {
      label: room.status === 'active' ? 'Desativar' : 'Ativar',
      icon: room.status === 'active' ? 'i-lucide-eye-off' : 'i-lucide-eye',
      color: room.status === 'active' ? 'warning' as const : 'success' as const,
      onSelect: () => toggleStatus(room)
    },
    {
      label: 'Eliminar',
      icon: 'i-lucide-trash-2',
      color: 'error' as const,
      onSelect: () => confirmDelete(room)
    }
  ]
}

onMounted(loadRooms)
</script>

<template>
  <div class="p-6 space-y-4">
        <div v-if="loading" class="flex justify-center py-16">
          <UIcon name="i-lucide-loader-2" class="size-6 animate-spin text-primary" />
        </div>

        <UTable
          v-else
          :data="rooms"
          :loading="loading"
          :ui="{
            base: 'table-fixed border-separate border-spacing-0',
            thead: '[&>tr]:bg-elevated/50 [&>tr]:after:content-none',
            th: 'py-2 first:rounded-l-lg last:rounded-r-lg border-y border-default first:border-l last:border-r',
            td: 'border-b border-default',
          }"
          :columns="[
            { accessorKey: 'name', header: 'Nome' },
            { accessorKey: 'capacity', header: 'Cap.' },
            { accessorKey: 'amenities', header: 'Equipamentos' },
            { accessorKey: 'status', header: 'Estado' },
            { id: 'actions', header: '' }
          ]"
        >
          <template #name-cell="{ row }">
            <span
              class="font-medium cursor-pointer hover:text-primary hover:underline transition-colors"
              @click="navigateTo(`/meeting-rooms/manage/${row.original.id}`)"
            >{{ row.original.name }}</span>
          </template>

          <template #capacity-cell="{ row }">
            <span class="flex items-center gap-1 text-sm">
              <UIcon name="i-lucide-users" class="size-3 text-muted" />
              {{ row.original.capacity }}
            </span>
          </template>

          <template #amenities-cell="{ row }">
            <span class="text-sm text-muted truncate max-w-[200px] block">
              {{ row.original.amenities || '—' }}
            </span>
          </template>

          <template #status-cell="{ row }">
            <UBadge
              :color="row.original.status === 'active' ? 'success' : 'neutral'"
              variant="subtle"
              size="sm"
            >
              {{ row.original.status === 'active' ? 'Ativa' : 'Inativa' }}
            </UBadge>
          </template>

          <template #actions-cell="{ row }">
            <div class="flex justify-end">
              <UDropdownMenu
                :content="{ align: 'end' }"
                :items="getRowItems(row.original)"
              >
                <UButton
                  icon="i-lucide-ellipsis-vertical"
                  color="neutral"
                  variant="ghost"
                  size="sm"
                />
              </UDropdownMenu>
            </div>
          </template>
        </UTable>

        <div v-if="!loading && rooms.length === 0" class="text-center py-16">
          <UIcon name="i-lucide-building-2" class="size-10 text-muted mx-auto mb-3" />
          <p class="text-sm text-muted">
            Nenhuma sala criada ainda.
          </p>
          <UButton
            label="Criar Sala"
            icon="i-lucide-plus"
            color="primary"
            class="mt-3"
            @click="navigateTo('/meeting-rooms/manage/new')"
          />
        </div>
  </div>

  <UModal v-model:open="showDeleteModal" title="Eliminar Sala">
    <template #body>
      <div class="space-y-4">
        <p>
          Tem a certeza que deseja eliminar a sala
          <span class="font-semibold">{{ roomToDelete?.name }}</span>?
          Todas as reservas associadas serão também eliminadas.
        </p>
        <div class="flex justify-end gap-2">
          <UButton label="Cancelar" color="neutral" variant="subtle" @click="showDeleteModal = false" />
          <UButton label="Eliminar" color="error" icon="i-lucide-trash-2" @click="executeDelete" />
        </div>
      </div>
    </template>
  </UModal>
</template>
