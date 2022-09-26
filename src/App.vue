<template>

  <div class="container">
    <div class="row my-5">
      <h1 class="display-4">Breadboard PC</h1>
    </div>

    <div class="row">
      <div class="col-lg-10 col-xl-8 mb-3">
        <label for="program-txt" class="form-label">Write your program</label>
        <textarea v-model="programString" class="form-control" id="program-txt" rows="3"></textarea>
      </div>

      <div class="col-12">
        <button @click="uploadProgram" type="button" class="btn btn-success btn-lg me-1">Upload</button>
        <button type="button" class="btn btn-warning btn-lg">Command program</button>
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
    }
  }
});
</script>

<style lang="scss">
</style>
