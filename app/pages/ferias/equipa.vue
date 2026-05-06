<script setup lang="ts">
definePageMeta({ title: 'Calendário da Equipa' })

const { canApproveVacation } = useRbac()
</script>

<template>
  <UDashboardPanel>
    <template #header>
      <UDashboardNavbar title="Calendário da Equipa">
        <template #leading>
          <UButton icon="i-lucide-arrow-left" variant="ghost" to="/ferias" />
        </template>
      </UDashboardNavbar>
    </template>

    <div class="p-4">
      <div v-if="!canApproveVacation" class="text-center py-8 text-muted">
        Sem permissão para ver o calendário da equipa.
      </div>
      <VacationTeamCalendar v-else />
    </div>
  </UDashboardPanel>
</template>
