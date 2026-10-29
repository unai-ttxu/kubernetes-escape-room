<script setup lang="ts">
import { computed } from 'vue'
import { useNav } from '@slidev/client'
const { currentPage, total } = useNav()
const progress = computed(() => `${(currentPage.value / total.value) * 100}%`)
</script>

<template>
  <div class="progress-track">
    <div class="progress-fill" :style="{ width: progress }" />
  </div>
  <div v-show="currentPage > 1" class="slide-number">{{ currentPage }}/{{ total }}</div>
</template>
