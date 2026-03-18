<script setup lang="ts">
import { defineAsyncComponent } from 'vue'

// Parent route that keeps the list visible and shows child routes as a modal
const route = useRoute()
const router = useRouter()

const RolesList = defineAsyncComponent(() => import('~/pages/users/roles/index.vue'))

const isModalActive = computed(() => {
  const name = route.name as string | undefined
  if (!name) return false
  return name !== 'users-roles' && name !== 'users-roles-index'
})

function closeModal() {
  router.replace('/users/roles')
}
</script>

<template>
  <RolesList />

  <Teleport to="body">
    <Transition name="fade">
      <div v-if="isModalActive" class="fixed inset-0 z-50 flex items-start justify-center p-6">
        <div class="relative w-full max-w-xl bg-background rounded-lg shadow-lg border border-default overflow-hidden">
          <div class="flex justify-end p-2">
            <UButton
              icon="i-lucide-x"
              variant="ghost"
              size="xs"
              aria-label="Fechar"
              @click="closeModal"
            />
          </div>
          <div class="p-4">
            <NuxtPage />
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>
