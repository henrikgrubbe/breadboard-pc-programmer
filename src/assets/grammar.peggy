{{
  function parseToBinary(digits, radix, length) {
    return toBinary(parseInt(digits.join(""), radix), length);
  }

  function toBinary(number, length) {
    return number.toString(2).padStart(length, '0');
  }

  function parseNibble(digits, radix) {
 	const str = digits.join("")
    const val = parseInt(str, radix); 
    return {type: "nibble", value: val, f: () => toBinary(val, 4), h: () => wrapInTag("token-immidiate", str) }
  }

  function parseByte(digits, radix) {
 	const str = digits.join("")
    const val = parseInt(str, radix); 
    return {type: "byte", value: val, f: () => toBinary(val, 8), h: () => wrapInTag("token-immidiate", str) }
  }

  function calculateAddress(location) {
    return toBinary(location.start.line - 1, 4);
  }
  function wrapInTag(tag, value) {
  	return `<${tag}>${value}</${tag}>`
  }
}}

{
  const labelMap = {};
  const instructions = [];
  function addInstruction(instr) {
  	instructions.push(instr)
  }
  function addLabel(lbl) {
  	labelMap[lbl] = {type: "label", label: lbl, location: instructions.length};
  }
  function getLabel(lbl) {
    return labelMap[lbl];
  }

  function compile() {
    console.log(labelMap, instructions)
    return instructions.map((instr,index) => toBinary(index,4)+":"+instr.f()).join("\n")
  }
}

program
  = l:line* { return {bin: compile(), code: l.join("") } } 

line
  = lbls:(lbl:label":" ws:__ { addLabel(lbl); return wrapInTag("token-label-definition", lbl+":")+ws })* ws1:__ cmd:command ws2:__ { return lbls.join("")+ws1+cmd+ws2}

command
  = i:instruction { return wrapInTag("token-instr", i) }
  / b:byte { addInstruction({key: ".byte", f: () => b.f()}); return wrapInTag("token-instr-pseudo",b.h()) }

instruction
  = "nop"                  { addInstruction({key: "nop", f: () => "00000000" }); return wrapInTag("token-mnemonic", "nop") }
  / "lda" ws:_ a:address   { addInstruction({key: "lda", f: () => "0001" + a.f() }); return wrapInTag("token-mnemonic", "lda")+ws+a.h() }
  / "add" ws:_ a:address   { addInstruction({key: "add", f: () => "0010" + a.f() }); return wrapInTag("token-mnemonic", "add")+ws+a.h() }
  / "sub" ws:_ a:address   { addInstruction({key: "sub", f: () => "0011" + a.f() }); return wrapInTag("token-mnemonic", "sub")+ws+a.h() }
  / "sta" ws:_ a:address   { addInstruction({key: "sta", f: () => "0100" + a.f() }); return wrapInTag("token-mnemonic", "sta")+ws+a.h() }
  / "ldi" ws:_ i:immediate { addInstruction({key: "ldi", f: () => "0101" + i.f() }); return wrapInTag("token-mnemonic", "ldi")+ws+i.h() }
  / "jmp" ws:_ a:address   { addInstruction({key: "jmp", f: () => "0110" + a.f() }); return wrapInTag("token-mnemonic", "jmp")+ws+a.h() }
  / "jc"  ws:_ a:address   { addInstruction({key: "jc",  f: () => "0111" + a.f() }); return wrapInTag("token-mnemonic", "jc")+ws+a.h() }
  / "jz"  ws:_ a:address   { addInstruction({key: "jz",  f: () => "1000" + a.f() }); return wrapInTag("token-mnemonic", "jz")+ws+a.h() }
  / "out"                  { addInstruction({key: "out", f: () => "11100000" }); return wrapInTag("token-mnemonic", "out") }
  / "hlt"                  { addInstruction({key: "hlt", f: () => "11110000" }); return wrapInTag("token-mnemonic", "hlt") }

address
  = imm:immediate { return {type: "imm_address", value: imm, f: imm.f, h: () => wrapInTag("token-jump-target",imm.h())}}
  / lbl:label { return {type: "lbl_address", label: lbl, f: () => {return toBinary(getLabel(lbl).location, 4)}, h: () => wrapInTag("token-jump-target", lbl)}}

immediate "4 bit word"
  = "0x" digits:[0-9A-Fa-f]+ & { return parseToBinary(digits, 16, 4).length <= 4 }
    { return parseNibble(digits, 16) }
  / "0b" digits:[0-1]+ & { return parseToBinary(digits, 2, 4).length <= 4 }
    { return parseNibble(digits, 2) }
  / digits:[0-9]+ & { return parseToBinary(digits, 10).length <= 4 }
    { return parseNibble(digits, 10) }

label "label"
  = text:[a-zA-Z]+[a-zA-Z0-9]* { return wrapInTag("token-label", text.join("")) }

byte "8 bit word"
  = "0x" digits:[0-9A-Fa-f]+ & { return parseToBinary(digits, 16, 8).length <= 8 }
    { return parseByte(digits, 16) }
  / "0b" digits:[0-1]+ & { return parseToBinary(digits, 2, 8).length <= 8 }
    { return parseByte(digits, 2) }
  / digits:[0-9]+ & { return parseToBinary(digits, 10).length <= 8 }
    { return parseByte(digits, 10) }

_ "whitespace"
  = ws:[ \t]* { return ws.join("") }

__ "whitespace and newline"
  = ws:[ \n\t\r]* { return ws.join("") }