return function(file)
    local s = { }
    local indent = 0
    
    local function write(t)
        --s = s .. string.rep("    ", indent) .. t .. "\r\n"
        table.insert(s, string.rep("    ", indent) .. t .. "\r\n")
    end
    
    local function formatConst(c)
        if c.Type == "Nil" then
            return 'nil'
        elseif c.Type == "Bool" then
            return c.Value and "true" or "false"
        elseif c.Type == "Number" then
            return tostring(c.Value)
        elseif c.Type == "String" then
            local v = ""
            for i = 1, c.Value:len() do
                local ch = string.byte(c.Value, i)
                -- other chars with values > 31 are '"' (34), '\' (92) and > 126
                if ch < 32 or ch == 34 or ch == 92 or ch > 126 then
                    if ch >= 7 and ch <= 13 then
                        ch = string.sub("abtnvfr", ch - 6, ch - 6)
                    elseif ch == 34 or ch == 92 then
                        ch = string.char(ch)
                    end
                    v = v .. "\\" .. ch
                else-- 32 <= v <= 126 (NOT 255)
                    v = v .. string.char(ch)
                end
            end
            return "\"" .. v .. "\""
        end
    end
    
    local function formatArg(instr, argIndex, arg, proto)
        if instr.OpcodeParams[argIndex] == 2 then
            if arg >= 256 then
                arg = arg - 256
            end
            assert(proto.Constants[arg], tostring(instr.Opcode) .." " .. tostring(arg))
            assert(tonumber(arg))
            return formatConst(proto.Constants[arg])
        elseif instr.OpcodeParams[argIndex] == 3 then
            if arg >= 256 then
                arg = arg - 256
                assert(proto.Constants[arg], tostring(instr.Opcode) .." " .. tostring(arg))
                assert(tonumber(arg))
                return formatConst(proto.Constants[arg])
			else
				if arg < proto.Locals.Count then
					if proto.Locals[arg].StartPC <= c and proto.Locals[arg].EndPC >= c then
                        -- NOT IMPLEMENTED ...
						--return "local[" .. proto.Locals[arg].Name .."]"
					end
				end
			end
        end
        return arg
    end
    
    local function decompile(chunk)
        if chunk ~= file.Main then
            write("; Function " .. chunk.Name)
            write(".func")
            indent = indent + 1
        else
            write("; Main code")
        end
        write(".name \"" .. chunk.Name .. "\"")
        write(".options " .. chunk.UpvalueCount .. " " .. chunk.ArgumentCount .. " " .. chunk.Vararg .. " " .. chunk.MaxStackSize)
        write("; Above contains: Upvalue count, Argument count, Vararg flag, Max Stack Size")
        write""
        if chunk.Constants.Count > 0 then
            write("; Constants")
            for i = 1, chunk.Constants.Count do
                local c = chunk.Constants[i - 1]
                write(".const " .. formatConst(c))
            end
        end
        if chunk.Locals.Count > 0 then
            write("; Locals")
            for i = 1, chunk.Locals.Count do
                write(".local '" .. chunk.Locals[i - 1].Name .. "'")
            end
        end
        if chunk.Upvalues.Count > 0 then
            write("; Upvalues")
            for i = 1, chunk.Upvalues.Count do
                write(".upval '" .. chunk.Upvalues[i - 1].Name .. "' " .. chunk.Upvalues[i - 1].InStack .. " " .. chunk.Upvalues[i - 1].Index)
            end
        end
        write("; Instructions")
        for i = 1, chunk.Instructions.Count do
            local instr = chunk.Instructions[i - 1]
            if instr.OpcodeType == "ABC" then
                write(instr.Opcode:lower() .. " " .. formatArg(instr, 1, instr.A, chunk) .. 
                    " " .. formatArg(instr, 2, instr.B, chunk) .. 
                    " " .. formatArg(instr, 3, instr.C, chunk))
            elseif instr.OpcodeType == "ABx" then
                write(instr.Opcode:lower() .. " " .. formatArg(instr, 1, instr.A, chunk) .. " " .. formatArg(instr, 2, instr.Bx, chunk))
            elseif instr.OpcodeType == "AsBx" then
                write(instr.Opcode:lower() .. " " .. formatArg(instr, 1, instr.A, chunk) .. " " .. formatArg(instr, 2, instr.sBx, chunk))
            elseif instr.OpcodeType == "Ax" then
                write(instr.Opcode:lower() .. " " .. formatArg(instr, 1, instr.Ax, chunk))
            end
        end
        if chunk.Protos.Count > 0 then
            write("; Protos")
            write""
            for i = 1, chunk.Protos.Count do
                decompile(chunk.Protos[i - 1])
            end
        end
        if chunk ~= file.Main then
            indent = indent - 1
            write(".end")
        end
    end
    
    decompile(file.Main)
    return table.concat(s, "")
end
