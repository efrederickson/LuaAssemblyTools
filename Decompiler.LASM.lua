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
                    write(".const \"" .. v .. "\"")
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
