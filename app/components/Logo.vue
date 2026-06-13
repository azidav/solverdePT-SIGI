<script setup lang="ts">
const props = defineProps<{
  collapsed?: boolean
}>()

const colorMode = useColorMode()
const logoSrc = computed(() =>
  props.collapsed ? '/solverde-logo-small.svg'
    : colorMode.value === 'dark' ? '/solverde-logo.svg'
    : '/solverde-logo-black.svg'
)
</script>
<template>
  <NuxtLink to="/" :class="['flex items-center py-2', collapsed ? '' : 'px-3']">
    <img
      :src="logoSrc"
      alt="SolverdePT"
      :class="collapsed ? 'h-8 w-8 object-contain' : 'h-8 w-auto'"
      :style="collapsed ? '' : 'max-width: 190px; width: 100%'"
    />
  </NuxtLink>
</template>

