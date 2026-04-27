<script setup lang="ts">
import * as z from 'zod'
import type { FormSubmitEvent } from '@nuxt/ui'

definePageMeta({ title: 'Mudar Password' })

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

const state = reactive({ currentPassword: '', newPassword: '', confirmPassword: '' })

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

    state.currentPassword = ''
    state.newPassword = ''
    state.confirmPassword = ''

    toast.success('Password alterada com sucesso', 'Sucesso')
  } catch (err: unknown) {
    const msg = ((err as any)?.data?.message) || 'Erro ao alterar password'
    toast.error(msg, 'Erro')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="space-y-4">
    <div>
      <h2 class="text-base font-semibold">Mudar Password</h2>
      <p class="text-sm text-muted mt-1">Atualiza a tua password de acesso.</p>
    </div>

    <UCard>
      <UForm :schema="schema" :state="state" class="space-y-4" @submit="onSubmit">
        <UFormField label="Password atual" name="currentPassword" required>
          <UInput v-model="state.currentPassword" type="password" placeholder="••••••••" class="w-1/2" />
        </UFormField>

        <UDivider />

        <UFormField label="Nova password" name="newPassword" required>
          <UInput v-model="state.newPassword" type="password" placeholder="••••••••" class="w-1/2" />
        </UFormField>

        <UFormField label="Confirmar nova password" name="confirmPassword" required>
          <UInput v-model="state.confirmPassword" type="password" placeholder="••••••••" class="w-1/2" />
        </UFormField>

        <div class="flex justify-end pt-2">
          <UButton type="submit" label="Guardar" color="primary" icon="i-lucide-save" :loading="loading" />
        </div>
      </UForm>
    </UCard>
  </div>
</template>
