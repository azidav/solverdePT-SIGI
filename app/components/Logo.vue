<script setup lang="ts">
defineProps<{
  collapsed?: boolean
}>()
</script>
<template>
  <NuxtLink to="/" :class="['flex items-center py-2', collapsed ? '' : 'px-3']">
    <img
      :src="collapsed ? '/solverde-logo-small.svg' : '/solverde-logo.svg'"
      alt="SolverdePT"
      :class="collapsed ? 'h-8 w-8 object-contain' : 'h-8 w-auto'"
      :style="collapsed ? '' : 'max-width: 190px; width: 100%'"
    />
  </NuxtLink>
</template>

