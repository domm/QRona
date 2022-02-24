<template>
  <div id="app">
    <h1></h1>
    <div id="camera">
      <qrcode-stream @decode="onDecode"></qrcode-stream>
    </div>
    <div id="raw">raw: {{result}}</div>
    <test-beep />
  </div>
</template>

<script>
import { QrcodeStream } from 'vue-qrcode-reader'
import {beep} from "@/components/beep/beep.js";

export default {
  name: 'App',
  components: {
    QrcodeStream,
  },
  data () {
    return {
      camera: 'auto',
      result: null,
      showScanConfirmation: false
    }
  },
  methods: {
      onDecode(content) {
        this.result = content;
        beep("set_complete");
      }
  }
}
</script>

<style>

body {
  color: #eee;
  background-color: #111;
}

#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #b5e853;
}

div#camera {
  width: 400px;
  height: 400px;
  margin:0px;
  padding: 0px;
  border: 2px #ddd solid;

}

</style>
