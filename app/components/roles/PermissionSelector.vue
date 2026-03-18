<template>
  <div class="space-y-4">
    <!-- Debug info -->
    <div class="text-xs bg-gray-100 dark:bg-slate-800 p-2 rounded mb-4">
      Props: permissions={{ permissions.length }}, modelValue={{ modelValue.length }}<br>
      Computed: groupedPermissions keys={{ Object.keys(groupedPermissions).join(', ') }}, total modules={{ Object.keys(groupedPermissions).length }}
    </div>

    <!-- Permissions grouped by module -->
    <div
      v-for="(perms, moduleName) in groupedPermissions"
      :key="moduleName"
      class="border rounded-lg p-4 bg-white dark:bg-slate-950"
    >
      <!-- Module header -->
      <div class="flex items-center gap-3 mb-3 pb-3 border-b">
        <UCheckbox
          :model-value="isModuleChecked(moduleName)"
          :indeterminate="isModulePartial(moduleName)"
          class="cursor-pointer"
          @update:model-value="toggleModule(moduleName)"
        />
        <h3 class="font-semibold text-sm">
          {{ moduleLabels[moduleName] || moduleName }}
        </h3>
        <span class="text-xs text-gray-500 ml-auto">
          {{ getModuleCount(moduleName) }} / {{ perms.length }}
        </span>
      </div>

      <!-- Permissions for module -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
        <div
          v-for="permission in perms"
          :key="permission.id"
          class="flex items-start gap-2"
        >
          <UCheckbox
            :model-value="isPermissionSelected(permission.id)"
            class="mt-1 cursor-pointer"
            @update:model-value="handlePermissionChange(permission.id)"
          />
          <div class="flex-1">
            <label class="text-sm font-medium cursor-pointer block">
              {{ permission.description }}
            </label>
            <p class="text-xs text-gray-500">
              {{ permission.code }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-if="Object.keys(groupedPermissions).length === 0" class="text-center py-8 text-gray-500">
      Nenhuma permissão para mostrar
    </div>
  </div>
</template>

<script setup lang="ts">
interface Permission {
  id: number
  code: string
  description: string
  module: string
  action?: string
}

const props = defineProps<{
  permissions: Permission[]
  modelValue: number[]
}>()

const emit = defineEmits<{
  'update:modelValue': [value: number[]]
}>()

const moduleLabels: Record<string, string> = {
  VACATION: '🏖️ Férias',
  EQUIPMENT: '🖥️ Equipamentos',
  ROOMS: '🏢 Salas de Reunião',
  SETTINGS: '⚙️ Definições'
}

const groupedPermissions = computed(() => {
  console.log('[PermissionSelector] Computing groupedPermissions from', props.permissions.length, 'permissions')
  const acc: Record<string, Permission[]> = {}
  props.permissions.forEach((perm) => {
    if (acc[perm.module] === undefined) {
      acc[perm.module] = []
    }
    acc[perm.module]!.push(perm)
  })
  console.log('[PermissionSelector] Grouped by modules:', Object.keys(acc).join(', '))
  return acc
})

const isPermissionSelected = (permissionId: number): boolean => {
  return props.modelValue.includes(permissionId)
}

const handlePermissionChange = (permissionId: number) => {
  const updated = props.modelValue.includes(permissionId)
    ? props.modelValue.filter(id => id !== permissionId)
    : [...props.modelValue, permissionId]
  emit('update:modelValue', updated)
}

const isModuleChecked = (module: string): boolean => {
  const perms = groupedPermissions.value[module] || []
  return perms.length > 0 && perms.every(p => props.modelValue.includes(p.id))
}

const isModulePartial = (module: string): boolean => {
  const perms = groupedPermissions.value[module] || []
  const selectedCount = perms.filter(p => props.modelValue.includes(p.id)).length
  return selectedCount > 0 && selectedCount < perms.length
}

const toggleModule = (module: string) => {
  const perms = groupedPermissions.value[module] || []
  const isChecked = isModuleChecked(module)
  const permIds = perms.map(p => p.id)

  let updated: number[]
  if (isChecked) {
    // Uncheck all in module
    updated = props.modelValue.filter(id => !permIds.includes(id))
  } else {
    // Check all in module
    const newIds = permIds.filter(id => !props.modelValue.includes(id))
    updated = [...props.modelValue, ...newIds]
  }
  emit('update:modelValue', updated)
}

const getModuleCount = (module: string): number => {
  const perms = groupedPermissions.value[module] || []
  return perms.filter(p => props.modelValue.includes(p.id)).length
}
</script>
