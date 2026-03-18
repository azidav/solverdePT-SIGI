<script setup lang="ts">
defineProps<{
  collapsed?: boolean
}>()
</script>
<template>
  <UHeader :title="collapsed ? 'Sv' : 'solverdePT'" to="/" :style=" collapsed ? '--spacing: 0' : '--spacing: 0.25rem'" />
</template>

