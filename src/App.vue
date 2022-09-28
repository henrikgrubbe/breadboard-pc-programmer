<template>

  <div class="container">
    <div class="row my-5">
      <h1 class="display-4">Breadboard PC</h1>
    </div>

    <div class="row mb-5">
      <div class="col-lg-10 col-xl-8 mb-3">
        <label for="program-txt" class="form-label">Write your program</label>
        <textarea v-model="programString" class="form-control" id="program-txt" rows="16" ></textarea>
      </div>

      <div class="col-12">
        <button @click="uploadProgram" type="button" class="btn btn-success btn-lg me-1">Upload</button>
        <button @click="writeProgram" type="button" class="btn btn-warning btn-lg">Command program</button>
      </div>
    </div>

    <div class="row">
      <div class="col-lg-10 col-xl-8 mb-3">
        <label for="program-txt" class="form-label">Write a single RAM address</label>
        <div class="input-group mb-3">
          <input v-model="data" type="number" class="form-control" placeholder="Value" aria-label="Value">
          <span class="input-group-text">@</span>
          <input v-model="address" type="number" min="0" max="15" class="form-control" placeholder="Address" aria-label="Address">
        </div>
      </div>

      <div class="col-12">
        <button @click="writeImmediate" type="button" class="btn btn-success btn-lg me-1">Write</button>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import '@/assets/style.scss'
import {defineComponent} from 'vue';

export default defineComponent({
  name: 'Breadboard PC programmer',
  components: {},
  data() {
    return {
      programString: '' as string,
      address: '' as string,
      data: '' as string
    }
  },
  methods: {
    clear(): void {
      this.programString = '';
    },
    uploadProgram(): void {
      console.log(this.programString);
      const body: Record<string, string> = {};
      this.programString
          .split('\n')
          .forEach((line, lineNumber) => {
            body[lineNumber] = line;
          });

      const requestOptions = {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(body)
      };

      fetch('https://mqtt.it.fantastiskefroe.dk/publish/program', requestOptions)
          .then((response) => response.json())
          .then((data) => console.log(data))
          .catch(error => console.error('There was an error!', error));
    },
    writeProgram(): void {
      const requestOptions = {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({command: "PROGRAM"})
      };

      fetch('https://mqtt.it.fantastiskefroe.dk/publish/command', requestOptions)
          .then((response) => response.json())
          .then((data) => console.log(data))
          .catch(error => console.error('There was an error!', error));
    },
    writeImmediate(): void {
      const requestOptions = {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({command: "WRITE", address: this.address, data: this.data})
      };

      fetch('https://mqtt.it.fantastiskefroe.dk/publish/command', requestOptions)
          .then((response) => response.json())
          .then((data) => console.log(data))
          .catch(error => console.error('There was an error!', error));
    }
  }
});
</script>

<style lang="scss">
</style>
