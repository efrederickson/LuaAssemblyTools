------------31----------------------------0
--iABC :	A:8	B:9	C:9		Op:6
--iABx :	A:8	Bx:18		Op:6
--iAsBx :	A:8	sBx:18     	Op:6 

local EncodeOp = {
iABC = function(op, a, b, c)

end,
iABx = function(op, a, bx)

end,
iAsBx = function(op, a, sbx)

end
}

local LuaOp = {
MOVE = 0,
LOADK = 1,
LOADBOOL = 2,
LOADNIL = 3,
GETUPVAL = 4,
GETGLOBAL = 5,
GETTABLE = 6,
SETGLOBAL = 7,
SETUPVAL = 8,
SETTABLE = 9,
NEWTABLE = 10,
SELF = 11,
ADD = 12,
SUB = 13,
MUL = 14,
DIV = 15,
MOD = 16,
POW = 17,
UNM = 18,
NOT = 19,
LEN = 20,
CONCAT = 21,
JMP = 22,
EQ = 23,
LT = 24,
LE = 25,
TEST = 26,
TESTSET = 27,
CALL = 28,
TAILCALL = 29,
RETURN = 30,
FORLOOP = 31,
FORPREP = 32,
TFORLOOP = 33,
SETLIST = 34,
CLOSE = 35,
CLOSURE = 36,
VARARG = 37
}

local LuaOpName = {
"MOVE",
"LOADK",
"LOADBOOL",
"LOADNIL",
"GETUPVAL",
"GETGLOBAL",
"GETTABLE",
"SETGLOBAL",
"SETUPVAL",
"SETTABLE",
"NEWTABLE",
"SELF",
"ADD",
"SUB",
"MUL",
"DIV",
"MOD",
"POW",
"UNM",
"NOT",
"LEN",
"CONCAT",
"JMP",
"EQ",
"LT",
"LE",
"TEST",
"TESTSET",
"CALL",
"TAILCALL",
"RETURN",
"FORLOOP",
"FORPREP",
"TFORLOOP",
"SETLIST",
"CLOSE",
"CLOSURE",
"VARARG"
}

local LuaOpType = {
iABC = 0,
iABx = 1,
iAsBx = 2
}

local LuaOpTypeLookup = {
LuaOpType.iABC,
LuaOpType.iABx,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABx,
LuaOpType.iABC,
LuaOpType.iABx,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC, --self = ?
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iAsBx,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iAsBx,
LuaOpType.iAsBx,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABC,
LuaOpType.iABx,
LuaOpType.iABC
}

--[[
==HEADER==
4 : ESC "Lua" (0x1B4C7561)
1 : 0x51
1 : Format version, 0 = official
1 : Endianness (0 = big, 1 = little)
1 : size of int in bytes (4)
1 : size of size_t in bytes (4)
1 : size of instruction in bytes (4)
1 : size of lua_Number in bytes (8)
1 : (0 = FP, 1 = integral) (should be 0)

==STRING==
Size_t : String data size
Bytes : String data including \0 at end

==FUNCTION==
String : source name
Integer : line defined
Integer : last line defined
1 : number of upvalues
1 : number of arguments
1 : (1 = VARARG_HASBVARARG, 2 = VARARG_ISVARARG, 4 = VARARG_NEEDSARG)
1 : max stack size
List : list of instructions
List : list of constants
List : list of function prototypes
== optional ==
List : list of source line positions
List : list of locals
List : list of upvalues

== INSTRUCTION LIST ==
Integer : size of code
[Instruction] : the code

== CONST LIST ==
Integer : size of constant list
[
	1 : (0 = NIL, 1 = BOOLEAN, 3 = NUMBER, 4 = STRING)
	Const : the constant (none for NIL, 0 or 1 for BOOL, Number for NUMBER, String for STRING)
]

== FUNC PROTO LIST ==
Integer : number of function protos
[Functions] : function prototype data or function blocks

]]

function GetOpString(op)
	local opcode = GetOpCode(op)
	local ty = GetOpCodeType(opcode)
	local name = GetOpCodeName(opcode)
	if ty == LuaOpType.iABC then
		local b = GetOpB(op)
		if b >= 256 then b = "256+"..(b-256) end
		local c = GetOpC(op)
		if c >= 256 then c = "256+"..(c-256) end
		return "OP="..name.." A="..GetOpA(op).." B="..b.." C="..c
	elseif ty == LuaOpType.iABx then
		return "OP="..name.." A="..GetOpA(op).." Bx="..GetOpBx(op)		
	elseif ty == LuaOpType.iAsBx then
		return "OP="..name.." A="..GetOpA(op).." sBx="..GetOpsBx(op)	
	end
	return "OP=<Bad Type>"
end
function GetOpCodeType(opcode)
	return LuaOpTypeLookup[opcode+1]
end
function GetOpCodeName(opcode)
	return LuaOpName[opcode+1]
end
function GetOpCode(op)
	return bit.get(op, 1, 6)
end
function GetOpA(op)
	return bit.get(op, 7, 14)
end
function GetOpB(op)
	return bit.get(op, 24, 32)
end
function GetOpC(op)
	return bit.get(op, 15, 23)
end
function GetOpBx(op)
	return bit.get(op, 15, 32)
end
function GetOpsBx(op)
	return GetOpBx(op) - 131071
end

function _G.DumpChunk(chunk, indent)
	local indent = indent or 0
	local index = 1
	local big_endian = false
	------------------------------------
	local function print(...)
		_G.print(string.rep("_", indent*2), ...)
	end
	local function GetInt8()
		local a = chunk:sub(index, index):byte()
		index = index + 1
		return a
	end
	local function GetInt16(str, inx)
		local a = GetInt8()
		local b = GetInt8()
		return 256*b + a
	end
	local function GetInt32(str, inx)
		local a = GetInt16()
		local b = GetInt16()
		return 65536*b + a
	end
	local function GetFloat64()
		--[[print("A="..a.." B'"..b)
		print("Bits="..bit.getstring(b, 32).."_"..bit.getstring(a, 32))
		print("Bits="..bit.get(b, 32).."__"..bit.getstring(bit.get(b, 21, 31), 11).."__"..bit.getstring(bit.get(b, 1, 20), 20).."-"..bit.getstring(a, 32))
		print("Sign="..sign..", Exp="..exponent..", Frac="..fraction)]]
		--[[local sign = -2*bit.get(b, 32)+1
		local exponent = bit.get(b, 21, 31)-1023
		local fraction = (bit.get(b, 1, 20)*(2^32) + a)/(2^52)+1
		return sign*(2^exponent)*fraction]]
		local a = GetInt32()
		local b = GetInt32()
		return (-2*bit.get(b, 32)+1)*(2^(bit.get(b, 21, 31)-1023))*((bit.get(b, 1, 20)*(2^32) + a)/(2^52)+1)
	end
	local function GetString(len)
		local str = chunk:sub(index, index+len-1)
		index = index + len
		return str
	end
	------------------------------------
	local function GetTypeInt() 
		local a = GetInt8()
		local b = GetInt8()
		local c = GetInt8()
		local d = GetInt8()
		return d*16777216 + c*65536 + b*256 + a
	end
	local function GetTypeString()
		local tmp = GetInt32(str, index)
		return GetString(tmp)
	end
	local function GetTypeFunction() 
		print("====FUNCTION DEF====")
		print("Source Name \""..GetTypeString():sub(1, -2).."\", Lines "..GetTypeInt().." to "..GetTypeInt())
		print("Upvalues : "..GetInt8()..", Arguments : "..GetInt8()..", VargFlag : "..GetInt8()..", Max Stack Size : "..GetInt8())
		do
			local num = GetInt32()
			print("Instructions : "..num.." {")
			indent = indent + 1
			for i = 1, num do
				local op = GetInt32()
				local opcode = GetOpCode(op)
				print(GetOpString(op))
			end
			indent = indent - 1
			print("}")
		end
		do
			local num = GetInt32()
			if num > 0 then
				print("Constants : "..num.." {")
				indent = indent + 1
				for i = 1, num do
					local ty = GetInt8()
					if ty == 0 then
						print((i-1).." : NIL")
					elseif ty == 1 then
						print((i-1).." : BOOL = "..(GetInt8() == 0 and "false" or "true"))
					elseif ty == 3 then
						print((i-1).." : NUMBER = "..GetFloat64())
					elseif ty == 4 then
						print((i-1).." : STRING = \""..GetTypeString():sub(1, -2).."\"")
					end
				end
				indent = indent - 1
				print("}")
			else
				print("Constants : 0 {}")
			end
		end
		do
			local num = GetInt32()
			if num > 0 then
				print("Functions Protos : "..num.." {")
				indent = indent + 1
				for i = 1, num do
					GetTypeFunction()
				end
				indent = indent - 1
				print("}")
			else
				print("Function Protos : 0 {}")
			end
		end
		do
			--strip debug info
			local numsrc = GetInt32()
			for i = 1, numsrc do GetInt32() end
			local numlocal = GetInt32()
			for i = 1, numlocal do GetTypeString() GetInt32() GetInt32() end
			local numups = GetInt32()
			for i = 1, numups do GetTypeString() end
		end
	end
	---------------------------------------
	--get chunk start
	print("====HEADER====")
	print("Chunk Identifier : "..GetString(4))
	print("Version number : "..GetInt8())
	print("Format : "..((GetInt8() == 0) and "Official" or "Unofficial"))
	big_endian = (GetInt8() == 0)
	print("Format version : "..(big_endian and "Big Endian (0)" or "Little Endian (1)"))
	print("Size of int : "..GetInt8().." bytes")
	print("Size of size_t : "..GetInt8().." bytes")
	print("Size of instruction : "..GetInt8().." bytes")
	print("Size of lua_Number : "..GetInt8().." bytes")
	print("Number format : "..((GetInt8() == 0) and "FP" or "INT"))
	GetTypeFunction()
end





