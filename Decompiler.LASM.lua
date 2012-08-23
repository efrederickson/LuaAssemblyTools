Decompile = Decompile or { }
Decompile.LASM = function(file)
    local s = ""
    
    local function write(t)
        s = s .. t .. "\r\n"
    end
    
    local function decompile(chunk)
        write("; Function " .. chunk.Name)
        write(".func")
        write(".name \"" .. chunk.Name .. "\"")
        write(".options " .. chunk.UpvalueCount .. " " .. chunk.ArgumentCount .. " " .. chunk.Vararg .. " " .. chunk.MaxStackSize)
        write""
        if chunk.Constants.Count > 0 then
            write("; Constants")
            for i = 1, chunk.Constants.Count do
                local c = chunk.Constants[i - 1]
                if c.Type == "Nil" then
                    write(".const nil")
                elseif c.Type == "Bool" then
                    write(".const " .. (c.Value and "true" or "false"))
                elseif c.Type == "Number" then
                    write(".const " .. c.Value)
                elseif c.Type == "String" then
                    local _ = c.Value
                    for i = 1, _:len() do
                        if _:sub(i, i) == "\n" then
                            _ = _:sub(1, i - 1) .. "\\n" .. _:sub(i)
                        elseif _:sub(i, i) == "\t" then
                            _ = _:sub(1, i - 1) .. "\\t" .. _:sub(i)
                        elseif _:sub(i, i) == "\r" then
                            _ = _:sub(1, i - 1) .. "\\r" .. _:sub(i)
                        elseif _:sub(i, i) == "\0" then
                            _ = _:sub(1, i - 1) .. "\\0" .. _:sub(i)
                        elseif _:sub(i, i) == "\"" then
                            _ = _:sub(1, i - 1) .. "\\\"" .. _:sub(i)
                        elseif _:sub(i, i) == "'" then
                            _ = _:sub(1, i - 1) .. "\\'" .. _:sub(i)
                        elseif _:sub(i, i) == "\\" then
                            _ = _:sub(1, i - 1) .. "\\\\" .. _:sub(i)
                        end
                    end
                    write(".const \"" .. _ .. "\"")
                end
            end
        end
        if chunk.Locals.Count > 0 then
            write("; Locals")
            for i = 1, chunk.Locals.Count do
                write(".local " .. chunk.Locals[i - 1].Name)
            end
        end
        if chunk.Upvalues.Count > 0 then
            write("; Upvalues")
            for i = 1, chunk.Upvalues.Count do
                write(".upval " .. chunk.Upvalues[i - 1].Name)
            end
        end
        write("; Instructions")
        for i = 1, chunk.Instructions.Count do
            local instr = chunk.Instructions[i - 1]
            if instr.OpcodeType == "ABC" then
                write(instr.Opcode:lower() .. " " .. instr.A .. " " .. instr.B .. " " .. instr.C)
            elseif instr.OpcodeType == "ABx" then
                write(instr.Opcode:lower() .. " " .. instr.A .. " " .. instr.Bx)
            elseif instr.OpcodeType == "AsBx" then
                write(instr.Opcode:lower() .. " " .. instr.A .. " " .. instr.sBx)
            end
        end
        if chunk.Protos.Count > 0 then
            write("; Protos")
            write""
            for i = 1, chunk.Protos.Count do
                decompile(chunk.Protos[i - 1])
            end
        end
        write(".end")
    end
    
    decompile(file.Main)
    return s
end
