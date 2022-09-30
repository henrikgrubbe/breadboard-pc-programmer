<template>

  <div class="container">
    <div class="row my-5">
      <h1 class="display-4">Breadboard PC</h1>
    </div>

    <div class="row mb-5">
      <div class="col-12 col-lg-6 mb-3 overflow-hidden">
        <label class="form-label">Write your program</label>
        <prism-editor class="editor"
                      v-model="programString"
                      :highlight="highlighter"
                      :line-numbers="true">
        </prism-editor>
      </div>

      <div class="col-12 col-lg-4 mb-3 overflow-hidden">
        <label for="program-txt" class="form-label">Compiled program</label>
        <div v-if="error">
          <prism-editor class="editor"
                        v-model="error"
                        :highlight="(str) => `<span class='text-danger'>${str}</span>`"
                        :readonly="true">
          </prism-editor>
        </div>
        <div v-else>
          <prism-editor class="editor"
                        v-model="compiledProgram"
                        :highlight="(str) => str"
                        :readonly="true">
          </prism-editor>
        </div>
      </div>

      <div class="col-12">
        <button @click="uploadProgram" :disabled="error !== ''" type="button" class="btn btn-success btn-lg me-1">
          Upload
        </button>
        <button @click="writeProgram" type="button" class="btn btn-warning btn-lg">Command program</button>
      </div>
    </div>

    <!--    <div class="row">-->
    <!--      <div class="col-lg-10 col-xl-8 mb-3">-->
    <!--        <label for="program-txt" class="form-label">Write a single RAM address</label>-->
    <!--        <div class="input-group mb-3">-->
    <!--          <input v-model="data" type="number" min="0" max="255" class="form-control" placeholder="Value"-->
    <!--                 aria-label="Value">-->
    <!--          <span class="input-group-text">@</span>-->
    <!--          <input v-model="address" type="number" min="0" max="15" class="form-control" placeholder="Address"-->
    <!--                 aria-label="Address">-->
    <!--        </div>-->
    <!--      </div>-->

    <!--      <div class="col-12">-->
    <!--        <button @click="writeImmediate" :disabled="data === '' || address === ''" type="button"-->
    <!--                class="btn btn-success btn-lg me-1">Write-->
    <!--        </button>-->
    <!--      </div>-->
    <!--    </div>-->
  </div>
</template>

<script lang="ts">
import '@/assets/style.scss'
import {defineComponent} from 'vue';
import * as peggy from 'peggy';
import {PrismEditor} from 'vue-prism-editor';
import 'vue-prism-editor/dist/prismeditor.min.css';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const grammar = require('@/assets/grammar.peggy?raw');


export default defineComponent({
  name: 'Breadboard PC programmer',
  components: {
    PrismEditor
  },
  data() {
    return {
      parser: peggy.generate(grammar),
      placeholderProgram: 'data:\t10\n\t\tldi 4\nx:\t\tadd data\n\t\tout\n\t\tjmp x\n' as string,
      programString: '' as string,
      compiledProgram: '' as string,
      error: ' ' as string,
      address: '' as string,
      data: '' as string,
    };
  },
  watch: {
    programString: function (code: string) {
      if (code.split('\n').length > 16) {
        this.error = 'Program too long';
        return;
      }

      let parsed;
      try {
        parsed = this.parser.parse(code);
      } catch (e: unknown) {
        this.error = (e as { message: string }).message as string;
        return;
      }
      this.error = '';
      this.compiledProgram = parsed.join('\n').trim();
    },
  },
  methods: {
    highlighter(code: string) {
      const rules = [
        {
          name: 'keyword',
          pattern: /(nop|lda|add|sub|sta|ldi|jmp|jc|jz|out|hlt)/g,
          style: 'color: #e06c75',
        },
        {
          name: 'integer',
          pattern: /(\d+)/g,
          style: 'color: #56b6c2',
        },
      ];

      let tokenized = code;
      rules.forEach((rule) => {
        tokenized = tokenized.replace(rule.pattern, `<${rule.name}>$1</${rule.name}>`);
      });

      let result = tokenized;
      rules.forEach((rule) => {
        const regex = RegExp(`<${rule.name}>(.*?)</${rule.name}>`, 'gm');
        result = result.replace(regex, `<span class="${rule.name}" style="${rule.style}">$1</span>`);
      });

      return result;
    },
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
.editor {
  background: #2d2d2d;
  color: #ccc;

  font-family: Fira code, Fira Mono, Consolas, Menlo, Courier, monospace;
  font-size: 14px;
  line-height: 1.5;
  padding: 5px;
}

.prism-editor__textarea:focus {
  outline: none;
}

pre {
  font-size: 1rem;
}
</style>
