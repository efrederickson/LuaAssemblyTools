require"bin"
require"PlatformConfig"
local verifier = require"Verifier"

Chunk = {
    new = function(self)
        local function toList(t) -- little hack using meta tables i put together in like 30 seconds. Might have some issues.
            t.Add = function(self, obj, index)
                getmetatable(self).__newindex(self, index or self.Count, obj)
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
        local _, DumpNumber = GetNumberType(file)
        
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
        c = c .. DumpString(self.Name)
        c = c .. DumpInt(self.FirstLine or 0)
        c = c .. DumpInt(self.LastLine or 0)
        c = c .. DumpBinary.Int8(self.UpvalueCount)
        c = c .. DumpBinary.Int8(self.ArgumentCount)
        c = c .. DumpBinary.Int8(self.Vararg)
        c = c .. DumpBinary.Int8(self.MaxStackSize)
        
        -- Instructions
        c = c .. DumpInt(self.Instructions.Count)
        for i = 1, self.Instructions.Count do
            c = c .. DumpBinary.Opcode(self.Instructions[i - 1])
        end
        
        -- Constants
        c = c .. DumpInt(self.Constants.Count)
        for i = 1, self.Constants.Count do
            local cnst = self.Constants[i - 1]
            if cnst.Type == "Nil" then
                c = c .. DumpBinary.Int8(0)
            elseif cnst.Type == "Bool" then
                c = c .. DumpBinary.Int8(1)
                c = c .. DumpBinary.Int8(cnst.Value and 1 or 0)
            elseif cnst.Type == "Number" then
                c = c .. DumpBinary.Int8(3)
                c = c .. DumpNumber(cnst.Value)
            elseif cnst.Type == "String" then
                c = c .. DumpBinary.Int8(4)
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
        verifier(self)
        for i = 1, self.Protos.Count do
            self.Protos[i - 1]:Verify()
        end
    end,
}
