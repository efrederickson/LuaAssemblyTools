local LuaOpName = {
    "MOVE", "LOADK", "LOADKX", "LOADBOOL", "LOADNIL", "GETUPVAL", "GETTABUP",
    "GETTABLE", "SETTABUP", "SETUPVAL", "SETTABLE", "NEWTABLE", "SELF", 
    "ADD", "SUB", "MUL", "DIV", "MOD", "POW", "UNM", "NOT", "LEN", "CONCAT", 
    "JMP", "EQ", "LT", "LE", "TEST", "TESTSET", "CALL", "TAILCALL", "RETURN",
    "FORLOOP", "FORPREP", "TFORCALL", "TFORLOOP", "SETLIST", "CLOSURE", "VARARG",
    "EXTRAARG",
}

local LuaOpType = { iABC = "ABC", iABx = "ABx", iAsBx = "AsBx", iAx = "Ax" }

local LuaOpTypeLookup = {
    LuaOpType.iABC, -- MOVE
    LuaOpType.iABx, -- LOADK
    LuaOpType.iABx, -- LOADKX
    LuaOpType.iABC, -- LOADBOOL
    LuaOpType.iABC, -- LOADNIL
    LuaOpType.iABC, -- GETUPVAL
    LuaOpType.iABC, -- GETTABUP
    LuaOpType.iABC, -- GETTABLE
    LuaOpType.iABC, -- SETTABUP
    LuaOpType.iABC, -- SETUPVAL
    LuaOpType.iABC, -- SETTABLE
    LuaOpType.iABC, -- NEWTABLE
    LuaOpType.iABC, -- SELF
    LuaOpType.iABC, -- ADD
    LuaOpType.iABC, -- SUB
    LuaOpType.iABC, -- MUL
    LuaOpType.iABC, -- DIV
    LuaOpType.iABC, -- MOD
    LuaOpType.iABC, -- POW
    LuaOpType.iABC, -- UNM
    LuaOpType.iABC, -- NOT
    LuaOpType.iABC, -- LEN
    LuaOpType.iABC, -- CONCAT
    LuaOpType.iAsBx, -- JMP
    LuaOpType.iABC, -- EQ
    LuaOpType.iABC, -- LT
    LuaOpType.iABC, -- LE
    LuaOpType.iABC, -- TEST
    LuaOpType.iABC, -- TESTSET
    LuaOpType.iABC, -- CALL
    LuaOpType.iABC, -- TAILCALL
    LuaOpType.iABC, -- RETURN
    LuaOpType.iAsBx, -- FORLOOP
    LuaOpType.iAsBx, -- FORPREP
    LuaOpType.iABC, -- TFORCALL
    LuaOpType.iAsBx, -- TFORLOOP
    LuaOpType.iABC, -- SETLIST
    LuaOpType.iABx, -- CLOSURE
    LuaOpType.iABC, -- VARARG
    LuaOpType.iAx, -- EXTRAARG
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
    LOADKX = { 1, 0, 0 },
    LOADBOOL = { 1, 0, 0 },
    LOADNIL = { 1, 1, 1 },
    GETUPVAL = { 1, 4, 0 },
    GETTABUP = { 1, 4, 2 },
    GETTABLE = { 1, 1, 3 },
    SETTABUP = { 1, 4, 2 },
    SETUPVAL = { 1, 4, 5 },
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
    TFORCALL = { 1, 0, 1 }, -- TODO
    TFORLOOP = { 1, 5, 0 },
    SETLIST = { 1, 0, 0 },
    CLOSURE = { 1, 0, 0 },
    VARARG = { 1, 1, 0 },
    EXTRAARG = { 2, 0, 0 }, -- TODO: ??? It's a Constant index, right? so should they all be constant indexes or what?
}
local LuaOp = {
	MOVE = 0,
	LOADK = 1,
    LOADKX = 2,
	LOADBOOL = 3,
	LOADNIL = 4,
	GETUPVAL = 5,
	GETTABUP = 6,
	GETTABLE = 7,
	SETTABUP = 8,
	SETUPVAL = 9,
	SETTABLE = 10,
	NEWTABLE = 11,
	SELF = 12,
	ADD = 13,
	SUB = 14,
	MUL = 15,
	DIV = 16,
	MOD = 17,
	POW = 18,
	UNM = 19,
	NOT = 20,
	LEN = 21,
	CONCAT = 22,
	JMP = 23,
	EQ = 24,
	LT = 25,
	LE = 26,
	TEST = 27,
	TESTSET = 28,
	CALL = 29,
	TAILCALL = 30,
	RETURN = 31,
	FORLOOP = 32,
	FORPREP = 33,
    TFORCALL = 34,
	TFORLOOP = 35,
	SETLIST = 36,
	CLOSURE = 37,
	VARARG = 38,
    EXTRAARG = 39,
}

local Instruction = {
    new = function(self, opcode, num)
        opcode = (type(opcode) == "number" and opcode) or (opcode and LuaOp[opcode:upper()] and LuaOp[opcode:upper()] + 1) or error("Unknown opcode '" .. (opcode == nil and  "<nil>" or opcode) .. "'!")
        return setmetatable({ 
            A = 0,
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
    new = function(self, instack, idx, name)
        return setmetatable({ InStack = instack, Index = idx, Name = name or "",}, { __index = self })
        --return setmetatable({ Name = name }, { __index = self })
    end,
}

return { Instruction, Local, Constant, Upvalue }
