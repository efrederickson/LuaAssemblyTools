local Parser = {
    new = function(self, source, name)
        return setmetatable({ 
            lexed = source and (type(source) == "table" and source) or (type(source) == "string" and LAT.Lua51.Lexer:new():Lex(source, "<unknown>")) or nil,
            name = name
        }, { __index = self })
    end,
    
    Parse = function(self, source, name)
        local constTable = { } -- will fill up with [const] = [constant table index]
        local constNil = nil -- because you can't index a table with nil, sadly...
        local funcJumps = { }
        local fixJumps = { }
        local funcJumpsTables = { }
        local funcConstTables = { } -- for functions, constTable and constNil go in here 
        local funcStack = { } -- functions... for nesting functions and such
        local func = nil -- the current function
        local file = LAT.Lua51.LuaFile:new()
        local wasStacksizeSet = false
        file.Main.Vararg = 2 -- main function is always vararg
        file.Main.Name = self.name or name or "LASM Chunk"
        func = file.Main
        
        local tok = self.lexed or (type(source) == "table" and source) or (type(source) == "string" and LAT.Lua51.Lexer:new():Lex(source, name or "<unknown>"))
        if not tok then error'No parser input!' end
        
        local function parseError(msg)
            local err = file.Main.Name .. ":" .. tok:Peek().Line .. ":" .. tok:Peek().Column .. ": " .. msg .. "\n"
            -- find the line
            --[[local lineNum = 0
            for line in src:gmatch("[^\n]*\n?") do
                if line:sub(-1,-1) == '\n' then line = line:sub(1,-2) end
                lineNum = lineNum+1
                if lineNum == tok:Peek().Line then
                    err = err.."'"..line:gsub('\t','    ').."'\n"
                    for i = 1, tok:Peek().Column do
                        local c = line:sub(i,i)
                        if c == '\t' then
                            err = err .. '    '
                        else
                            err = err .. ' '
                        end
                    end
                    err = err .. "^"
                    break
                end
            end]]
            error(err)
            return err
        end
        
        local function evalString(str) -- Lexed data is safe to evaluate.
            local ret = loadstring("return " .. str)()
            assert(type(ret) == "string", "Error reading string")
            return ret
        end
        
        local function evalNumber(num)
            num = num:gsub("_", "")
            local x = tonumber(num)
            if x then return x end
            if num:sub(1, 2):upper() == "0B" then
                num = num:sub(3)
                x = tonumber(num, 2)
                if x then return x end
            elseif num:sub(1, 2):upper() == "0O" then -- might looke like two zeros. its not. Its a zero and a o
                num = num:sub(3)
                x = tonumber(num, 8)
                if x then return x end
            end
            
            parseError("Cannot read number")
        end
        
        local function readString() 
            if not tok:Is'String' then parseError"String expected" end
            return evalString(tok:Get().Data) 
        end
        
        local function readNum()
            if not tok:Is'Number' then parseError"Number expected" end
            return evalNumber(tok:Get().Data) 
        end
        
        local function isOpcode(d)
            local x,y = pcall(function() LAT.Lua51.Instruction:new(d) end)
            --print(x, y)
            return x
        end
        
        local function patchJumps()
            while #fixJumps > 0 do
                local item = table.remove(fixJumps)
                local found = false
                for k, v in pairs(funcJumps) do
                    if v.Label == item.Label then
                        if v.Offset < item.Instr.Number then
                            item.Instr.sBx = v.Offset - item.Instr.Number
                        else
                            item.Instr.sBx = v.Offset - item.Instr.Number
                        end
                        found = true
                        break
                    end
                end
                if not found then
                    parseError("Label " .. item.Label .. " not found")
                end
            end
        end
        
        local function addConst(alwaysDefine)
            alwaysDefine = alwaysDefine == nil and true or alwaysDefine
            local value = nil
            
            if tok:Is'String' then value = evalString(tok:Get().Data)
            elseif tok:Is'Number' then value = evalNumber(tok:Get().Data)
            elseif tok:ConsumeKeyword'true' then value = true
            elseif tok:ConsumeKeyword'false' then value = false
            elseif tok:ConsumeKeyword'nil' or tok:ConsumeKeyword'null' then value = nil
            else parseError"Unable to process constant"
            end
            
            if alwaysDefine or constTable[value] == nil then
                if value == true or value == false then
                    func.Constants:Add(LAT.Lua51.Constant:new("Bool", value))
                elseif value == nil then
                    func.Constants:Add(LAT.Lua51.Constant:new("Nil", nil))
                elseif type(value) == "number" then
                    func.Constants:Add(LAT.Lua51.Constant:new("Number", value))
                elseif type(value) == "string" then
                    func.Constants:Add(LAT.Lua51.Constant:new("String", value))
                end
                
                if value ~= nil then
                    constTable[value] = func.Constants.Count - 1
                else
                    constNil = func.Constants.Count - 1
                end
            end
            if value ~= nil then
                return constTable[value]
            else
                return constNil
            end
        end
        
        local function doControl()
            if tok:ConsumeKeyword".const" then
                addConst()
            elseif tok:ConsumeKeyword".name" then
                local name
                if tok:Is'String' then
                    name = readString()
                elseif tok:Is'Ident' then
                    name = tok:Get().Data
                end
                func.Name = name
            elseif tok:ConsumeKeyword".options" then
                local i = 0
                local line = tok:Peek(-1).Line
                while tok:Is'Number' and i < 4 do
                    if i == 0 then
                        func.UpvalueCount = readNum()
                    elseif i == 1 then
                        func.ArgumentCount = readNum()
                    elseif i == 2 then
                        func.Vararg = readNum()
                    elseif i == 3 then
                        func.MaxStackSize = readNum()
                        wasStacksizeSet = true
                    end
                    i = i + 1
                    tok:ConsumeSymbol','
                end
            elseif tok:ConsumeKeyword".params" or tok:ConsumeKeyword".args" or tok:ConsumeKeyword".arguments" or tok:ConsumeKeyword".argcount" then
                func.ArgumentCount = readNum()
            elseif tok:ConsumeKeyword".local" then
                local name
                if tok:Is'String' then
                    name = readString()
                elseif tok:Is'Ident' then
                    name = tok:Get().Data
                end
                func.Locals:Add(LAT.Lua51.Local:new(name, 0, 0))
            elseif tok:ConsumeKeyword".upval" or tok:ConsumeKeyword".upvalue" then
                local name
                if tok:Is'String' then
                    name = readString()
                elseif tok:Is'Ident' then
                    name = tok:Get().Data
                end
                func.Upvalues:Add(LAT.Lua51.Upvalue:new(name))
            elseif tok:ConsumeKeyword".stacksize" or tok:ConsumeKeyword".maxstacksize" then
                func.MaxStackSize = readNum()
                wasStacksizeSet = true
            elseif tok:ConsumeKeyword".vararg" then
                func.Vararg = readNum()
            elseif tok:ConsumeKeyword".func" or tok:ConsumeKeyword".function" then
                local n = LAT.Lua51.Chunk:new()
                n.FirstLine = tok:Peek(-1).Line
                n.Name = tok:Is'String' and readString() or "LASM Chunk"
                func.Protos:Add(n)
                funcStack[#funcStack + 1] = func
                func = n
                funcConstTables[#funcConstTables + 1] = { constTable = constTable, constNil = constNil }
                funcJumpsTables[#funcJumpsTables + 1] = { jumps = funcJumps, fix = fixJumps }
            elseif tok:ConsumeKeyword".end" then
                patchJumps()
                local f = table.remove(funcStack)
                func.LastLine = tok:Peek(-1).Line
                local instr1 = func.Instructions[func.Instructions.Count - 1]
                local instr2 = LAT.Lua51.Instruction:new("RETURN")
                instr2.A = 0
                instr2.B = 1
                instr2.C = 0
                if instr1 then
                    if instr1.Opcode ~= "RETURN" then
                        func.Instructions:Add(instr2)
                    end
                else
                    func.Instructions:Add(instr2, 0)
                end 
                    
                func = f
                
                local ct = table.remove(funcConstTables)
                constNil = ct.constNil
                constTable = ct.constTable
                local fj = table.remove(funcJumpsTables)
                funcJumps = fj.jumps
                fixJumps = fj.fix
            else
                parseError("Unknown control '" .. tok:Peek().Data .. "'")
            end
        end
        
        local function manageConstant(needParen)
            local hadParen = false
            needParen = needParen == nil and true or needParen
            if not tok:ConsumeSymbol'(' then 
                if needParen == true then
                    if tok:Is'String' == false then 
                        parseError"'(' expected" 
                    end
                end 
            else
                hadParen = true
            end
            local index = addConst()
            if hadParen == true then
                if not tok:ConsumeSymbol')' then 
                    parseError"')' expected" 
                end
            elseif needParen == true then
                if not tok:ConsumeSymbol')' then 
                    parseError"')' expected" 
                end
            end
            return index
        end
        
        local function parseOpcode()
            local function readnumber(isRK)
                isRK = isRK or false
                if tok:IsSymbol'$' or tok:IsIdent'R' then
                    tok:Get()
                elseif tok:ConsumeIdent'k' or tok:ConsumeIdent'const' or tok:ConsumeIdent'constant' then
                    return (isRK and 256 or 0) + manageConstant()
                elseif (tok:Is'Keyword' and (tok:Peek().Data == "true" or tok:Peek().Data == "false" or tok:Peek().Data == "nil" or tok:Peek().Data == "null")) or tok:Is'String' then
                    return (isRK and 256 or 0) + manageConstant(false)
                elseif tok:Peek().Data == 'p' or tok:Peek().Data == 'proto' then
                    local name
                    if tok:Is'String' then
                        name = readString()
                    else
                        if not tok:ConsumeSymbol'(' then parseError"'(' expected" end
                        name = tok:Get().Data
                        if not tok:ConsumeSymbol')' then parseError"')' expected" end
                    end
                    for _, v in pairs(func.Protos) do
                        if v.Name == name then
                            return (isRK and 256 or 0) + _
                        end
                    end
                    parseError("Proto '" .. name .. "' was not found")
                end
                return readNum()
            end
            
            local function isNumber()
                if tok:Is'Number' then
                    return true
                elseif tok:IsSymbol'$' or tok:IsIdent'R' then
                    return true
                elseif tok:Peek().Data == 'k' or tok:Peek().Data == 'const' or tok:Peek().Data == 'constant' then
                    return true
                elseif (tok:Is'Keyword' and (tok:Peek().Data == "true" or tok:Peek().Data == "false" or tok:Peek().Data == "nil" or tok:Peek().Data == "null")) or tok:Is'String' then
                    return true
                elseif tok:Peek().Data == 'p' or tok:Peek().Data == 'proto' then
                    return true
                end
                return false
            end
            
            if not tok:Is'Ident' then parseError'Opcode expected' end
            local op = tok:ConsumeIdent()            
            local instr = LAT.Lua51.Instruction:new(op, 0)
            if not instr.Opcode then
                parseError("Unknown opcode: " .. op)
            end
            local isARK = instr.OpcodeParams[1] == 3 or false
            local isBRK = instr.OpcodeParams[2] == 3 or false
            local isCRK = instr.OpcodeParams[3] == 3 or false
            if instr.OpcodeType == "ABC" then
                instr.A = readnumber(isARK)
                tok:ConsumeSymbol','
                instr.B = readnumber(isBRK)
                tok:ConsumeSymbol','
                if isNumber() then
                    instr.C = readnumber(isCRK)
                else
                    instr.C = 0
                end
            elseif instr.OpcodeType == "ABx" then
                instr.A = readnumber(isARK)
                tok:ConsumeSymbol','
                instr.Bx = readnumber(isBRK)
            elseif instr.OpcodeType == "AsBx" then
                if instr.Opcode ~= "JMP" then
                    instr.A = readnumber(isARK)
                    tok:ConsumeSymbol','
                    instr.sBx = readnumber(isBRK)
                else
                    local lbl = nil
                    local function maybeNum()
                        if not isNumber() then
                            if tok:Is'Ident'
                            and isOpcode(tok:Peek().Data) == false 
                            and tok:Peek().Data ~= "" then
                                -- a jump label
                                lbl = tok:Get().Data
                                return 0
                            else -- only sBx was specified
                                instr.sBx = instr.A
                                instr.A = 0
                                return instr.sBx
                            end
                        else
                            return readnumber(isBRK)
                        end
                    end
                    instr.A = maybeNum()
                    instr.sBx = maybeNum()
                    if lbl then
                        table.insert(fixJumps, { Instr = instr, Label = lbl })
                    end
                end
            end
            
            if instr.OpcodeParams[1] == 3 then
                if not wasStacksizeSet and instr.A <= 255 then
                    if func.MaxStackSize < instr.A + 1 then
                        func.MaxStackSize = instr.A + 1
                    end
                end
            elseif instr.OpcodeParams[1] == 1 then
                if not wasStacksizeSet then
                    if func.MaxStackSize < instr.A + 1 then
                        func.MaxStackSize = instr.A + 1
                    end
                end
            end
            
            return instr
        end
        
        while tok:IsEof() == false do
            if tok:Peek().Type == 'Keyword' and tok:Peek().Data:sub(1, 1) == '.' then
                doControl()
            elseif tok:Peek().Type == 'Ident' and tok:Peek().Data:sub(1, 1) == '.' then
                parseError'Unknown control'
            elseif tok:Is'Label' then
                table.insert(funcJumps, { Label = tok:Get().Data, Offset = func.Instructions.Count })
            else
                local ln = tok:Peek().Line
                local opcode = parseOpcode()
                if not opcode then parseError'Opcode expected' end
                opcode.LineNumber = ln
                opcode.Number = func.Instructions.Count + 1
                func.Instructions:Add(opcode)
            end
        end
        patchJumps()
        
        local instr1 = func.Instructions[func.Instructions.Count - 1]
        if instr1 then
            if instr1.Opcode ~= "RETURN" then
                local instr2 = LAT.Lua51.Instruction:new("RETURN")
                instr2.A = 0
                instr2.B = 1
                instr2.C = 0
                func.Instructions:Add(instr2)
            end
        else
            func.Instructions:Add(instr2)
        end
        
        return file
    end,
}

return Parser
