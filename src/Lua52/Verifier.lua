local OpcodeChecks = {
	MOVE = function(f, i) 
		assert(i.C == 0, "MOVE.C must equal 0") 
		assert(i.A < f.MaxStackSize, "MOVE.A out of bounds") 
		assert(i.B < f.MaxStackSize, "MOVE.B out of bounds")
	end,
    
	LOADK = function(f, i)
		assert(i.A < f.MaxStackSize, "LOADK.A out of bounds")
		assert(i.Bx < f.Constants.Count, "LOADK.Bx out of bounds")
	end,
    
    LOADKX = function(f, i, i2)
        assert(f.Instructions[i2], "Opcode after LOADKX should be EXTRAARG")
        assert(f.Instructions[i2].Opcode == "EXTRAARG", "Opcode after LOADKX should be EXTRAARG")
        assert(i.A < f.MaxStackSize, "LOADKX.A out of bounds")
    end,
    
	LOADBOOL = function(f, i)
		assert(i.A < f.MaxStackSize, "LOADBOOL.A out of bounds")
		assert(i.B < 2, "LOADBOOL.B invalid value")
		assert(i.C < 2, "LOADBOOL.C invalid value")
	end,
	
    LOADNIL = function(f, i)
        assert(i.A < f.MaxStackSize, "LOADNIL.A out of bounds")
        assert(i.B < f.MaxStackSize, "LOADNIL.B out of bounds")
    end,
    
    GETUPVAL = function(f, i)
        assert(i.A < f.MaxStackSize, "GETUPVAL.A out of bounds")
        assert(i.B < f.Upvalues.Count or i.B < f.UpvalueCount, "GETUPVAL.B out of bounds")
    end,
    
    GETTABUP = function(f, i)
        assert(i.A < f.MaxStackSize, "GETGLOBAL.A out of bounds")
        assert(i.Bx < f.Constants.Count, "GETGLOBAL.Bx out of bounds")
    end,
    
    SETTABUP = function(f, i)
        assert(i.A < f.MaxStackSize, "SETGLOBAL.A out of bounds")
        assert(i.Bx < f.Constants.Count, "SETGLOBAL.Bx out of bounds")
    end,
    
    SETUPVAL = function(f, i)
        assert(i.A < f.MaxStackSize, "SETUPVAL.A out of bounds")
        assert(i.B < f.Upvalues.Count or i.B < f.UpvalueCount, "SETUPVAL.B out of bounds")
    end,
    
    GETTABLE = function(f, i)
        assert(i.A < f.MaxStackSize, "GETTABLE.A out of bounds")
        assert(i.B < f.MaxStackSize, "GETTABLE.B out of bounds")
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "GETTABLE.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "GETTABLE.C out of bounds")
        end
    end,
    
    SETTABLE = function(f, i)
        assert(i.A < f.MaxStackSize, "SETTABLE.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "SETTABLE.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "SETTABLE.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "SETTABLE.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "SETTABLE.C out of bounds")
        end
    end,
    
    ADD = function(f, i)
        assert(i.A < f.MaxStackSize, "ADD.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "ADD.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "ADD.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "ADD.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "ADD.C out of bounds")
        end
    end,
    
    SUB = function(f, i)
        assert(i.A < f.MaxStackSize, "SUB.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "SUB.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "SUB.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "SUB.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "SUB.C out of bounds")
        end
    end,
    
    MUL = function(f, i)
        assert(i.A < f.MaxStackSize, "MUL.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "MUL.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "MUL.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "MUL.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "MUL.C out of bounds")
        end
    end,
    
    DIV = function(f, i)
        assert(i.A < f.MaxStackSize, "DIV.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "DIV.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "DIV.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "DIV.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "DIV.C out of bounds")
        end
    end,
    
    MOD = function(f, i)
        assert(i.A < f.MaxStackSize, "MOD.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "MOD.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "MOD.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "MOD.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "MOD.C out of bounds")
        end
    end,
    
    POW = function(f, i)
        assert(i.A < f.MaxStackSize, "POW.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "POW.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "POW.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "POW.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "POW.C out of bounds")
        end
    end,
    
    UNM = function(f, i)
        assert(i.A < f.MaxStackSize, "UNM.A out of bounds")
        assert(i.B < f.MaxStackSize, "UNM.B out of bounds")
    end,
    
    NOT = function(f, i)
        assert(i.A < f.MaxStackSize, "NOT.A out of bounds")
        assert(i.B < f.MaxStackSize, "NOT.B out of bounds")
    end,
    
    LEN = function(f, i)
        assert(i.A < f.MaxStackSize, "LEN.A out of bounds")
        assert(i.B < f.MaxStackSize, "LEN.B out of bounds")
    end,
    
    CONCAT = function(f, i)
        assert(i.A < f.MaxStackSize, "CONCAT.A out of bounds")
        assert(i.B < f.MaxStackSize and i.B < i.C, "CONCAT.B out of bounds")
        assert(i.C < f.MaxStackSize, "CONCAT.C out of bounds")
    end,
    
    JMP = function(f, i, i2)
        if i.sBx < 0 then
            local tmp = f.Instructions.Count - (i2 - 1) + i.sBx + 1
            --print(i.sBx, tmp)
            --assert(tmp >= 0, "JMP.sBx out of bounds")
            assert(math.abs(i.sBx) >= f.Instructions.Count - i2, "JMP.sBx out of bounds")
            --assert(i.sBx >= i2 - f.Instructions.Count, "JMP.sBx out of bounds")
        else
            assert(i.sBx < (f.Instructions.Count - i2) + 1, "JMP.sBx out of bounds")
        end
    end,
    
    CALL = function(f, i)
        assert(i.A < f.MaxStackSize, "CALL.A out of bounds")
        assert(i.A + i.C - 2 < f.MaxStackSize, "CALL.C out of bounds")
        assert(i.A + i.B - 1 < f.MaxStackSize, "CALL.B out of bounds")
    end,
    
    RETURN = function(f, i)
        assert(i.A < f.MaxStackSize, "RETURN.A out of bounds")
        assert(i.A + i.B - 2 < f.MaxStackSize, "RETURN.B out of bounds")
        --assert(i.A <= i.B, "RETURN.A must be <= than RETURN.B")
    end,
    
    TAILCALL = function(f, i)
        assert(i.A < f.MaxStackSize, "TAILCALL.A out of bounds")
        assert(i.A + i.B - 1 < f.MaxStackSize, "TAILCALL.B out of bounds")
    end,
    
    VARARG = function(f, i)
        assert(i.A < f.MaxStackSize, "VARARG.A out of bounds")
        assert(i.A + i.B - 1 < f.MaxStackSize, "VARARG.B out of bounds")
        --assert(i.A <= i.B, "VARARG.A must be <= than VARARG.B")
    end,
    
    SELF = function(f, i)
        assert(i.A < f.MaxStackSize, "SELF.A out of bounds")
        assert(i.B < f.MaxStackSize, "SELF.B out of bounds")
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "SELF.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "SELF.C out of bounds")
        end
    end,
    
    EQ = function(f, i)
        assert(i.A == 0 or i.A == 1, "EQ.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "EQ.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "EQ.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "EQ.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "EQ.C out of bounds")
        end
    end,
    
    LT = function(f, i)
        assert(i.A == 0 or i.A == 1, "LT.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "LT.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "LT.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "LT.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "LT.C out of bounds")
        end
    end,
    
    LE = function(f, i)
        assert(i.A == 0 or i.A == 1, "LE.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "LE.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "LE.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "LE.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "LE.C out of bounds")
        end
    end,
    
    TEST = function(f, i)
        assert(i.A < f.MaxStackSize, "TEST.A out of bounds")
        assert(i.C < 2, "TEST.C out of bounds")
    end,
    
    TESTSET = function(f, i)
        assert(i.A < f.MaxStackSize, "TESTSET.A out of bounds")
        assert(i.B < f.MaxStackSize, "TESTSET.B out of bounds")
        assert(i.C < 2, "TESTSET.C out of bounds")
    end,
    
    FORPREP = function(f, i)
        assert(i.A + 2 < f.MaxStackSize, "FORPREP.A out of bounds")
        assert(i.sBx < f.Instructions.Count - 1, "FORPREP.sBx out of bounds")
    end,
    
    FORLOOP = function(f, i)
        assert(i.A + 3 < f.MaxStackSize, "FORLOOP.A out of bounds")
        assert(i.sBx < f.Instructions.Count, "FORLOOP.sBx out of bounds")
    end,
    
    TFORLOOP = function(f, i)
        assert(i.A + 3 < f.MaxStackSize, "TFORLOOP.A out of bounds")
        assert(i.A + 2 + i.C < f.Instructions.Count, "TFORLOOP.C out of bounds")
    end,
    
    NEWTABLE = function(f, i)
        assert(i.A < f.MaxStackSize, "NEWTABLE.A out of bounds")
    end,
    
    SETLIST = function(f, i)
        assert(i.A < f.MaxStackSize, "SETLIST.A out of bounds")
    end,
    
    CLOSURE = function(f, i)
        assert(i.A < f.MaxStackSize, "CLOSURE.A out of bounds")
        assert(i.Bx < f.Protos.Count, "CLOSURE.Bx out of bounds")
    end,
    
    EXTRAARG = function(f, i, i2)
        assert(f.Instructions[i2 - 2], "Opcode before EXTRAARG should be LOADKX")
        assert(f.Instructions[i2 - 2].Opcode == "LOADKX", "Opcode before EXTRAARG should be LOADKX")
        assert(i.Ax < f.Constants.Count, "EXTRAARG.Ax out of bounds")
    end,
    -- TODO
    -- TFORCALL
}
setmetatable(OpcodeChecks, {
    __index = function(t, k)
        return function() end 
    end
})

--function VerifyChunk(chunk)
return function(chunk)
    assert(chunk.MaxStackSize <= 255, "Invalid MaxStackSize " .. chunk.MaxStackSize .. ". It must be <=255")
    for i = 1, chunk.Instructions.Count do
        local instr = chunk.Instructions[i - 1]
        local func = OpcodeChecks[instr.Opcode:upper()]
        func(chunk, instr, i - 1)
    end
end
