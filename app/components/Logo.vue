<script setup lang="ts">
defineProps<{
  collapsed?: boolean
}>()
</script>

<template>
  <NuxtLink to="/" :class="['flex items-center py-2', collapsed ? '' : 'px-3']">
    <img
      v-if="collapsed"
      src="/solverde-logo-small.svg"
      alt="SolverdePT"
      class="h-8 w-8 object-contain"
    >
    <template v-else>
      <!-- Troca por CSS: correta no primeiro paint mesmo com preferência 'system' (o SSR resolve sempre 'light') -->
      <img
        src="/solverde-logo-black.svg"
        alt="SolverdePT"
        class="h-8 w-auto dark:hidden"
        style="max-width: 190px; width: 100%"
      >
      <img
        src="/solverde-logo.svg"
        alt="SolverdePT"
        class="h-8 w-auto hidden dark:block"
        style="max-width: 190px; width: 100%"
      >
    </template>
  </NuxtLink>
</template>
