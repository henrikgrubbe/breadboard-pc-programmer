{{ 
  function toBinary(number, length) {
    return number.toString(2).padStart(length, "0");
  }

  function wrapInTag(tag, value) {
  	return `<${tag}>${value}</${tag}>`
  }

  function _checkBinaryLength(value, radix, length) {
    return toBinary(parseInt(value, radix), length).length === length;
  }

  function _parseBinary(prefix, digits, radix, length) {
 	const str = digits.join("")
    const raw = prefix + str;
    const parsed = parseInt(str, radix); 

    return {
      parsed,
      raw,
      f: () => toBinary(parsed, length), 
      h: () => wrapInTag("token-immediate", raw) 
    };
  }
}}

{
  const labelMap = {};
  const instructions = [];

  function addInstruction(instr) {
  	instructions.push(instr);
  }

  function addLabel(lbl) {
  	labelMap[lbl] = {
      label: lbl, 
      location: instructions.length
    };
  }

  function getLabel(lbl) {
    if (labelMap[lbl] === undefined) {
      error(`Use of undefined label: "${lbl}"`);
    }

    return labelMap[lbl];
  }

  function parseNibble(prefix, digits, radix) {
    return _parseInteger(prefix, digits, radix, 4);
  }

  function parseByte(prefix, digits, radix) {
    return _parseInteger(prefix, digits, radix, 8);
  }

  function _parseInteger(prefix, digits, radix, length) {
    const result = _parseBinary(prefix, digits, radix, length);

    if (result.f().length > length) {
      error(`Value ${result.raw} (0b${result.f()}) too large for memory!`);
    }

    return result;
  }

  function compile(lines) {
    if (options.compile) {
      console.info("labels", labelMap);
      console.info("instructions", instructions);

      return instructions
        .map((instr, index) => `${toBinary(index, 4)}:${instr.f()}`)
        .join("\n");
    }

    if (options.highlight) {
      return lines.join("");
    }

    error("Option 'compile' or 'highlight' must be passed to parse function");
  }
}

program
  = lines:line* { return compile(lines) } 

line
  = lbls:(lbl:label":" ws:__ { addLabel(lbl.f()); return wrapInTag("token-label-definition", lbl.h()+":") + ws } )* ws1:__ cmd:command ws2:__ 
    { return `${lbls.join("")}${ws1}${cmd}${ws2}` }

command
  = i:instruction 
    { return wrapInTag("token-instr", i) }
  / b:byte 
    { addInstruction({f: () => b.f()}); return wrapInTag("token-instr-pseudo", b.h()) }

instruction
  = mne:"lda" ws:_ a:address   { addInstruction({f: () => "0001" + a.f()}); return `${wrapInTag("token-mnemonic", mne)}${ws}${a.h()}` }
  / mne:"add" ws:_ a:address   { addInstruction({f: () => "0010" + a.f()}); return wrapInTag("token-mnemonic", mne)+ws+a.h() }
  / mne:"sub" ws:_ a:address   { addInstruction({f: () => "0011" + a.f()}); return wrapInTag("token-mnemonic", mne)+ws+a.h() }
  / mne:"sta" ws:_ a:address   { addInstruction({f: () => "0100" + a.f()}); return wrapInTag("token-mnemonic", mne)+ws+a.h() }
  / mne:"ldi" ws:_ i:immediate { addInstruction({f: () => "0101" + i.f()}); return wrapInTag("token-mnemonic", mne)+ws+i.h() }
  / mne:"jmp" ws:_ a:address   { addInstruction({f: () => "0110" + a.f()}); return wrapInTag("token-mnemonic", mne)+ws+a.h() }
  / mne:"jc"  ws:_ a:address   { addInstruction({f: () => "0111" + a.f()}); return wrapInTag("token-mnemonic", mne)+ws+a.h() }
  / mne:"jz"  ws:_ a:address   { addInstruction({f: () => "1000" + a.f()}); return wrapInTag("token-mnemonic", mne)+ws+a.h() }
  / mne:"nop"                  { addInstruction({f: () => "00000000"}); return wrapInTag("token-mnemonic", mne) }
  / mne:"out"                  { addInstruction({f: () => "11100000"}); return wrapInTag("token-mnemonic", mne) }
  / mne:"hlt"                  { addInstruction({f: () => "11110000"}); return wrapInTag("token-mnemonic", mne) }

address
  = imm:immediate 
    { return {f: imm.f, h: () => wrapInTag("token-jump-target", imm.h()) } }
  / lbl:label 
    { return {f: () => toBinary(getLabel(lbl.f()).location, 4), h: () => wrapInTag("token-jump-target", lbl.h())} }

immediate "4 bit word"
  = prefix:"0x" digits:[0-9A-Fa-f]+
    { return parseNibble(prefix, digits, 16) }
  / prefix:"0b" digits:[0-1]+
    { return parseNibble(prefix, digits, 2) }
  / digits:[0-9]+
    { return parseNibble("", digits, 10) }

label "label"
  = text:[a-zA-Z]+[a-zA-Z0-9]* 
    { const lbl = text.join(""); return {f: () => lbl, h: () => wrapInTag("token-label", lbl)} }

byte "8 bit word"
  = prefix:"0x" digits:[0-9A-Fa-f]+
    { return parseByte(prefix, digits, 16) }
  / prefix:"0b" digits:[0-1]+
    { return parseByte(prefix, digits, 2) }
  / digits:[0-9]+
    { return parseByte("", digits, 10) }

_ "whitespace"
  = $ [ \t]*

__ "whitespace and newline"
  = $ [ \n\t\r]*
