<template>

  <div class="container">
    <div class="row my-5">
      <h1 class="display-4">QR codes</h1>
    </div>

    <div class="row mb-3 justify-content-center">
      <div class="col-lg-10 col-xl-8">
        <div class="input-group">
          <input v-model.trim="inputString" @keyup.enter="download(inputString)" class="form-control form-control-lg"
                 type="text" maxlength="100" autofocus placeholder="Type some content" aria-label="QR content"
                 aria-describedby="input-length-helper">
          <button @click="clear()" :disabled="!inputString" class="btn btn-secondary" type="button">
            Clear
          </button>
        </div>
        <div id="input-length-helper" class="form-text"
             :class="{'text-warning': inputString.length >= 75, 'text-danger': inputString.length >= 90}">
          {{ inputString.length }} / 100
        </div>
      </div>
    </div>

    <div class="row justify-content-center mb-3">
      <div v-if="inputString" class="col-6 col-sm-4 col-lg-3 col-xl-2">
        <div class="mb-3" v-html="qrSvg"></div>
        <div class="d-grid">
          <button @click="download(inputString)" class="btn btn-primary btn-lg" type="button">Download</button>
        </div>
      </div>
    </div>

    <div class="row justify-content-center">
      <div class="col-lg-10 col-xl-8">
        <ProductList></ProductList>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import '@/assets/style.scss'
import {defineComponent} from 'vue';
import QRCode from 'qrcode'
import ProductList from '@/components/ProductList.vue';

export default defineComponent({
  name: 'App',
  components: {ProductList},
  data() {
    return {
      inputString: '' as string,
      qrSvg: '' as string,
    }
  },
  watch: {
    async inputString(newString) {
      if (newString.length <= 0) {
        return;
      }

      this.qrSvg = await this.qr(newString);
    }
  },
  methods: {
    clear(): void {
      this.inputString = '';
    },
    qr(inputString: string, width?: number): Promise<string> {
      return QRCode.toString(inputString, {
        type: 'svg',
        errorCorrectionLevel: 'H',
        margin: 0,
        color: {
          dark: '#000000FF',
          light: '#FFFFFF00'
        },
        width
      });
    },
    async download(inputString: string): Promise<void> {
      if (!inputString) {
        return;
      }

      const fileName = this.generateFileName(inputString);
      const objectUrl = this.generateObjectURL(await this.qr(inputString, 45.354));

      // Create and activate link element
      const el = document.createElement('a');
      el.download = fileName;
      el.href = objectUrl;
      el.click();

      // Clean up
      el.remove();
      window.URL.revokeObjectURL(objectUrl);
    },
    generateFileName(inputString: string): string {
      const split = inputString.split('/');

      return split[split.length - 1] + '-qr.svg';
    },
    generateObjectURL(data: string): string {
      return window.URL.createObjectURL(new Blob([data]));
    }
  }
});
</script>

<style lang="scss">
</style>
