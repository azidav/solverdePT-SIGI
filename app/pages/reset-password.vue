<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

definePageMeta({ layout: 'auth', title: 'Definir Password' })

const route = useRoute()
const router = useRouter()
const auth = useAuth()
const toast = useAppToast()

const token = computed(() => route.query.token as string || '')
const loading = ref(false)

if (!token.value) {
  navigateTo('/login', { replace: true })
}

const schema = z.object({
  password: z.string().min(6, 'A password deve ter pelo menos 6 caracteres'),
  confirm: z.string()
}).refine(d => d.password === d.confirm, {
  message: 'As passwords não coincidem',
  path: ['confirm']
})

type Schema = z.output<typeof schema>

async function onSubmit(event: FormSubmitEvent<Schema>) {
  loading.value = true
  try {
    const result = await $fetch('/api/auth/reset-password', {
      method: 'POST',
      body: { token: token.value, password: event.data.password }
    }) as { user: { id: number; username: string; name: string; email: string; permission: number; status: number } }

    auth.loginWithUser(result.user as any)
    toast.success(`Bem-vindo/a de volta, ${result.user.name}!`, 'Password alterada')
    await router.push('/')
  } catch (err: unknown) {
    const msg = ((err as any)?.data?.message) || 'Link inválido ou expirado'
    toast.error(msg, 'Erro')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="flex min-h-screen flex-col items-center justify-center gap-4 p-4">
    <UPageCard class="w-full max-w-md">
      <UAuthForm
        :schema="schema"
        title="Nova Password"
        icon="i-lucide-lock"
        :fields="[
          {
            name: 'password',
            type: 'password',
            label: 'Nova Password',
            placeholder: '••••••••',
            required: true
          },
          {
            name: 'confirm',
            type: 'password',
            label: 'Confirmar Password',
            placeholder: '••••••••',
            required: true
          }
        ]"
        :loading="loading"
        submit-label="Definir Password"
        @submit="onSubmit"
      >
        <template #description>
          <ULink to="/login" class="text-primary font-medium">Voltar ao Login</ULink>
        </template>
      </UAuthForm>
    </UPageCard>
  </div>
</template>
