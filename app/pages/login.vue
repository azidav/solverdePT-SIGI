<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent, AuthFormField } from '@nuxt/ui'
import { useAuth } from '~/composables/useAuth'

const auth = useAuth()
const toast = useAppToast()

definePageMeta({ layout: 'auth', title: 'Login' })

const fields: AuthFormField[] = [{
  name: 'username',
  type: 'text',
  label: 'Utilizador',
  placeholder: 'Insere o teu utilizador',
  required: true
}, {
  name: 'password',
  label: 'Password',
  type: 'password',
  placeholder: 'Insere a tua password',
  required: true
}]

const schema = z.object({
  username: z.string('Utilizador obrigatório').min(1, 'Utilizador obrigatório'),
  password: z.string('Password obrigatória').min(4, 'Tem que conter pelo menos 4 caracteres')
})

type Schema = z.output<typeof schema>

const isLoading = ref(false)

async function onSubmit(payload: FormSubmitEvent<Schema>) {
  if (isLoading.value) return // Prevent resubmit

  isLoading.value = true
  try {
    await auth.login(payload.data.username, payload.data.password)
    // If login did not navigate, redirect as a fallback
    if (!auth.isAuthenticated.value) {
      toast.error(auth.error.value || auth.error || 'Invalid credentials', 'Erro no login')
      isLoading.value = false
      return
    }


    const u = auth.user?.value ?? null
    const welcomeToast = useState<string | null>('welcome-toast', () => null)
    welcomeToast.value = `Bem-vindo/a ${u?.name || u?.username}`

    await navigateTo('/')
  } catch (e: unknown) {
    isLoading.value = false
    let message = 'Invalid credentials'
    if (typeof e === 'object' && e) {
      const maybe = e as Record<string, unknown>
      const data = maybe['data'] as Record<string, unknown> | undefined
      const fromData = typeof data?.message === 'string' ? data.message : undefined
      const fromMessage = typeof maybe['message'] === 'string' ? maybe['message'] as string : undefined
      message = fromData || fromMessage || message
    }
    toast.error(message, 'Erro no login')
  }
}
</script>

<template>
  <div class="flex min-h-screen flex-col items-center justify-center gap-4 p-4">
    <UPageCard class="w-full max-w-md">
      <UAuthForm
        :schema="schema"
        title="Login"
        description="Insere as credenciais da tua conta."
        icon="i-lucide-user"
        :fields="fields"
        :loading="isLoading"
        @submit="onSubmit"
      >
        <template #description>
          <ULink to="/forgot-password" class="text-primary font-medium">Esqueceste-te da password?</ULink>
        </template>
      </UAuthForm>
    </UPageCard>

    <UPageCard class="w-full max-w-md">
      <div class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-3">
          <UIcon name="i-lucide-door-open" class="size-8 text-primary shrink-0" />
          <div>
            <p class="text-sm font-medium">
              Reservar Sala de Reunião
            </p>
            <p class="text-xs text-muted">
              Acesso sem conta necessária
            </p>
          </div>
        </div>
        <UButton
          label="Entrar como visitante"
          icon="i-lucide-arrow-right"
          trailing
          color="primary"
          variant="soft"
          size="sm"
          to="/meeting-rooms"
        />
      </div>
    </UPageCard>
  </div>
</template>

