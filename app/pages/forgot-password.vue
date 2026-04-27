<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

definePageMeta({ layout: 'auth' })

const toast = useAppToast()
const loading = ref(false)
const sent = ref(false)

const schema = z.object({
  email: z.email('Email inválido')
})

type Schema = z.output<typeof schema>

async function onSubmit(event: FormSubmitEvent<Schema>) {
  loading.value = true
  try {
    await $fetch('/api/auth/forgot-password', {
      method: 'POST',
      body: { email: event.data.email }
    })
    sent.value = true
  } catch {
    toast.error('Erro ao enviar email de recuperação', 'Erro')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="flex min-h-screen flex-col items-center justify-center gap-4 p-4">
    <UPageCard class="w-full max-w-md">
      <!-- Sucesso -->
      <div v-if="sent" class="flex flex-col items-center gap-4 p-8 text-center">
        <UIcon name="i-lucide-mail-check" class="size-14 text-primary" />
        <h2 class="text-xl font-semibold">Email enviado!</h2>
        <p class="text-muted text-sm">
          Se o email existir na nossa base de dados, receberás um link para redefinir a tua password.
          O link expira em <strong>1 hora</strong>.
        </p>
        <UButton label="Voltar ao Login" to="/login" color="primary" variant="soft" class="mt-2" />
      </div>

      <!-- Formulário -->
      <UAuthForm
        v-else
        :schema="schema"
        title="Recuperar Password"
        icon="i-lucide-lock-keyhole"
        :fields="[{
          name: 'email',
          type: 'email',
          label: 'Email',
          placeholder: 'o.teu@email.com',
          required: true
        }]"
        :loading="loading"
        submit-label="Enviar Link"
        @submit="onSubmit"
      >
        <template #description>
          Recordas-te da password?
          <ULink to="/login" class="text-primary font-medium">Volta ao Login</ULink>.
        </template>
      </UAuthForm>
    </UPageCard>
  </div>
</template>
