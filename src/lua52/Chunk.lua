local Chunk = {
    new = function(self)
        local function toList(t) -- little hack using meta tables i put together in like 30 seconds. Might have some issues.
            t.Add = function(self, obj, index)
                getmetatable(self).__newindex(self, index or self.Count, obj)
                return index or self.Count - 1
            end
            t.Remove = function(self, obj)
                local mt = getmetatable(self)
                for i = 1, self.Count do
                    if self[i - 1] == obj then
                        local x = table.remove(mt.table, i - 1)
                        if x then
                            self.Count = self.Count - 1
                        end
                        --print(mt.table[#mt.table].Opcode, self.Count, #mt.table)
                    end
                end
            end
            return setmetatable(t, { 
                table = { },
                __newindex = function(t, k, v)
                    if v == nil then
                        t.Count = t.Count - 1
                    else
                        if k == "Count" then rawset(t, k, v) end
                        if getmetatable(t).table[k] == nil then
                            t.Count = t.Count + 1
                        end
                    end
                    getmetatable(t).table[k] = v
                end,
                __index = function(t, k)
                    if k ~= "Count" then
                        return getmetatable(t).table[k]
                    else
                        return rawget(t, k)
                        --return #getmetatable(t).table + 1
                    end
                end
            })
        end
        return setmetatable({
            Name = "",
            FirstLine = 1,
            LastLine = 1,
            UpvalueCount = 0,
            ArgumentCount = 0,
            Vararg = 0,
            MaxStackSize = 250,
            Instructions = toList{ Count = 0 },
            Constants = toList{ Count = 0 },
            Protos = toList{ Count = 0 },
            Locals = toList{ Count = 0 },
            Upvalues = toList{ Count = 0 },
        }, { __index = self })
    end,
    
    Compile = function(self, file, verify)
        verify = verify == nil and true or verify
        if verify then self:Verify() end
        local _, DumpNumber = LAT.Lua52.GetNumberType(file)
        
        local function DumpInt(num)
            local v = ""
            for i = 1, file.IntegerSize do
                v = v .. string.char(num % 256)
                num = math.floor(num / 256)
            end
            return v
        end
        
        local function DumpString(s)
            if not s or s:len() == 0 then
                return DumpInt(1) .. "\0"
                
                -- wat? this doesn't work...
                --return s = string.rep("\0", file.SizeT)-- 4)
            else
                return DumpInt(s:len() + 1) .. s .. "\0"
            end
        end
        
        local c = ""
        c = c .. DumpInt(self.FirstLine or 0)
        c = c .. DumpInt(self.LastLine or 0)
        c = c .. LAT.Lua52.DumpBinary.Int8(self.ArgumentCount)
        c = c .. LAT.Lua52.DumpBinary.Int8(self.Vararg)
        c = c .. LAT.Lua52.DumpBinary.Int8(self.MaxStackSize)
        
        -- Instructions
        c = c .. DumpInt(self.Instructions.Count)
        for i = 1, self.Instructions.Count do
            c = c .. LAT.Lua52.DumpBinary.Opcode(self.Instructions[i - 1])
        end
        
        -- Constants
        c = c .. DumpInt(self.Constants.Count)
        for i = 1, self.Constants.Count do
            local cnst = self.Constants[i - 1]
            if cnst.Type == "Nil" then
                c = c .. LAT.Lua52.DumpBinary.Int8(0)
            elseif cnst.Type == "Bool" then
                c = c .. LAT.Lua52.DumpBinary.Int8(1)
                c = c .. LAT.Lua52.DumpBinary.Int8(cnst.Value and 1 or 0)
            elseif cnst.Type == "Number" then
                c = c .. LAT.Lua52.DumpBinary.Int8(3)
                c = c .. DumpNumber(cnst.Value)
            elseif cnst.Type == "String" then
                c = c .. LAT.Lua52.DumpBinary.Int8(4)
                c = c .. DumpString(cnst.Value)
            else
                error("Invalid constant type: " .. (cnst.Type and cnst.Type or "<nil>"))
            end
        end
        
        -- Protos
        c = c .. DumpInt(self.Protos.Count)
        for i = 1, self.Protos.Count do
            c = c .. self.Protos[i - 1]:Compile(file)
        end
        
        -- Upvalues
        c = c .. DumpInt(self.Upvalues.Count)
        for i = 1, self.Upvalues.Count do
            local x = self.Upvalues[i - 1]
            c = c .. string.char(x.InStack)
            c = c .. string.char(x.Index)
        end
        
        -- Name
        c = c .. DumpString(self.Name)
        
        -- Line Numbers
        c = c .. DumpInt(self.Instructions.Count)
        for i = 1, self.Instructions.Count do
            c = c .. DumpInt(self.Instructions[i - 1].LineNumber)
        end
        
        -- Locals 
        c = c .. DumpInt(self.Locals.Count)
        for i = 1, self.Locals.Count do
            local l = self.Locals[i - 1]
            c = c .. DumpString(l.Name)
            c = c .. DumpInt(l.StartPC)
            c = c .. DumpInt(l.EndPC)
        end
        
        -- Upvalues
        c = c .. DumpInt(self.Upvalues.Count)
        for i = 1, self.Upvalues.Count do
            c = c .. DumpString(self.Upvalues[i - 1].Name)
        end
        return c
    end,
    
    StripDebugInfo = function(self)
        self.Name = ""
        self.FirstLine = 0
        self.LastLine = 0
        for i = 1, self.Instructions.Count do
            self.Instructions[i - 1].LineNumber = 0
        end
        for i = 1, self.Protos.Count do
            self.Protos[i - 1]:StripDebugInfo()
        end
        if self.UpvalueCount < self.Upvalues.Count then self.UpvalueCount = self.Upvalues.Count end
        for i = 1, self.Upvalues.Count do
            self.Upvalues[i - 1].Name = ""
        end
        for i = 1, self.Locals.Count do
            self.Locals[i - 1] = nil
        end
    end,
    
    Verify = function(self)
        LAT.Lua52.Verifier(self)
        for i = 1, self.Protos.Count do
            self.Protos[i - 1]:Verify()
        end
    end,
}

return Chunk
