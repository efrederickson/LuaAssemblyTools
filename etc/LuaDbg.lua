-- 
--		Thank you for choosing LuaDbg!
--			By: 					NecroBumpist
--			Latest Revision: 	v1.01 (27/5/2011)
--	
--		So, now a quick description of the LuaDbg library.
--		LuaDbg aims to provide a comprehensive set of tools to work with Lua Bytecode, 
--		regardless of whether or not you wish to work with the raw Bytecode, or Lua Assembly.
-- 	Now you might be asking, `What the heck is Lua Assembly or Bytecode,` so I'll tell you.
--
--		Many believe that Lua is interpreted, but it is infact a compiled language.
--		But the compilation of a Lua script is done usually when the script is first ran.
--		Lua does not compile to x86 assembly, but instead a special language aptly called
--		Lua assembly. Lua Assembly, or LASM, is ran by the LuaVM, and that's where the magic happens.
-- 	
--		I'll spare most of you the boring discussion of LASM, but incase you want to learn it,
--		I suggest you read the 'ANoFrillsIntroToLua51VMInstructions.pdf' document, aviable on the
--		LuaForge website.
--
--		In this short README file, I will only cover the basic usage of the Rip(), and Debug() functions.
-- 	I will document more of the Assemble() and Disassemble() functions at a later time.

-- 			## SPECIAL NOTE: 	RobloxApp.exe does not properly display tabs, so the Debug()
--				## 					function does not work entirely as inteded.
--[[
-- Rip()
repeat
	wait();					-- Wait for the library.
until _G.lasm
local lasm = _G.lasm;

local function test()	-- Create an example function prototype.
	local d = "4";
	
	return (function()
		local a, b, c = "1", "2", "3";
		return a .. b .. c .. d;
	end)()
end

local a = string.dump(test);		-- Dump the example function into bytecode.
local b = lasm.Rip(a);				--	Remove the bytecode's debug information.

print("Function length with debug info: " .. #a);
print("Function length without debug info: " .. #b);

print(loadstring(a)())				-- Confirm both functions work properly
print(loadstring(b)())				-- Should print 'abcd'


-- Debug()
repeat
	wait();					-- Wait for the library.
until _G.lasm
local lasm = _G.lasm;

local function test()	-- Create an example function prototype.
	local d = "4";
	
	return (function()
		local a, b, c = "1", "2", "3";
		return a .. b .. c .. d;
	end)()
end

local a = string.dump(test);		-- Dump the example function into bytecode.
lasm.Debug(a);							-- Disassemble the function, printing everything out;
]]
-- Proper Output (I think, tabbed this out by hand)
--[[
LuaDbg.lua
[Chunk Header]
	Identifier: Lua
	Version: 0x51
	Format: Official
	Endianness: Litte
	Integer Size: 4 bytes
	String Size Size: 4 bytes
	Instruction Size: 4 bytes
	Number Size: 8 bytes
	Number Type: Floating Point
	[Main]
		Name: "=Workspace.LuaDbg.README" Lines: 55-62
		Upvalues: 0 Arguments: 0 VargFlag: 0 MaxStackSize: 2
		[Instructions] Count: 6
			[1] (56) Opcode: LOADK 0 0 ; ![d] ('4')
			[2] (61) Opcode: CLOSURE 1 0 ; 1 0
			[3] (61) Opcode: MOVE 0 0 0 ; [d] [d] 0
			[4] (61) Opcode: TAILCALL 1 1 0 ; 1 1 0
			[5] (61) Opcode: RETURN 1 0 0 ; 1 0 0
			[6] (62) Opcode: RETURN 0 1 0 ; 0 1 0
		[Constants] Count: 1
			[0] Type: (String) "4"
		[Locals] Count: 1
			[0] SPC: 1 EPC: 5 Name: "d"
		[Upvalues] Count:0
		[Prototypes] Count: 1
		[0]
			Name: "" Lines: 58-61
			Upvalues: 1 Arguments: 0 VargFlag: 0 MaxStackSize: 7
			[Instructions] Count: 10
				[1] (59) Opcode: LOADK 0 0 ; 0 ('1')
				[2] (59) Opcode: LOADK 1 1 ; 1 ('2')
				[3] (59) Opcode: LOADK 2 2 ; ![c] ('3')
				[4] (60) Opcode: MOVE 3 0 0 ; 3 [a] 0
				[5] (60) Opcode: MOVE 4 1 0 ; 4 [b] 0
				[6] (60) Opcode: MOVE 5 2 0 ; 5 [c] 0
				[7] (60) Opcode: GETUPVAL 6 0 0 ; 6 <d> 0
				[8] (60) Opcode: CONCAT 3 3 6 ; 3 3 6
				[9] (60) Opcode: RETURN 3 2 0 ; 3 2 0
				[10] (61) Opcode: RETURN 0 1 0 ; 0 1 0
			[Constants] Count: 3
				[0] Type: (String) "1"
				[1] Type: (String) "2"
				[2] Type: (String) "3"
			[Locals] Count: 3
				[0] SPC: 3 EPC: 9 Name: "a"
				[1] SPC: 3 EPC: 9 Name: "b"
				[2] SPC: 3 EPC: 9 Name: "c"
			[Upvalues] Count:1
				[0] Name: "d"
			[Prototypes] Count: 0
]]



-- 
--				QUICK OVERVIEW OF Debug() OUTPUT;
--
--		Steps:
--			- Print out the information contained in the 12 byte header
--			- Begin debuging of the main function prototype
--				- Print the Function name, lines, and several VM specifications
--				- Print out the instructions
--					- [Opcode Number] (Line Number)	Opcode: <opcode name> <parameters>; parameter description
--						- ('') 	= constants
--						- <>		= upvalues
--						- [] 		= predefined local register
--						- ![] 	= newly defined local register
--				- Print out the constants
--				- Print out locals
--				- Print out upvalues
--				- Recursively debug prototypes
--

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
iABC = "ABC";
iABx = "ABx";
iAsBx = "AsBx";
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
LuaOpType.iABC, --self = xLEGOx's Question (ABC works)
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

local LuaOpcodeParams = {
["MOVE"] = {1, 1, 0};
["LOADK"] = {1, 2};
["LOADBOOL"] = {1, 0, 0};
["LOADNIL"] = {1, 1, 1};
["GETUPVAL"] = {1, 4};
["GETGLOBAL"] = {1, 2};
["GETTABLE"] = {1, 1, 3};
["SETGLOBAL"] = {1, 2};
["SETUPVAL"] = {1, 4};
["SETTABLE"] = {1, 3, 3};
["NEWTABLE"] = {1, 0, 0};
["SELF"] = {1, 1, 3};
["ADD"] = {1, 1, 3};
["SUB"] = {1, 1, 3};
["MUL"] = {1, 1, 3};
["DIV"] = {1, 1, 3};
["MOD"] = {1, 1, 3};
["UNM"] = {1, 1, 0};
["NOT"] = {1, 1, 0};
["LEN"] = {1, 1, 0};
["CONCAT"] = {1, 1, 1};
["JMP"] = {0, 5};
["EQ"] = {1, 3, 3};
["LT"] = {1, 3, 3};
["LE"] = {1, 3, 3};
["TEST"] = {1, 0, 1};
["TESTSET"] = {1, 1, 1};
["CALL"] = {1, 0, 0};
["TAILCALL"] = {1, 0, 0};
["RETURN"] = {1, 0, 0};
["FORLOOP"] = {1, 5};
["FORPREP"] = {1, 5};
["TFORLOOP"] = {1, 0};
["SETLIST"] = {1, 0, 0};
["CLOSE"] = {1, 0, 0};
["CLOSURE"] = {1, 0};
["VARARG"] = {1, 1, 0}
}

bit = {
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

local OpcodeEncode = function(op)
	local c0, c1, c2, c3
	if op.OpcodeType == "AsBx" then op.Bx = op.sBx + 131071 op.OpcodeType = "ABx" end
	if op.OpcodeType == "ABx" then op.C = keep(op.Bx, 9); op.B = srb (op.Bx, 9) end
	c0 = LuaOp[op.Opcode] + slb(keep(op.A, 2), 6)
	c1 = srb(op.A, 2) + slb(keep(op.C, 2), 6)
	c2 = srb(op.C, 2) + slb(keep (op.B, 1), 7)
	c3 = srb(op.B, 1)
	return string.char(c0, c1, c2, c3)
end

local OpcodeChecks = {
	MOVE = function(tab, ins) 
		assert(ins.C == 0, "Err: MOVE.C must equal 0") 
		assert(ins.A < tab.MaxStackSize, "Err: MOVE.A out of bounds") 
		assert(ins.B < tab.MaxStackSize, "Err: MOVE.B out of bounds")
	end,
	LOADK = function(tab, ins)
		assert(ins.A < tab.MaxStackSize, "Err: LOADK.A out of bounds")
		assert(ins.Bx < tab.NumberOfConstants, "Err: LOADK.Bx out of bounds")
	end,
	LOADBOOL = function(tab, ins)
		assert(ins.A < tab.MaxStackSize, "Err: LOADBOOL.A out of bounds");
		assert(ins.B < 2, "Err: LOADBOOL.B invalid value");
		assert(ins.C < 2, "Err: LOADBOOL.C invalid value");
	end,
	
}
setmetatable(OpcodeChecks, {__index = function() return function() end end})

local DumpBinary
DumpBinary = {
	String = function(s)
		if #s ~= 0 then
			return DumpBinary.Int32(#s+1)..s.."\0"
		else
			return "\0\0\0\0";
		end
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

local function Disassemble(chunk)
	local index = 1
	local tab = {}
	local big = false;
	
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
		local a = GetInt32()
		local b = GetInt32()
		if a == b and a == 0 then
			return 0;
		else
			return (-2*bit.get(b, 32)+1)*(2^(bit.get(b, 21, 31)-1023))*((bit.get(b, 1, 20)*(2^32) + a)/(2^52)+1)
		end
	end
	
	local function GetString(len)
		local str = chunk:sub(index, index+len-1)
		index = index + len
		return str
	end
	
	local function GetTypeInt()
		local a = GetInt8()
		local b = GetInt8()
		local c = GetInt8()
		local d = GetInt8()
		return d*16777216 + c*65536 + b*256 + a
	end
	local function GetTypeString()
		local tmp = GetInt32()
		if tab.SizeT == 8 then GetInt32() end
		return GetString(tmp)
	end
	local function GetTypeFunction()
		local tab = {}
		tab.Name = GetTypeString():sub(1, -2);
		tab.FirstLine = GetTypeInt();
		tab.LastLine = GetTypeInt();
		GetInt8() -- Upvalues
		tab.Arguments = GetInt8();
		tab.VargFlag = GetInt8()
		tab.MaxStackSize = GetInt8()
		

		do
			local instructions = {};
			local num = GetInt32()
			
			tab.NumberOfInstructions = num;
			instructions.Count = num;

			for i = 1, num do
				local instr = {};
				local op = GetInt32();
				local opcode = bit.get(op, 1, 6)
				instr.Number = i;
				instr.Opcode =  LuaOpName[opcode+1]
				instr.OpcodeType = LuaOpTypeLookup[opcode+1]
				if instr.OpcodeType == "ABC" then
					instr.A = bit.get(op, 7, 14)
					instr.B = bit.get(op, 24, 32)
					instr.C = bit.get(op, 15, 23)
				elseif instr.OpcodeType == "ABx" then
					instr.A = bit.get(op, 7, 14)
					instr.Bx = bit.get(op, 15, 32)
				elseif instr.OpcodeType == "AsBx" then
					instr.A = bit.get(op, 7, 14)
					instr.sBx = bit.get(op, 15, 32) - 131071
				end
				
				instructions[i-1] = instr;
			end
			
			tab.Instructions = instructions;
		end
		
		do	
			local constants = {};
			local num = GetInt32()
			
			tab.NumberOfConstants = num;
			constants.Count = num;
	
			for i = 1, num do
				local k = {};
				local ty = GetInt8()
				
				k.Number = i-1;
				
				if ty == 0 then
					k.ConstantType = "nil";
					k.Value = ""
				elseif ty == 1 then
					k.ConstantType = "Bool"
					k.Value = GetInt8() ~= 0
				elseif ty == 3 then
					k.ConstantType = "Number"
					k.Value = GetFloat64();
				elseif ty == 4 then
					k.ConstantType = "String"
					k.Value = GetTypeString():sub(1,-2);
				end
				constants[i-1] = k;
			end
			tab.Constants = constants;
		end
		
		do
			local protos = {};
			local num = GetInt32()
			
			tab.NumberOfProtos = num;
			protos.Count = num;
			
			for i = 1, num do
				protos[i-1] = GetTypeFunction()
			end
			
			tab.Protos = protos
		end
		do
			local numsrc = GetInt32()

			for i = 1, numsrc do 
				tab.Instructions[i-1].LineNumber = GetInt32();
			end

			local locals = {};
			local numlocal = GetInt32()
			tab.NumberOfLocals = numlocal;
			locals.Count = numlocal;
			tab.Locals = locals;
			
			for i = 1, numlocal do
				locals[i-1] = {
					Name = GetTypeString():sub(1,-2),
					SPC = GetInt32(),
					EPC = GetInt32(),
				};
			end

			local numups = GetInt32()
			local ups = {Count = numups}
			tab.NumberOfUpvalues = numups;
			tab.Upvalues = ups;
			
			for i = 1, numups do 
				ups[i-1] = {Name = GetTypeString():sub(1, -2)};
			end
		end
		
		return tab;
	end
	
	tab.Identifier = GetString(4)
	tab.Version = GetInt8()
	tab.Format = GetInt8() == 0 and "Official" or "Unofficial"
	tab.BigEndian = GetInt8() == 0
	tab.IntSize = GetInt8()
	tab.SizeT = GetInt8() 	
	tab.InstructionSize = GetInt8()
	tab.NumberSize = GetInt8()
	tab.FloatingPoint = GetInt8() == 0
	tab.Main = GetTypeFunction()
	return tab;
end


local function Assemble(tab)
	local chunk = "";
	local function recurse(tab)
		chunk = chunk .. DumpBinary.String(assert(tab.Name, "Invalid Prototype; proto.Name (nil)"));
		chunk = chunk .. DumpBinary.Int32(assert(tab.FirstLine, "Invalid Prototype; proto.FirstLine (nil)"));
		chunk = chunk .. DumpBinary.Int32(assert(tab.LastLine, "Invalid Prototype; proto.LastLine (nil"));
		chunk = chunk .. DumpBinary.Int8(assert(tab.NumberOfUpvalues, "Invalid Prototype; proto.NumberOfUpvalues (nil)"))
		chunk = chunk .. DumpBinary.Int8(assert(tab.Arguments, "Invalid Prototype; proto.Arguments (nil)"))
		chunk = chunk .. DumpBinary.Int8(assert(tab.VargFlag, "Invalid Prototype; proto.VargFlag (nil)"))
		chunk = chunk .. DumpBinary.Int8(assert(tab.MaxStackSize, "Invalid Prototype; proto.MaxStackSize (nil)"))
		
		chunk = chunk .. DumpBinary.Int32(assert(tab.NumberOfInstructions, "Invalid Prototype; proto.NumberOfInstructions (nil)"))
		for i=1, tab.NumberOfInstructions do
			local ins = tab.Instructions[i-1]
			OpcodeChecks[ins.Opcode](tab, ins)
			chunk = chunk .. OpcodeEncode(ins)
		end
		chunk = chunk .. DumpBinary.Int32(assert(tab.NumberOfConstants, "Invalid Prototype; proto.NumberOfConstants (nil)"))
		for i=1, tab.NumberOfConstants do
			local k = tab.Constants[i-1]
			if k.ConstantType == "nil" then
				chunk = chunk .. DumpBinary.Int8(0);
			elseif k.ConstantType == "Bool" then
				chunk = chunk .. DumpBinary.Int8(1)
				chunk = chunk .. DumpBinary.Int8(k.Value and 1 or 0)
			elseif k.ConstantType == "Number" then
				chunk = chunk .. DumpBinary.Int8(3)
				chunk = chunk .. DumpBinary.Float64(k.Value)
			elseif k.ConstantType == "String" then
				chunk = chunk .. DumpBinary.Int8(4)
				chunk = chunk .. DumpBinary.String(k.Value)
			end
		end
		chunk = chunk .. DumpBinary.Integer(assert(tab.NumberOfProtos, "Invalid Prototype; proto.NumberOfProtos (nil)"))
		for i=1, tab.NumberOfProtos do
			recurse(tab.Protos[i-1])
		end
		
		chunk = chunk .. DumpBinary.Int32(tab.NumberOfInstructions)
		for i=1, tab.NumberOfInstructions do
			chunk = chunk .. DumpBinary.Int32(assert(tab.Instructions[i-1].LineNumber, "Invalid Instruction; instr.LineNumber (nil)"))
		end
		
		chunk = chunk .. DumpBinary.Int32(assert(tab.NumberOfLocals, "Invalid Prototype; proto.NumberOfLocals (nil)"));
		for i=1, tab.NumberOfLocals do
			local l = tab.Locals[i-1];
			chunk = chunk .. DumpBinary.String(assert(l.Name, "Invalid Local; local.Name (nil)"))
			chunk = chunk .. DumpBinary.Int32(assert(l.SPC, "Invalid Local; local.SPC (nil)"))
			chunk = chunk .. DumpBinary.Int32(assert(l.EPC, "Invalid Local; local.EPC (nil)"))
		end
		
		chunk = chunk .. DumpBinary.Int32(assert(tab.NumberOfUpvalues, "Invalid Prototype; proto.NumberOfUpvalues (nil)"))
		for i=1, tab.NumberOfUpvalues do
			chunk = chunk .. DumpBinary.String(assert(tab.Upvalues[i-1].Name, "Invalid Upvalue; upval.Name (nil)"));
		end
	end
	
	chunk = chunk .. '\27Lua\81\0\1\4\4\4\8\0'
	recurse(tab.Main)
	
	return chunk;
end

local function Debug(bytecode)
	local chunk = Disassemble(bytecode);
	local xprint = print;
	local indent = 1;
	local last = true;
	
	local function print(n, ...)
		xprint(("\t"):rep(n) .. table.concat({...}, ""));
	end
	
	local function getSpec(chunk, instr, a, b, c)
		local rules = LuaOpcodeParams[instr.Opcode];
		if rules[b] == 1 then
			if a < chunk.NumberOfLocals then
				if chunk.Locals[a].SPC < c and chunk.Locals[a].EPC >= c then
					return "[" .. chunk.Locals[a].Name .."]"
				elseif chunk.Locals[a].SPC == c then
					return "![" .. chunk.Locals[a].Name .."]"
				end
			end
		elseif rules[b] == 2 then
				local k= chunk.Constants[a];
				if k.ConstantType == "String" then
					return "(\'" ..k.Value  .."\')"
				elseif k.ConstantType == "nil" then
					return "(nil)"
				else
					return "("..tostring(k.Value)..")";
				end		
		elseif rules[b] == 3 then
			if a >= 256 then
				local k= chunk.Constants[a-256];
				if k.ConstantType == "String" then
					return "(\'" ..k.Value  .."\')"
				elseif k.ConstantType == "nil" then
					return "(nil)"
				else
					return "("..tostring(k.Value)..")";
				end	
			else
				if a < chunk.NumberOfLocals then
					if chunk.Locals[a].SPC <= c and chunk.Locals[a].EPC >= c then
						return "[" .. chunk.Locals[a].Name .."]"
					end
				end
			end
		elseif rules[b] == 4 then
			return "<"..(chunk.Upvalues[a] and chunk.Upvalues[a].Name or "")..">";
		elseif rules[b] == 5 then
			return "to [" .. c+a+1 .. "]";
		end
		
		return a;
	end
	
	local function printInstructions(indent, chunk)
		print(indent-1, "[Instructions] \tCount: ",chunk.Instructions.Count)
		for i=1, chunk.Instructions.Count do
			local instr = chunk.Instructions[i-1]
			
			if instr.OpcodeType == "ABC" then
				local a, b, c = instr.A, instr.B, instr.C
				local _a = getSpec(chunk, instr, a, 1, i)
				local _b = getSpec(chunk, instr, b, 2, i)
				local _c = getSpec(chunk, instr, c, 3, i)
				
				print(indent,"[",i,"] (",instr.LineNumber or 0,")\tOpcode: ", instr.Opcode,#instr.Opcode==4 and "\t\t" or #instr.Opcode< 4  and "\t\t" or "\t",
				a,"\t",b,"\t",c,"\t; ",_a,"\t ",_b,"\t ",_c)
			elseif instr.OpcodeType == "ABx" then
				local a, bx = instr.A, instr.Bx;
				local _a = getSpec(chunk, instr, a, 1, i)
				local _bx = getSpec(chunk, instr, bx, 2, i)
				
				print(indent,"[",i,"] (",instr.LineNumber or 0,")\tOpcode: ",instr.Opcode,#instr.Opcode == 5 and "\t\t" or #instr.Opcode<=4 and "\t\t\t" or "\t",a,"\t",bx,
				"\t\t; ",_a,"\t ",_bx)
			elseif instr.OpcodeType == "AsBx" then
				local a, sbx = instr.A, instr.sBx;
				local _a, _sbx = getSpec(chunk, instr, a, 1, i), getSpec(chunk, instr, sbx, 2, i);
				if #instr.Opcode == 7 then
					print(indent,"[",i,"] (",instr.LineNumber or 0,")\tOpcode: ",instr.Opcode,"\t",a,"\t",sbx,"\t\t; ",_a,"\t",_sbx)
				else
					print(indent,"[",i,"] (",instr.LineNumber or 0,")\tOpcode: ",instr.Opcode,"\t\t",a,"\t",sbx,"\t\t; ",_a,"\t",_sbx)
				end
			end
		end
	end
	
	local function printConstants(indent, chunk)
		print(indent-1, "[Constants] \tCount: ", chunk.Constants.Count)
		for i=0, chunk.Constants.Count-1 do
			local k = chunk.Constants[i];
			if k.ConstantType == "String" then
				print(indent,"[",i,"]\tType: (",k.ConstantType,")\t\"",k.Value,"\"")
			else
				print(indent,"[",i,"]\tType: (",k.ConstantType,")\t",tostring(k.Value))
			end
		end
	end
	
	local function printLocals(indent, chunk)
		print(indent-1, "[Locals]\t\tCount: ", chunk.Locals.Count)
		for i=0, chunk.Locals.Count-1 do
			local l = chunk.Locals[i];
			print(indent,"[",i,"]\t","SPC:\t",l.SPC,"\tEPC:\t",l.EPC,"\tName: \"", l.Name,"\"")
		end
	end
	
	local function printUpvalues(indent, chunk)
		print(indent-1, "[Upvalues]\tCount:", chunk.Upvalues.Count)
		for i=0, chunk.Upvalues.Count-1 do
			print(indent,"[",i,"]\tName: \"",chunk.Upvalues[i].Name,"\"")
		end
	end
	
	local function printProto(indent, proto)
		print(indent, "Name: \"", proto.Name, "\"\tLines: ",proto.FirstLine, "-", proto.LastLine)
		print(indent, "Upvalues: ", proto.Upvalues.Count, "\tArguments: ", proto.Arguments, "\tVargFlag: ", proto.VargFlag, "\tMaxStackSize: ", proto.MaxStackSize)
		printInstructions(indent+1, proto)
		printConstants(indent+1, proto)		
		printLocals(indent+1, proto)		
		printUpvalues(indent+1, proto)
		
		print(indent, "[Prototypes]\tCount: ", proto.Protos.Count)
		for i=0, proto.Protos.Count-1 do
			print(indent,"[", i,"]")
			printProto(indent+1, proto.Protos[i])
		end
	end
	
	print(0, "LuaDbg.lua")
	print(0, "")
	print(0, "[Chunk Header]")
	print(1, "Identifier: ", chunk.Identifier)
	print(1, "Version: ", ("0x%02X"):format(chunk.Version))
	print(1, "Format: ", chunk.Format)
	print(1, "Endianness: ", chunk.BigEndian and "Big" or "Litte")
	print(1, "Integer Size: ", chunk.IntSize," bytes")
	print(1, "String Size Size: ", chunk.SizeT," bytes")
	print(1, "Instruction Size: ", chunk.InstructionSize," bytes")
	print(1, "Number Size: ", chunk.NumberSize, " bytes")
	print(1, "Number Type: ", chunk.FloatingPoint and "Floating Point" or "Integer")
	print(0, "")
	print(0, "[Main]")
	printProto(indent, chunk.Main)
end

local function Rip(input)
	assert(type(input) == "string", "string DebugRip::Rip(string Bytecode) Invalid Parameter");
	local disassembly = Disassemble(input);
	
	local function recurse(proto)
		proto.Name = "";
		proto.FirstLine = 0;
		proto.LastLine = 0;
		
		for i = 0, proto.NumberOfInstructions - 1 do
			proto.Instructions[i].LineNumber = 0;
		end
		
		proto.NumberOfLocals = 0;
		proto.Locals = {Count = 0};
		
		for i = 0, proto.NumberOfProtos -1 do
			recurse(proto.Protos[i])
		end
		
		
		for i = 0, proto.NumberOfUpvalues -1 do
			proto.Upvalues[i] = {Name = ""};
		end
	end
	
	recurse(disassembly.Main);
	
	return Assemble(disassembly)
end

_G.lasm = {Disassemble = Disassemble, Assemble = Assemble, Debug = Debug, Rip = Rip};

-- ADDED FOR NON-ROBLOX USE
if arg then
    if #arg == 0 then
        error("Invalid usage!")
    end
    options = { Debug = true, Rip = false, File = "" }
    for i = 1, #arg do
        local a = arg[i]
        if a:lower() == "--debug" then
            options.Debug = true
        elseif a:lower() == "--nodebug" then
            options.Debug = false
        elseif a:lower() == "--rip" then
            options.Rip = true
        else
            options.File = a
        end
    end
    local source = io.open(options.File, "rb"):read("*a")
    if options.Debug then
        _G.lasm.Debug(source)
    end
    if options.Rip then
        print(_G.lasm.Rip(source))
    end
end
