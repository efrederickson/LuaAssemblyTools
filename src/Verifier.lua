local OpcodeChecks = {
	MOVE = function(f, i) 
		assert(i.C == 0, "Error: MOVE.C must equal 0") 
		assert(i.A < f.MaxStackSize, "Error: MOVE.A out of bounds") 
		assert(i.B < f.MaxStackSize, "Error: MOVE.B out of bounds")
	end,
    
	LOADK = function(f, i)
		assert(i.A < f.MaxStackSize, "Error: LOADK.A out of bounds")
		assert(i.Bx < f.Constants.Count, "Error: LOADK.Bx out of bounds")
	end,
    
	LOADBOOL = function(f, i)
		assert(i.A < f.MaxStackSize, "Error: LOADBOOL.A out of bounds")
		assert(i.B < 2, "Error: LOADBOOL.B invalid value")
		assert(i.C < 2, "Error: LOADBOOL.C invalid value")
	end,
	
    LOADNIL = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: LOADNIL.A out of bounds")
        assert(i.b < f.MaxStackSize, "Error: LOADNIL.B out of bounds")
    end,
    
    GETUPVAL = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: GETUPVAL.A out of bounds")
        assert(i.B < f.Upvalues.Count or i.B < f.UpvalueCount, "Error: GETUPVAL.B out of bounds")
    end,
    
    GETGLOBAL = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: GETGLOBAL.A out of bounds")
        assert(i.Bx < f.Constants.Count, "Error: GETGLOBAL.Bx out of bounds")
    end,
    
    SETGLOBAL = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: SETGLOBAL.A out of bounds")
        assert(i.Bx < f.Constants.Count, "Error: SETGLOBAL.Bx out of bounds")
    end,
    
    SETUPVAL = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: SETUPVAL.A out of bounds")
        assert(i.B < f.Upvalues.Count or i.B < f.UpvalueCount, "Error: SETUPVAL.B out of bounds")
    end,
    
    GETTABLE = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: GETTABLE.A out of bounds")
        assert(i.B < f.MaxStackSize, "Error: GETTABLE.B out of bounds")
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "Error: GETTABLE.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "Error: GETTABLE.C out of bounds")
        end
    end,
    
    SETTABLE = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: SETTABLE.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "Error: SETTABLE.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "Error: SETTABLE.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "Error: SETTABLE.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "Error: SETTABLE.C out of bounds")
        end
    end,
    
    ADD = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: ADD.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "Error: ADD.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "Error: ADD.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "Error: ADD.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "Error: ADD.C out of bounds")
        end
    end,
    
    SUB = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: SUB.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "Error: SUB.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "Error: SUB.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "Error: SUB.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "Error: SUB.C out of bounds")
        end
    end,
    
    MUL = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: MUL.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "Error: MUL.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "Error: MUL.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "Error: MUL.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "Error: MUL.C out of bounds")
        end
    end,
    
    DIV = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: DIV.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "Error: DIV.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "Error: DIV.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "Error: DIV.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "Error: DIV.C out of bounds")
        end
    end,
    
    MOD = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: MOD.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "Error: MOD.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "Error: MOD.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "Error: MOD.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "Error: MOD.C out of bounds")
        end
    end,
    
    POW = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: POW.A out of bounds")
        if i.B < 256 then
            assert(i.B < f.MaxStackSize, "Error: POW.B out of bounds")
        else
            assert(i.B - 256 < f.Constants.Count, "Error: POW.B out of bounds")
        end
        if i.C < 256 then
            assert(i.C < f.MaxStackSize, "Error: POW.C out of bounds")
        else
            assert(i.C - 256 < f.Constants.Count, "Error: POW.C out of bounds")
        end
    end,
    
    UNM = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: UNM.A out of bounds")
        assert(i.B < f.MaxStackSize, "Error: UNM.B out of bounds")
    end,
    
    NOT = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: NOT.A out of bounds")
        assert(i.B < f.MaxStackSize, "Error: NOT.B out of bounds")
    end,
    
    LEN = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: LEN.A out of bounds")
        assert(i.B < f.MaxStackSize, "Error: LEN.B out of bounds")
    end,
    
    CONCAT = function(f, i)
        assert(i.A < f.MaxStackSize, "Error: CONCAT.A out of bounds")
        assert(i.B < f.MaxStackSize and i.B < i.C, "Error: CONCAT.B out of bounds")
        assert(i.C < f.MaxStackSize, "Error: CONCAT.C out of bounds")
    end,
    
    JMP = function(f, i, i2)
        if i.sBx < 0 then
            --assert(i.sBx >= i2 - f.Instructions.Count, "Error:JMP.sBx out of bounds")
        else
            assert(i.sBx < (f.Instructions.Count - i2) + 1, "Error:JMP.sBx out of bounds")
        end
    end,
    
    -- TODO:
    -- CALL A B C R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
    -- RETURN A B return R(A), ... ,R(A+B-2)
    -- TAILCALL A B C return R(A)(R(A+1), ... ,R(A+B-1))
    -- VARARG A B R(A), R(A+1), ..., R(A+B-1) = vararg
    -- SELF A B C R(A+1) := R(B); R(A) := R(B)[RK(C)]
    -- EQ A B C if ((RK(B) == RK(C)) ~= A) then PC++
    -- LT A B C if ((RK(B) < RK(C)) ~= A) then PC++
    -- LE A B C if ((RK(B) <= RK(C)) ~= A) then PC++
    -- TEST A C if not (R(A) <=> C) then PC++
    -- TESTSET A B C if (R(B) <=> C) then R(A) := R(B) else PC++
    -- FORPREP A sBx R(A) -= R(A+2); PC += sBx
    -- FORLOOP A sBx R(A) += R(A+2)
    --    if R(A) <?= R(A+1) then {
    --    PC += sBx; R(A+3) = R(A)
    -- }
    -- TFORLOOP A C R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
    --    if R(A+3) ~= nil then {
    --    R(A+2) = R(A+3);
    --    } else {
    --    PC++;
    -- }
    -- NEWTABLE A B C R(A) := {} (array,hash = B,C)
    -- SETLIST A B C R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
    -- CLOSURE A Bx R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))
    -- CLOSE A close all variables in the stack up to (>=) R(A)
    
}
setmetatable(OpcodeChecks, {
    __index = function(t, k)
        return function() end 
    end
})

function VerifyChunk(chunk)
    assert(chunk.MaxStackSize <= 255, "Invalid MaxStackSize " .. chunk.MaxStackSize .. ". It must be <=255")
    for i = 1, chunk.Instructions.Count do
        local instr = chunk.Instructions[i - 1]
        local func = OpcodeChecks[instr.Opcode:upper()]
        func(chunk, instr, i - 1)
    end
end
