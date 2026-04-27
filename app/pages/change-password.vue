<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

definePageMeta({ layout: 'auth' })

const auth = useAuth()
const router = useRouter()
const toast = useAppToast()
const loading = ref(false)

const schema = z.object({
  currentPassword: z.string().min(4, 'Password atual obrigatória'),
  newPassword: z.string().min(6, 'Nova password deve ter pelo menos 6 caracteres'),
  confirmPassword: z.string()
}).refine(d => d.newPassword === d.confirmPassword, {
  message: 'As passwords não coincidem',
  path: ['confirmPassword']
}).refine(d => d.currentPassword !== d.newPassword, {
  message: 'A nova password deve ser diferente da atual',
  path: ['newPassword']
})

type Schema = z.output<typeof schema>

async function onSubmit(event: FormSubmitEvent<Schema>) {
  loading.value = true
  try {
    await useApiFetch('/api/auth/change-password', {
      method: 'POST',
      body: {
        currentPassword: event.data.currentPassword,
        newPassword: event.data.newPassword
      }
    })

    // Clear the flag in client auth state
    if (auth.user.value) {
      auth.loginWithUser({ ...auth.user.value, must_change_password: false })
    }

    toast.success('Password alterada com sucesso! Bem-vindo/a.', 'Sucesso')
    await router.push('/')
  } catch (err: unknown) {
    const msg = ((err as any)?.data?.message) || 'Erro ao alterar password'
    toast.error(msg, 'Erro')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="flex min-h-screen flex-col items-center justify-center gap-4 p-4">
    <UPageCard class="w-full max-w-md">
      <div class="flex flex-col items-center gap-1 pb-4 text-center">
        <UIcon name="i-lucide-lock-keyhole" class="size-10 text-primary mb-2" />
        <h1 class="text-xl font-semibold">Definir password pessoal</h1>
        <p class="text-sm text-muted">
          Por segurança, tem de definir uma nova password antes de continuar.<br>
          Encontra a sua password temporária no email que recebeu.
        </p>
      </div>

      <UForm :schema="schema" :state="{ currentPassword: '', newPassword: '', confirmPassword: '' }" class="space-y-4" @submit="onSubmit">
        <UFormField label="Password atual (temporária)" name="currentPassword" required>
          <UInput
            name="currentPassword"
            type="password"
            placeholder="••••••••"
            class="w-full"
          />
        </UFormField>

        <UFormField label="Nova password" name="newPassword" required>
          <UInput
            name="newPassword"
            type="password"
            placeholder="••••••••"
            class="w-full"
          />
        </UFormField>

        <UFormField label="Confirmar nova password" name="confirmPassword" required>
          <UInput
            name="confirmPassword"
            type="password"
            placeholder="••••••••"
            class="w-full"
          />
        </UFormField>

        <UButton
          type="submit"
          label="Definir Password e Entrar"
          color="primary"
          block
          :loading="loading"
        />
      </UForm>
    </UPageCard>
  </div>
</template>
