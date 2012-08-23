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
        assert(i.B < f.Upvalues.Count, "Error: GETUPVAL.B out of bounds")
    end,
    
}
setmetatable(OpcodeChecks, {
    __index = function(t, k) 
        local x = rawget(t, k)
        if x then return x end
        return function() end 
    end
})

function VerifyChunk(chunk)
    for i = 1, chunk.Instructions.Count do
        local instr = chunk.Instructions[i - 1]
        local func = OpcodeChecks[instr.Opcode:upper()]
        func(chunk, instr)
    end
end
