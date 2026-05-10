<script setup lang="ts">
definePageMeta({ title: 'Níveis de Aprovação' })

const { can, loading: rbacLoading } = useRbac()

const triggerCreateLevel = useState('ferias-create-level', () => false)
watch(triggerCreateLevel, (val) => {
  if (val) {
    openCreate()
    triggerCreateLevel.value = false
  }
})

watchEffect(() => {
  if (!rbacLoading.value && !can('VACATION:VIEW_LEVELS')) {
    navigateTo('/ferias')
  }
})

interface Member {
  id: number
  name: string
  username: string
  email: string
}

interface Level {
  id: number
  name: string
  description: string | null
  step_order: number
  parent_id: number | null
  members: Member[]
}

interface User {
  id: number
  name: string
  username: string
  email: string
}

// Flat node used for rendering the tree hierarchy
interface FlatNode {
  id: number
  name: string
  description: string | null
  members: Member[]
  parent_id: number | null
  step_order: number   // local to siblings
  depth: number
  hasChildren: boolean
}

const toast = useToast()

// ── Data ──────────────────────────────────────────────────────────────────
const levels = ref<Level[]>([])
const allUsers = ref<User[]>([])
const loading = ref(true)
const activeTab = ref('levels')

// ── Level create/edit form ────────────────────────────────────────────────
const showLevelForm = ref(false)
const editingLevel = ref<Level | null>(null)
const levelForm = reactive({ name: '', description: '' })
const savingLevel = ref(false)

// ── Delete confirmation ───────────────────────────────────────────────────
const confirmDeleteLevel = ref<Level | null>(null)
const deletingLevel = ref(false)

// ── Member picker modal ───────────────────────────────────────────────────
const memberModalLevel = ref<Level | null>(null)
const memberSearch = ref('')
const selectedUserIds = ref<number[]>([])
const addingMembers = ref(false)

// ── Tree hierarchy state ──────────────────────────────────────────────────
// Working copy for the hierarchy tab (mutable before saving)
const treeItems = ref<Level[]>([])
const savingOrder = ref(false)
const orderDirty = ref(false)

// Drag state
const draggingId = ref<number | null>(null)
const dropIndicator = ref<{ targetId: number, pos: 'before' | 'into' | 'after' } | null>(null)

// Build a flat DFS list from the current treeItems
const flatNodes = computed((): FlatNode[] => {
  const childrenOf = new Map<number | null, Level[]>()
  for (const item of treeItems.value) {
    const k = item.parent_id
    if (!childrenOf.has(k)) childrenOf.set(k, [])
    childrenOf.get(k)!.push(item)
  }
  for (const [, arr] of childrenOf) arr.sort((a, b) => a.step_order - b.step_order)

  const result: FlatNode[] = []
  function walk(parentId: number | null, depth: number) {
    for (const item of childrenOf.get(parentId) ?? []) {
      result.push({
        id: item.id,
        name: item.name,
        description: item.description,
        members: item.members,
        parent_id: item.parent_id,
        step_order: item.step_order,
        depth,
        hasChildren: (childrenOf.get(item.id) ?? []).length > 0
      })
      walk(item.id, depth + 1)
    }
  }
  walk(null, 0)
  return result
})

// ── Computed ──────────────────────────────────────────────────────────────
const availableUsers = computed(() => {
  const memberIds = new Set(memberModalLevel.value?.members.map(m => m.id) ?? [])
  const q = memberSearch.value.toLowerCase()
  return allUsers.value
    .filter(u => !memberIds.has(u.id))
    .filter(u => !q || u.name.toLowerCase().includes(q) || u.username.toLowerCase().includes(q))
})

// ── Load ──────────────────────────────────────────────────────────────────
async function loadLevels() {
  loading.value = true
  try {
    levels.value = await useApiFetch('/api/approval-levels') as Level[]
    if (!orderDirty.value) treeItems.value = levels.value.map(l => ({ ...l }))
  } catch {
    toast.add({ title: 'Erro ao carregar níveis', color: 'error' })
  } finally {
    loading.value = false
  }
}

async function loadUsers() {
  try {
    allUsers.value = await useApiFetch('/api/users') as User[]
  } catch {}
}

// ── Level CRUD ────────────────────────────────────────────────────────────
function openCreate() {
  editingLevel.value = null
  levelForm.name = ''
  levelForm.description = ''
  showLevelForm.value = true
}

function openEdit(level: Level) {
  editingLevel.value = level
  levelForm.name = level.name
  levelForm.description = level.description ?? ''
  showLevelForm.value = true
}

async function saveLevel() {
  if (!levelForm.name.trim()) return
  savingLevel.value = true
  try {
    if (editingLevel.value) {
      await useApiFetch(`/api/approval-levels/${editingLevel.value.id}`, {
        method: 'PUT',
        body: { name: levelForm.name, description: levelForm.description || null }
      })
      toast.add({ title: 'Nível atualizado', color: 'success' })
    } else {
      await useApiFetch('/api/approval-levels', {
        method: 'POST',
        body: { name: levelForm.name, description: levelForm.description || null }
      })
      toast.add({ title: 'Nível criado', color: 'success' })
    }
    showLevelForm.value = false
    await loadLevels()
  } catch (e: unknown) {
    toast.add({ title: (e as any)?.data?.message || 'Erro ao guardar nível', color: 'error' })
  } finally {
    savingLevel.value = false
  }
}

async function deleteLevel() {
  if (!confirmDeleteLevel.value) return
  deletingLevel.value = true
  try {
    await useApiFetch(`/api/approval-levels/${confirmDeleteLevel.value.id}`, { method: 'DELETE' })
    toast.add({ title: 'Nível eliminado', color: 'success' })
    confirmDeleteLevel.value = null
    await loadLevels()
  } catch {
    toast.add({ title: 'Erro ao eliminar nível', color: 'error' })
  } finally {
    deletingLevel.value = false
  }
}

// ── Members ───────────────────────────────────────────────────────────────
function openMemberModal(level: Level) {
  memberModalLevel.value = level
  memberSearch.value = ''
  selectedUserIds.value = []
}

async function addMembers() {
  if (!memberModalLevel.value || selectedUserIds.value.length === 0) return
  addingMembers.value = true
  try {
    await useApiFetch(`/api/approval-levels/${memberModalLevel.value.id}/members`, {
      method: 'POST',
      body: { user_ids: selectedUserIds.value }
    })
    toast.add({ title: 'Membros adicionados', color: 'success' })
    memberModalLevel.value = null
    await loadLevels()
  } catch {
    toast.add({ title: 'Erro ao adicionar membros', color: 'error' })
  } finally {
    addingMembers.value = false
  }
}

async function removeMember(level: Level, userId: number) {
  try {
    await useApiFetch(`/api/approval-levels/${level.id}/members/${userId}`, { method: 'DELETE' })
    await loadLevels()
  } catch {
    toast.add({ title: 'Erro ao remover membro', color: 'error' })
  }
}

// ── Tree drag & drop ──────────────────────────────────────────────────────
function isDescendantOf(items: Level[], ancestorId: number, nodeId: number): boolean {
  const node = items.find(i => i.id === nodeId)
  if (!node?.parent_id) return false
  if (node.parent_id === ancestorId) return true
  return isDescendantOf(items, ancestorId, node.parent_id)
}

function resequence(items: Level[], parentId: number | null) {
  const siblings = items.filter(i => i.parent_id === parentId)
  siblings.sort((a, b) => a.step_order - b.step_order)
  siblings.forEach((s, idx) => { s.step_order = idx + 1 })
}

function applyDrop(sourceId: number, targetId: number, pos: 'before' | 'into' | 'after') {
  if (sourceId === targetId) return
  const items = treeItems.value
  if (isDescendantOf(items, sourceId, targetId)) return // prevent circular

  const source = items.find(i => i.id === sourceId)!
  const target = items.find(i => i.id === targetId)!
  const oldParentId = source.parent_id

  if (pos === 'into') {
    source.parent_id = targetId
    const maxOrder = Math.max(0, ...items.filter(i => i.parent_id === targetId && i.id !== sourceId).map(i => i.step_order))
    source.step_order = maxOrder + 1
  } else {
    source.parent_id = target.parent_id
    const siblings = items
      .filter(i => i.parent_id === target.parent_id && i.id !== sourceId)
      .sort((a, b) => a.step_order - b.step_order)
    const targetIdx = siblings.findIndex(i => i.id === targetId)
    const insertAt = pos === 'before' ? targetIdx : targetIdx + 1
    siblings.splice(insertAt, 0, source)
    siblings.forEach((s, idx) => { s.step_order = idx + 1 })
  }

  // Re-sequence old parent's remaining children
  if (oldParentId !== source.parent_id) resequence(items, oldParentId)

  orderDirty.value = true
}

function onDragStart(id: number) {
  draggingId.value = id
}

function onDragOver(event: DragEvent, id: number) {
  if (!draggingId.value || draggingId.value === id) return
  event.preventDefault()
  const el = event.currentTarget as HTMLElement
  const { top, height } = el.getBoundingClientRect()
  const pct = (event.clientY - top) / height
  dropIndicator.value = { targetId: id, pos: pct < 0.3 ? 'before' : pct > 0.7 ? 'after' : 'into' }
}

function onDragLeave(event: DragEvent) {
  // Only clear if leaving the element itself (not a child)
  if (!(event.currentTarget as HTMLElement).contains(event.relatedTarget as Node)) {
    dropIndicator.value = null
  }
}

function onDrop(targetId: number) {
  if (draggingId.value && dropIndicator.value?.targetId === targetId) {
    applyDrop(draggingId.value, targetId, dropIndicator.value.pos)
  }
  draggingId.value = null
  dropIndicator.value = null
}

function onDragEnd() {
  draggingId.value = null
  dropIndicator.value = null
}

async function saveOrder() {
  savingOrder.value = true
  try {
    await useApiFetch('/api/approval-levels/reorder', {
      method: 'PUT',
      body: {
        items: treeItems.value.map(i => ({
          id: i.id,
          parent_id: i.parent_id,
          step_order: i.step_order
        }))
      }
    })
    toast.add({ title: 'Hierarquia guardada', color: 'success' })
    orderDirty.value = false
    await loadLevels()
  } catch {
    toast.add({ title: 'Erro ao guardar hierarquia', color: 'error' })
  } finally {
    savingOrder.value = false
  }
}

function discardChanges() {
  treeItems.value = levels.value.map(l => ({ ...l }))
  orderDirty.value = false
}

const tabs = [
  { label: 'Níveis', value: 'levels', slot: 'levels', icon: 'i-lucide-layers' },
  { label: 'Hierarquia', value: 'hierarchy', slot: 'hierarchy', icon: 'i-lucide-git-branch' }
]

onMounted(() => {
  loadLevels()
  loadUsers()
})
</script>

<template>
  <div class="p-4 space-y-4">
    <UTabs v-model="activeTab" :items="tabs">

        <!-- ── Níveis tab ── -->
        <template #levels>
          <div v-if="loading" class="flex justify-center py-12">
            <UIcon name="i-lucide-loader-2" class="size-5 animate-spin text-muted" />
          </div>

          <div v-else-if="levels.length === 0" class="text-center py-12">
            <UIcon name="i-lucide-layers" class="size-10 text-muted mx-auto mb-3" />
            <p class="text-sm text-muted">
              Nenhum nível criado ainda.
            </p>
            <UButton
              label="Criar primeiro nível"
              size="sm"
              color="primary"
              variant="soft"
              class="mt-3"
              @click="openCreate"
            />
          </div>

          <div v-else class="space-y-3 pt-3">
            <UCard
              v-for="level in levels"
              :key="level.id"
            >
              <template #header>
                <div class="flex items-center justify-between gap-3">
                  <div class="flex items-center gap-2">
                    <UBadge color="primary" variant="subtle" size="sm">
                      Nível {{ level.step_order }}
                    </UBadge>
                    <span class="font-semibold text-sm">{{ level.name }}</span>
                    <span v-if="level.description" class="text-xs text-muted">
                      — {{ level.description }}
                    </span>
                  </div>
                  <div class="flex gap-1">
                    <UButton
                      icon="i-lucide-user-plus"
                      size="xs"
                      color="primary"
                      variant="soft"
                      @click="openMemberModal(level)"
                    />
                    <UButton
                      icon="i-lucide-pencil"
                      size="xs"
                      color="neutral"
                      variant="ghost"
                      @click="openEdit(level)"
                    />
                    <UButton
                      icon="i-lucide-trash-2"
                      size="xs"
                      color="error"
                      variant="ghost"
                      @click="confirmDeleteLevel = level"
                    />
                  </div>
                </div>
              </template>

              <div v-if="level.members.length === 0" class="text-xs text-muted italic">
                Sem membros — clique em + para adicionar utilizadores.
              </div>
              <div v-else class="flex flex-wrap gap-2">
                <div
                  v-for="member in level.members"
                  :key="member.id"
                  class="flex items-center gap-1.5 rounded-full border border-default pl-1 pr-2 py-0.5 text-xs"
                >
                  <UAvatar :alt="member.name" size="xs" />
                  <span>{{ member.name }}</span>
                  <button
                    class="text-muted hover:text-error-500 transition-colors ml-0.5"
                    @click="removeMember(level, member.id)"
                  >
                    ×
                  </button>
                </div>
              </div>
            </UCard>

            <UButton
              label="Adicionar Nível"
              icon="i-lucide-plus"
              color="primary"
              variant="soft"
              class="w-full"
              @click="openCreate"
            />
          </div>
        </template>

        <!-- ── Hierarquia tab ── -->
        <template #hierarchy>
          <div class="pt-3 space-y-3">
            <UAlert
              icon="i-lucide-info"
              color="neutral"
              variant="soft"
              description="Arraste para reordenar. Solte EM CIMA de um nível para criar um sub-nível (aparece indentado). Solte ACIMA ou ABAIXO para reordenar ao mesmo nível."
            />

            <div v-if="flatNodes.length === 0" class="text-center py-10 text-sm text-muted">
              Crie níveis no separador "Níveis" primeiro.
            </div>

            <div v-else>
              <div
                v-for="node in flatNodes"
                :key="node.id"
                class="relative"
              >
                <!-- Before drop indicator -->
                <div
                  v-if="dropIndicator?.targetId === node.id && dropIndicator.pos === 'before'"
                  class="absolute top-0 left-0 right-0 z-10 h-0.5 bg-primary rounded-full -translate-y-px"
                  :style="{ marginLeft: `${node.depth * 2}rem` }"
                />

                <div
                  draggable="true"
                  class="flex items-center gap-3 rounded-xl border p-2.5 mb-1 cursor-grab active:cursor-grabbing select-none transition-all"
                  :style="{ marginLeft: `${node.depth * 2}rem` }"
                  :class="[
                    draggingId === node.id
                      ? 'opacity-40 border-dashed'
                      : dropIndicator?.targetId === node.id && dropIndicator.pos === 'into'
                        ? 'border-primary bg-primary/5 shadow-sm'
                        : 'border-default bg-default hover:bg-elevated/50'
                  ]"
                  @dragstart="onDragStart(node.id)"
                  @dragover="onDragOver($event, node.id)"
                  @dragleave="onDragLeave($event)"
                  @drop.prevent="onDrop(node.id)"
                  @dragend="onDragEnd"
                >
                  <UIcon name="i-lucide-grip-vertical" class="size-4 text-muted shrink-0" />

                  <!-- Tree connector for children -->
                  <UIcon
                    v-if="node.depth > 0"
                    name="i-lucide-corner-down-right"
                    class="size-3.5 text-muted shrink-0"
                  />

                  <!-- Sibling order badge -->
                  <div class="flex items-center justify-center size-6 rounded-full bg-primary/10 text-primary text-xs font-bold shrink-0">
                    {{ node.step_order }}
                  </div>

                  <div class="flex-1 min-w-0">
                    <p class="font-medium text-sm">
                      {{ node.name }}
                    </p>
                    <p v-if="node.members.length > 0" class="text-xs text-muted truncate">
                      {{ node.members.map(m => m.name.split(' ')[0]).join(', ') }}
                    </p>
                  </div>

                  <div class="flex items-center gap-1.5 shrink-0">
                    <UBadge v-if="node.hasChildren" color="info" variant="subtle" size="xs">
                      sub-níveis
                    </UBadge>
                    <UBadge color="neutral" variant="subtle" size="xs">
                      {{ node.members.length }} membro{{ node.members.length !== 1 ? 's' : '' }}
                    </UBadge>
                  </div>
                </div>

                <!-- After drop indicator -->
                <div
                  v-if="dropIndicator?.targetId === node.id && dropIndicator.pos === 'after'"
                  class="absolute bottom-0 left-0 right-0 z-10 h-0.5 bg-primary rounded-full translate-y-px mb-1"
                  :style="{ marginLeft: `${node.depth * 2}rem` }"
                />
              </div>
            </div>

            <div v-if="orderDirty" class="flex justify-end gap-2 pt-2 border-t border-default">
              <UButton
                label="Descartar"
                color="neutral"
                variant="subtle"
                @click="discardChanges"
              />
              <UButton
                label="Guardar Hierarquia"
                icon="i-lucide-save"
                color="primary"
                :loading="savingOrder"
                @click="saveOrder"
              />
            </div>
          </div>
        </template>

    </UTabs>
  </div>

  <!-- Create / Edit modal -->
  <UModal
    :open="showLevelForm"
    :title="editingLevel ? 'Editar Nível' : 'Novo Nível'"
    :ui="{ content: 'max-w-sm' }"
    @update:open="(v) => { if (!v) showLevelForm = false }"
  >
    <template #body>
      <div class="space-y-3">
        <UFormField label="Nome do Nível" required>
          <UInput
            v-model="levelForm.name"
            placeholder="ex: Gestores, Recursos Humanos..."
            class="w-full"
            autofocus
          />
        </UFormField>
        <UFormField label="Descrição (opcional)">
          <UInput
            v-model="levelForm.description"
            placeholder="Descrição do nível..."
            class="w-full"
          />
        </UFormField>
        <div class="flex justify-end gap-2 pt-1">
          <UButton label="Cancelar" color="neutral" variant="subtle" @click="showLevelForm = false" />
          <UButton
            :label="editingLevel ? 'Guardar' : 'Criar'"
            color="primary"
            :loading="savingLevel"
            @click="saveLevel"
          />
        </div>
      </div>
    </template>
  </UModal>

  <!-- Delete confirmation -->
  <UModal
    :open="!!confirmDeleteLevel"
    title="Eliminar Nível"
    :ui="{ content: 'max-w-sm' }"
    @update:open="(v) => { if (!v) confirmDeleteLevel = null }"
  >
    <template #body>
      <div class="space-y-4">
        <p class="text-sm">
          Tem a certeza que pretende eliminar o nível
          <span class="font-semibold">"{{ confirmDeleteLevel?.name }}"</span>?
          Todos os membros serão removidos e a hierarquia será reordenada.
        </p>
        <div class="flex justify-end gap-2">
          <UButton label="Cancelar" color="neutral" variant="subtle" @click="confirmDeleteLevel = null" />
          <UButton
            label="Eliminar"
            color="error"
            icon="i-lucide-trash-2"
            :loading="deletingLevel"
            @click="deleteLevel"
          />
        </div>
      </div>
    </template>
  </UModal>

  <!-- Add members modal -->
  <UModal
    :open="!!memberModalLevel"
    :title="`Adicionar Membros — ${memberModalLevel?.name}`"
    :ui="{ content: 'max-w-md' }"
    @update:open="(v) => { if (!v) memberModalLevel = null }"
  >
    <template #body>
      <div class="space-y-3">
        <UInput
          v-model="memberSearch"
          icon="i-lucide-search"
          placeholder="Pesquisar utilizador..."
          autofocus
        />
        <div class="max-h-64 overflow-y-auto divide-y divide-default rounded-lg border border-default">
          <div
            v-for="user in availableUsers"
            :key="user.id"
            class="flex items-center gap-3 px-3 py-2.5 hover:bg-elevated/50 cursor-pointer transition-colors"
            @click="selectedUserIds.includes(user.id)
              ? selectedUserIds.splice(selectedUserIds.indexOf(user.id), 1)
              : selectedUserIds.push(user.id)"
          >
            <UCheckbox :model-value="selectedUserIds.includes(user.id)" @click.stop />
            <UAvatar :alt="user.name" size="xs" />
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium truncate">
                {{ user.name }}
              </p>
              <p class="text-xs text-muted truncate">
                {{ user.username }}
              </p>
            </div>
          </div>
          <div v-if="availableUsers.length === 0" class="px-3 py-6 text-center text-sm text-muted">
            Nenhum utilizador disponível.
          </div>
        </div>
        <div class="flex items-center justify-between pt-1">
          <span class="text-sm text-muted">{{ selectedUserIds.length }} selecionado(s)</span>
          <div class="flex gap-2">
            <UButton label="Cancelar" color="neutral" variant="subtle" @click="memberModalLevel = null" />
            <UButton
              label="Adicionar"
              color="primary"
              icon="i-lucide-user-plus"
              :disabled="selectedUserIds.length === 0"
              :loading="addingMembers"
              @click="addMembers"
            />
          </div>
        </div>
      </div>
    </template>
  </UModal>
</template>
