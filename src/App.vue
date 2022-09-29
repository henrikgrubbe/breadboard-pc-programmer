<template>

  <div class="container">
    <div class="row my-5">
      <h1 class="display-4">Breadboard PC</h1>
    </div>

    <div class="row mb-5">
      <div class="col-6 mb-3">
        <label for="program-txt" class="form-label">Write your program</label>
        <textarea v-model="programString" class="form-control" id="program-txt" rows="16"></textarea>
      </div>

      <div class="col-4 mb-3">
        <label for="program-txt" class="form-label">Compiled program</label>
        <p v-if="error" class="text-secondary">
          {{ error }}
        </p>
        <pre v-else>{{ compiledProgram }}</pre>
      </div>

      <div class="col-12">
        <button @click="uploadProgram" :disabled="error !== ''" type="button" class="btn btn-success btn-lg me-1">
          Upload
        </button>
        <button @click="writeProgram" type="button" class="btn btn-warning btn-lg">Command program</button>
      </div>
    </div>

    <div class="row">
      <div class="col-lg-10 col-xl-8 mb-3">
        <label for="program-txt" class="form-label">Write a single RAM address</label>
        <div class="input-group mb-3">
          <input v-model="data" type="number" min="0" max="255" class="form-control" placeholder="Value"
                 aria-label="Value">
          <span class="input-group-text">@</span>
          <input v-model="address" type="number" min="0" max="15" class="form-control" placeholder="Address"
                 aria-label="Address">
        </div>
      </div>

      <div class="col-12">
        <button @click="writeImmediate" :disabled="data === '' || address === ''" type="button"
                class="btn btn-success btn-lg me-1">Write
        </button>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import '@/assets/style.scss'
import {defineComponent} from 'vue';
import * as peggy from 'peggy';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const grammar = require('@/assets/grammar.peggy?raw');

export default defineComponent({
  name: 'Breadboard PC programmer',
  components: {},
  data() {
    return {
      parser: peggy.generate(grammar),
      programString: '' as string,
      error: ' ' as string,
      compiledProgram: '' as string,
      address: '' as string,
      data: '' as string,
    };
  },
  watch: {
    programString: function (newVal: string) {
      let parsed;
      try {
        parsed = this.parser.parse(newVal);
      } catch (e) {
        this.error = e as string;
        return;
      }
      this.error = '';
      this.compiledProgram = parsed.join('\n').trim();
    },
  },
  methods: {
    uploadProgram(): void {
      if (this.error) {
        return;
      }

      const body: Record<string, number> = {};
      this.compiledProgram
          .split('\n')
          .forEach((line: string) => {
            const [address, instruction] = line.split(':');
            body[parseInt(address, 2).toString()] = parseInt(instruction, 2);
          });

      this.publishToTopic('program', body);
    },
    writeProgram(): void {
      const body = {
        command: 'PROGRAM',
      };

      this.publishToTopic('command', body);
    },
    writeImmediate(): void {
      if (this.address === '' || this.data === '') {
        return;
      }

      const body = {
        command: 'WRITE',
        address: this.address,
        data: this.data
      };

      this.publishToTopic('command', body);
    },
    publishToTopic(topic: string, data: object): Promise<void> {
      const requestOptions = {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(data)
      };

      return fetch(`https://mqtt.it.fantastiskefroe.dk/publish/${topic}`, requestOptions)
          .then((response) => response.json())
          .then((data) => console.log(data))
          .catch(error => console.error('There was an error!', error));
    }
  }
});
</script>

<style lang="scss">
pre {
  font-size: 1rem;
}
</style>
