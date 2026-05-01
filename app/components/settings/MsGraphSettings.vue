<script setup lang="ts">
const props = defineProps<{ enabled: boolean }>()

interface RoomMapping {
  id: number
  room_id: number
  room_name: string
  resource_email: string
  created_at: string
}

interface Subscription {
  id: number
  subscription_id: string
  room_name: string | null
  resource_email: string
  expiration_datetime: string
  updated_at: string
}

interface Room {
  id: number
  name: string
}

const toast = useToast()

// ─── Webhook URL ───────────────────────────────────────────────
const webhookUrl = computed(() =>
  import.meta.client ? `${window.location.origin}/api/webhook/msgraph` : '/api/webhook/msgraph'
)
async function copyWebhookUrl() {
  await navigator.clipboard.writeText(webhookUrl.value)
  toast.add({ title: 'Copiado', description: 'URL do webhook copiado para a área de transferência', color: 'success' })
}

// ─── Room Mappings ─────────────────────────────────────────────
const mappings = ref<RoomMapping[]>([])
const rooms = ref<Room[]>([])
const loadingMappings = ref(true)
const newMappingRoomId = ref<number | null>(null)
const newMappingEmail = ref('')
const addingMapping = ref(false)

const unmappedRooms = computed(() =>
  rooms.value.filter(r => !mappings.value.some(m => m.room_id === r.id))
)

async function loadMappings() {
  loadingMappings.value = true
  try {
    const [m, r] = await Promise.all([
      useApiFetch<RoomMapping[]>('/api/msgraph/room-mappings'),
      useApiFetch<Room[]>('/api/meeting-rooms?all=true')
    ])
    mappings.value = m as RoomMapping[]
    rooms.value = (r as Room[]) || []
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar mapeamentos', color: 'error' })
  } finally {
    loadingMappings.value = false
  }
}

async function addMapping() {
  if (!newMappingRoomId.value || !newMappingEmail.value.trim()) return
  addingMapping.value = true
  try {
    const m = await useApiFetch<RoomMapping>('/api/msgraph/room-mappings', {
      method: 'POST',
      body: { room_id: newMappingRoomId.value, resource_email: newMappingEmail.value.trim() }
    })
    mappings.value.push(m as RoomMapping)
    newMappingRoomId.value = null
    newMappingEmail.value = ''
    toast.add({ title: 'Mapeamento criado', color: 'success' })
  } catch (err: any) {
    toast.add({ title: 'Erro', description: err?.data?.message || 'Erro ao criar mapeamento', color: 'error' })
  } finally {
    addingMapping.value = false
  }
}

async function deleteMapping(id: number) {
  try {
    await useApiFetch(`/api/msgraph/room-mappings/${id}`, { method: 'DELETE' })
    mappings.value = mappings.value.filter(m => m.id !== id)
    toast.add({ title: 'Mapeamento removido', color: 'success' })
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao remover mapeamento', color: 'error' })
  }
}

// ─── Subscriptions ─────────────────────────────────────────────
const subscriptions = ref<Subscription[]>([])
const loadingSubscriptions = ref(true)
const subscribing = ref<number | null>(null)
const renewing = ref<number | null>(null)

async function loadSubscriptions() {
  loadingSubscriptions.value = true
  try {
    subscriptions.value = await useApiFetch<Subscription[]>('/api/msgraph/subscriptions') as Subscription[]
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar subscrições', color: 'error' })
  } finally {
    loadingSubscriptions.value = false
  }
}

async function subscribe(mapping: RoomMapping) {
  subscribing.value = mapping.id
  try {
    await useApiFetch('/api/msgraph/subscriptions', {
      method: 'POST',
      body: { mapping_id: mapping.id }
    })
    await loadSubscriptions()
    toast.add({ title: 'Subscrição criada', description: `Webhook activo para ${mapping.resource_email}`, color: 'success' })
  } catch (err: any) {
    toast.add({ title: 'Erro', description: err?.data?.message || 'Erro ao criar subscrição', color: 'error' })
  } finally {
    subscribing.value = null
  }
}

async function renewSubscription(sub: Subscription) {
  renewing.value = sub.id
  try {
    const updated = await useApiFetch<Subscription>(`/api/msgraph/subscriptions/${sub.id}/renew`, { method: 'POST' })
    const idx = subscriptions.value.findIndex(s => s.id === sub.id)
    if (idx !== -1) subscriptions.value[idx] = updated as Subscription
    toast.add({ title: 'Subscrição renovada', color: 'success' })
  } catch (err: any) {
    toast.add({ title: 'Erro', description: err?.data?.message || 'Erro ao renovar subscrição', color: 'error' })
  } finally {
    renewing.value = null
  }
}

async function deleteSubscription(sub: Subscription) {
  try {
    await useApiFetch(`/api/msgraph/subscriptions/${sub.id}`, { method: 'DELETE' })
    subscriptions.value = subscriptions.value.filter(s => s.id !== sub.id)
    toast.add({ title: 'Subscrição removida', color: 'success' })
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao remover subscrição', color: 'error' })
  }
}

// Subscription status helpers
function expiryStatus(expirationDatetime: string): 'ok' | 'soon' | 'expired' {
  const diff = new Date(expirationDatetime).getTime() - Date.now()
  if (diff < 0) return 'expired'
  if (diff < 12 * 60 * 60 * 1000) return 'soon' // < 12 hours
  return 'ok'
}

function mappingHasSubscription(mapping: RoomMapping) {
  return subscriptions.value.some(s => s.resource_email === mapping.resource_email)
}

// ─── Mock Payload ──────────────────────────────────────────────
const mockPayload = `{
  "value": [
    {
      "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "subscriptionExpirationDateTime": "2026-05-04T10:00:00.0000000Z",
      "changeType": "created",
      "resource": "users/sala-a@empresa.pt/events/AAMkAGI...",
      "resourceData": {
        "@odata.type": "#Microsoft.Graph.Event",
        "@odata.id": "Users/xxxxxxxx/Events/AAMkAGI...",
        "@odata.etag": "W/\\"abc123\\"",
        "id": "AAMkAGI2..."
      },
      "clientState": "o-teu-webhook-secret"
    }
  ]
}`

const showMock = ref(false)

onMounted(() => {
  loadMappings()
  loadSubscriptions()
})
</script>

<template>
  <div class="space-y-8" :class="{ 'opacity-50 pointer-events-none select-none': !props.enabled }">
    <UAlert
      v-if="!props.enabled"
      icon="i-lucide-power-off"
      color="warning"
      variant="soft"
      title="Integração desactivada"
      description="Activa a opção 'Integração Ativa' acima e guarda as credenciais para começar a usar o webhook e os mapeamentos."
    />

    <!-- Webhook URL -->
    <div>
      <p class="text-sm font-medium text-(--ui-text) mb-2">URL do Webhook (configurar no Azure AD)</p>
      <div class="flex items-center gap-2">
        <UInput :model-value="webhookUrl" readonly class="flex-1 font-mono text-sm" />
        <UButton icon="i-lucide-copy" color="neutral" variant="outline" @click="copyWebhookUrl" />
      </div>
      <p class="text-xs text-(--ui-text-muted) mt-1">
        Registe este URL como <strong>Notification URL</strong> no Azure AD App Registration.
        A aplicação precisa de permissões de aplicação <code>Calendars.ReadWrite</code> com admin consent.
      </p>
    </div>

    <!-- Mock Payload -->
    <div>
      <UButton
        :label="showMock ? 'Ocultar payload de teste' : 'Ver payload mock (teste local)'"
        :icon="showMock ? 'i-lucide-chevron-up' : 'i-lucide-code-2'"
        color="neutral" variant="ghost" size="sm"
        @click="showMock = !showMock"
      />
      <div v-if="showMock" class="mt-2 rounded-lg bg-(--ui-bg-muted) border border-(--ui-border) p-3 overflow-x-auto">
        <pre class="text-xs font-mono whitespace-pre text-(--ui-text)">{{ mockPayload }}</pre>
        <p class="text-xs text-(--ui-text-muted) mt-2">
          Envia este JSON via <code>POST /api/webhook/msgraph</code> para testar localmente
          (sem precisar de acesso ao Azure AD).
        </p>
      </div>
    </div>

    <!-- Room Mappings -->
    <div>
      <p class="text-sm font-semibold text-(--ui-text) mb-3">Mapeamento de Salas → Caixa de Recurso Outlook</p>

      <div v-if="loadingMappings" class="flex justify-center py-6">
        <UIcon name="i-lucide-loader-2" class="size-5 animate-spin text-primary" />
      </div>

      <template v-else>
        <UTable
          v-if="mappings.length"
          :data="mappings"
          :columns="[
            { key: 'room_name', label: 'Sala' },
            { key: 'resource_email', label: 'Email de Recurso Outlook' },
            { key: 'actions', label: '' }
          ]"
          class="mb-4"
        >
          <template #actions-data="{ row }">
            <div class="flex justify-end gap-2">
              <UButton
                v-if="!mappingHasSubscription(row)"
                label="Subscrever webhook"
                icon="i-lucide-webhook"
                size="xs"
                color="primary"
                variant="soft"
                :loading="subscribing === row.id"
                @click="subscribe(row)"
              />
              <UBadge v-else label="Subscrito" color="success" variant="soft" size="xs" />
              <UButton
                icon="i-lucide-trash-2"
                size="xs"
                color="error"
                variant="ghost"
                @click="deleteMapping(row.id)"
              />
            </div>
          </template>
        </UTable>

        <p v-else class="text-sm text-(--ui-text-muted) mb-4">Nenhum mapeamento configurado.</p>

        <!-- Add mapping form -->
        <div v-if="unmappedRooms.length" class="flex items-end gap-2 flex-wrap">
          <UFormField label="Sala" class="flex-1 min-w-40">
            <USelect
              v-model="newMappingRoomId"
              :items="unmappedRooms.map(r => ({ label: r.name, value: r.id }))"
              placeholder="Escolher sala..."
            />
          </UFormField>
          <UFormField label="Email de recurso Outlook" class="flex-1 min-w-56">
            <UInput
              v-model="newMappingEmail"
              placeholder="sala-a@empresa.pt"
              type="email"
            />
          </UFormField>
          <UButton
            label="Adicionar"
            icon="i-lucide-plus"
            :loading="addingMapping"
            :disabled="!newMappingRoomId || !newMappingEmail.trim()"
            @click="addMapping"
          />
        </div>
      </template>
    </div>

    <!-- Subscriptions -->
    <div>
      <p class="text-sm font-semibold text-(--ui-text) mb-1">Subscrições de Webhook Activas</p>
      <p class="text-xs text-(--ui-text-muted) mb-3">
        As subscrições do Microsoft Graph expiram ao fim de 3 dias — renove antes da expiração.
      </p>

      <div v-if="loadingSubscriptions" class="flex justify-center py-6">
        <UIcon name="i-lucide-loader-2" class="size-5 animate-spin text-primary" />
      </div>

      <template v-else>
        <UTable
          v-if="subscriptions.length"
          :data="subscriptions"
          :columns="[
            { key: 'room_name', label: 'Sala' },
            { key: 'resource_email', label: 'Email de Recurso' },
            { key: 'expiration_datetime', label: 'Expira em' },
            { key: 'actions', label: '' }
          ]"
        >
          <template #expiration_datetime-data="{ row }">
            <div class="flex items-center gap-2">
              <UBadge
                :label="new Date(row.expiration_datetime).toLocaleString('pt-PT')"
                :color="expiryStatus(row.expiration_datetime) === 'expired' ? 'error' : expiryStatus(row.expiration_datetime) === 'soon' ? 'warning' : 'success'"
                variant="soft"
                size="xs"
              />
            </div>
          </template>
          <template #actions-data="{ row }">
            <div class="flex justify-end gap-2">
              <UButton
                label="Renovar"
                icon="i-lucide-refresh-cw"
                size="xs"
                color="primary"
                variant="soft"
                :loading="renewing === row.id"
                @click="renewSubscription(row)"
              />
              <UButton
                icon="i-lucide-trash-2"
                size="xs"
                color="error"
                variant="ghost"
                @click="deleteSubscription(row)"
              />
            </div>
          </template>
        </UTable>

        <p v-else class="text-sm text-(--ui-text-muted)">
          Sem subscrições activas. Clique em <strong>Subscrever webhook</strong> junto a um mapeamento para activar a sincronização.
        </p>
      </template>
    </div>

    <!-- Azure AD Setup Notes -->
    <UAlert
      icon="i-lucide-info"
      color="info"
      variant="soft"
      title="Configuração no Azure AD"
      description="1. Registe uma App em Azure AD → App registrations. 2. Adicione permissão de aplicação Calendars.ReadWrite e conceda admin consent. 3. Crie um Client Secret e preencha os campos acima. 4. As caixas de recurso das salas devem ter a licença Exchange Online activa."
    />

  </div>
</template>
