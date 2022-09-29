{{
  function parseToBinary(digits, radix, length) {
    return toBinary(parseInt(digits.join(""), radix), length);
  }

  function toBinary(number, length) {
    return number.toString(2).padStart(length, '0');
  }

  function calculateAddress(location) {
    return toBinary(location.start.line - 1, 4);
  }
}}

{
  const labelMap = {};
  function addLabel(lbl, location) {
  	labelMap[lbl] = toBinary(location.start.line - 1, 4);
  }
  function getLabel(lbl) {
	return labelMap[lbl];
  }
}

program
  = line *

line
  = (lbl:label":"  _ ("\n"+)* _ { addLabel(lbl, location()) })?
    _ ("\n"+)? c:command _ ("\n"+)? { return calculateAddress(location()) + ":" + c }

command
  = instruction
  / byte

instruction
  = "nop"               { return "00000000" }
  / "lda" _ a:address   { return "0001" + a }
  / "add" _ a:address   { return "0010" + a }
  / "sub" _ a:address   { return "0011" + a }
  / "sta" _ a:address   { return "0100" + a }
  / "ldi" _ i:immediate { return "0101" + i }
  / "jmp" _ a:address   { return "0110" + a }
  / "jc"  _ a:address   { return "0111" + a }
  / "jz"  _ a:address   { return "1000" + a }
  / "out"               { return "11100000" }
  / "hlt"               { return "11110000" }

address
  = immediate
  / lbl:label { return getLabel(lbl); }

immediate "4 bit word"
  = "0x" digits:[0-9A-Fa-f]+ & { return parseToBinary(digits, 16, 4).length <= 4 }
    { return parseToBinary(digits, 16, 4) }
  / "0b" digits:[0-1]+ & { return parseToBinary(digits, 2, 4).length <= 4 }
    { return parseToBinary(digits, 2, 4) }
  / digits:[0-9]+ & { return parseToBinary(digits, 10).length <= 4 }
      { return parseToBinary(digits, 10, 4) }

label "label"
  = text:[a-zA-Z]+[a-zA-Z0-9]* { return text.join("") }

byte "8 bit word"
  = "0x" digits:[0-9A-Fa-f]+ & { return parseToBinary(digits, 16, 8).length <= 8 }
    { return parseToBinary(digits, 16, 8) }
  / "0b" digits:[0-1]+ & { return parseToBinary(digits, 2, 8).length <= 8 }
    { return parseToBinary(digits, 2, 8) }
  / digits:[0-9]+ & { return parseToBinary(digits, 10).length <= 8 }
      { return parseToBinary(digits, 10, 8) }

_ "whitespace"
  = [ \t\r]*