--[==[

		Maximum Overdrive System
			CODENAME: MODS

Chapters:
1.) Intro
2.) Syntax
	2.0) Basic code parsing
	2.1) Opcode usage
	2.2) Control Code usage
		2.2.1) Changing Chunk properties
	2.3) Declaring Constants, Locals, and Upvalues
	2.4) Declaring functions
		2.4.1) Using Upvalues in functions
		2.4.2) Using Varargs in functions
3.) Changelog




= = = = CHAPTER 1 = = = =

	This is the formal documentation of the MODS Lua Assembly suite.

	In the following chapters you will learn:
		The history of the MODS system
		How to properly use the MODS Syntax
		Maybe a few random Lua tricks

	WHAT YOU WILL NOT LEARN IN THE FOLLOWING CHAPTERS:
		To read / comprehend Lua Assembly
	If you are looking to learn Lua Assembly, go get the "ANoFrillsIntroToLua51VMInstructions.pdf"
	file from LuaForge.


	CURRENTLY, AS OF VERSION v0.5, THERE IS:
		FULL SUPPORT FOR MULTIPLE DATATYPES
		FULL COMMENT SUPPORT (; denotes a comment)
		SUPPORT FOR TABBING AND BLANK LINES AND LINES STARTING WITH COMMENTS
		NO SUPPORT FOR MULTI-LINE STRINGS
		NO SUPPORT FOR MULTIPLE INSTRUCTIONS / LINE

	### MODS IS DESIGNED FOR NORMAL LUA ONLY, INCOMPATIBLE WITH RBX.LUA ###
	## MEANING, YOU CANNOT RUN MODS IN ROBLOX.EXE, ONLY LUA.EXE OR SOMETHING SIMILAR ##


	~!~ DON'T READ THE SOURCE CODE, IT'S PRETTY NASTY. IT WERKS, BUT JUST BARELY. SOMETIMES ERRORS ARE REALLY INDECIPHERABLE (espicially if it's a problem with running the code). ~!~

= = = = CHAPTER 2 = = = =



= = SECTION 0 = =


To parse a block of LASM code, use something along the following.

local bytecode = parseLASM([[
; put LASM code here
]])


string parseLASM(string LASM)
the parseLASM will return the bytecode string of the assembled code, equiveleant to string.dump()
You can then run your code like this:

print(pcall(loadstring(bytecode)))


= = SECTION 1 = =


Each LASM opcode can be denoted by starting a new line with it's name (case insensitive).
The opcode's parameters are seperated by spaces.

Example:
move 1 0
Move 2 1
MOVE 3 2

When supplying a parameter, any and all constants should be prepended by the letter "k"

Example:
getglobal 0 k0


= = = SECTION 2 = = =


There are currently 7 control codes (Ctrl codes), each one serving a different purpose.
ctrl codes are used to define properties of chunks, and declare values.
All ctrl codes are denoted by prepending a period (".") infront of their name.

There is:
	.const	- Declares a new constant value in the current chunk
	.local 	- Declares a new local value in the current chunk
	.upval 	- Declares a new upvalue in the current chunk
	.optns	- Changes the current chunk's properties
	.cname	- Changes the current chunk's source name
	.funct	- starts a new chunk
	.end	- Ends a chunk


= = SUB-SECTION 1 = =

You can change 5 chunk properties with the ctrl codes .optns and .cname

.optns has 4 arguments, all of which change 1 property of a chunk.
The arguments, in order are, Number of Upvalues, Number of Arguments,
Variable Argument Flag, and Maximum Stack Size.

.cname has only 1 argument, which is what the sourcename of a chunk should be


Example:
.optns 5 6 3 9
.cname "AChunk"

A segment of the preceding chunk's disassembly:
Source Name "AChunk", Lines 1 to 1
Upvalues : 5, Arguments : 6, VargFlag : 3, Max Stack Size : 9

= = = SECTION 3 = = =


You can declare a constant, local value, or upvalue, using each of their own respective
ctrl codes.

Example:
.const 3.14
.local 'text'
.upval 'text'


= = = SECTION 4 = = =


You can declare a new function prototype using the .funct ctrl code
you then can denote the end of that prototype with the .end ctrl code
(the embedding of mutliple prototypes is supported)

Example:
Normal Lua:

local function coolprint() print("MAGIC!") end
coolprint()
>MAGIC!

LASM:

.local "coolprint"
.funct
	.const "print"
	.const "MAGIC!"
	getglobal 0 k0
	loadk 1 k1
	call 0 2 1
.end
closure 0 0
call 0 1 1

>MAGIC!

NOTE:
the functionality of the .optns ctrl code is also included with the .funct ctrl code.
So you can add four extra arguments to .funct (not required though)


= = SUB-SECTION 1 = =

Example usage of Upvalues
Lua Version:

local text = "Woah!"
local function fucn() print(text) end
func()
>Woah!

LASM Version:

.local "text"
.local "func"
.const "Woah!"
.funct 1 0 0 2
	.upval "text"
	.const "print"
	getglobal 0 k0
	getupval 1 0
	call 0 2 1
.end
loadk 0 k0
closure 1 0
move 0 0
call 1 1 1
>Woah!

= = SUB-SECTION 2 = =

Example Usage of Variable Arguments:
Lua verison:

local function coolprint(...) print(...) end
coolprint("abc", 3, "why", 0)
>abc	3	why	0

LASM Version:

.local "coolprint"
.const "abc"
.const 3
.const "why"
.const 0
.funct 0 0 3 3
	.const "print"
	getglobal 0 k0
	vararg 1 0
	call 0 0 1
.end
closure 0 0
loadk 1 k0
loadk 2 k1
loadk 3 k2
loadk 4 k3
call 0 5 1
>abc	3	why	0

(Interesting Note: whenever you use a vararg, if you declare the local variable "arg", it will become a table filled with all of the arguments)



= = = = CHAPTER 3 = = = =



	CHANGELOG
		v0.5
		 - Actually fixed the encoding of sBx opcodes
		   - Turns out I did it wrong before (because I never tested)
       - Lots more comment support (so put them everywhere!)
		v0.4
		 - Improved documentation
		 - Fixed a problem with the JUMP opcode's assembler
		 - Fixed a problem with the encoding of sBx opcodes

		v0.3
		 - Added support for chunk customization
		 - Added support for Local values, Upvalues, Function values, and Variable Arguments
		 - Completely rewrote the Parser / Assembler interface

		V0.2
		 - Completely rewrote the Parser (multiple times)

		v0.1
		 - Improved on the parser in several places
		 - Attempted support for local values, upvalues, function values with the help of Linoleum
		    - Never finished

		v0.0
		 - Concieved the idea of how the parser currently works.
		 - Wrote a very primitive version of the current parser.


Thanks for reading!
]==]

------------31----------------------------0
--iABC :	A:8	B:9	C:9		Op:6
--iABx :	A:8	Bx:18		Op:6
--iAsBx :	A:8	sBx:18     	Op:6

local p2 = {1,2,4,8,16,32,64,128,256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072}
local function keep (x, n) return x % p2[n+1] end
local function srb (x,n) return math.floor(x / p2[n+1]) end
local function slb (x,n) return x * p2[n+1] end
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

local CreateOp = {
	ABC = function(op, a, b, c)
		return {TY="ABC", OP=op, A=a, B=b, C=c}
	end,
	ABx = function(op, a, bx)
		return {TY="ABx", OP=op, A=a, Bx=bx}
	end,
	AsBx = function(op, a, sbx)
		return {TY="AsBx", OP=op, A=a, sBx=sbx} -- Bx = sbx
	end,
	Encode = function(op)
		local c0, c1, c2, c3
		if op.sBx then op.Bx = op.sBx + 131071 end
		if op.Bx then op.C = keep(op.Bx, 9); op.B = srb (op.Bx, 9) end
		c0 = op.OP + slb(keep(op.A, 2), 6)
		c1 = srb(op.A, 2) + slb(keep(op.C, 2), 6)
		c2 = srb(op.C, 2) + slb(keep (op.B, 1), 7)
		c3 = srb(op.B, 1)
		return string.char(c0, c1, c2, c3)
	end
}


local DumpBinary;
DumpBinary = {
	String = function(s)
		return DumpBinary.Integer(#s+1)..s.."\0"
	end,
	Integer = function(n)
		return DumpBinary.Int32(n)
	end,
	Int8 = function(n)
		return string.char(n)
	end,
	Int16 = function(n)
		error("DumpBinary::Int16() Not Implemented")
	end,
	Int32 = function(x)
		local v = ""
		x = math.floor(x)
		if x >= 0 then
			for i = 1, 4 do
			v = v..string.char(x % 256)
			x = math.floor(x / 256)
			end
		else -- x < 0
			x = -x
			local carry = 1
			for i = 1, 4 do
				local c = 255 - (x % 256) + carry
				if c == 256 then c = 0; carry = 1 else carry = 0 end
				v = v..string.char(c)
				x = math.floor(x / 256)
			end
		end
		return v
	end,
	Float64 = function(x)
		local function grab_byte(v)
			return math.floor(v / 256), string.char(math.floor(v) % 256)
		end
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
			x, byte = grab_byte(x)
			v = v..byte -- 47:0
		end
		x, byte = grab_byte(exponent * 16 + x)
		v = v..byte -- 55:48
		x, byte = grab_byte(sign * 128 + x)
		v = v..byte -- 63:56
		return v
	end
}

_G.bit = {
	new = function(str)
		return tonumber(str, 2)
	end,
	get = function(num, n, n2)
		if n2 then
			local total = 0
			local digitn = 0
			for i = n, n2 do
				total = total + 2^digitn*bit.get(num, i)
				digitn = digitn + 1
			end
			return total
		else
			local pn = 2^(n-1)
			return (num % (pn + pn) >= pn) and 1 or 0
		end
	end,
	getstring = function(num, mindigit, sep)
		mindigit = mindigit or 0
		local pow = 0
		local tot = 1
		while tot <= num do
			tot = tot * 2
			pow = pow + 1
		end
		---
		if pow < mindigit then pow = mindigit end
		---
		local str = ""
		for i = pow, 1, -1 do
			str = str..bit.get(num, i)..(i==1 and "" or (sep or "-"))
		end
		return str
	end
}

function _G.CreateChunk()
	local chunk = {}
	-----
	local nargs = 0
	local vConstants = {}
	local nextConstantIndex = 1
	local vCode = {}
	local vProto = {}
	local CNAME = "LuaCXX Source"
	local U,A,V,S = 0, 0, 0, 10
	local UPV, LCL = {}, {}
	-----
	chunk.CompileChunk = function()
		--append header
		return "\027Lua\81\0\1\4\4\4\8\0"..chunk.Compile()
	end
	chunk.Compile = function()
		local body = ""
		body = body..DumpBinary.String(CNAME)
		body = body..DumpBinary.Integer(1) --first line
		body = body..DumpBinary.Integer(1) --last line
		body = body..DumpBinary.Int8(U) --upvalues
		body = body..DumpBinary.Int8(A) --arguments
		body = body..DumpBinary.Int8(V) --VARG_FLAG
		body = body..DumpBinary.Int8(S) --max stack size
		do --instructions
			body = body..DumpBinary.Integer(#vCode+1)
			for i = 1, #vCode do
				body = body..CreateOp.Encode(vCode[i])
			end
			body = body..CreateOp.Encode(CreateOp.ABC(LuaOp.RETURN, 0, 1, 0))
		end
		do --constants
			local const = {}
			for k, v in pairs(vConstants) do
				const[v] = k
			end
			--
			body = body..DumpBinary.Integer(#const)
			for i = 1, #const do
				local c = const[i]
				if type(c) == "string" then
					body = body..DumpBinary.Int8(4)..DumpBinary.String(c)
				elseif type(c) == "number" then
					body = body..DumpBinary.Int8(3)..DumpBinary.Float64(c)
				elseif type(c) == "boolean" then
					body = body..DumpBinary.Int8(1)..DumpBinary.Int8(c and 1 or 0)
				elseif type(c) == "nil" then
					body = body..DumpBinary.Int8(0)
				end
			end
		end
		do --protos
			body = body..DumpBinary.Integer(#vProto)
			for i = 1, #vProto do
				body = body..vProto[i].Compile()
			end
		end
		--add PLENTIFUL debug into
		body = body..DumpBinary.Integer(0) --// 0 line thingies
		body = body..DumpBinary.Integer(#LCL)
		for i,v in pairs(LCL) do
			body = body .. DumpBinary.String(v[1]) .. DumpBinary.Integer(v[2]) .. DumpBinary.Integer(v[3]);
		end
		body = body..DumpBinary.Integer(#UPV)
		for i,v in pairs(UPV) do
			body = body .. DumpBinary.String(v)
		end
		return body
	end
	--
	chunk.GetOp = function(inx)
		return vCode[inx]
	end
	chunk.GetNumOp = function()
		return #vCode
	end
	chunk.PushOp = function(op)
		vCode[#vCode+1] = op
	end
	--
	chunk.GetProto = function(inx)
		return vProto[inx]
	end
	chunk.GetNumProto = function()
		return #vProto
	end
	chunk.PushProto = function(proto)
		vProto[#vProto+1] = proto
	end
	chunk.SetProtoIndex = function(proto, inx)
		vProto[inx] = proto
	end
	--
	chunk.GetConstant = function(constant)
		local inx = vConstants[constant]
		if inx then
			return inx
		else
			inx = nextConstantIndex
			nextConstantIndex = nextConstantIndex + 1
			vConstants[constant] = inx
			return inx
		end
	end
	chunk.SetConstantIndex = function(constant, index) --manually set an index to a constant
		nextConstantIndex = index + 1
		vConstants[constant] = index
	end
	chunk.SetParams = function(u,a,v,s)
		U,A,V,S = u,a,v,s;
	end
	chunk.SetLocals = function(l,u)
		LCL,UPV = l,u
	end
	chunk.SetName = function(str)
		CNAME = tostring(str);
	end
	return chunk
end

function CreateAnObject(ty, callfunc)
	if callfunc then
		return setmetatable({type=ty}, {__call = callfunc})
	else
		return {type=ty}
	end
end

function CheckAValue(fname, a)
	if a < 0 or a > 255 then
		error("Argument #1 to "..fname.." must be in the range [0-255]")
	end
end

function CheckIsConstant(a, err)
	if type(a) ~= "table" or a.type ~= "constant" then
		error(err)
	end
end

function CheckIsProto(a, err)
	if type(a) ~= "table" or a.type ~= "proto" then
		error(err)
	end
end

function CheckIsRK(a, err)
	if type(a) ~= "number" and (type(a) ~= "table" or a.type ~= "constant") then
		error(err)
	end
end

function _G.aChunk(chunkname, LCL,UPV,U,A,V,S, CNAME)
	return CreateAnObject("chunk", function(self, childtb)
		self.name = chunkname
		self.nextconst = 1
		self.const = {} --my constants
		self.code = {}	--instruction : value
		self.nextproto = 1
		self.proto = {} --name : object
		self.pushop = function(op)
			self.code[#self.code+1] = op
		end
		self.buildchunk = function()
			local chunk = CreateChunk()
			--args
			chunk.SetParams(U,A,V,S);
			chunk.SetLocals(LCL, UPV);
			chunk.SetName(CNAME or "LuaCXX Source");
			--constants
			for c, i in pairs(self.const) do
				chunk.SetConstantIndex(c, i)
			end
			--code
			for i = 1, #self.code do
				chunk.PushOp(self.code[i])
			end
			--protos
			for k, p in pairs(self.proto) do
				chunk.SetProtoIndex(p.buildchunk(), p.protonum)
			end
			return chunk
		end
		self.Compile = function()
			return self.buildchunk().CompileChunk()
		end
		--
		for i, child in ipairs(childtb) do
			if child.type == "chunk" then
				child.protonum = self.nextproto
				self.nextproto = self.nextproto + 1
				self.proto[child.name] = child
			elseif child.type == "instruction" then
				child(self)
			end
		end
		--
		return self
	end)
end

function _G.aMOVE(a, b)
	CheckAValue("aMOVE", a)
	CheckAValue("aMOVE", b)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.MOVE, a, b, 0))
	end)
end

function _G.aLOADNIL(a, b)
	CheckAValue("aLOADNIL", a)
	CheckAValue("aLOADNIL", b)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.LOADNIL, a, b, 0))
	end)
end

function _G.aLOADK(inx, k)
	CheckAValue("aLOADK", inx)
	CheckIsConstant(k, "Argument #2 to aLOADK must be a constant")
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABx(LuaOp.LOADK, inx, k(chunk)))
	end)
end

function _G.aLOADBOOL(a, b, c)
	CheckAValue("aLOADBOOL", a)
	CheckAValue("aLOADBOOL", b)
	CheckAValue("aLOADBOOL", c)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.LOADBOOL, a, b, c))
	end)
end

function _G.aGETGLOBAL(inx, k)
	CheckAValue("aGETGLOBAL", inx)
	CheckIsConstant(k, "Argument #2 to aGETGLOBAL must be a constant")
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABx(LuaOp.GETGLOBAL, inx, k(chunk)))
	end)
end

function _G.aGETUPVAL(a,b)
	CheckAValue("aGETUPVAL",a)
	CheckAValue("aGETUPVAL",b)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.GETUPVAL, a, b, 0));
	end)
end

function _G.aSETUPVAL(a,b)
	CheckAValue("aSETUPVAL",a)
	CheckAValue("aSETUPVAL",b)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.SETUPVAl, a, b, 0));
	end)
end

function _G.aSETGLOBAL(inx, k)
	CheckAValue("aSETGLOBAL", inx)
	CheckIsConstant(k, "Argument #2 to aGETGLOBAL must be a constant")
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABx(LuaOp.SETGLOBAL, inx, k(chunk)))
	end)
end

function _G.aGETTABLE(a, b, c)
	CheckAValue("aGETTABLE", a)
	CheckAValue("aGETTABLE", b)
	CheckIsRK(c, "Argument #3 to aGETTABLE must be a register or constant")
	return CreateAnObject("instruction", function(self, chunk)
		if type(c) == "table" then
			c = c(chunk) + 256
		end
		chunk.pushop(CreateOp.ABC(LuaOp.GETTABLE, a, b, c))
	end)
end

function _G.aSETTABLE(a, b, c)
	CheckAValue("aSETTABLE", a)
	CheckIsRK(b, "Argument #2 to aSETTABLE must be a register or constant")
	CheckIsRK(c, "Argument #3 to aSETTABLE must be a register or constant")
	return CreateAnObject("instruction", function(self, chunk)
		if type(b) == "table" then
			b = b(chunk) + 256
		end
		if type(c) == "table" then
			c = c(chunk) + 256
		end
		chunk.pushop(CreateOp.ABC(LuaOp.SETTABLE, a, b, c))
	end)
end

for _, v in pairs({"ADD", "SUB", "MUL", "DIV", "MOD", "POW", "EQ", "LT", "LE"}) do
	_G["a"..v] = function(a, b, c)
		CheckAValue("a"..v, a)
		CheckIsRK(b, "Argument #2 to a"..v.." must be a register or constant")
		CheckIsRK(c, "Argument #3 to a"..v.." must be a register or constant")
		return CreateAnObject("instruction", function(self, chunk)
			if type(b) == "table" then
				b = b(chunk) + 256
			end
			if type(c) == "table" then
				c = c(chunk) + 256
			end
			chunk.pushop(CreateOp.ABC(LuaOp[v], a, b, c))
		end)
	end
end

function _G.aUNM(a, b)
	CheckAValue("aUNM", a)
	CheckAValue("aUNM", b)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.UNM, a, b, 0))
	end)
end

function _G.aNOT(a, b)
	CheckAValue("aNOT", a)
	CheckAValue("aNOT", b)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.NOT, a, b, 0))
	end)
end

function _G.aLEN(a, b)
	CheckAValue("aLEN", a)
	CheckAValue("aLEN", b)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.LEN, a, b, 0))
	end)
end

function _G.aCONCAT(a, b, c)
	CheckAValue("aCONCAT", a)
	CheckAValue("aCONCAT", b)
	CheckAValue("aCONCAT", c)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.CONCAT, a, b, c))
	end)
end

function _G.aJMP(a)
	assert(type(a) == "number", "Argument #1 to aJMP must be a number")
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.AsBx(LuaOp.JMP,0,a))
	end)
end

function _G.aCALL(a, b, c)
	CheckAValue("aCALL", a)
	CheckAValue("aCALL", b)
	CheckAValue("aCALL", c)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.CALL, a, b, c))
	end)
end

function _G.aRETURN(a, b)
	CheckAValue("aRETURN", a)
	CheckAValue("aRETURN", b)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.RETURN, a, b, 0))
	end)
end

function _G.aTAILCALL(a, b, c)
	CheckAValue("aTAILCALL", a)
	CheckAValue("aTAILCALL", b)
	CheckAValue("aTAILCALL", c)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.TAILCALL, a, b, c))
	end)
end

function _G.aVARARG(a, b)
	CheckAValue("aVARARG", a)
	CheckAValue("aVARARG", b)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.VARARG, a, b, 0))
	end)
end

function _G.aSELF(a, b, c)
	CheckAValue("aSELF", a)
	CheckAValue("aSELF", b)
	CheckIsRK(c, "Argument #3 to aSELF must be a register or constant")
	return CreateAnObject("instruction", function(self, chunk)
		if type(c) == "table" then
			c = c(chunk) + 256
		end
		chunk.pushop(CreateOp.ABC(LuaOp.SELF, a, b, c))
	end)
end

function _G.aTEST(a, c)
	CheckAValue("aTEST", a)
	CheckAValue("aTEST", c)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.TEST, a, 0, c))
	end)
end

function _G.aTESTSET(a, b, c)
	CheckAValue("aTESTSET", a)
	CheckAValue("aTESTSET", b)
	CheckAValue("aTESTSET", c)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.TESTSET, a, b, c))
	end)
end

function _G.aFORPREP(a, b)
	CheckAValue("aFORPREP", a)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.AsBx(LuaOp.FORPREP, a, b))
	end)
end

function _G.aFORLOOP(a, b)
	CheckAValue("aFORLOOP", a)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.AsBx(LuaOp.FORLOOP, a, b))
	end)
end

function _G.aTFORLOOP(a, c)
	CheckAValue("aTFORLOOP", a)
	CheckAValue("aTFORLOOP", c)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.TFORLOOP, a, 0, c))
	end)
end

function _G.aNEWTABLE(a, b, c)
	CheckAValue("aNEWTABLE", a)
	CheckAValue("aNEWTABLE", b)
	CheckAValue("aNEWTABLE", c)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.NEWTABLE, a, b, c))
	end)
end

function _G.aSETLIST(a, b, c)
	CheckAValue("aSETLIST", a)
	CheckAValue("aSETLIST", b)
	CheckAValue("aSETLIST", c)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.SETLIST, a, b, c))
	end)
end

function _G.aCLOSURE(a, proto)
	CheckAValue("aCLOSURE", a)
	--CheckIsProto(proto, "Argument #2 to aCLOSURE must be a function prototype")
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABx(LuaOp.CLOSURE, a, proto))
	end)
end

function _G.aCLOSE(a)
	CheckAValue("aCLOSE", a)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABC(LuaOp.CLOSE, a, 0, 0))
	end)
end

function _G.aK(constant)
	return CreateAnObject("constant", function(self, chunk)
		local constinx = chunk.const[constant]
		if not constinx then
			constinx = chunk.nextconst
			chunk.nextconst = chunk.nextconst + 1
			chunk.const[constant] = constinx
		end
		return constinx-1
	end)
end

function _G.aProto(name)
	return CreateAnObject("proto", function(self, chunk)
		local proto = chunk.proto[name]
		if not proto then
			error("Chunk `"..chunk.name.."` has no prototype named `"..name)
		end
		return proto.protonum-1
	end)
end


local EncodeOp = {
iABC = function(op, a, b, c)

end,
iABx = function(op, a, bx)

end,
iAsBx = function(op, a, sbx)

end
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
		_G.print(string.rep("_", indent*2) .. ...)
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
			print("====DEBUG INFO====")
			--strip debug info
			local numsrc = GetInt32()
			for i = 1, numsrc do GetInt32() end
			local numlocal = GetInt32()
			print("Local Values : " .. (numlocal > 0 and numlocal .. " {" or "0 {}"))
			indent = indent + 1
			for i = 1, numlocal do
				local name = GetTypeString()
				local spc = GetInt32()
				local epc = GetInt32()
				print("NAME="..name:sub(1,#name-1).." STARTPC="..spc.." ENDPC="..epc)
			end
			indent = indent - 1
			if numlocal > 0 then print("}") end
			local numups = GetInt32()
			print("UpValues : " .. (numups > 0 and numups.. " {" or "0 {}"))
			indent = indent + 1
			for i = 1, numups do print("NAME="..GetTypeString()) end
			indent = indent - 1
			if numups > 0 then print("}") end

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

local NPROTO = 0;

local function base(str, name, NUPS, NARGS, VFLAG, STACKS, CNAME)
	local S = "";
    for line in str:gmatch("(.-)%\n") do     --// helps with allowing tabbing.
        S = S .. " \t" .. line .. " \n";
    end
    str = S .. " ";
    local S;

    --// Variables
    local POS = 0;
    local CONSTLIST = {}
    local functSTART = 0;
    local functCODE = "";
    local OPCODES = {};
	local LOCALS = {}
	local UPVALS = {}
    NUPS, NARGS, VFLAG, STACKS = NUPS or 0, NARGS or 0, VFLAG or 0, STACKS or 10

    --// Main
    for line in str:gmatch("%s+(.-)%\n") do
	POS = POS + 1
    local forgetThis, useThis = functCODE:gsub("\n","");
		if POS > functSTART + useThis then
			if line:sub(1,1) ~= ";" then
				if line:sub(1,1) == "." then                    --// directives
					local op = line:match("(.%a-)%s")
					local para = line:sub(#op+2)
					if op:lower() == ".const" then
						local _, k = (para .. ";"):match("([\'\"])(.-)%1;")
						if not k and not _ then _, k= (para .. ";"):match("([\'\"])(.-)%1%s-;") end
						if not k then _,k = "", (para .. ";"):match("(%d+)%s-;") end
						local c = loadstring("return aK(" .. _ .. k .. _ .. ")")();
						table.insert(CONSTLIST, c);
					elseif op:lower() == ".local" then
						local str, s, e = para:match("%s?(.+)%s(%d+)%s(%d+)")
						if not str then
							local _, k = (para .. ";"):match("([\'\"])(.-)%1;")
							if not k and not _ then _, k= (para .. ";"):match("([\'\"])(.-)%1%s-;") end
							str, s, e = _..k.._, 0, 0
						end
						str,s,e = loadstring("return " .. str)(), tonumber(s), tonumber(e)
						table.insert(LOCALS, {str,s,e})
					elseif op:lower() == ".funct" then
						local upv, args, var, maxs = line:sub(line:find(op)+#op+1):match("%s?(%d+)%s(%d+)%s(%d+)%s(%d+)");
						upv,args,var,maxs = tonumber(upv),tonumber(args),tonumber(var),tonumber(maxs)
						local depth = 1;
						functSTART = POS;
						functCODE = "";
						local keepGoing = 1;
						local fCODE = "";
						local currentNPROTO = NPROTO;

						for miniLine in str:gmatch("%s+(.-)%\n") do
							if keepGoing > functSTART then
								fCODE = fCODE .. miniLine .. "\n";
							end
							keepGoing = keepGoing + 1;
						end

						for miniLine in fCODE:gmatch("(.-)%\n") do
							if miniLine:sub(1,6) == ".funct" then
								depth = depth + 1;
							elseif miniLine:sub(1,4) == ".end" then
								depth = depth - 1;
							end
							if depth > 0 then
								functCODE = functCODE .. miniLine .. "\n";
							else break; end
						end

						table.insert(OPCODES, base(functCODE,"PROTO"..currentNPROTO, upv, args, var, maxs))
						aProto("PROTO"..currentNPROTO)
						NPROTO = NPROTO + 1;
					elseif op:lower() == ".upval" then
						local _, k = (para .. ";"):match("([\'\"])(.-)%1;")
						if not k and not _ then _, k= (para .. ";"):match("([\'\"])(.-)%1%s-;") end
						if not k then _,k = "", (para .. ";"):match("(%d+)%s-;") end
						table.insert(UPVALS, loadstring("return " .._..k.._)())
					elseif op:lower() == ".optns" then
						local upv, args, var, maxs = line:sub(line:find(op)+#op+1):match("%s?(%d+)%s(%d+)%s(%d+)%s(%d+)");
						upv,args,var,maxs = tonumber(upv),tonumber(args),tonumber(var),tonumber(maxs)
						NUPS, NARGS, VFLAG, STACKS = upv,args,var,maxs
					elseif op:lower() == ".cname" then
						local _, k = (para .. ";"):match("([\'\"])(.-)%1;")
						if not k and not _ then _, k= (para .. ";"):match("([\'\"])(.-)%1%s-;") end
						if not k then _,k = "", (para .. ";"):match("(%d+)%s-;") end
						CNAME = loadstring("return " .. _ .. k .. _)();
					end
				else                                       --// opcodes
					local OPTIONS = {}
					local opcode = line:match("(%a+)%s")
					if opcode then
						for option in line:gmatch("(.%d+)") do
							if option:sub(1,1):lower() == "k" then
								table.insert(OPTIONS, CONSTLIST[tonumber(option:sub(2)) + 1]);
							else
								table.insert(OPTIONS, tonumber(option));
							end
						end
						table.insert(OPCODES, _G["a" .. opcode:upper()](unpack(OPTIONS)));
					end
				end
			end
		end
    end
    local chunk = aChunk(name or "MAIN", LOCALS, UPVALS, NUPS, NARGS, VFLAG, STACKS, CNAME)(OPCODES);
    return chunk;
end

function _G.parseLASM(str)
    local chunk = base(str);
    return chunk.Compile();
end
