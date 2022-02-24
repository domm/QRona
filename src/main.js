import Vue from 'vue'
import App from './App.vue'
import TestBeep from '@/components/TestBeep.vue'

Vue.component(TestBeep.name,TestBeep);

Vue.config.productionTip = false

new Vue({
  render: h => h(App),
}).$mount('#app')
