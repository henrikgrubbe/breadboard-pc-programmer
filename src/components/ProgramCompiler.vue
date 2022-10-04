<template>
  <div class="row mb-5">
    <div class="col-12 col-lg-6 mb-3 overflow-hidden">
      <label class="form-label">Write your program</label>
      <prism-editor class="editor source"
                    v-model="source"
                    :highlight="sourceHighlighter"
                    :line-numbers="true">
      </prism-editor>
    </div>

    <div class="col-12 col-lg-4 mb-3 overflow-hidden">
      <div class="mb-3">
        <label for="program-txt" class="form-label">Compiled program</label>
        <div v-if="error">
          <prism-editor class="editor error"
                        v-model="error"
                        :highlight="(err) => err"
                        :readonly="true">
          </prism-editor>
        </div>
        <div v-else>
          <prism-editor class="editor compiled"
                        v-model="compiled"
                        :highlight="compiledHighlighter"
                        :readonly="true">
          </prism-editor>
        </div>
      </div>

      <div class="btn-group d-flex justify-content-end" role="group" aria-label="button group">
        <button @click="uploadProgram" :disabled="error !== ''" type="button" class="btn btn-lg btn-primary">
          Upload
        </button>
        <button @click="writeProgram" type="button" class="btn btn-lg btn-success">
          Write to RAM
        </button>
      </div>
    </div>
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
      source: '' as string,
      compiled: '' as string,
      error: ' ' as string,
      debouncedCompiler: debounce(this.compile, 500),
    };
  },
  mounted() {
    this.source = '      ldi 4\nx:j:  add data\n      out\n      jmp j\ndata: 0x42\n'
  },
  watch: {
    source: function (code: string) {
      this.debouncedCompiler(code);
    },
  },
  methods: {
    compile(code: string): void {
      let parsed;
      try {
        parsed = this.parser.parse(code, {compile: true});
      } catch (e: unknown) {
        console.log(e);
        this.error = (e as { message: string }).message as string;
        return;
      }
      this.error = '';
      this.compiled = parsed;
    },
    sourceHighlighter(code: string) {
      try {
        return this.parser.parse(code, {highlight: true});
      } catch (e: unknown) {
        return code;
      }
    },
    compiledHighlighter(code: string) {
      return code
          .split('\n')
          .map((line: string) => line.replace(/(\d{4}):(\d{4})(\d{4})/, '<compiled-addr>$1</compiled-addr>:<compiled-instr>$2</compiled-instr><compiled-optcode>$3</compiled-optcode>'))
          .join('\n');
    },
    uploadProgram(): void {
      if (this.error) {
        return;
      }

      const body: Record<string, number> = {};
      this.compiled
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
  background: #2B2B2B;
  color: #A9B7C6;
  padding: 5px;
}

.editor,
.prism-editor__line-number {
  font-family: Fira code, Fira Mono, Consolas, Menlo, Courier, monospace;
  font-size: 1rem;
  line-height: 1.5;
}

.prism-editor__textarea:focus {
  outline: none;
}


.prism-editor-wrapper.source {
  token-mnemonic {
    color: #CC7832;
  }

  token-immediate {
    color: #6897BB;
  }

  token-instr token-label {
    color: #9876AA;
  }

  token-label-definition {
    color: #808080;
  }

  token-label-definition token-label {
    color: #FFC66D;
  }
}

.prism-editor-wrapper.error {
  color: #BC3F3C;
}

.prism-editor-wrapper.compiled {
  compiled-addr {
    color: #A5C261;
  }

  compiled-instr {
    color: #6D9CBE;
  }

  compiled-optcode {
    color: #BC3F3C;
  }
}
</style>
