<template>
  <ul>
    <li v-for="(action, index) in beeper" :key="index">
     <a @click="doBeep(action)">{{ action }}</a></li>
    </ul>
</template>

<script>
import {beep} from "@/components/beep/beep.js";

export default {
  name: "TestBeep",
  data() {
    return {
      beeper: [
        'error', 'success', 'warning', 'checkin_success', 'scan_to_add_success', 'set_complete'
      ]
    }
  },
  methods: {
    doBeep(action) {
      console.log("beep", action);
      beep(action);
    }
  }
};
</script>
