------------31----------------------------0
--iABC :	A:8	B:9	C:9		Op:6
--iABx :	A:8	Bx:18		Op:6
--iAsBx :	A:8	sBx:18     	Op:6 

local p2 = {1,2,4,8,16,32,64,128,256, 512, 1024, 2048, 4096}
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
		return {TY="AsBx", OP=op, A=a, Bx=sbx}
	end,
	Encode = function(op)
		local c0, c1, c2, c3
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

function _G.CreateChunk()
	local chunk = {}
	-----
	local nargs = 0
	local vConstants = {}
	local nextConstantIndex = 1
	local vCode = {}
	local vProto = {}
	-----
	chunk.CompileChunk = function()
		--append header
		return "\027Lua\81\0\1\4\4\4\8\0"..chunk.Compile()
	end
	chunk.Compile = function()
		local body = ""
		body = body..DumpBinary.String("LuaCXX Source")
		body = body..DumpBinary.Integer(1) --first line
		body = body..DumpBinary.Integer(1) --last line
		body = body..DumpBinary.Int8(0) --upvalues
		body = body..DumpBinary.Int8(nargs) --arguments
		body = body..DumpBinary.Int8(0) --VARG_FLAG
		body = body..DumpBinary.Int8(4) --max stack size
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
		--add empty debug into
		body = body..DumpBinary.Integer(0)..DumpBinary.Integer(0)..DumpBinary.Integer(0)
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
	chunk.SetArguments = function(n)
		nargs = n
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

function _G.aChunk(chunkname, nargs)
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
			chunk.SetArguments(nargs or 0)
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
			return loadstring(self.buildchunk().CompileChunk())
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

function _G.aJMP(a, b)
	CheckAValue("aJMP", a)
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.AsBx(LuaOp.JMP, a, b))
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
	CheckIsProto(proto, "Argument #2 to aCLOSURE must be a function prototype")
	return CreateAnObject("instruction", function(self, chunk)
		chunk.pushop(CreateOp.ABx(LuaOp.CLOSURE, a, proto(chunk)))
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













