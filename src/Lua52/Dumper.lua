-- Mainly all LuaDbg code =P

local function Dump(file)
    local _print = print
	local indent = 1
	local last = true
	
	local function print(...) -- MWAHAHA HAX !!
        local function patch(...)
            local t = { ... }
            local r = { }
            for k, v in pairs(t) do r[k] = tostring(v) end
            return unpack(r)
        end
		_print(("\t"):rep(indent) .. table.concat({patch(...)}, ""))
	end
	
	local function getSpec(chunk, instr, a, b, c)
		local rules = instr.OpcodeParams
		if rules[b] == 1 then
			if a < chunk.Locals.Count then
				if chunk.Locals[a].StartPC < c and chunk.Locals[a].EndPC >= c then
					return "[" .. chunk.Locals[a].Name .."]"
				elseif chunk.Locals[a].StartPC == c then
					return "new [" .. chunk.Locals[a].Name .."]"
				end
			end
		elseif rules[b] == 2 then
				local k = chunk.Constants[a]
				if k.Type == "String" then
					return "(\'" ..k.Value  .."\')"
				elseif k.Type == "nil" then
					return "(nil)"
				else
					return "("..tostring(k.Value)..")";
				end		
		elseif rules[b] == 3 then
			if a >= 256 then
				local k= chunk.Constants[a-256]
				if k.Type == "String" then
					return "(\'" ..k.Value  .."\')"
				elseif k.Type == "nil" then
					return "(nil)"
				else
					return "("..tostring(k.Value)..")"
				end	
			else
				if a < chunk.Locals.Count then
					if chunk.Locals[a].StartPC <= c and chunk.Locals[a].EndPC >= c then
						return "[" .. chunk.Locals[a].Name .."]"
					end
				end
			end
		elseif rules[b] == 4 then
			return "<"..(chunk.Upvalues[a] and chunk.Upvalues[a].Name or "Unknown Upvalue")..">"
		elseif rules[b] == 5 then
			return "to [" .. c + a + 1 .. "]"
		end
		
		return a
	end
	
	local function dumpInstruction(chunk, instr, i)
        if instr.OpcodeType == "ABC" then
            local a, b, c = instr.A, instr.B, instr.C
            local _a = getSpec(chunk, instr, a, 1, i)
            local _b = getSpec(chunk, instr, b, 2, i)
            local _c = getSpec(chunk, instr, c, 3, i)
            
            print("[", i, "] (Line ", instr.LineNumber or 0, ")\tOpcode: ", instr.Opcode, "\t",
            a, "\t" ,b, "\t", c, "\t; ",_a, "\t ", _b, "\t ", _c)
        elseif instr.OpcodeType == "ABx" then
            local a, bx = instr.A, instr.Bx
            local _a = getSpec(chunk, instr, a, 1, i)
            local _bx = getSpec(chunk, instr, bx, 2, i)
            
            print("[", i, "] (Line ", instr.LineNumber or 0, ")\tOpcode: ", instr.Opcode, "\t", a, "\t" ,bx,
            "\t<nil>\t; ", _a, "\t ", _bx)
        elseif instr.OpcodeType == "AsBx" then
            local a, sbx = instr.A, instr.sBx
            local _a, _sbx = getSpec(chunk, instr, a, 1, i), getSpec(chunk, instr, sbx, 2, i);
            print("[", i, "] (Line ", instr.LineNumber or 0, ")\tOpcode: ", instr.Opcode, "\t", a, "\t", sbx, "\t<nil>\t; ", _a, "\t", _sbx)
        elseif instr.OpcodeType == "Ax" then
            local ax = instr.Ax
            local _ax = getSpec(chunk, instr, ax, 1, i)
            print("[", i, "] (Line ", instr.LineNumber or 0, ")\tOpcode: ", instr.Opcode, "\t", ax, "\t<nil>\t<nil>; ", _ax)
        end
	end
	
	local function dumpFunc(f)
		print("[Function ", (f.Name and (f.Name == "" and "<Unnamed>" or f.Name) or "<Unnamed>"), "]")
        indent = indent + 1
        print("Lines: ", f.FirstLine, " - ", f.LastLine)
        print("Upvalue count: ", f.UpvalueCount)
        print("Argument count: ", f.ArgumentCount)
        print("Vararg flag: ", f.Vararg)
        print("MaxStackSize: ", f.MaxStackSize)
        print("[Instructions, Count = ", f.Instructions.Count, "]")
        indent = indent + 1
        for i = 1, f.Instructions.Count do
            dumpInstruction(f, f.Instructions[i - 1], i)
        end
        indent = indent - 1
        print("[Constants, Count = ", f.Constants.Count, "]")
        indent = indent + 1
        for i = 1, f.Constants.Count do
            local constant = f.Constants[i - 1]
            if constant.Type == "Nil" then
                print("[Constant 'nil', Type = Nil]")
            else
                print("[Constant '", constant.Value, "', Type = ", constant.Type, "]")
            end
        end
        indent = indent - 1
        print("[Locals, Count = ", f.Locals.Count, "]")
        indent = indent + 1
        for i = 1, f.Locals.Count do
            local l = f.Locals[i - 1]
            print("[Local '", l.Name, "', StartPC = ", l.StartPC, " EndPC = ", l.EndPC, "]")
        end
        indent = indent - 1
        print("[Upvalues, Count = ", f.Upvalues.Count, "]")
        indent = indent + 1
        for i = 1, f.Upvalues.Count do  
            local upv = f.Upvalues[i - 1]
            print("[Upvalue '", upv.Name or "<unknown name>", "'\tInStack\tIndex:\t", upv.InStack, "\t", upv.Index, "]")
        end
        indent = indent - 1

        print("[Prototypes, Count: ", f.Protos.Count, "]")
        indent = indent + 1
        for i = 1, f.Protos.Count do
            dumpFunc(f.Protos[i - 1])
        end
        indent = indent - 2
	end

	print("[File Header]")
    if file.Identifier == "\027Lua" then
        print("Identifier: ", "<ESC>Lua")
    else
        print("Identifier (Invalid): ", file.Identifier)
    end
	print("Version: ", ("0x%02X"):format(file.Version))
	print("Format: ", file.Format)
	print("Little Endian: ", tostring(not file.BigEndian))
	print("Integer Size: ", file.IntegerSize)
	print("String Size: ", file.SizeT)
	print("Instruction Size: ", file.InstructionSize)
	print("Number Size: ", file.NumberSize)
	print("Number Type: ", file.IsFloatingPoint and "Floating Point" or "Integer")
	print("")
    print("[Main function]")
	dumpFunc(file.Main)
end

return Dump
