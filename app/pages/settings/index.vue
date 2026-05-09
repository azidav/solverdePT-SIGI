<script setup lang="ts">
definePageMeta({ title: 'Variáveis de Configuração' })

interface ConfigVar {
  id: number
  section: string
  key: string
  label: string
  value: string
  is_secret: boolean
  description: string
  input_type: string
}

const SECTION_META: Record<string, { label: string, icon: string }> = {
  email: { label: 'Configurações de Email', icon: 'i-lucide-mail' },
  rooms: { label: 'Salas de Reunião', icon: 'i-lucide-door-open' },
  ferias: { label: 'Férias', icon: 'i-lucide-calendar-days' },
  msgraph: { label: 'Integração Microsoft 365', icon: 'i-simple-icons-microsoftoutlook' }
}

const EXTRA_SECTIONS = [
  { slot: 'vacation_types', label: 'Tipos de Ausência', icon: 'i-lucide-tag' }
]

const toast = useToast()
const loading = ref(true)
const saving = ref<string | null>(null)

const allVars = ref<ConfigVar[]>([])
const editedValues = reactive<Record<string, string>>({})

const sections = computed(() => {
  const groups: Record<string, ConfigVar[]> = {}
  allVars.value.forEach((v) => {
    if (!groups[v.section]) groups[v.section] = []
    groups[v.section]!.push(v)
  })
  return groups
})

const standardSections = computed(() => {
  const result: Record<string, ConfigVar[]> = {}
  Object.entries(sections.value).forEach(([k, v]) => {
    if (k !== 'msgraph') result[k] = v
  })
  return result
})

const accordionItems = computed(() => [
  ...Object.keys(sections.value).map(section => ({
    label: SECTION_META[section]?.label || section,
    icon: SECTION_META[section]?.icon || 'i-lucide-settings-2',
    slot: section
  })),
  ...EXTRA_SECTIONS
])

async function loadConfig() {
  loading.value = true
  try {
    const data = await useApiFetch('/api/config')
    allVars.value = data as ConfigVar[]
    allVars.value.forEach((v) => {
      editedValues[v.key] = v.value || ''
    })
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao carregar configurações', color: 'error' })
  } finally {
    loading.value = false
  }
}

async function saveSection(section: string) {
  saving.value = section
  try {
    const updates = (sections.value[section] || []).map(v => ({
      key: v.key,
      value: editedValues[v.key] ?? ''
    }))
    await useApiFetch('/api/config', { method: 'PUT', body: updates })
    toast.add({ title: 'Sucesso', description: 'Configurações guardadas com sucesso', color: 'success' })
  } catch {
    toast.add({ title: 'Erro', description: 'Erro ao guardar configurações', color: 'error' })
  } finally {
    saving.value = null
  }
}

onMounted(loadConfig)
</script>

<template>
  <div v-if="loading" class="flex items-center justify-center py-16">
    <UIcon name="i-lucide-loader-2" class="size-6 animate-spin text-primary" />
  </div>
  <UAccordion v-else :items="accordionItems" :default-value="accordionItems[0]?.slot">
    <template v-for="(vars, section) in standardSections" :key="section" #[section]>
      <div class="space-y-5 px-1 pb-4 pt-2">
        <div v-for="v in vars" :key="v.key">
          <UFormField
            :label="v.label"
            :description="v.description || undefined"
            :name="v.key"
          >
            <template v-if="v.input_type === 'checkbox'">
              <UCheckbox
                :model-value="editedValues[v.key] === 'true'"
                :label="v.label"
                @update:model-value="(val) => { editedValues[v.key] = String(val) }"
              />
            </template>
            <template v-else>
              <UInput
                v-model="editedValues[v.key]"
                :type="v.input_type || 'text'"
                class="w-1/2"
                :placeholder="v.label"
              />
            </template>
          </UFormField>
        </div>
        <div class="flex justify-end border-t border-default pt-4">
          <UButton
            label="Guardar"
            color="primary"
            icon="i-lucide-save"
            :loading="saving === section"
            @click="saveSection(section as string)"
          />
        </div>
      </div>
    </template>
    <template #vacation_types>
      <div class="px-1 pb-4 pt-2">
        <SettingsVacationTypeManager />
      </div>
    </template>

    <template #msgraph>
      <div class="space-y-6 px-1 pb-4 pt-2">
        <div class="space-y-5">
          <div v-for="v in sections.msgraph" :key="v.key">
            <UFormField
              :label="v.label"
              :description="v.description || undefined"
              :name="v.key"
            >
              <template v-if="v.input_type === 'checkbox'">
                <UCheckbox
                  :model-value="editedValues[v.key] === 'true'"
                  :label="v.label"
                  @update:model-value="(val) => { editedValues[v.key] = String(val) }"
                />
              </template>
              <template v-else>
                <UInput
                  v-model="editedValues[v.key]"
                  :type="v.input_type || 'text'"
                  class="w-1/2"
                  :placeholder="v.label"
                />
              </template>
            </UFormField>
          </div>
          <div class="flex justify-end border-t border-default pt-4">
            <UButton
              label="Guardar credenciais"
              color="primary"
              icon="i-lucide-save"
              :loading="saving === 'msgraph'"
              @click="saveSection('msgraph')"
            />
          </div>
        </div>
        <div class="border-t border-default pt-2">
          <p class="text-xs font-semibold uppercase tracking-wide text-muted mb-4">
            Mapeamentos &amp; Subscrições de Webhook
          </p>
          <SettingsMsGraphSettings :enabled="editedValues['msgraph_enabled'] === 'true'" />
        </div>
      </div>
    </template>
  </UAccordion>
</template>
