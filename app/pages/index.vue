<script setup lang="ts">
import type { DropdownMenuItem } from '@nuxt/ui'

const items = [[{
  label: 'Nova Sessão',
  icon: 'i-lucide-calendar-plus',
  to: '/book-session'
}, {
  label: 'Novo Cliente',
  icon: 'i-lucide-user-plus',
  to: '/customers'
}]] satisfies DropdownMenuItem[][]
</script>

<template>
  <UDashboardPanel id="home">
    <template #header>
      <UDashboardNavbar title="Início">
        <template #leading>
          <UDashboardSidebarCollapse />
        </template>

        <template #right>
          <UDropdownMenu :items="items">
            <UButton icon="i-lucide-plus" size="md" class="rounded-full" />
          </UDropdownMenu>
        </template>
      </UDashboardNavbar>
    </template>

    <template #body>
      <div class="space-y-6">
        <UCard>
          <template #header>
            <h2 class="text-xl font-semibold">
              Bem-vindo à SolverdePT SIGI
            </h2>
          </template>

          <div class="space-y-4">
            <p class="text-muted">
              Sistema de gestão de sessões e clientes
            </p>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <UCard>
                <NuxtLink to="/book-session" class="block">
                  <div class="flex items-center gap-3">
                    <UIcon name="i-lucide-calendar" class="size-8 text-primary" />
                    <div>
                      <p class="font-semibold">
                        Sessões
                      </p>
                      <p class="text-sm text-muted">
                        Gerir agendamentos
                      </p>
                    </div>
                  </div>
                </NuxtLink>
              </UCard>

              <UCard>
                <NuxtLink to="/customers" class="block">
                  <div class="flex items-center gap-3">
                    <UIcon name="i-lucide-users" class="size-8 text-primary" />
                    <div>
                      <p class="font-semibold">
                        Clientes
                      </p>
                      <p class="text-sm text-muted">
                        Gerir clientes
                      </p>
                    </div>
                  </div>
                </NuxtLink>
              </UCard>

              <UCard>
                <NuxtLink to="/users/accounts" class="block">
                  <div class="flex items-center gap-3">
                    <UIcon name="i-lucide-user-cog" class="size-8 text-primary" />
                    <div>
                      <p class="font-semibold">
                        Utilizadores
                      </p>
                      <p class="text-sm text-muted">
                        Gerir utilizadores
                      </p>
                    </div>
                  </div>
                </NuxtLink>
              </UCard>
            </div>
          </div>
        </UCard>
      </div>
    </template>
  </UDashboardPanel>
</template>
