<template>
  <div id="app">
    <div id="camera">
      <qrcode-stream @decode="onDecode"></qrcode-stream>
    </div>
    <div id="result" :class="status">raw: {{result}}</div>
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
      showScanConfirmation: false,
      status: 'waiting',
    }
  },
  methods: {
      async onDecode(content) {
        fetch("http://localhost:5000/api/foo", {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ qr: content })
        })
        .then(response => response.json())
        .then(json => {
          this.result = json;
          this.status = json.status;
          if (json.status == 'valid') {
            beep("set_complete");
          }
          else {
            beep("error");
          }
        })
        .catch(err => console.log('Request Failed', err)); // Catch errors
      },
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
  display: flex;
  flex-wrap: wrap;
}

div#camera {
  width: 400px;
  height: 400px;
  margin:0px;
  padding: 0px;
  border: 2px #ddd solid;
  flex-basis: 400px;
}

div#result {
  border: 10px solid;
  padding: 1em;
  flex: 50% 1;
}

.waiting {
  border-color: #222 !important;
}

.valid {
  border-color: #33dd33 !important;
}

.invalid {
  border-color: #dd3333 !important;
}


</style>
