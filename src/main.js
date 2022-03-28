import Vue from 'vue'
import QRona from './App.vue'

Vue.config.productionTip = false

new Vue({
  render: h => h(QRona),
}).$mount('#app')
