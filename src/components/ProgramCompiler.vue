<template>
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
      <div class="mb-3">
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

      <div class="btn-group d-flex justify-content-end" role="group" aria-label="button group">
        <button @click="uploadProgram" :disabled="error !== ''" type="button" class="btn btn-lg btn-outline-primary">
          Upload
        </button>
        <button @click="writeProgram" type="button" class="btn btn-lg btn-outline-success">
          Write to RAM
        </button>
      </div>
    </div>


    <!--    <div class="col-12">-->
    <!--      <button @click="uploadProgram" :disabled="error !== ''" type="button" class="btn btn-success  me-1">-->
    <!--        Upload-->
    <!--      </button>-->
    <!--      <button @click="writeProgram" type="button" class="btn btn-warning ">-->
    <!--        Command program-->
    <!--      </button>-->
    <!--    </div>-->
  </div>
</template>

<script lang="ts">
import {defineComponent} from 'vue';
import {PrismEditor} from 'vue-prism-editor';
import * as peggy from 'peggy';
import {debounce} from '@/utils/debounce';
import {publishToTopic} from '@/utils/mqtt-upload';
import 'vue-prism-editor/dist/prismeditor.min.css';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const grammar = require('@/assets/grammar.peggy?raw');

export default defineComponent({
  name: 'ProgramCompiler',
  components: {
    PrismEditor
  },
  data() {
    return {
      parser: peggy.generate(grammar),
      programString: '' as string,
      compiledProgram: '' as string,
      error: ' ' as string,
      debouncedCompiler: debounce(this.compile, 500),
    };
  },
  watch: {
    programString: function (code: string) {
      this.debouncedCompiler(code);
    },
  },
  methods: {
    compile(code: string): void {
      let parsed;
      try {
        parsed = this.parser.parse(code);
      } catch (e: unknown) {
        this.error = (e as { message: string }).message as string;
        return;
      }
      this.error = '';
      this.compiledProgram = parsed.bin
    },
    highlighter(code: string) {
      try {
        return this.parser.parse(code).code;
      } catch (e: unknown) {
        return code;
      }
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

      publishToTopic('program', body);
    },
    writeProgram(): void {
      publishToTopic('command', {
        command: 'PROGRAM',
      });
    },
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

token-mnemonic {
  color: salmon;
}

token-immidiate {
  color: yellow;
}

token-label-definition {
  color: grey;
}

token-label-definition token-label {
  color: green;
}

token-instr token-label {
  color: limegreen;
}
</style>
