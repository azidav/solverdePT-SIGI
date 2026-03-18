<script setup lang="ts">
import * as z from 'zod'
import type { FormError } from '@nuxt/ui'
import { ref } from 'vue'

const showPass = ref(false)
const showPassDuplo = ref(false)

const passwordSchema = z.object({
  current: z.string().min(4, 'Must be at least 4 characters'),
  new: z.string().min(4, 'Must be at least 4 characters')
})

type PasswordSchema = z.output<typeof passwordSchema>

const password = reactive<Partial<PasswordSchema>>({
  current: undefined,
  new: undefined
})

const validate = (state: Partial<PasswordSchema>): FormError[] => {
  const errors: FormError[] = []
  if (state.current && state.new && state.current === state.new) {
    errors.push({ name: 'new', message: 'Passwords must be different' })
  }
  return errors
}

const toast = useToast()
const isSubmitting = ref(false)

async function onSubmit() {
  // basic guard
  if (!password.current || !password.new) return

  isSubmitting.value = true
  try {
    await useApiFetch('/api/auth/change-password', {
      method: 'POST',
      body: {
        currentPassword: password.current,
        newPassword: password.new,
      },
    })

    toast.add({
      title: 'Password updated',
      description: 'Your password was changed successfully.',
      color: 'success',
      icon: 'i-lucide-check',
    })

    // reset form
    password.current = undefined
    password.new = undefined
  } catch (e: any) {
    toast.add({
      title: 'Error',
      description: e?.data?.message || e?.message || 'Failed to update password',
      color: 'error',
      icon: 'i-lucide-alert-triangle',
    })
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <UPageCard
    title="Password"
    description="Confirm your current password before setting a new one."
    variant="subtle"
  >
    <UForm
      :schema="passwordSchema"
      :state="password"
      :validate="validate"
      class="flex flex-col gap-4 max-w-xs"
      @submit.prevent="onSubmit"
    >
      <UFormField name="current">
          <UInput
            v-model="password.current"
            :type="showPass ? 'text' : 'password'"
            placeholder="Current password"
            class="w-full"
          >
          <template #trailing>
            <UButton
              color="neutral"
              variant="link"
              size="sm"
              :icon="showPass ? 'i-lucide-eye-off' : 'i-lucide-eye'"
              :aria-label="showPass ? 'Esconder password' : 'Mostrar password'"
              :aria-pressed="showPass"
              aria-controls="password"
              @click="showPass = !showPass"
            />
          </template>
        </UInput>
      </UFormField>

      <UFormField name="new">
        <UInput
          v-model="password.new"
          :type="showPassDuplo ? 'text' : 'password'"
          placeholder="New password"
          class="w-full"
          >
          <template #trailing>
            <UButton
              color="neutral"
              variant="link"
              size="sm"
              :icon="showPassDuplo ? 'i-lucide-eye-off' : 'i-lucide-eye'"
              :aria-label="showPassDuplo ? 'Esconder password' : 'Mostrar password'"
              :aria-pressed="showPassDuplo"
              aria-controls="password"
              @click="showPassDuplo = !showPassDuplo"
            />
          </template>
        </UInput>
      </UFormField>

      <UButton :label="isSubmitting ? 'Updating...' : 'Update'" class="w-fit" type="submit" :disabled="isSubmitting" />
    </UForm>
  </UPageCard>

</template>
