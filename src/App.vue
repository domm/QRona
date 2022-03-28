<template>
  <div id="app">
    <main>
      <div id="head">
        <h1>QRona</h1>
        Scan and validate your Corona QR Certificate
      </div>
      <div id="camera">
        <qrcode-stream :camera="camera" @decode="onDecode"></qrcode-stream>
      </div>
      <div id="result" :class="status">
        <div v-if="result">
          <h1>{{ result.reason }}</h1>
          <h3>{{ result.given_name }} {{result.family_name}}</h3>
          <p>{{ result.date_of_birth }}</p>
          <p v-if="result.more_reason">{{ result.more_reason }}</p>
          <button @click="reset">Scan another code!</button>
        </div>
        <h1 v-else>Please scan your Covid Certificate QR Code!</h1>
      </div>
    </main>
    <footer>
      QRona - a not very serious Corona Certificate Validator.<br />
      Made by <a href="https://domm.plix.at">domm</a> for <a href="http://act.yapc.eu/gpw2022/talk/7791">this talk at German Perl Workshop</a>.<br />
      Original validator code by Maroš.
    </footer>
  </div>
</template>

<script>
import { QrcodeStream } from 'vue-qrcode-reader';
import { beep } from "@/components/beep/beep.js";

export default {
  name: 'QRona',
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
      fetch("/api/qr", {
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
          beep(json.reason);
        }
        else {
          beep("error");
        }
        this.camera = 'off';
        setTimeout(this.reset, 10 * 1000);
      })
      .catch(err => alert('Request Failed: ' + err));
    },
    reset() {
      this.result = null;
      this.status = 'waiting';
      this.camera = 'auto';
    }
  }
}
</script>

<style>

html {
  height: 100%;}

body {
  color: #b5e853;
  background-color: #111;
  font-size: 1.2rem;
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  height: 100%;
}

div#app {
  height: 100%;
  display: flex;
  flex-direction: column;
  align-content: flex-start;
}

main {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  align-content: flex-start;
  flex: 1 0 auto;
}

div#head {
  flex: 100%;
  margin-bottom:1em;
}


div#camera {
  margin:0px;
  padding: 0px;
  border: 2px solid #333;
  flex: 400px 0 1;
  height: 400px;
}

div#result {
  border: 10px solid;
  padding: 10px;
  flex: 364px 0 1;
  height: 364px;
}

.waiting {
  border-color: #333 !important;
}

.valid {
  border-color: #33dd33 !important;
}

.invalid {
  border-color: #dd3333 !important;
  color: #dd3333;
}

button {
  border: 0;
  line-height: 2.5;
  padding: 0 20px;
  font-size: 1rem;
  text-align: center;
  background-color: #b5e853;
  color: #111;
  text-shadow: 1px 1px 1px #333;
  border-radius: 10px;
  box-shadow: inset 2px 2px 3px rgba(255, 255, 255, .6),
              inset -2px -2px 3px rgba(0, 0, 0, .6);
}

button:hover {
  background-color: #ffff80;
}

button:active {
  box-shadow: inset -2px -2px 3px rgba(255, 255, 255, .6),
              inset 2px 2px 3px rgba(0, 0, 0, .6);
}

h1 {
  margin-bottom: 0.2em;
}

footer {
  border-top: 1px solid;
  margin: 2em 10% 1em 10%;
  padding-top: 0.5em;
  color: #75a813;
  font-size:0.8em;
  flex-shrink: 0;
  text-align: right;
}

a {
  color: #ffff00;
}

</style>
