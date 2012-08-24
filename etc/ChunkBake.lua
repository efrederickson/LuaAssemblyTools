#!/usr/bin/env lua
--[[--------------------------------------------------------------------

  ChunkBake
  A Lua 5 binary chunk assembler.

  Copyright (c) 2005 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions under which this
  software may be distributed (basically a Lua 5-style license.)

  http://luaforge.net/projects/chunkbake/
  http://www.geocities.com/keinhong/chunkbake.html
  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- Notes:
-- * Modules aren't separate objects; they mess with each other
-- * Numbers are parsed and converted into the internal number data type.
--   The accuracy of the output file's number data type will be
--   restricted by this internal number type.
-- * Handling of numbers is limited to the precision/range available.
-- * Floating point conversion may not be accurate to the last digit
--   because of the way the conversion function is written. +/- infinity
--   supported, +/- NaN not supported. See yueliang project for tests.
-- * TODOs: please see the TODO files for a list of TODOs.
-- * For notes on assembler behaviour, please see the README file.
-----------------------------------------------------------------------
-- Modules: Number, Lex, Parse, Code
-- Outline: main() -> ChunkBakeDoFiles() -> Parse:Parse() -> Lex:Lex()
----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- Description and help texts
----------------------------------------------------------------------]]

title = [[
ChunkBake: A Lua 5 binary chunk assembler
Version 0.7.0 (20050512)  Copyright (c) 2005 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed (basically a Lua 5-style license.)
]]
-----------------------------------------------------------------------
USAGE = [[
usage: %s [options] [filenames]

options:
  -h, --help        prints usage information
  --quiet           do not display warnings
  -o <file>         specify file name to write output listing
  --                stop handling arguments

example:
  >%s myscript.asm -o myscript.out
]]
--TODO  --list            generate listing file
--TODO  --run             assemble and execute

-----------------------------------------------------------------------
-- Global constants, argument flags, etc.
-----------------------------------------------------------------------

config = {}
config.EXT_BIN = ".out"
config.EXT_LST = ".lst"

--[[--------------------------------------------------------------------
-- Other globals
----------------------------------------------------------------------]]

arg_other = {}          -- other arguments (for --run option)

-- arg[0] is not set if ChunkBake.lua is embedded
local usage, exec
if arg[0] then exec = "lua ChunkBake.lua" else exec = "ChunkBake" end
usage = string.format(USAGE, exec, exec)

--[[--------------------------------------------------------------------
-- Number handler for multiple data types
-- * the actual call is set as Number:Convert(n)
-- * calls Code:Error() out of sheer laziness, beware!
----------------------------------------------------------------------]]
Number = {}     -- number object

-----------------------------------------------------------------------
-- Selects a conversion function based on the given name or sample
-----------------------------------------------------------------------
function Number:SetNumberType(s)
  local matcher = {
    ["double"] = "double",
    ["single"] = "single",
    ["int"] = "int",
    ["long long"] = "long long",
    ["\182\9\147\104\231\245\125\65"] = "double",
    ["\59\175\239\75"] = "single",
    ["\118\94\223\1"] = "int",
    ["\118\94\223\1\0\0\0\0"] = "long long",
  }
  local test_number = {
    ["double"] = "\182\9\147\104\231\245\125\65",
    ["single"] = "\59\175\239\75",
    ["int"] = "\118\94\223\1",
    ["long long"] = "\118\94\223\1\0\0\0\0",
  }
  local match = matcher[s]
  if not match then
    Code:Error("unrecognized number type")
  end
  self.Convert = self[match]    -- initialize parameters
  self.test_number = test_number[match]
  self.lua_Number = string.len(self.test_number)
  return match
end

-----------------------------------------------------------------------
-- Support function for convert_to functions
-----------------------------------------------------------------------
function Number:grab_byte(v)
  return math.floor(v / 256), string.char(math.mod(math.floor(v), 256))
end

-----------------------------------------------------------------------
-- Converts a IEEE754 double number to an 8-byte little-endian string
-- * NOTE: see warning about accuracy in the header comments!
-----------------------------------------------------------------------
Number["double"] = function(self, x)
  local sign = 0
  if x < 0 then sign = 1; x = -x end
  local mantissa, exponent = math.frexp(x)
  if x == 0 then -- zero
    mantissa, exponent = 0, 0
  elseif x == 1/0 then
    mantissa, exponent = 0, 2047
  else
    mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 53)
    exponent = exponent + 1022
  end
  local v, byte = "" -- convert to bytes
  x = mantissa
  for i = 1,6 do
    x, byte = self:grab_byte(x); v = v..byte -- 47:0
  end
  x, byte = self:grab_byte(exponent * 16 + x); v = v..byte -- 55:48
  x, byte = self:grab_byte(sign * 128 + x); v = v..byte -- 63:56
  return v
end

-----------------------------------------------------------------------
-- Converts a IEEE754 single number to a 4-byte little-endian string
-- * TODO UNTESTED!!! *
-----------------------------------------------------------------------
Number["single"] = function(self, x)
  local sign = 0
  if x < 0 then sign = 1; x = -x end
  local mantissa, exponent = math.frexp(x)
  if x == 0 then -- zero
    mantissa = 0; exponent = 0
  elseif x == 1/0 then
    mantissa, exponent = 0, 255
  else
    mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 24)
    exponent = exponent + 126
  end
  local v, byte = "" -- convert to bytes
  x, byte = self:grab_byte(mantissa); v = v..byte -- 7:0
  x, byte = self:grab_byte(x); v = v..byte -- 15:8
  x, byte = self:grab_byte(exponent * 128 + x); v = v..byte -- 23:16
  x, byte = self:grab_byte(sign * 128 + x); v = v..byte -- 31:24
  return v
end

-----------------------------------------------------------------------
-- Converts a number to a little-endian integer string
-- * TODO UNTESTED!!! *
-----------------------------------------------------------------------
Number["int"] = function(self, x)
  local v = ""
  x = math.floor(x)
  if x >= 0 then
    for i = 1, self.lua_Number do
      v = v..string.char(math.mod(x, 256)); x = math.floor(x / 256)
    end
  else-- x < 0
    x = -x
    local carry = 1
    for i = 1, self.lua_Number do
      local c = 255 - math.mod(x, 256) + carry
      if c == 256 then c = 0; carry = 1 else carry = 0 end
      v = v..string.char(c); x = math.floor(x / 256)
    end
  end
  -- optional overflow test
  if x > 0 then Code:Warn("integer number conversion overflow") end
  return v
end

-----------------------------------------------------------------------
-- * WARNING this will fail for large long longs (64-bit numbers)
--   because long longs exceeds the precision of doubles.
-----------------------------------------------------------------------
Number["long long"] = Number["int"]

--[[--------------------------------------------------------------------
-- (ChunkBake) Lua assembly language lexer
-- * adapted from Lua 5.0.2 llex.*, see COPYRIGHT and COPYRIGHT_Lua5
----------------------------------------------------------------------]]
Lex = {}        -- lexer object
--OPCODE        -- this is set up by Lex:Init()

-----------------------------------------------------------------------
-- Initialize lexer
-- * sets up OPCODE as a global table
-----------------------------------------------------------------------
function Lex:Init(asmdata, asmfile)
  self.pos = 1
  self.line = 1
  self.asm = asmdata or ""
  self.asmlen = string.len(self.asm)
  self.asmfile = asmfile or "(no name)"
  if not self.EOF then self.EOF = -1 end
  self:nextc()
  ---------------------------------------------------------------
  -- build opcode name table
  ---------------------------------------------------------------
  local op =
    "MOVE LOADK LOADBOOL LOADNIL GETUPVAL \
    GETGLOBAL GETTABLE SETGLOBAL SETUPVAL SETTABLE \
    NEWTABLE SELF ADD SUB MUL \
    DIV POW UNM NOT CONCAT \
    JMP EQ LT LE TEST \
    CALL TAILCALL RETURN FORLOOP TFORLOOP \
    TFORPREP SETLIST SETLISTO CLOSE CLOSURE"
  if not self.OPCODE then
    self.OPCODE = {}
    local i = 0
    for v in string.gfind(op, "[^%s]+") do
      self.OPCODE[i] = v; self.OPCODE[v] = i; i = i + 1
    end
    self.OPCODE_COUNT = i
  end
  ---------------------------------------------------------------
  -- build keyword name table
  ---------------------------------------------------------------
  local kw = "nil false true and or"
  if not self.KEYWORD then
    self.KEYWORD = {}
    local i = 0
    for v in string.gfind(kw, "[^%s]+") do
      self.KEYWORD[i] = v; self.KEYWORD[v] = i; i = i + 1
    end
    self.KEYWORD_COUNT = i
  end
end

-----------------------------------------------------------------------
-- Format error message for display, throw an error
-----------------------------------------------------------------------
function Lex:Error(msg)
  error(string.format("%s:%d: Error: %s", self.asmfile, self.line, msg))
end

-----------------------------------------------------------------------
-- Get next character
-----------------------------------------------------------------------
function Lex:nextc()
  if self.pos > self.asmlen then
    self.c = self.EOF; self.ch = ""; self.dble = "" return
  end
  self.c = string.byte(self.asm, self.pos)      -- return a character
  self.pos = self.pos + 1
  -- universal handling for newlines, a newline is always one LF
  if self.c == 13 then
    if self.pos <= self.asmlen                  -- translate CRLF
       and string.byte(self.asm, self.pos) == 10 then
      self.pos = self.pos + 1
    end
    self.c = 10
  end
  self.ch = string.char(self.c)
  if self.pos <= self.asmlen then               -- easy dual-char
    self.c2 = string.byte(self.asm, self.pos)
    self.ch2 = string.char(self.c2)
    self.dble = string.char(self.c, self.c2)
  else
    self.dble = self.ch
  end
end

-----------------------------------------------------------------------
-- skip rest of a line (for single-line comments)
-----------------------------------------------------------------------
function Lex:SkipToEOL()
  while self.ch ~= "\n" and self.c ~= self.EOF do self:nextc() end
end

-----------------------------------------------------------------------
-- save character to buffer, get next character
-----------------------------------------------------------------------
function Lex:SaveNext()
  self.buff = self.buff..self.ch; self:nextc()
end

-----------------------------------------------------------------------
-- continue reading characters of one particular class
-----------------------------------------------------------------------
function Lex:ReadChars(pat)
  while string.find(self.ch, pat) do
    self.buff = self.buff..self.ch; self:nextc()
  end
end

-----------------------------------------------------------------------
-- read and convert a number
-----------------------------------------------------------------------
function Lex:ReadNumber()
  local isint = true
  self.buff = ""
  self:ReadChars("%d")                  -- integer part
  if self.dble == ".." then             -- prefer ..
    local num = tonumber(self.buff)
    return num, isint
  elseif self.ch == "." then            -- optional .
    isint = false; self:SaveNext()
  end
  self:ReadChars("%d")                  -- fraction part
  if string.upper(self.ch) == "E" then
    isint = false; self:SaveNext()
    if self.ch == "+" or self.ch == "-" then self:SaveNext() end
    self:ReadChars("%d")                -- exponent
  end
  local num = tonumber(self.buff)
  if not num then self:Error("could not lex number") end
  return num, isint
end

-----------------------------------------------------------------------
-- read and convert a hexadecimal number
-----------------------------------------------------------------------
function Lex:ReadHex()
  self.buff = ""
  self:nextc(); self:nextc()
  self:ReadChars("%x")                  -- read in hex digits
  local num = tonumber(self.buff, 16)
  if not num then self:Error("could not lex hex number") end
  return num, true
end

-----------------------------------------------------------------------
-- reads a single-quoted or double-quoted string
-----------------------------------------------------------------------
function Lex:ReadString(delimiter)
  self:nextc()
  self.buff = ""
  while self.ch ~= delimiter do
    -------------------------------------------------------------
    if self.c == self.EOF or self.ch == "\n" then
      self:Error("undelimited string")
    -------------------------------------------------------------
    elseif self.ch == "\\" and string.len(self.dble) == 2 then
      self:nextc()
      local i = string.find("\nabfnrtv", self.ch, 1, 1)
      if i then                                 -- standard escapes
        self.ch = string.sub("\n\a\b\f\n\r\t\v", i, i)
        if i == 1 then self.line = self.line + 1 end
        self:SaveNext()
      elseif string.find(self.ch, "%d") then    -- \xxx sequence
        local c, j = 0, 0
        repeat
          c = 10 * c + self.ch; self:nextc(); j = j + 1
        until (j >= 3 or not string.find(self.ch, "%d"))
        if c > 255 then
          self:Error("\\ddd escape overflow")
        end
        self.buff = self.buff..string.char(c)
      else                                      -- punctuation
        self:SaveNext()
      end
    -------------------------------------------------------------
    else                                      -- normal literal
      self:SaveNext()
    end--if self.ch
    -------------------------------------------------------------
  end--while
  self:nextc()
  return self.buff
end

-----------------------------------------------------------------------
-- reads a [[...]] style long string or comment
-----------------------------------------------------------------------
function Lex:ReadLongString(comment)
  local level = 0
  self.buff = ""
  self:nextc(); self:nextc()
  if self.ch == "\n" then     -- skip first newline
    self:nextc(); self.line = self.line + 1
  end
  while true do
    -------------------------------------------------------------
    if self.c == self.EOF then                  -- unexpected EOF
      if comment then
        self:Error("incomplete long comment")
      else
        self:Error("incomplete long string")
      end
    -------------------------------------------------------------
    elseif self.ch == "\n" then                 -- end-of-line
      self:SaveNext(); self.line = self.line + 1
    -------------------------------------------------------------
    elseif self.dble == "[[" then               -- inc nesting
      self:SaveNext(); self:SaveNext()
      level = level + 1
    -------------------------------------------------------------
    elseif self.dble == "]]" then               -- dec nesting
      self:nextc(); self:nextc()
      if level == 0 then break end              -- end of string
      self.buff = self.buff.."]]"
      level = level - 1
    -------------------------------------------------------------
    else                                        -- string content
      self:SaveNext()
    end--if self.ch
    -------------------------------------------------------------
  end--while
  return self.buff
end

-----------------------------------------------------------------------
-- Main lexer function
-----------------------------------------------------------------------
function Lex:Lex()
  ---------------------------------------------------------------
  -- main lexer loop
  ---------------------------------------------------------------
  while true do
    -------------------------------------------------------------
    if self.ch == "\n" then                     -- end-of-line
      self:nextc(); self.line = self.line + 1
      return "TK_EOL", "\n"
    -------------------------------------------------------------
    elseif self.ch == ";" then                  -- comment
      self:SkipToEOL()
    -------------------------------------------------------------
    elseif self.dble == "--" then               -- comment
      self:nextc(); self:nextc()
      if self.dble == "[[" then
        self:ReadLongString(true)
      else
        self:SkipToEOL()                        -- short comment
      end
    -------------------------------------------------------------
    elseif self.ch == "\"" or self.ch == "\'" then -- string
      return "TK_STRING", self:ReadString(self.ch)
    -------------------------------------------------------------
    elseif self.dble == "[[" then               -- long string
      return "TK_STRING", self:ReadLongString()
    -------------------------------------------------------------
    elseif self.ch == "\\" then
      self:nextc()
      if self.ch == "\n" then                   -- line continue
        self:nextc(); self.line = self.line + 1
      else
        return "TK_OP", "\\"
      end
    -------------------------------------------------------------
    elseif self.c == self.EOF then              -- end-of-file
      return "TK_EOF", self.c
    -------------------------------------------------------------
    elseif string.find(self.ch, "%s") then      -- whitespace
      self:nextc()
    -------------------------------------------------------------
    elseif string.find(self.ch, "%d") then      -- number
      if self.ch2 == "x" or self.ch2 == "X" then
        return "TK_NUM", self:ReadHex()
      end
      return "TK_NUM", self:ReadNumber()
    -------------------------------------------------------------
    elseif string.find(self.ch, "[%a_]") then   -- symbols, etc.
      self.buff = ""; self:ReadChars("[%w_]")
      if self.ch == ":" then                    -- label:
        self:nextc()
        return "TK_LABEL", self.buff
      elseif string.find(self.buff, "^[rR][%d]+$") then   -- Rnum
        local reg = tonumber(string.sub(self.buff, 2))
        return "TK_REG", reg
      elseif self.OPCODE[string.upper(self.buff)] then  -- mnemonic
        return "TK_MNE", string.upper(self.buff)
      elseif self.KEYWORD[self.buff] then       -- keyword
        return "TK_KEY", self.buff
      end
      return "TK_SYM", self.buff                -- symbol
    -------------------------------------------------------------
    elseif self.ch == "$" then
      if string.find(self.ch2, "%d") then       -- $num
        self:nextc()
        self.buff = ""; self:ReadChars("%d")
        local reg = tonumber(self.buff)
        return "TK_REG", reg
      else
        self:nextc()
        return "TK_OP", "$"
      end
    -------------------------------------------------------------
    elseif self.ch == "." then
      if self.dble == ".." then                 -- concat operator
        self:nextc(); self:nextc()
        if self.ch == "." then                  -- range operator
          self:nextc()
          return "TK_OP", "..."
        end
        return "TK_OP", ".."
      end
      if string.find(self.ch2, "%d") then       -- .number
        return "TK_NUM", self:ReadNumber()
      end
      self:nextc()
      if string.find(self.ch, "[%a_]") then    -- .directive
        self.buff = "."; self:ReadChars("[%w_]")
        return "TK_CMD", string.lower(self.buff)
      end
      return "TK_OP", "."
    -------------------------------------------------------------
    elseif string.find(self.ch, "%p") then      -- operators, etc.
      local punc = self.ch
      self:nextc()
      if string.find("~=<>", punc, 1, 1)        -- two-char operators
         and self.ch == "=" then
        self:nextc()
        punc = punc.."="
      end
      return "TK_OP", punc
    -------------------------------------------------------------
    else                                        -- catch the rest
      self:Error("unknown character or control character")
    end--if self.ch
    -------------------------------------------------------------
  end--while
end

--[[-------------------------------------------------------------------=
-- (ChunkBake) Lua assembly language parser
-- * not very clean integration with Lex and Code objects
-- * many variables and functions are freely shared between objects
----------------------------------------------------------------------]]
Parse = {}      -- parser object

-----------------------------------------------------------------------
-- get a token from the lexer
-----------------------------------------------------------------------
function Parse:GetToken()
  if self.looktt then
    self.tt, self.tok, self.isint =
      self.looktt, self.looktok, self.lookisint
    self.line = self.lookline
    self.looktt = nil
  else
    self.tt, self.tok, self.isint = Lex:Lex()
    self.line = Lex.line
  end
  -- Parse.line points to the correct line for error messages
  if self.tt == "TK_EOL" then self.line = self.line - 1 end
end

-----------------------------------------------------------------------
-- lookahead one token (used in OperandDisp)
-----------------------------------------------------------------------
function Parse:LookAhead()
  if self.looktt then
    self:Error("attempt to perform double-token lookahead")
  end
  self.looktt, self.looktok, self.lookisint = Lex:Lex()
  self.lookline = Lex.line
  return self.looktt, self.looktok, self.lookisint
end

-----------------------------------------------------------------------
-- Format error message for display, throw an error
-----------------------------------------------------------------------
function Parse:Error(msg)
  error(string.format("%s:%d: Error: %s", self.asmfile, self.line, msg))
end

-----------------------------------------------------------------------
-- Expects an end-of-line at the end of a directive or function
-----------------------------------------------------------------------
function Parse:EndOfLine()
  if self.tt == "TK_EOL" or self.tt == "TK_EOF" then
    self:GetToken(); return
  end
  self:Error("end of line expected, extra operands in statement")
end

-----------------------------------------------------------------------
-- Check if next token is EOL or EOF
-----------------------------------------------------------------------
function Parse:IsEOL()
  return self.tt == "TK_EOL" or self.tt == "TK_EOF"
end

-----------------------------------------------------------------------
-- Optionally consumes an equal sign
-----------------------------------------------------------------------
function Parse:OptionalEqual()
  if self.tt == "TK_OP" and self.tok == "=" then
    self:GetToken(); return true
  end
end

-----------------------------------------------------------------------
-- Optionally consumes a comma
-----------------------------------------------------------------------
function Parse:OptionalComma()
  if self.tt == "TK_OP" and self.tok == "," then
    self:GetToken(); return true
  end
end

-----------------------------------------------------------------------
-- Optionally consumes a "[", and compulsory "]" if it does
-----------------------------------------------------------------------
function Parse:OptionalBracketOpen()
  if self.tt == "TK_OP" and self.tok == "[" then
    self:GetToken(); return true
  end
end

function Parse:BracketClose()
  if self.tt == "TK_OP" and self.tok == "]" then
    self:GetToken(); return true
  end
  self:Error("closing square bracket expected")
end

-----------------------------------------------------------------------
-- Optionally consumes a comma or a range operator (...)
-----------------------------------------------------------------------
function Parse:OptionalCommaRange()
  if (self.tt == "TK_OP" and self.tok == ",")
     or (self.tt == "TK_OP" and self.tok  == "...") then
    self:GetToken(); return true
  end
end

------------------------------------------------------------------------
-- Expression parsing subsystem
-- * lookup tables: binop and binop_r are used by Parse:Subexpr, while
--   opclass is used by Parse:ExecBinop
-- * TODO intrinsic functions and pseudo-constants:
--      simpleexp -> ... | NAME {funcargs}
--      funcargs -> '(' explist1 ')'
--      explist1 -> expr { ',' expr }
-- * TODO can't use any forward-referenced symbols
------------------------------------------------------------------------

Parse.unop = { -- unary operator priority
  ["#"] = 11, ["~"] = 8, ["-"] = 8,
}

Parse.binop = { -- left-hand-side operator priority
  ["^"] = 10,
  ["*"] = 7, ["/"] = 7, ["+"] = 6, ["-"] = 6,
  [".."] = 5,
  ["~="] = 3, ["=="] = 3, ["<"] = 3,
  ["<="] = 3, [">"] = 3, [">="] = 3,
  ["and"] = 2, ["or"] = 1,
}

Parse.binop_r = { -- right-hand-side operator priority
  ["^"] = 9,
  ["*"] = 7, ["/"] = 7, ["+"] = 6, ["-"] = 6,
  [".."] = 4,
  ["~="] = 3, ["=="] = 3, ["<"] = 3,
  ["<="] = 3, [">"] = 3, [">="] = 3,
  ["and"] = 2, ["or"] = 1,
}

Parse.opclass = { -- lookup operator class (for type conversion)
  ---------------------------------------------------------------
  -- these fails with nils and booleans
  -- "arith" and "string" operands may be coerced
  -- "comp" operands need to be of the same type
  ["^"] = "arith", ["*"] = "arith",
  ["/"] = "arith", ["+"] = "arith",
  ["-"] = "arith", [".."] = "string",
  ["<"] = "comp", ["<="] = "comp",
  [">"] = "comp", [">="] = "comp",
  ---------------------------------------------------------------
  -- these can operate with all types
  ["~="] = "equal", ["=="] = "equal",
  ["and"] = "logic", ["or"] = "logic",
}

-----------------------------------------------------------------------
-- Returns true if current token is an unary operator
-----------------------------------------------------------------------
function Parse:IsUnop()
  if self.tt == "TK_OP"
     and (self.tok == "~" or self.tok == "-" or self.tok == "#") then
    return true
  end
  return false
end

-----------------------------------------------------------------------
-- Returns true if current token is a binary operator
-----------------------------------------------------------------------
function Parse:IsBinop()
  if self.tt == "TK_OP" or self.tt == "TK_KEY" then
    if self.binop[self.tok] then return true end
  end
  return false
end

-----------------------------------------------------------------------
-- Return true if one or both valuetype(s) (vt) is a number-equivalent
-----------------------------------------------------------------------
function Parse:IsNum(vt, vt2)
  -- IMPLIED that symboltype is in lower case
  local b = true
  if vt2 then
    if vt2 ~= "TK_NUM" and vt2 ~= string.lower(vt2) then b = false end
  end
  if vt == "TK_NUM" or vt == string.lower(vt) then return b end
  return false
end

-----------------------------------------------------------------------
-- Return nil if the two operands types are different symboltypes,
-- otherwise returns the merged numerical type information, operation
-- is valid only if both are TK_NUM or symboltypes
-- * nil used to flag a warning that potentially dangerous mixing is
--   being performed
-----------------------------------------------------------------------
function Parse:MergeNumType(vt, vt2)
  local st = vt == string.lower(vt)
  local st2 = vt2 == string.lower(vt2)
  if st and st2 then
    if vt == vt2 then return vt end     -- same symboltype
    return nil                          -- different symboltype
  end
  if st then return vt end      -- vt is symboltype
  return vt2                    -- vt2 is symboltype or both TK_NUM
end

-----------------------------------------------------------------------
-- Expression parsing: top level function; it starts here...
-- * returns 4 results: value, tokentype, isint, symboltype
-- * tokentype tracking is needed because there are two kinds of numbers
--   (TK_NUM for register numbers, TK_IMM for numeric constants)
-- * Expr tt result loses symboltype (converted to a generic TK_NUM);
--   symboltype is required to track what KIND of number (local, upvalue,
--   etc.) is being accumulated, so any mixing will flag a warning
-----------------------------------------------------------------------
function Parse:Expr(symbolcheck)
  local v, vt = self:Subexpr(-1)
  local st = ""
  if vt == "TK_KEY" then -- translate lexer-style TK_KEY values
    if v == true then
      v = "true"
    elseif v == false then
      v = "false"
    else
      v = "nil"
    end
  elseif self:IsNum(vt) then -- lose symboltype information
    if symbolcheck then
      if symbolcheck == "TK_NUM" then
        -- must not have symboltype information case
        if vt ~= "TK_NUM" then
          Code:Warn("potentially dangerous symbol mixing in expression")
        end
      elseif vt ~= "TK_NUM" then
        -- must have particular type of symboltype case
        if not string.find(symbolcheck, vt, 1, 1) then
          Code:Warn("potentially dangerous symbol mixing in expression")
        end
      end
    end
    st, vt = vt, "TK_NUM"
  elseif vt == "TK_CONST" then -- affirm return constant index
    vt = "TK_NUM"
  end
  local isint = false
  if type(v) == "number" then
    isint = v == math.floor(v)
  end
  return v, vt, isint, st
end

-----------------------------------------------------------------------
-- Expression parsing: parse subexpressions; the meat is here...
-- * subexpr -> (unop subexpr | simpleexp) {binop subexpr}
-- * for main while loop, a call up to the next level is made if:
--   (1) the next operator is right associative, or
--   (2) the next operator has a higher priority
-- * otherwise, the current result is returned so that the parent can
--   perform the higher-priority operation and accumulate the result
--   in a left-associative manner
-----------------------------------------------------------------------
function Parse:Subexpr(prev_op)
  local v, vt, op
  if self:IsUnop() then                 -- unop subexpr
    op = self.tok
    self:GetToken()
    v, vt = self:Subexpr(self.unop[op])
    v, vt = self:ExecUnop(v, vt, op)
  else
    v, vt = self:Simpleexp()            -- simpleexp
  end
  op = self.tok
  if self:IsBinop() then                -- {binop subexpr}
    while self.binop[op] and self.binop[op] > prev_op do
      self:GetToken()
      local v2, vt2, next_op = self:Subexpr(self.binop_r[op])
      v, vt = self:ExecBinop(v, vt, op, v2, vt2)
      op = next_op
    end
  end
  return v, vt, op
end

-----------------------------------------------------------------------
-- Expression parsing: simple expressions
-- * simpleexp -> 'nil' | 'true' | 'false' | TK_NUM | TK_STRING
--                | TK_REG | TK_IMM | '(' expr ')' | TK_SYM
-- * nil, true and false are all TK_KEY
-----------------------------------------------------------------------
function Parse:Simpleexp()
  local tt, tok = self.tt, self.tok
  self:GetToken()
  ---------------------------------------------------------------
  if tt == "TK_KEY" then
    if tok == "nil" then
      return nil, "TK_KEY"
    elseif tok == "true" then
      return true, "TK_KEY"
    elseif tok == "false" then
      return false, "TK_KEY"
    else
      self:Error("unknown keyword '"..tok.."' found in expression")
    end
  ---------------------------------------------------------------
  elseif tt == "TK_NUM" or tt == "TK_STRING"
         or tt == "TK_REG" or tt == "TK_IMM" then
    if tt == "TK_REG" then tt = "local" end
    return tok, tt
  ---------------------------------------------------------------
  elseif tt == "TK_OP" and tok == "(" then
    local v, vt = self:Expr()
    if self.tt ~= "TK_OP" or self.tok ~= ")" then
      self:Error("')' expected as delimiter in expression")
    end
    self:GetToken()
    return v, vt
  ---------------------------------------------------------------
  elseif tt == "TK_SYM" then
    if not Code:IsSymbol(tok) then
      self:Error("unknown symbol '"..tok.."' in expression")
    end
    return Code:GetSymbol(tok)
  ---------------------------------------------------------------
  end--if tt
  if tt == "TK_MNE" then
    self:Error("illegal mnemonic '"..tok.."' in expression")
  elseif tt == "TK_OP" then
    self:Error("illegal symbol '"..tok.."' in expression")
  elseif tt == "TK_EOL" or tt == "TK_EOF" then
    self:Error("premature end of line encountered in expression")
  else
    self:Error("illegal token type '"..tt.."' in expression")
  end
end

-----------------------------------------------------------------------
-- Expression parsing: perform unary operations
-- * the # merely promotes a number (which denotes a register location)
--   into an immediate number (which denotes a numerical constant)
-- * # operates on an immediately following constant symbol to get the
--   actual value of the constant, otherwise you only get the index
-----------------------------------------------------------------------
function Parse:ExecUnop(v, vt, op)
  ---------------------------------------------------------------
  if op == "~" then
    -- accepts all types
    v = not v
    vt = "TK_KEY"
  ---------------------------------------------------------------
  elseif op == "-" then
    -- illegal for nil|boolean, coerced: string -> immediate
    if vt == "TK_KEY" then
      self:Error("illegal operation with nil or boolean in expression")
    elseif vt == "TK_STRING" then
      local n = tonumber(v)
      if not n then
        self:Error("failed to coerce string into a number in expression")
      end
      v, vt = n, "TK_IMM"
    end
    v = -v
  ---------------------------------------------------------------
  else-- op == "#" then
    -- valid for numbers, immediates, constant references
    if vt == "const" then
      v = Code:GetConstIdx(v)
    elseif vt ~= "TK_IMM" and vt ~= "TK_STRING"
           and not self:IsNum(vt) then
      self:Error("'#' can only be applied to numbers or strings")
    end
    if vt ~= "TK_STRING" then
      vt = "TK_IMM"             -- unconditional promotion
    end
  ---------------------------------------------------------------
  end--if op
  return v, vt
end

-----------------------------------------------------------------------
-- Expression parsing: perform binary operations
-- * once you operate on a TK_CONST, you won't be able to promote it
--   in order to get the value of the constant
-----------------------------------------------------------------------
function Parse:ExecBinop(v, vt, op, v2, vt2)
  local oc = self.opclass[op]
  local vtm = self:MergeNumType(vt, vt2)
  -- different symboltypes shouldn't mix, (expr) disambiguates
  if self:IsNum(vt, vt2) and not vtm then
    Code:Warn("potentially dangerous symbol mixing in expression")
    vtm = "TK_NUM"
  end
  ---------------------------------------------------------------
  if oc ~= "logic" and oc ~= "equal" then
    -- illegal for nil|boolean
    if vt == "TK_KEY" or vt2 == "TK_KEY" then
      self:Error("illegal operation with nil or boolean in expression")
    end
    -------------------------------------------------------
    if oc == "arith" then
      -- coerced: string -> immediate
      if vt == "TK_STRING" then
        local n = tonumber(v)
        if not n then
          self:Error("failed to coerce string into a number in expression")
        end
        v, vt = n, "TK_IMM"
      elseif vt2 == "TK_STRING" then
        local n = tonumber(v2)
        if not n then
          self:Error("failed to coerce string into a number in expression")
        end
        v2, vt2 = n, "TK_IMM"
      end
      if op == "^" then
        v = v ^ v2
      elseif op == "*" then
        v = v * v2
      elseif op == "/" then
        v = v / v2
      elseif op == "+" then
        v = v + v2
      else-- op == "-" then
        v = v - v2
      end
      -- if any operand is immediate, result promoted to immediate
      if vt == "TK_IMM" or vt2 == "TK_IMM" then
        vt = "TK_IMM"
      else
        vt = vtm
      end
    -------------------------------------------------------
    elseif oc == "string" then
      -- assume coercion always works
      v = v .. v2
      vt = "TK_STRING"
    -------------------------------------------------------
    else-- oc == "comp" then
      -- operands must have same data type, result always boolean
      if vt ~= vt2 then
        self:Error("trying to compare different data types in expression")
      end
      if op == "<" then
        v = v < v2
      elseif op == "<=" then
        v = v <= v2
      elseif op == ">" then
        v = v > v2
      else-- op == ">=" then
        v = v >= v2
      end
      vt = "TK_KEY"
    -------------------------------------------------------
    end--if oc
  ---------------------------------------------------------------
  elseif oc == "equal" then
    -- accepts all types, always gives a boolean result
    if op == "~=" then
      v = v ~= v2
    else-- op == "==" then
      v = v == v2
    end
    vt = "TK_KEY"
  ---------------------------------------------------------------
  else-- oc == "logic" then
    -- accepts all types, values preserved
    if op == "and" then
      if v then v, vt = v2, vt2 end
    else-- op == "or" then
      if not v then v, vt = v2, vt2 end
    end
  ---------------------------------------------------------------
  end--if oc
  return v, vt
end

-----------------------------------------------------------------------
-- Parse and decodes an R(x) operand
-- * allows TK_REG (Rnum, $num), TK_NUM, TK_SYM (locals or labels)
-- * R(x) and RK(x) tracks register usage for maxstacksize
-----------------------------------------------------------------------
function Parse:OperandR()
  if self:IsEOL() then
    self:Error("R(x) operand expected")
  end
  local r, rt, isint = self:Expr("local")
  if rt == "TK_NUM" then
    if not isint then
      self:Error("integer R(x) register operand expected")
    end
  else
    self:Error("R(x) operand expected")
  end
  Code:CheckR(r)
  if r >= Code.func.maxstacksize then Code.func.maxstacksize = r + 1 end
  return r
end

-----------------------------------------------------------------------
-- Parse and decodes an RK(x) operand
-- * allows the three types of tokens allowed by Parse:OperandR(), and
--   TK_IMM (immediate numerical const), TK_STRING (string const)
-----------------------------------------------------------------------
function Parse:OperandRK()
  if self:IsEOL() then
    self:Error("RK(x) operand expected")
  end
  local r, rt, isint, st = self:Expr("local,const")
  if rt == "TK_NUM" and not isint then
    self:Error("integer RK(x) register operand expected")
  end
  if st == "const" then
    r = r + Code.config.MAXSTACK
  elseif rt == "TK_NUM" then
    if r >= Code.config.MAXSTACK then
      local actual = r - Code.config.MAXSTACK
      if not Code:IsConst(actual) then
        self:Error("constant number "..actual.." not yet defined")
      end
    end
  elseif rt == "TK_IMM" or rt == "TK_STRING" then
    -- literals are auto-added into constant table
    r = Code:GetConst(r) + Code.config.MAXSTACK
  elseif rt == "TK_KEY" then
    if r == "true" or r == "false" then
      self:Error("'"..r.."' cannot be used as an RK(x) operand")
    end
    -- TK_KEY, nil (auto-add)
    r = Code:GetConst(nil) + Code.config.MAXSTACK
  else
    self:Error("RK(x) operand expected")
  end
  Code:CheckRK(r)
  if r < Code.config.MAXSTACK and
     r >= Code.func.maxstacksize then Code.func.maxstacksize = r + 1 end
  return r
end

-----------------------------------------------------------------------
-- Parse and decodes a Kst(x) operand
-- * allows TK_SYM (labeled const), TK_NUM (constant number),
--   TK_IMM (immediate number), TK_STRING (immediate string)
-----------------------------------------------------------------------
function Parse:OperandKst()
  if self:IsEOL() then
    self:Error("Kst(x) operand expected")
  end
  local k, kt, isint = self:Expr("const")
  if kt == "TK_NUM" then
    if not isint then
      self:Error("integer Kst(x) constant operand expected")
    end
    if not Code:IsConst(k) then
      self:Error("constant number "..k.." not yet defined")
    end
  elseif kt == "TK_IMM" or kt == "TK_STRING" then
    -- literals are auto-added into constant table
    k = Code:GetConst(k)
  elseif kt == "TK_KEY" then
    if k == "true" or k == "false" then
      self:Error("'"..k.."' cannot be used as a Kst(x) operand")
    end
    -- TK_KEY, nil (auto-add)
    k = Code:GetConst(nil)
  else
    self:Error("Kst(x) operand expected")
  end--if kt
  Code:CheckKst(k)
  return k
end

-----------------------------------------------------------------------
-- Parse and decodes an upvalue operand
-----------------------------------------------------------------------
function Parse:OperandUpval()
  if self:IsEOL() then
    self:Error("missing operand(s)")
  end
  local v, vt, isint = self:Expr("upvalue")
  if vt == "TK_NUM" and isint then
    if not Code:IsUpvalue(v) then
      self:Error("undefined upvalue number "..v)
    end
    return v
  end
  self:Error("integer number or upvalue operand expected")
end

-----------------------------------------------------------------------
-- Parse and decodes an integer number, optionally checks range
-- * if range is a string, then allows immediates also, this is only for
--   the NEWTABLE instruction, for real array and hash sizes
-----------------------------------------------------------------------
function Parse:OperandNum(range)
  if self:IsEOL() then
    self:Error("integer operand expected")
  end
  local v, vt, isint = self:Expr("TK_NUM")
  if vt == "TK_NUM" or
     (type(range) == "string" and vt == "TK_IMM") then
    if not isint then self:Error("integer operand expected") end
  else
    self:Error("integer operand expected")
  end
  if v < 0 then
    self:Error("positive integer operand expected")
  end
  if type(range) == "number" and (v < 0 or v >= range) then
    self:Error("numeric operand out of range")
  end
  return v, vt
end

-----------------------------------------------------------------------
-- Parse and decodes a displacement or label
-- * can be TK_NUM (absolute), TK_IMM (relative), or TK_SYM
-- * if label is a forward reference, it is kept as a string and is
--   resolved at the end of a function's parsing (.end)
-- * only a single code label can be used as a forward-reference
--   (since all other expressions are evaluated immediately)
-- * disp=relative, dest=absolute
-----------------------------------------------------------------------
function Parse:OperandDisp()
  if self:IsEOL() then
    self:Error("displacement or label expected")
  end
  if self.tt == "TK_SYM" then
    -- lookahead to ensure that symbol is the only token left
    local ltt, ltok = Parse:LookAhead()
    if (ltt == "TK_EOL" or lt == "TK_EOF")
       and (not Code:IsSymbol(self.tok)) then
      local fwd = self.tok
      self:GetToken()
      Code:GetLabel(fwd)
      return fwd
    end
  end
  local disp, dt, isint = self:Expr("code")
  local dest
  if dt == "TK_NUM" then
    if not isint then
      self:Error("integer displacement absolute operand expected")
    end
  elseif dt == "TK_IMM" then
    if not isint then
      self:Error("integer displacement relative operand expected")
    end
  else
    self:Error("displacement or label expected")
  end
  if type(disp) == "number" then
    if dt ~= "TK_IMM" then
      -- at time of parsing, PC is positioned at the last instruction
      -- so there is a difference of 2 compared to the next instruction
      disp = disp - Code.func.sizecode - 2
    end
    dest = Code.func.sizecode + 2 + disp
  end
  Code:CheckDisp(disp)
  return disp, dest
end

-----------------------------------------------------------------------
-- Parse and decodes a function prototype number or label operand
-- * can be TK_NUM or TKSYM ("function" preferred)
-----------------------------------------------------------------------
function Parse:OperandProto()
  if self:IsEOL() then
    self:Error("missing operand(s)")
  end
  local p, pt, isint = self:Expr("function")
  if pt == "TK_NUM" then
    if p >= Code.func.sizep then
      self:Error("function number "..p.." not yet defined")
    end
  else
    self:Error("integer number or function label expression expected")
  end
  return p
end

-----------------------------------------------------------------------
-- Parse and decodes a boolean operand
-- * can be TK_NUM (0|1), TK_KEY (true|false)
-----------------------------------------------------------------------
function Parse:OperandBool()
  if self:IsEOL() then
    self:Error("missing operand(s)")
  end
  local v, vt, isint = self:Expr("TK_NUM")
  if vt == "TK_NUM" and isint and (v == 0 or v == 1) then
    return v
  elseif vt == "TK_KEY" and (v == "true" or v == "false") then
    if v == "true" then return 1 else return 0 end
  end
  self:Error("operand B must be 0, 1, true or false")
end

-----------------------------------------------------------------------
-- Parse and decodes a 0|1 operand
-- * can be TK_NUM (0|1) only
-----------------------------------------------------------------------
function Parse:Operand01(operand)
  if self:IsEOL() then
    self:Error("missing operand(s)")
  end
  local v, vt, isint = self:Expr("TK_NUM")
  if vt == "TK_NUM" and isint and (v == 0 or v == 1) then
    return v
  end
  self:Error("operand "..operand.." must be 0 or 1")
end

-----------------------------------------------------------------------
-- Parse a key-value parameter pair; SYNTAX: <key>=<string>|<number>
-----------------------------------------------------------------------
function Parse:Parameter()
  if self.tt ~= "TK_SYM" then
    self:Error("symbol expected for parameter key")
  end
  local pkey = self.tok
  self:GetToken()
  if self.tt ~= "TK_OP" or self.tok ~= "=" then
    self:Error("'=' expected in key-value parameter pair")
  end
  self:GetToken()
  local pval, pvalt = self:Expr()
  if pvalt ~= "TK_NUM" and pvalt ~= "TK_STRING" then
    self:Error("number or string expected as parameter value")
  end
  return pkey, pval
end

-----------------------------------------------------------------------
-- Parse a directive or command
-----------------------------------------------------------------------
function Parse:Directive(cmd)
  ---------------------------------------------------------------
  -- declares global header properties
  ---------------------------------------------------------------
  if cmd == ".header" then
    if Code:HasLabels() then
      self:Error(cmd.." doesn't accept label prefixes")
    end
    while not self:IsEOL() do
      local pkey, pval = self:Parameter()
      Code:HeaderOption(pkey, pval)
      self:OptionalComma()
    end
    self:EndOfLine()
  ---------------------------------------------------------------
  -- declares a function prototype
  ---------------------------------------------------------------
  elseif cmd == ".function" or cmd == ".func" then
    Code:InitHeader()
    Code:FunctionBegin()
    while not self:IsEOL() do
      local pkey, pval = self:Parameter()
      Code:FunctionOption(pkey, pval)
      self:OptionalComma()
    end
    self:EndOfLine()
    if Code:HasLabels() then
      if Code.func.prev then
        Code:SetLabel("function", Code.func.prev.sizep, 1)
      else
        self:Error("top-level function cannot have a label")
      end
    end
  ---------------------------------------------------------------
  -- ends a function
  ---------------------------------------------------------------
  elseif cmd == ".end" then
    if Code:HasLabels() then
      self:Error(cmd.." doesn't accept label prefixes")
    end
    -- TODO possible: ".end TK_SYM" function syntax
    --if self.tt == "TK_SYM" then <blah blah> end
    self:EndOfLine()
    Code:FunctionEnd()
  ---------------------------------------------------------------
  -- declares a parameter (more or less a local)
  ---------------------------------------------------------------
  elseif cmd == ".param" then
    if Code.state ~= 1 then
      self:Error(".param declaration illegal outside a function")
    end
    if self.tt == "TK_SYM" then
      local param, loc = self.tok
      self:GetToken()
      -- SYNTAX: .param <symbol> TK_EOL
      loc = Code:AddParam(param)
      self:EndOfLine()
      if Code:HasLabels() then Code:SetLabel("local", loc) end
    else
      self:Error("symbol expected in .param directive")
    end
  ---------------------------------------------------------------
  -- declares a local variable
  -- * TODO doesn't handle startpc/endpc yet
  ---------------------------------------------------------------
  elseif cmd == ".local" then
    if Code.state ~= 1 then
      self:Error(".local declaration illegal outside a function")
    end
    if self.tt == "TK_SYM" then
      local locname, loc = self.tok
      self:GetToken()
      local comma = self:OptionalComma()
      if self:IsEOL() then
        if comma then
          self:Error("number expected after comma in .local directive")
        end
        -- SYNTAX: .local <symbol> TK_EOL
        loc = Code:AddLocal(locname)
      else
        local v, vt, isint = self:Expr("local")
        if vt == "TK_NUM" and isint then
          -- SYNTAX: .local <symbol>[,] <number> TK_EOL
          loc = Code:AddLocal(locname, v)
        elseif comma then
          self:Error("number expected after comma in .local directive")
        else
          self:Error("number expected as second operand in .local directive")
        end
      end
      self:EndOfLine()
      if Code:HasLabels() then Code:SetLabel("local", loc) end
    else
      self:Error("symbol expected in .local directive")
    end
  ---------------------------------------------------------------
  -- declares an upvalue
  ---------------------------------------------------------------
  elseif cmd == ".upvalue" then
    if Code.state ~= 1 then
      self:Error(".upvalue declaration illegal outside a function")
    end
    if self.tt == "TK_SYM" then
      local upval, upv = self.tok
      self:GetToken()
      local comma = self:OptionalComma()
      if self:IsEOL() then
        if comma then
          self:Error("number expected after comma in .upvalue directive")
        end
        -- SYNTAX: .upvalue <symbol> TK_EOL
        upv = Code:AddUpvalue(upval)
      else
        local v, vt, isint = self:Expr("upvalue")
        if vt == "TK_NUM" and isint then
          -- SYNTAX: .upvalue <symbol>, <number> TK_EOL
          upv = Code:AddUpvalue(upval, v)
        elseif comma then
          self:Error("number expected after comma in .upvalue directive")
        else
          self:Error("number expected as second operand in .upvalue directive")
        end
      end
      self:EndOfLine()
      if Code:HasLabels() then Code:SetLabel("upvalue", upv) end
    else
      self:Error("symbol expected in .upvalue directive")
    end
  ---------------------------------------------------------------
  -- declares a constant, with optional label
  ---------------------------------------------------------------
  elseif cmd == ".const" then
    if Code.state ~= 1 then
      self:Error(".const declaration illegal outside a function")
    end
    -- SYNTAX: .const [<symbol>,] ...
    local const
    if self.tt == "TK_SYM" then
      const = self.tok
      self:GetToken()
    end
    self:OptionalComma()
    if self:IsEOL() then
      self:Error("number or string expected in .const directive")
    else
      local v, vt = self:Expr()
      if vt == "TK_NUM" or vt == "TK_IMM" or
         vt == "TK_STRING" or vt == "TK_KEY" then
        local val, cn = v
        -- handle nil constants
        if vt == "TK_KEY" then
          if val == "true" or val == "false" then
            self:Error(val.." cannot be used in .const directive")
          end
          val = nil
        end
        local comma = self:OptionalComma()
        if self:IsEOL() then
          if comma then
            self:Error("number expected after comma in .const directive")
          end
          -- SYNTAX: .const [<symbol>,] <num>|<imme>|<string> TK_EOL
          cn = Code:AddConst(const, val)
        else
          local v2, vt2, isint = self:Expr("const")
          if vt2 == "TK_NUM" and isint then
            -- SYNTAX: .const [<symbol>,] <num>|<imme>|<string>|nil, <number> TK_EOL
            cn = Code:AddConst(const, val, v2)
          elseif comma then
            self:Error("number expected after comma in .const directive")
          else
            self:Error("number operand expected in .const directive")
          end
        end
        self:EndOfLine()
        if Code:HasLabels() then Code:SetLabel("const", cn) end
      else
        self:Error("number or string expected in .const directive")
      end
    end
  ---------------------------------------------------------------
  -- declares an equate
  ---------------------------------------------------------------
  elseif cmd == ".equ" then
    if self.tt == "TK_SYM" then
      local equname = self.tok
      self:GetToken()
      local comma = self:OptionalComma()
      if self:IsEOL() then
        if comma then
          self:Error("expression expected after comma in .equ directive")
        else
          self:Error("expression expected in .equ directive")
        end
      else
        local v, vt, isint = self:Expr()
        -- SYNTAX: .equ <symbol>[,] <expression> TK_EOL
        Code:SetEqu(equname, v, vt)
      end
      self:EndOfLine()
      if Code:HasLabels() then Code:SetGlobLabel("equ", equname) end
    else
      self:Error("symbol expected in .equ directive")
    end
  ---------------------------------------------------------------
  else
    self:Error("unknown directive "..cmd.." encountered")
  end--if cmd
end

-----------------------------------------------------------------------
-- Parse an instruction
-----------------------------------------------------------------------
function Parse:Instruction(mne)
  local RA, RB, RC, RBx, dest
  if Code.state ~= 1 then
    self:Error("instruction cannot live outside a function")
  end
  ---------------------------------------------------------------
  -- MOVE R(A) [,] R(B)
  ---------------------------------------------------------------
  if mne == "MOVE" then
    RA = self:OperandR()
    self:OptionalComma()
    RB = self:OperandR()
    self:EndOfLine()
    if RA == RB then
      Code:Warn("MOVE to same register; does nothing")
    end
    Code:AddInst(Code:iABC(mne, RA, RB, 0))
  ---------------------------------------------------------------
  -- LOADK R(A) [,] Kst(Bx)
  ---------------------------------------------------------------
  elseif mne == "LOADK" then
    RA = self:OperandR()
    self:OptionalComma()
    RBx = self:OperandKst()
    self:EndOfLine()
    Code:AddInst(Code:iABx(mne, RA, RBx))
  ---------------------------------------------------------------
  -- LOADBOOL R(A) [,] B(0|1|true|false) [,] C(0|1)
  ---------------------------------------------------------------
  elseif mne == "LOADBOOL" then
    RA = self:OperandR()
    self:OptionalComma()
    RB = self:OperandBool()
    self:OptionalComma()
    RC = self:Operand01("C")
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, RB, RC))
    if RC == 1 then Code:AddJmp("skip") end
  ---------------------------------------------------------------
  -- LOADNIL R(A) [(,|...)] R(B)
  ---------------------------------------------------------------
  elseif mne == "LOADNIL" then
    RA = self:OperandR()
    self:OptionalCommaRange()
    RB = self:OperandR()
    self:EndOfLine()
    if RA > RB then
      self:Error("operand A must not exceed operand B")
    end
    Code:AddInst(Code:iABC(mne, RA, RB, 0))
  ---------------------------------------------------------------
  -- GETUPVAL R(A) [,] Upvalue[B]
  -- SETUPVAL R(A) [,] Upvalue[B]
  ---------------------------------------------------------------
  elseif mne == "GETUPVAL"
      or mne == "SETUPVAL" then
    RA = self:OperandR()
    self:OptionalComma()
    RB = self:OperandUpval()
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, RB, 0))
  ---------------------------------------------------------------
  -- GETGLOBAL R(A) [,] Kst(Bx)
  -- SETGLOBAL R(A) [,] Kst(Bx)
  ---------------------------------------------------------------
  elseif mne == "GETGLOBAL"
      or mne == "SETGLOBAL" then
    RA = self:OperandR()
    self:OptionalComma()
    RBx = self:OperandKst()
    self:EndOfLine()
    Code:AddInst(Code:iABx(mne, RA, RBx))
  ---------------------------------------------------------------
  -- GETTABLE R(A) [,] R(B) [,] RK(C)
  -- GETTABLE R(A) [,] R(B) "[" RK(C) "]"
  ---------------------------------------------------------------
  elseif mne == "GETTABLE" then
    RA = self:OperandR()
    self:OptionalComma()
    RB = self:OperandR()
    if self:OptionalBracketOpen() then
      RC = self:OperandRK()
      self:BracketClose()
    else
      self:OptionalComma()
      RC = self:OperandRK()
    end
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, RB, RC))
  ---------------------------------------------------------------
  -- SETTABLE R(A) [,] RK(B) [,] RK(C)
  -- SETTABLE R(A) "[" RK(B) "]" [,] RK(C)
  ---------------------------------------------------------------
  elseif mne == "SETTABLE" then
    RA = self:OperandR()
    if self:OptionalBracketOpen() then
      RB = self:OperandRK()
      self:BracketClose()
    else
      self:OptionalComma()
      RB = self:OperandRK()
    end
    self:OptionalComma()
    RC = self:OperandRK()
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, RB, RC))
  ---------------------------------------------------------------
  -- NEWTABLE R(A) [,] (num|imm) [,] (num|imm)
  ---------------------------------------------------------------
  elseif mne == "NEWTABLE" then
    local RBf, RCf
    RA = self:OperandR()
    self:OptionalComma()
    RB, RBf = self:OperandNum("")
    self:OptionalComma()
    RC, RCf = self:OperandNum("")
    self:EndOfLine()
    if RBf == "TK_IMM" then
      -- calculate actual array part size
      -- * conversion into a "floating point byte", where:
      --   value = (xxx) * 2^(mmmmm), byte (mmmmmxxx) in binary
      local m = 0
      while RB >= 8 do
        RB = math.floor((RB + 1) / 2); m = m + 1
      end
      RB = m * 8 + RB
    end
    if RB < 0 or RB > 255 then
      self:Error("encoded table array size out of range")
    end
    if RCf == "TK_IMM" then
      if RC < 0 then
        self:Error("table hash size cannot be negative")
      end
      -- calculate actual hash part size
      -- * the exp part of math.frexp() gives the exact amount
      RCf, RC = math.frexp(RC)
    end
    if RC < 0 or RC > 32 then
      self:Error("encoded table hash size out of range")
    end
    Code:AddInst(Code:iABC(mne, RA, RB, RC))
  ---------------------------------------------------------------
  -- SELF R(A) [,] R(B) [,] RK(C)
  -- SELF R(A) [,] R(B) "[" RK(C) "]"
  ---------------------------------------------------------------
  elseif mne == "SELF" then
    RA = self:OperandR()
    self:OptionalComma()
    RB = self:OperandR()
    if self:OptionalBracketOpen() then
      RC = self:OperandRK()
      self:BracketClose()
    else
      self:OptionalComma()
      RC = self:OperandRK()
    end
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, RB, RC))
  ---------------------------------------------------------------
  -- ADD R(A) [,] RK(B) [,] RK(C)
  ---------------------------------------------------------------
  elseif mne == "ADD"
      or mne == "SUB"
      or mne == "MUL"
      or mne == "DIV"
      or mne == "POW" then
    RA = self:OperandR()
    self:OptionalComma()
    RB = self:OperandRK()
    self:OptionalComma()
    RC = self:OperandRK()
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, RB, RC))
  ---------------------------------------------------------------
  -- UNM R(A) [,] R(B)
  ---------------------------------------------------------------
  elseif mne == "UNM"
      or mne == "NOT" then
    RA = self:OperandR()
    self:OptionalComma()
    RB = self:OperandR()
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, RB, 0))
  ---------------------------------------------------------------
  -- CONCAT R(A) [,] R(B) [(,|...)] R(C)
  ---------------------------------------------------------------
  elseif mne == "CONCAT" then
    RA = self:OperandR()
    self:OptionalComma()
    RB = self:OperandR()
    self:OptionalCommaRange()
    RC = self:OperandR()
    self:EndOfLine()
    if RB > RC then
      self:Error("operand B must not exceed operand C")
    end
    Code:AddInst(Code:iABC(mne, RA, RB, RC))
  ---------------------------------------------------------------
  -- EQ (0|1) [,] RK(B) [,] RK(C)
  ---------------------------------------------------------------
  elseif mne == "EQ"
      or mne == "LT"
      or mne == "LE" then
    RA = self:Operand01("A")
    self:OptionalComma()
    RB = self:OperandRK()
    self:OptionalComma()
    RC = self:OperandRK()
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, RB, RC))
    Code:AddJmp("skip")
  ---------------------------------------------------------------
  -- TEST R(A) [,] R(B) [,] (0|1)
  ---------------------------------------------------------------
  elseif mne == "TEST" then
    RA = self:OperandR()
    self:OptionalComma()
    RB = self:OperandR()
    self:OptionalComma()
    RC = self:Operand01("C")
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, RB, RC))
    Code:AddJmp("skip")
  ---------------------------------------------------------------
  -- JMP label|disp
  ---------------------------------------------------------------
  elseif mne == "JMP" then
    RBx, dest = self:OperandDisp()
    self:EndOfLine()
    Code:AddInst(Code:iAsBx(mne, 0, RBx))
    Code:AddJmp(dest)
  ---------------------------------------------------------------
  -- CALL R(A) [,] B [,] C
  ---------------------------------------------------------------
  elseif mne == "CALL" then
    RA = self:OperandR()
    self:OptionalComma()
    RB = self:OperandNum(Code.MASK_B)
    self:OptionalComma()
    RC = self:OperandNum(Code.MASK_C)
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, RB, RC))
  ---------------------------------------------------------------
  -- TAILCALL R(A) [,] B
  ---------------------------------------------------------------
  elseif mne == "TAILCALL" then
    RA = self:OperandR()
    self:OptionalComma()
    RB = self:OperandNum(Code.MASK_B)
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, RB, 0))
  ---------------------------------------------------------------
  -- RETURN R(A) [,] B
  ---------------------------------------------------------------
  elseif mne == "RETURN" then
    RA = self:OperandR()
    self:OptionalComma()
    RB = self:OperandNum(Code.MASK_B)
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, RB, 0))
  ---------------------------------------------------------------
  -- FORLOOP R(A) [,] label|disp
  ---------------------------------------------------------------
  elseif mne == "FORLOOP" then
    RA = self:OperandR()
    self:OptionalComma()
    RBx, dest = self:OperandDisp()
    self:EndOfLine()
    Code:AddInst(Code:iAsBx(mne, RA, RBx))
    Code:AddJmp(dest)
  ---------------------------------------------------------------
  -- TFORLOOP R(A) [,] C
  ---------------------------------------------------------------
  elseif mne == "TFORLOOP" then
    RA = self:OperandR()
    self:OptionalComma()
    RC = self:OperandNum(Code.MASK_C)
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, 0, RC))
    Code:AddJmp("skip")
  ---------------------------------------------------------------
  -- TFORPREP R(A) [,] label|disp
  ---------------------------------------------------------------
  elseif mne == "TFORPREP" then
    RA = self:OperandR()
    self:OptionalComma()
    RBx, dest = self:OperandDisp()
    self:EndOfLine()
    Code:AddInst(Code:iAsBx(mne, RA, RBx))
    Code:AddJmp(dest)
  ---------------------------------------------------------------
  -- SETLIST R(A) [,] Bx
  -- SETLIST R(A) [,] start [...] end
  ---------------------------------------------------------------
  elseif mne == "SETLIST"
      or mne == "SETLISTO" then
    RA = self:OperandR()
    self:OptionalComma()
    RBx = self:OperandNum(Code.MASK_Bx)
    if self.tt == "TK_OP" and self.tok == "..." then
      self:GetToken()
      RC = self:OperandNum(Code.MASK_Bx)
      -- range calculation for RBx -> RC
      if math.mod(RBx, Code.config.FPF) ~= 1 then -- start index
        self:Error("range must start with a multiple of FPF ("..
                   Code.config.FPF..") plus 1")
      end
      if (RC - RBx) >= Code.config.FPF then -- range
        self:Error("range must be not exceed FPF ("..Code.config.FPF..")")
      end
      RBx = RC - 1
    end
    self:EndOfLine()
    Code:AddInst(Code:iABx(mne, RA, RBx))
  ---------------------------------------------------------------
  -- CLOSE R(A)
  ---------------------------------------------------------------
  elseif mne == "CLOSE" then
    RA = self:OperandR()
    self:EndOfLine()
    Code:AddInst(Code:iABC(mne, RA, 0, 0))
  ---------------------------------------------------------------
  -- CLOSURE R(A) [,] Bx
  ---------------------------------------------------------------
  elseif mne == "CLOSURE" then
    RA = self:OperandR()
    self:OptionalComma()
    RBx = self:OperandProto()
    self:EndOfLine()
    Code:AddInst(Code:iABx(mne, RA, RBx))
  ---------------------------------------------------------------
  else
    -- should never arrive here, since all in op table are valid
    self:Error("unknown mnemonic '"..mne.."' encountered")
  end--if mne
  -- assign labels if any
  if Code:HasLabels() then Code:SetLabel("code", Code.func.sizecode) end
end

-----------------------------------------------------------------------
-- Parse a statement
-----------------------------------------------------------------------
function Parse:Statement()
  local tok = self.tok
  if self.tt == "TK_CMD" then
    self:GetToken()
    self:Directive(tok)
  elseif self.tt == "TK_MNE" then
    Code.mneline = Lex.line
    self:GetToken()
    self:Instruction(tok)
  else
    self:Error("directive or mnemonic expected")
  end
end

-----------------------------------------------------------------------
-- Main parser function
-----------------------------------------------------------------------
function Parse:Parse(asm, asmfile)
  self.asm = asm
  self.asmfile = asmfile
  Lex:Init(asm, asmfile)
  Code:Init(asmfile)
  self:GetToken()

  ---------------------------------------------------------------
  -- main parser loop
  -- * each loop parses one syntactical line (strings etc. might
  --   cause a "single" line to spill over into many lines
  ---------------------------------------------------------------
  repeat
    if self.tt == "TK_EOL" then -- empty line, do nothing
      self:GetToken()
    elseif self.tt == "TK_EOF" then
      -- nothing to do
    elseif self.tt == "TK_LABEL" then
      Code:AddLabel(self.tok)
      self:GetToken()
      if self.tt ~= "TK_EOL" and self.tt ~= "TK_EOF" then
        self:Statement()
      end
    elseif self.tt == "TK_SYM" then
      local maybeLabel = self.tok
      self:GetToken()
      if self.tt == "TK_EOL" then
        self:Error("orphaned symbol or identifier '"..maybeLabel.."'")
      end
      Code:AddLabel(maybeLabel)
      self:Statement()
    else
      self:Statement()
    end
  until self.tt == "TK_EOF"
  return Code:Dump()
end

--[[--------------------------------------------------------------------
-- (ChunkBake) Lua assembly language code generator
-- * state interpreted as follows:
--   0=global header, 1=after first function, 2=top-level closed
----------------------------------------------------------------------]]
Code = {}       -- code generator object

-----------------------------------------------------------------------
-- Initialize code generator object
-----------------------------------------------------------------------
function Code:Init(asmfile)
  self.asmfile = asmfile
  self.state = 0
  self.level = 0        -- function levels are always >= 1
  self.root = nil       -- top-level function
  self.func = nil       -- current function being assembled
  self.labelsnow = {}   -- labels to process (per-line)
  self.header = {}      -- properties set by .header directives
  self.funcop = {}      -- properties set by .function directives
  self.globtyp = {}     -- global symbols (equates)
  self.globval = {}
  self.labels = nil     -- local symbol (initialize)
  self.labelt = nil
  self.config = nil     -- reset configuration
end

-----------------------------------------------------------------------
-- Format error message for display, throw an error
-----------------------------------------------------------------------
function Code:Error(msg, line)
  if not line then line = Parse.line end
  error(string.format("%s:%d: Error: %s", self.asmfile, line, msg))
end

-----------------------------------------------------------------------
-- Warning message for display
-----------------------------------------------------------------------
function Code:Warn(msg, line)
  if config.QUIET then return end
  if not line then line = Parse.line end
  local message = string.format("ChunkBake: %s:%d: Warning: %s\n", self.asmfile, line, msg)
  if not TEST then
    io.stderr:write(message)
    io.stderr:flush()
  else
    WARN = (WARN or "")..message
  end
end

-----------------------------------------------------------------------
-- Process setting of header properties
-- * case insensitive, so constants here must be *lower case*
-----------------------------------------------------------------------
function Code:HeaderOption(pkey, pval)
  if self.state ~= 0 then
    self:Error(".header declarations must be defined at the start")
  end
  pkey = string.lower(pkey)
  ---------------------------------------------------------------
  -- convenient test functions for .header property declarations
  ---------------------------------------------------------------
  local function Expect(typ)
    if type(pval) ~= typ then
      self:Error(typ.." expected for property "..pkey)
    end
  end
  ---------------------------------------------------------------
  local function Range(lo, hi)
    local n = pval
    if math.floor(n) ~= n then
      self:Error("integer number expected for property "..pkey)
    elseif (lo and n < lo) or (hi and n > hi) then
      self:Error("integer out of range for property "..pkey)
    end
  end
  ---------------------------------------------------------------
  -- match, check and set properties
  ---------------------------------------------------------------
  if pkey == "signature" then
    Expect("string")
    if string.len(pval) ~= 4 then
      self:Warn("signature declared in not of normal length (4)")
    end
    self.header.signature = pval
  ---------------------------------------------------------------
  elseif pkey == "version" then
    Expect("number"); Range(80)
    self.header.version = pval
  ---------------------------------------------------------------
  elseif pkey == "endianness" then
    Expect("number"); Range(0, 1)
    self.header.endianness = pval
  ---------------------------------------------------------------
  elseif pkey == "int" then
    Expect("number"); Range(4, 8)
    self.header.int = pval
  ---------------------------------------------------------------
  elseif pkey == "size_t" then
    Expect("number"); Range(2, 8)
    self.header.size_t = pval
  ---------------------------------------------------------------
  elseif pkey == "instruction" then
    Expect("number"); Range(4, 8)
    self.header.Instruction = pval
  ---------------------------------------------------------------
  elseif pkey == "size_op" then
    Expect("number"); Range(6, 64)
    self.header.SIZE_OP = pval
  ---------------------------------------------------------------
  elseif pkey == "size_a" then
    Expect("number"); Range(1, 64)
    self.header.SIZE_A = pval
  ---------------------------------------------------------------
  elseif pkey == "size_b" then
    Expect("number"); Range(1, 64)
    self.header.SIZE_B = pval
  ---------------------------------------------------------------
  elseif pkey == "size_c" then
    Expect("number"); Range(1, 64)
    self.header.SIZE_C = pval
  ---------------------------------------------------------------
  elseif pkey == "number_type" then
    Expect("string")
    if pval == "double" or pval == "single" or
       pval == "int" or pval == "long long" then
      self.header.number_type = Number:SetNumberType(pval)
    else
      self:Error("unrecognized number type for property "..pkey)
    end
  ---------------------------------------------------------------
  elseif pkey == "maxstack" then
    Expect("number"); Range(1)
    self.header.MAXSTACK = pval
  ---------------------------------------------------------------
  elseif pkey == "maxvars" then
    Expect("number"); Range(1)
    self.header.MAXVARS = pval
  ---------------------------------------------------------------
  elseif pkey == "maxupvalues" then
    Expect("number"); Range(1)
    self.header.MAXUPVALUES = pval
  ---------------------------------------------------------------
  elseif pkey == "maxparams" then
    Expect("number"); Range(1)
    self.header.MAXPARAMS = pval
  ---------------------------------------------------------------
  elseif pkey == "fpf" then
    Expect("number"); Range(2)
    self.header.FPF = pval
  ---------------------------------------------------------------
  else
    self:Error("unrecognized .header property "..pkey)
  end--if pkey
end

-----------------------------------------------------------------------
-- Once-only initialization of binary chunk properties and opcode stuff
-----------------------------------------------------------------------
function Code:InitHeader()
  self.state = 1 -- no longer accept .header directives
  if self.config then return end
  self.config = {}
  ---------------------------------------------------------------
  -- set global header values, default or user override
  -- * platform defaults are used if no override declared
  ---------------------------------------------------------------
  local SAMPLE = string.dump(function() end)
  local function Byte(i) return string.byte(SAMPLE, i + 1) end
  -- grab defaults from a sample binary chunk
  self.config.signature = self.header.signature or string.sub(SAMPLE, 1, 4)
  self.config.version = self.header.version or Byte(4)
  self.config.endianness = self.header.endianness or Byte(5)
  -- byte sizes
  self.config.int = self.header.int or Byte(6)
  self.config.size_t = self.header.size_t or Byte(7)
  self.config.Instruction = self.header.Instruction or Byte(8)
  -- bit sizes
  self.config.SIZE_OP = self.header.SIZE_OP or Byte(9)
  self.config.SIZE_A = self.header.SIZE_A or Byte(10)
  self.config.SIZE_B = self.header.SIZE_B or Byte(11)
  self.config.SIZE_C = self.header.SIZE_C or Byte(12)
  -- check validity
  if self.config.SIZE_OP < 6 then
    self:Error("operand field too small to hold all opcodes")
  end
  if self.config.SIZE_A >= self.config.SIZE_B then
    self:Error("bit field A must be smaller than bit field B and C")
  end
  if self.config.SIZE_B ~= self.config.SIZE_C then
    self:Error("bit field B must be the same as bit field C")
  end
  if (self.config.Instruction * 8) ~= (self.config.SIZE_OP +
      self.config.SIZE_A + self.config.SIZE_B + self.config.SIZE_C) then
    self:Error("instruction bit field sizes inconsistent with instruction size")
  end
  ---------------------------------------------------------------
  -- initialize number conversion function and settings
  ---------------------------------------------------------------
  self.config.number_type = self.header.number_type
    or Number:SetNumberType(string.sub(SAMPLE, 15, Byte(13) + 14))
  self.config.test_number = Number.test_number
  self.config.lua_Number = Number.lua_Number
  if not self.config.number_type then
    self:Error("number type initialization failed")
  end
  ---------------------------------------------------------------
  -- initialize constants for opcode handling
  -- * note: field order is hard-coded into some encoding/decoding
  --   functions elsewhere in Code object
  ---------------------------------------------------------------
  self.config.SIZE_Bx = self.config.SIZE_B + self.config.SIZE_C
  self.MASK_OP = math.ldexp(1, self.config.SIZE_OP)
  self.MASK_B  = math.ldexp(1, self.config.SIZE_B)
  self.MASK_C  = math.ldexp(1, self.config.SIZE_C)
  self.MASK_Bx = math.ldexp(1, self.config.SIZE_Bx)
  self.MASK_A  = math.ldexp(1, self.config.SIZE_A)
  self.MAXARG_Bx = self.MASK_Bx - 1
  self.MAXARG_sBx = math.floor(self.MAXARG_Bx / 2)
  -- field order for encoding
  self.SEQ_iABC = {
    self.config.SIZE_OP, self.config.SIZE_C,
    self.config.SIZE_B,  self.config.SIZE_A,
  }
  ---------------------------------------------------------------
  -- set some implementation constants not defined in global header
  ---------------------------------------------------------------
  -- default constants are defined in llimits.h
  self.config.MAXSTACK = self.header.MAXSTACK or 250
  self.config.MAXVARS = self.header.MAXVARS or 200
  self.config.MAXUPVALUES = self.header.MAXUPVALUES or 32
  self.config.MAXPARAMS = self.header.MAXPARAMS or 100
  self.config.FPF = self.header.FPF or 32
  -- check validity
  if self.config.MAXSTACK < 20 then
    self:Error("MAXSTACK must be greater than 20")
  end
  if self.config.MAXSTACK >= self.MASK_A then
    self:Error("MAXSTACK beyond range of instruction field A")
  end
  if self.config.MAXUPVALUES > self.MASK_Bx then
    self:Error("MAXUPVALUES beyond range of instruction field Bx")
  end
  if self.config.MAXVARS >= self.config.MAXSTACK then
    self:Error("MAXVARS cannot exceed or equal MAXSTACK")
  end
  if self.config.MAXPARAMS >= self.config.MAXVARS then
    self:Error("MAXPARAMS cannot exceed or equal MAXVARS")
  end
  self.config.LUA_TNIL    = 0   -- these can't be touched for now
  self.config.LUA_TNUMBER = 3
  self.config.LUA_TSTRING = 4
end

-----------------------------------------------------------------------
-- Process setting of function properties
-- * nups and list sizes are not handled, they are auto-generated
-----------------------------------------------------------------------
function Code:FunctionOption(pkey, pval)
  self.state = 1
  pkey = string.lower(pkey)
  ---------------------------------------------------------------
  -- convenient test functions for .function property declarations
  ---------------------------------------------------------------
  local function Expect(typ)
    if type(pval) ~= typ then
      self:Error(typ.." expected for property "..pkey)
    end
    if typ == "number" and (math.floor(pval) ~= pval or pval < 0) then
      self:Error("illegal number value for property "..pkey)
    end
  end
  ---------------------------------------------------------------
  local function Range(lo, hi)
    local n = pval
    if math.floor(n) ~= n then
      self:Error("integer number expected for property "..pkey)
    elseif (lo and n < lo) or (hi and n > hi) then
      self:Error("integer out of range for property "..pkey)
    end
  end
  ---------------------------------------------------------------
  -- match, check and set properties
  ---------------------------------------------------------------
  if pkey == "source_name" then
    Expect("string")
    self.funcop.source_name = pval
  ---------------------------------------------------------------
  elseif pkey == "line_defined" then
    Expect("number"); Range(1)
    self.funcop.line_defined = pval
  ---------------------------------------------------------------
  elseif pkey == "numparams" then
    Expect("number"); Range(0, self.config.MAXPARAMS)
    self.funcop.numparams = pval
  ---------------------------------------------------------------
  elseif pkey == "is_vararg" then
    Expect("number"); Range(0, 1)
    self.funcop.is_vararg = pval
  ---------------------------------------------------------------
  elseif pkey == "maxstacksize" then
    Expect("number"); Range(2, self.config.MAXSTACK)
    self.funcop.maxstacksize = pval
  ---------------------------------------------------------------
  else
    self:Error("unrecognized .function property "..pkey)
  end--if pkey
end

-----------------------------------------------------------------------
-- Encode/decode instruction fields
-- * for encoding, OP can be a string mnemonic name
-- * partially encoded instructions are tables, see Code:iAsBx
-----------------------------------------------------------------------
function Code:iABC(OP, A, B, C)
  if type(OP) == "string" then OP = Lex.OPCODE[OP] end
  local field = {OP, C, B, A}
  local v, i = "", 0
  local cValue, cBits, cPos = 0, 0, 1
  -- encode an instruction
  while i < self.config.Instruction do
    -- if need more bits, suck in a field at a time
    while cBits < 8 do
      cValue = field[cPos] * math.ldexp(1, cBits) + cValue
      cBits = cBits + self.SEQ_iABC[cPos]; cPos = cPos + 1
    end
    -- extract bytes to instruction string
    while cBits >= 8 do
      v = v..string.char(math.mod(cValue, 256))
      cValue = math.floor(cValue / 256)
      cBits = cBits - 8; i = i + 1
    end
  end
  return v
end

-- not the most efficient methods...
function Code:iABx(OP, A, Bx)
  return self:iABC(OP, A, math.floor(Bx / self.MASK_C),
                          math.mod(Bx, self.MASK_C))
end

function Code:iAsBx(OP, A, sBx)
  -- if forward reference, defer instruction generation
  if type(sBx) == "string" then return {OP, A, sBx} end
  local Bx = sBx + self.MAXARG_sBx
  return self:iABC(OP, A, math.floor(Bx / self.MASK_C),
                          math.mod(Bx, self.MASK_C))
end

-- returns mnemonic string from an instruction
function Code:GetMne(code)
  if type(code) == "table" then return Lex.OPCODE[code.OP] end
  return Lex.OPCODE[math.mod(string.byte(code, 1), self.MASK_OP)]
end

-----------------------------------------------------------------------
-- Range checking for operands (other checks in Parse:Instruction)
-----------------------------------------------------------------------
function Code:CheckR(reg)
  if reg >= self.MASK_A then
    self:Error("R-type register operand out of range")
  end
end
function Code:CheckRK(reg)
  if reg >= self.MASK_B then
    self:Error("RK-type register operand out of range")
  end
end
function Code:CheckKst(kst)
  if type(kst) ~= "number" then return end
  if kst >= self.MASK_Bx then
    self:Error("Kst-type constant operand out of range")
  end
end
function Code:CheckDisp(disp)
  if type(disp) ~= "number" then return end
  if disp < -self.MAXARG_sBx or disp > self.MAXARG_sBx then
    self:Error("Displacement-type operand out of range")
  end
end

-----------------------------------------------------------------------
-- Initialize function object
-----------------------------------------------------------------------
function Code:FunctionBegin()
  if self.state == 2 then
    self:Error("cannot have more than one top-level function")
  end
  local func = {}
  ---------------------------------------------------------------
  -- initialize function state
  ---------------------------------------------------------------
  func.locvars = {}             -- init locals table
  func.sizelocvars = 0
  func.localflag = false
  func.upvalues = {}            -- init upvalues table
  func.sizeupvalues = 0
  func.k = {}                   -- init constants table
  func.rk = {}
  func.rknil = nil
  func.sizek = 0
  func.p = {}                   -- init prototypes table
  func.sizep = 0
  func.code = {}                -- init instructions table
  func.sizecode = 0
  func.lineinfo = {}            -- debug line info table
  func.jmpinfo = {}             -- jmp destination table
  func.maxstacksize = 2
  func.line_defined = Parse.line
  ---------------------------------------------------------------
  -- push one level
  ---------------------------------------------------------------
  self.level = self.level + 1   -- PUSH
  func.prev = self.func         -- save parent struct
  func.prevop = self.funcop     -- save parent function options
  func.prevlb = self.labels     -- save parent label set (2 tables)
  func.prevlt = self.labelt
  self.func = func              -- set this to current
  self.labels = {}              -- new label set
  self.labelt = {}
  self.funcop = {}              -- new function option set
  -- set root (top-level) function if first time
  if not self.root then self.root = func end
end

-----------------------------------------------------------------------
-- Ends and processes function object
-----------------------------------------------------------------------
function Code:FunctionEnd()
  if not self.func then
    self:Error(".end directive without matching .function")
  end
  local parent, now = self.func.prev, self.func
  ---------------------------------------------------------------
  -- code post-processing
  -- * resolve forward references for jump displacement labels
  ---------------------------------------------------------------
  if now.sizecode == 0 then
    self:Error("a function cannot have no code")
  end
  for i = 1, now.sizecode do
    local v = now.code[i]
    if type(v) ~= "string" then
      local sym = v[3]
      local typ = self:IsSymbol(sym)
      local dest
      if typ == "code" or typ == nil then
        dest = self:GetLabel(sym)
      else
        self:Error("symbol '"..sym.."' is not a code label")
      end
      if type(dest) ~= "number" then
        self:Error("could not resolve label '"..dest.."'", now.lineinfo[i])
      end
      -- displacement relative to the next instruction
      sym = dest - i - 1
      self:CheckDisp(sym)
      now.code[i] = Code:iAsBx(v[1], v[2], sym)
      now.jmpinfo[i] = dest
    end
  end
  local lastmne = self:GetMne(now.code[now.sizecode])
  if lastmne ~= "RETURN" and lastmne ~= "JMP" then
    self:Error("last instruction must be RETURN or JMP", now.lineinfo[now.sizecode])
  end
  now.sizelineinfo = now.sizecode       -- these two are the same
  ---------------------------------------------------------------
  -- look for out-of-bounds jump destinations or infinite loops
  ---------------------------------------------------------------
  for i = 1, now.sizecode do
    local dest = now.jmpinfo[i]
    if dest and (dest < 1 or dest > now.sizecode) then
      self:Error("jump out of bounds (to "..dest..")", now.lineinfo[i])
    end
    if dest == i then
      self:Warn("instruction jumps to itself", now.lineinfo[i])
    end
  end
  ---------------------------------------------------------------
  -- update sizes of lists (declarations with explicit indices do
  -- not update the size value, so we make sure...)
  -- * locals with no names are given the default name "(none)"
  ---------------------------------------------------------------
  -- update self.func.sizelocvars
  local maxidx = -1
  for i, v in pairs(now.locvars) do
    if i > maxidx then maxidx = i end
  end
  if maxidx >= now.sizelocvars then now.sizelocvars = maxidx + 1 end
  -- update self.func.sizeupvalues
  maxidx = -1
  for i, v in pairs(now.upvalues) do
    if i > maxidx then maxidx = i end
  end
  if maxidx >= now.sizeupvalues then now.sizeupvalues = maxidx + 1 end
  -- update self.func.sizek
  maxidx = -1
  for i, v in pairs(now.k) do
    if i > maxidx then maxidx = i end
  end
  if maxidx >= now.sizek then now.sizek = maxidx + 1 end
  if now.rknil and now.rknil > maxidx then now.sizek = now.rknil + 1 end
  ---------------------------------------------------------------
  -- set up function header information based on supplied info
  ---------------------------------------------------------------
  now.source_name = self.funcop.source_name
  now.line_defined = self.funcop.line_defined or now.line_defined
  now.nups = now.sizeupvalues
  now.is_vararg = self.funcop.is_vararg or 0
  -- update and validate numparams
  if now.numparams and self.funcop.numparams then
    if self.funcop.numparams < now.numparams then
      self:Error("numparams in .function less than number of .param declarations")
    end
  end
  now.numparams = self.funcop.numparams or now.numparams or 0
  -- update and validate maxstacksize
  if self.funcop.maxstacksize then
    if self.funcop.maxstacksize < now.maxstacksize then
      self:Error("maxstacksize in .function less than required value")
    end
    now.maxstacksize = self.funcop.maxstacksize
  end
  ---------------------------------------------------------------
  -- pop one level
  ---------------------------------------------------------------
  self.level = self.level - 1   -- POP
  self.func = parent            -- load parent struct
  self.funcop = now.prevop      -- load parent function options
  self.labels = now.prevlb      -- load parent label set (2 tables)
  self.labelt = now.prevlt
  if parent then                -- update prototypes table, or
    parent.p[parent.sizep] = now
    parent.sizep = parent.sizep + 1
  else
    self.state = 2              -- top-level is closed properly
    if not now.source_name then -- set the top-level source name
      now.source_name = "@"..self.asmfile
    end
  end
end

-----------------------------------------------------------------------
-- Add instruction to instructions list
-----------------------------------------------------------------------
function Code:AddInst(inst)
  self.func.sizecode = self.func.sizecode + 1
  self.func.code[self.func.sizecode] = inst
  self.func.lineinfo[self.func.sizecode] = self.mneline
end

-----------------------------------------------------------------------
-- take note of jump destination for later checking, set after AddInst
-- * by default, sets the 'skip' destination
-----------------------------------------------------------------------
function Code:AddJmp(dest)
  if not dest then return end
  if dest == "skip" then dest = self.func.sizecode + 2 end
  self.func.jmpinfo[self.func.sizecode] = dest
end

-----------------------------------------------------------------------
-- Adds a pending label to be noted
-----------------------------------------------------------------------
function Code:AddLabel(tok)
  table.insert(self.labelsnow, tok)
end

-----------------------------------------------------------------------
-- True if there is a label to be processed
-----------------------------------------------------------------------
function Code:HasLabels()
  return table.getn(self.labelsnow) > 0
end

-----------------------------------------------------------------------
-- Sets local label with a type and a value, generic label mechanism
-- * if parent flag set, label is added in parent function
--   (this is only for function labels, and self.prev must exist)
-----------------------------------------------------------------------
function Code:SetLabel(typ, val, parent)
  local labelt, labels
  if parent then
    labelt = self.func.prevlt
    labels = self.func.prevlb
  else
    labelt = self.labelt
    labels = self.labels
  end
  for i = 1, table.getn(self.labelsnow) do
    local label = table.remove(self.labelsnow)
    if self.globtyp[label] or (labelt[label] and (labelt[label] ~= "code"
       or type(labels[label]) ~= "string")) then
      -- "code"/"string" case is forward-referenced label placeholder
      self:Error("symbol '"..label.."' already defined")
    else
      labelt[label] = typ
      labels[label] = val
    end
  end
end

-----------------------------------------------------------------------
-- Returns symbol type if symbol exists, otherwise returns nil
-- * checks both local and global namespace
-- * local symbol results are simple lookups, for globals, the final
--   object type is returned instead (same with GetSymbol below)
-----------------------------------------------------------------------
function Code:IsSymbol(sym)
  local e
  if self.labelt then
    e = self.labelt[sym]
    if e then return e end        -- local symbol
  end
  e = self.globtyp[sym]
  if e == "label" then          -- transparently aliasing global labels
    while e and e == "label" do -- lookup
      e = self.globtyp[self.globval[sym]]
    end
  end
  return e
end

-----------------------------------------------------------------------
-- Gets value and tokentype of a given symbol, or fail if not found
-- (check existence of symbol check with Code:IsSymbol() first)
-- * single-pass makes forward referencing hard, KIV for now
-- * local/code/function/const/upvalue are marked with symbol type
--   information instead so expression parser can propagate this
--   within an expression and warn of symbol mixing
-----------------------------------------------------------------------
function Code:GetSymbol(sym)
  local typ = self.labelt and self.labelt[sym]
  ---------------------------------------------------------------
  if typ then                                   -- local symbol
    v = self.labels[sym]
    if typ == "code" and type(v) == "string" then
      self:Error("forward referenced symbol illegal in expression")
    end
    return v, typ
  ---------------------------------------------------------------
  else                                          -- global symbol
    typ = self.globtyp[sym]
    if typ then
      local orig = sym
      if typ == "label" then
        while typ and typ == "label" do -- lookup
          sym = self.globval[sym]
          typ = self.globtyp[sym]
        end
      end
      if typ == "equ" then
        return unpack(self.globval[sym])
      else
        self:Error("failed to resolve global symbol '"..orig.."'")
      end
    end
  end
  self:Error("symbol '"..sym.."' does not exist")
end

-----------------------------------------------------------------------
-- Gets value of a given code label, or return the same symbol if fail
-- and enters label as a potential forward-referenced code label
-- * for "code" only, this is for forward reference label mechanism
-- * not used by expression parser, so forward ref fails for expressions
-----------------------------------------------------------------------
function Code:GetLabel(sym)
  local typ = self.labelt[sym]
  if typ == "code" then
    return self.labels[sym]
  elseif typ then
    self:Error("label '"..sym.."' is not a code label")
  end
  self.labelt[sym] = "code"
  self.labels[sym] = sym
  return sym
end

-----------------------------------------------------------------------
-- Sets a local variable
-----------------------------------------------------------------------
function Code:SetLocal(sym, idx)
  self.func.locvars[idx] = sym
  self.labels[sym] = idx
  self.labelt[sym] = "local"
  return idx
end

-----------------------------------------------------------------------
-- Adds a local variable (explicit or next location)
-----------------------------------------------------------------------
function Code:AddLocal(sym, idx)
  if self:IsSymbol(sym) then
    self:Error("symbol '"..sym.."' already defined")
  end
  if not self.func.localflag then
    self.func.localflag = true  -- can no longer accept more params
    self.func.numparams = self.func.sizelocvars
  end
  if idx then -- explicit declaration
    if idx >= self.config.MAXVARS then
      self:Error("local index out of range")
    elseif self.func.locvars[idx] then
      self:Error("local with index "..idx.." already defined")
    end
    return self:SetLocal(sym, idx)
  end
  local i = self.func.sizelocvars -- add in next location
  while i < self.config.MAXVARS do
    if self.func.locvars[i] == nil then
      self.func.sizelocvars = i + 1
      return self:SetLocal(sym, i)
    end
    i = i + 1
  end
  self:Error("too many locals, list overflow")
end

-----------------------------------------------------------------------
-- Adds a parameter (next location), never after a local declaration
-----------------------------------------------------------------------
function Code:AddParam(sym)
  if self:IsSymbol(sym) then
    self:Error("symbol '"..sym.."' already defined")
  end
  if self.func.localflag then
    self:Error("all parameters must be defined before locals")
  end
  local i = self.func.sizelocvars -- add in the next location
  while i < self.config.MAXPARAMS do
    if self.func.locvars[i] == nil then
      self.func.sizelocvars = i + 1
      self.func.numparams = self.func.sizelocvars
      return self:SetLocal(sym, i)
    end
    i = i + 1
  end
  self:Error("too many parameters, list overflow")
end

-----------------------------------------------------------------------
-- Sets an upvalue
-----------------------------------------------------------------------
function Code:SetUpvalue(sym, idx)
  self.func.upvalues[idx] = sym
  self.labels[sym] = idx
  self.labelt[sym] = "upvalue"
  return idx
end

-----------------------------------------------------------------------
-- Adds an upvalue (explicit or next location)
-----------------------------------------------------------------------
function Code:AddUpvalue(sym, idx)
  if self:IsSymbol(sym) then
    self:Error("symbol '"..sym.."' already defined")
  end
  if idx then -- explicit declaration
    if idx >= self.config.MAXUPVALUES then
      self:Error("upvalue index out of range")
    elseif self.func.upvalues[idx] then
      self:Error("upvalue with index "..idx.." already defined")
    end
    return self:SetUpvalue(sym, idx)
  end
  local i = self.func.sizeupvalues -- add in next location
  while i < self.config.MAXUPVALUES do
    if self.func.upvalues[i] == nil then
      self.func.sizeupvalues = i + 1
      return self:SetUpvalue(sym, i)
    end
    i = i + 1
  end
  self:Error("too many upvalues, list overflow")
end

-----------------------------------------------------------------------
-- Checks for an upvalue by its number
-----------------------------------------------------------------------
function Code:IsUpvalue(idx)
  return self.func.upvalues[idx]
end

-----------------------------------------------------------------------
-- Sets a constant
-- * a nil is specially handled since it can't be used as a key
-----------------------------------------------------------------------
function Code:SetConst(sym, val, idx)
  self.func.k[idx] = val
  if val then
    self.func.rk[val] = idx
  else
    self.func.rknil = idx
  end
  if sym then
    self.labels[sym] = idx
    self.labelt[sym] = "const"
  end
  return idx
end

-----------------------------------------------------------------------
-- Adds a constant (explicit or next location)
-----------------------------------------------------------------------
function Code:AddConst(sym, val, idx)
  if sym and self:IsSymbol(sym) then
    self:Error("symbol '"..sym.."' already defined")
  end
  if idx then -- explicit declaration
    if idx >= self.MAXARG_Bx then
      self:Error("constant index out of range")
    elseif self.func.k[idx] then
      self:Error("constant with index "..idx.." already defined")
    end
    return self:SetConst(sym, val, idx)
  end
  local i = self.func.sizek -- add in next location
  while i < self.MAXARG_Bx do
    if self.func.k[i] == nil and self.func.rknil ~= i then
      self.func.sizek = i + 1
      return self:SetConst(sym, val, i)
    end
    i = i + 1
  end
  self:Error("too many constants, list overflow")
end

-----------------------------------------------------------------------
-- Checks for a constant by constant number
-----------------------------------------------------------------------
function Code:IsConst(idx)
  if self.func.rknil == idx then return true end
  return self.func.k[idx]
end

-----------------------------------------------------------------------
-- Gets a constant given a valid constant number
-----------------------------------------------------------------------
function Code:GetConstIdx(idx)
  if self.func.rknil == idx then return nil end
  return self.func.k[idx]
end

-----------------------------------------------------------------------
-- Gets a constant or adds a new constant by value
-----------------------------------------------------------------------
function Code:GetConst(val)
  if val == nil then
    if self.func.rknil then return self.func.rknil end
    return self:AddConst(nil, nil)
  end
  local idx = self.func.rk[val]
  if idx then return idx end
  return self:AddConst(nil, val)
end

-----------------------------------------------------------------------
-- Sets a global label with a type and a value, generic label mechanism
-----------------------------------------------------------------------
function Code:SetGlobLabel(typ, val)
  for i = 1, table.getn(self.labelsnow) do
    local label = table.remove(self.labelsnow)
    if self:IsSymbol(label) then
      self:Error("symbol '"..label.."' already defined")
    else
      self.globtyp[label] = "label"
      self.globval[label] = val
    end
  end
end

-----------------------------------------------------------------------
-- Adds an equate to global symbol table
-----------------------------------------------------------------------
function Code:SetEqu(sym, value, tt)
  local typ = self:IsSymbol(sym)
  -- only equates can be redefined
  if typ and (typ ~= "equ" or self.globtyp[sym] == "label") then
    self:Error("symbol '"..sym.."' already defined")
  end
  self.globtyp[sym] = "equ"
  self.globval[sym] = { value, tt }
end

-----------------------------------------------------------------------
-- Dumps a binary chunk of the assembled code as a string
-----------------------------------------------------------------------
function Code:Dump()
  local function Byte(c) return string.char(c) end
  ---------------------------------------------------------------
  -- return a block of bytes with correct endianness
  ---------------------------------------------------------------
  local function Block(v)
    if self.config.endianness == 0 then -- big endian
      local w = ""
      for i = string.len(v), 1, -1 do
        w = w..string.char(string.byte(v, i))
      end
      return w
    else
      return v
    end
  end
  ---------------------------------------------------------------
  -- builds global header
  ---------------------------------------------------------------
  if not self.config or not self.root then
    self:Error("no valid function defined in source file")
  end
  if self.state ~= 2 then
    self:Error("top-level function not yet closed by a .end")
  end
  local header =
    self.config.signature..
    Byte(self.config.version)..
    Byte(self.config.endianness)..
    Byte(self.config.int)..             -- byte sizes
    Byte(self.config.size_t)..
    Byte(self.config.Instruction)..
    Byte(self.config.SIZE_OP)..         -- bit sizes
    Byte(self.config.SIZE_A)..
    Byte(self.config.SIZE_B)..
    Byte(self.config.SIZE_C)..
    Byte(self.config.lua_Number)..      -- number info
    Block(self.config.test_number)
  ---------------------------------------------------------------
  -- recursively called to dump function data
  ---------------------------------------------------------------
  local function DumpFunction(func)
    -------------------------------------------------------------
    -- dumps an unsigned integer (for integers, size_ts)
    -------------------------------------------------------------
    local function DumpUnsigned(num, type_size)
      if not type_size then type_size = self.config.int end
      local v = ""
      for i = 1, type_size do
        v = v..string.char(math.mod(num, 256))
        num = math.floor(num / 256)
      end
      return Block(v)
    end
    -------------------------------------------------------------
    -- dumps a number (lua_Number type)
    -------------------------------------------------------------
    local function DumpNumber(num)
      if not Number.Convert then
        self:Error("conversion function for lua_Number not initialized")
      end
      return Block(Number:Convert(num))
    end
    -------------------------------------------------------------
    -- dumps a string
    -------------------------------------------------------------
    local function DumpString(str)
      if not str then
        return DumpUnsigned(0, config.size_size_t)
      end
      str = str.."\0"   -- mandatory NUL termination
      return DumpUnsigned(string.len(str), self.config.size_t)..str
    end
    -------------------------------------------------------------
    -- dumps debug line information
    -------------------------------------------------------------
    local function DumpLines()
      local s = DumpUnsigned(func.sizelineinfo)
      if func.sizelineinfo == 0 then return s end
      --TODO debug info option
      for i = 1, func.sizelineinfo do
        s = s..DumpUnsigned(func.lineinfo[i])
      end
      return s
    end
    -------------------------------------------------------------
    -- dump local variables
    -------------------------------------------------------------
    local function DumpLocals()
      local s = DumpUnsigned(func.sizelocvars)
      if func.sizelocvars == 0 then return s end
      for i = 0, func.sizelocvars - 1 do
        local locname = func.locvars[i]
        if not locname then locname = "(none)" end
        local startpc, endpc = 1, func.sizecode
        if func.numparams > i then startpc = 0 end
        s = s..DumpString(locname)..
               DumpUnsigned(startpc)..
               DumpUnsigned(endpc)
      end
      return s
    end
    -------------------------------------------------------------
    -- dump upvalues
    -------------------------------------------------------------
    local function DumpUpvalues()
      local s = DumpUnsigned(func.sizeupvalues)
      if func.sizeupvalues == 0 then return s end
      for i = 0, func.sizeupvalues - 1 do
        local upval = func.upvalues[i]
        if not upval then upval = "(none)" end
        s = s..DumpString(upval)
      end
      return s
    end
    -------------------------------------------------------------
    -- dump constants
    -- * generates nil constants; Lua doesn't seem to do that...
    -------------------------------------------------------------
    local function DumpConstantKs()
      local s = DumpUnsigned(func.sizek)
      if func.sizek == 0 then return s end
      for i = 0, func.sizek -1 do
        local v = func.k[i]
        if type(v) == "number" then
          s = s..Byte(self.config.LUA_TNUMBER)..DumpNumber(v)
        elseif type(v) == "string" then
          s = s..Byte(self.config.LUA_TSTRING)..DumpString(v)
        elseif type(v) == "nil" then
          s = s..Byte(self.config.LUA_TNIL)
        else
          self:Error("failed writing constant "..i.." bad type")
        end
      end--for
      return s
    end
    -------------------------------------------------------------
    -- dump function prototypes
    -------------------------------------------------------------
    local function DumpConstantPs()
      local s = DumpUnsigned(func.sizep)
      if func.sizep == 0 then return s end
      for i = 0, func.sizep - 1 do
        s = s..DumpFunction(func.p[i])
      end
      return s
    end
    -------------------------------------------------------------
    -- dump code
    -------------------------------------------------------------
    local function DumpCode()
      local s = DumpUnsigned(func.sizecode)
      if func.sizecode == 0 then return s end
      for i = 1, func.sizecode do
        s = s..Block(func.code[i])
      end
      return s
    end
    -------------------------------------------------------------
    -- body of WriteFunction() starts here
    -------------------------------------------------------------
    return DumpString(func.source_name)..
           DumpUnsigned(func.line_defined)..
           Byte(func.nups)..            -- some byte counts
           Byte(func.numparams)..
           Byte(func.is_vararg)..
           Byte(func.maxstacksize)..
           DumpLines()..                -- these are lists
           DumpLocals()..
           DumpUpvalues()..
           DumpConstantKs()..
           DumpConstantPs()..           -- may be recursive
           DumpCode()
  end--DumpFunction

  ---------------------------------------------------------------
  -- recursive call to function writing process
  ---------------------------------------------------------------
  return header..DumpFunction(self.root)
end

--[[--------------------------------------------------------------------
-- Top-level file handling, processes user's input file list
----------------------------------------------------------------------]]

function ChunkBakeDoFiles(files)
  for i, asmfile in ipairs(files) do
    local binfile, lstfile
    -------------------------------------------------------------
    -- find and replace extension for filenames
    -------------------------------------------------------------
    local extb, exte = string.find(asmfile, "%.[^%.%\\%/]*$")
    local basename = asmfile
    if extb and extb > 1 then
      basename = string.sub(asmfile, 1, extb - 1)
    end
    if config.LISTING_FLAG then lstfile = basename..config.EXT_LST end
    binfile = config.OUTPUT_FILE or basename..config.EXT_BIN
    -------------------------------------------------------------
    -- load and parse (source) assembly files
    -------------------------------------------------------------
    local INF = io.open(asmfile, "rb")
    if not INF then
      error("cannot open \""..asmfile.."\" for reading")
    end
    local asmdata = INF:read("*a")
    if not asmdata then
      error("error reading \""..asmfile.."\" assembly file")
    end
    io.close(INF)
    -- assembly starts from here...
    local bindata, lstdata = Parse:Parse(asmdata, asmfile)
    -------------------------------------------------------------
    -- optionally write out binary file
    -------------------------------------------------------------
    if not config.RUN_FLAG and binfile then
      local OUTF = io.open(binfile, "wb")
      if not OUTF then
        error("cannot open \""..binfile.."\" for writing")
      end
      OUTF:write(bindata)
      io.close(OUTF)
    end
--[[
    -------------------------------------------------------------
    --TODO OPTIONALLY write out listing file
    -------------------------------------------------------------
    if not config.RUN_FLAG and lstfile then
    end
    -------------------------------------------------------------
    --TODO OPTIONALLY run the binary chunk
    -------------------------------------------------------------
    if config.RUN_FLAG then
    end
--]]
  end--for
end

--[[--------------------------------------------------------------------
-- Command-line interface
----------------------------------------------------------------------]]

function main()
  ---------------------------------------------------------------
  -- handle arguments
  ---------------------------------------------------------------
  if table.getn(arg) == 0 then
    print(title) print(usage) return
  end
  local files, i = {}, 1
  while i <= table.getn(arg) do
    local a, b = arg[i], arg[i + 1]
    if string.sub(a, 1, 1) == "-" then        -- handle options here
      if a == "-h" or a == "--help" then
        print(title) print(usage) return
      elseif a == "--quiet" then
        config.QUIET = true
--[[
      elseif a == "--list" then
        config.LISTING_FLAG = true
--]]
      elseif a == "-o" then
        if not b then error("-o option needs a file name") end
        config.OUTPUT_FILE = b
        i = i + 1
--[[
      elseif a == "--run" then
        config.RUN_FLAG = true
--]]
      elseif a == "--" then
        for j = i + 1, table.getn(arg) do
          table.insert(arg_other, arg[j])     -- gather rest of args
        end
        break
      else
        error("unrecognized option "..a)
      end
    else
      table.insert(files, a)                  -- potential filename
    end
    i = i + 1
  end--while
  if table.getn(files) > 0 then
    if table.getn(files) > 1 then
      if config.OUTPUT_FILE then
        error("with -o, only one source file can be specified")
      elseif config.RUN_FLAG then
        error("specify only one assembly file with --run")
      end
    end
    ChunkBakeDoFiles(files)
  else
    print(title) print("ChunkBake: nothing to do!")
  end
end

-----------------------------------------------------------------------
-- program entry point
-----------------------------------------------------------------------
if not TEST then
  local ok, msg = pcall(main)           -- call main() for proper traceback
  if not ok then                        -- error
    print(title)
    print("* Run with option -h or --help for usage information")
    print(msg)
  end
end

----end-of-script----
