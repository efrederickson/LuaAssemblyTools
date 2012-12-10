local LuaOpName = {
    "MOVE", "LOADK", "LOADBOOL", "LOADNIL", "GETUPVAL", "GETGLOBAL",
    "GETTABLE", "SETGLOBAL", "SETUPVAL", "SETTABLE", "NEWTABLE", "SELF", 
    "ADD", "SUB", "MUL", "DIV", "MOD", "POW", "UNM", "NOT", "LEN", "CONCAT", 
    "JMP", "EQ", "LT", "LE", "TEST", "TESTSET", "CALL", "TAILCALL", "RETURN",
    "FORLOOP", "FORPREP", "TFORLOOP", "SETLIST", "CLOSE", "CLOSURE", "VARARG",
}

local LuaOpType = { iABC = "ABC", iABx = "ABx", iAsBx = "AsBx" }

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
    LuaOpType.iABC,
}

-- Parameter types (likely to change):
    -- Unused/Arbitrary  = 0
    -- Register 		 = 1
    -- Constant 		 = 2
    -- Constant/Register = 3
    -- Upvalue 			 = 4
    -- Jump Distace 	 = 5

local LuaOpcodeParams = {
    MOVE = { 1, 1, 0 },
    LOADK = { 1, 2, 0 },
    LOADBOOL = { 1, 0, 0 },
    LOADNIL = { 1, 1, 1 },
    GETUPVAL = { 1, 4, 0 },
    GETGLOBAL = { 1, 2, 0 },
    GETTABLE = { 1, 1, 3 },
    SETGLOBAL = { 1, 2, 0 },
    SETUPVAL = { 1, 4, 0 },
    SETTABLE = { 1, 3, 3 },
    NEWTABLE = { 1, 0, 0 },
    SELF = { 1, 1, 3 },
    ADD = { 1, 1, 3 },
    SUB = { 1, 1, 3 },
    MUL = { 1, 1, 3 },
    DIV = { 1, 1, 3 },
    MOD = { 1, 1, 3 },
    POW = { 1, 1, 3 },
    UNM = { 1, 1, 0 },
    NOT = { 1, 1, 0 },
    LEN = { 1, 1, 0 },
    CONCAT = { 1, 1, 1 },
    JMP = {0, 5, 0 },
    EQ = { 1, 3, 3 },
    LT = { 1, 3, 3 },
    LE = { 1, 3, 3 },
    TEST = { 1, 0, 1 },
    TESTSET = { 1, 1, 1 },
    CALL = { 1, 0, 0 },
    TAILCALL = { 1, 0, 0 },
    RETURN = { 1, 0, 0 },
    FORLOOP = { 1, 5, 0 },
    FORPREP = { 1, 5, 0 },
    TFORLOOP = { 1, 5, 0 },
    SETLIST = { 1, 0, 0 },
    CLOSE = { 1, 0, 0 },
    CLOSURE = { 1, 0, 0 },
    VARARG = { 1, 1, 0 },
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

local Instruction = {
    new = function(self, opcode, num)
        opcode = (type(opcode) == "number" and opcode) or (opcode and LuaOp[opcode:upper()] and LuaOp[opcode:upper()] + 1) or error("Unknown opcode '" .. (opcode == nil and  "<nil>" or opcode) .. "'!")
        return setmetatable({ 
            A = 0,
            Ax = 0,
            B = 0,
            C = 0,
            Bx = 0,
            sBx = 0,
            Opcode = LuaOpName[opcode],
            OpcodeNumber = opcode - 1,
            OpcodeType = LuaOpTypeLookup[opcode],
            OpcodeParams = LuaOpcodeParams[LuaOpName[opcode]],
            Number = num or 0,
            LineNumber = 0,
        }, { __index = self })
    end,
}

local Local = {
    new = function(self, name, spc, epc)
        return setmetatable({ Name = name, StartPC = spc, EndPC = epc }, { __index = self })
    end,
}

local Constant = { 
    new = function(self, type, val)
        return setmetatable({ Type = type, Value = val, Number = 0 }, { __index = self })
    end,
}

local Upvalue = {
    new = function(self, name)
        return setmetatable({ Name = name }, { __index = self })
    end,
}

return { Instruction, Local, Constant, Upvalue }
