require"bin"
require"PlatformConfig"
require"Verifier"

Chunk = {
    new = function(self)
        local function toList(t) -- little hack using meta tables i put together in like 30 seconds. Might have some issues.
            return setmetatable(t, { table = { },
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
            MaxStackSize = 10,
            Instructions = toList{ Count = 0 },
            Constants = toList{ Count = 0 },
            Protos = toList{ Count = 0 },
            Locals = toList{ Count = 0 },
            Upvalues = toList{ Count = 0}
        }, { __index = self })
    end,
    
    Compile = function(self, file)
        local DumpInt = 
        
        local c = ""
        c = c .. DumpBinary.String(self.Name)
        c = c .. DumpBinary.Integer(self.FirstLine)
        c = c .. DumpBinary.Integer(self.LastLine)
        c = c .. DumpBinary.Int8(self.UpvalueCount)
        c = c .. DumpBinary.Int8(self.ArgumentCount)
        c = c .. DumpBinary.Int8(self.Vararg)
        c = c .. DumpBinary.Int8(self.MaxStackSize)
        
        -- Instructions
        c = c .. DumpBinary.Integer(self.Instructions.Count)
        for i = 1, self.Instructions.Count do
            c = c .. DumpBinary.Opcode(self.Instructions[i - 1])
        end
        
        -- Constants
        c = c .. DumpBinary.Integer(self.Constants.Count)
        for i = 1, self.Constants.Count do
            local cnst = self.Constants[i - 1]
            if cnst.Type == "Nil" then
                c = c .. DumpBinary.Int8(0)
            elseif cnst.Type == "Bool" then
                c = c .. DumpBinary.Int8(1)
                c = c .. DumpBinary.Int8(cnst.Value and 1 or 0)
            elseif cnst.Type == "Number" then
                c = c .. DumpBinary.Int8(3)
                c = c .. DumpBinary.Float64(cnst.Value)
            elseif cnst.Type == "String" then
                c = c .. DumpBinary.Int8(4)
                c = c .. DumpBinary.String(cnst.Value)
            else
                error("Invalid constant type: " .. (cnst.Type and cnst.Type or "<nil>"))
            end
        end
        
        -- Protos
        c = c .. DumpBinary.Integer(self.Protos.Count)
        for i = 1, self.Protos.Count do
            c = c .. self.Protos[i - 1]:Compile(file)
        end
        
        -- Line Numbers
        c = c .. DumpBinary.Integer(self.Instructions.Count)
        for i = 1, self.Instructions.Count do
            c = c .. DumpBinary.Integer(self.Instructions[i - 1].LineNumber)
        end
        
        -- Locals 
        c = c .. DumpBinary.Integer(self.Locals.Count)
        for i = 1, self.Locals.Count do
            local l = self.Locals[i - 1]
            c = c .. DumpBinary.String(l.Name)
            c = c .. DumpBinary.Integer(l.StartPC)
            c = c .. DumpBinary.Integer(l.EndPC)
        end
        
        -- Upvalues
        c = c .. DumpBinary.Integer(self.Upvalues.Count)
        for i = 1, self.Upvalues.Count do
            c = c .. DumpBinary.String(self.Upvalues[i - 1].Name)
        end
        return c
    end,
    
    StripDebugInfo = function(self)
        self.Name = ""
        self.FirstLine = 1
        self.LastLine = 1
        for i = 1, self.Instructions.Count do
            self.Instructions[i - 1].LineNumber = 0
        end
        for i = 1, self.Protos.Count do
            self.Protos[i - 1]:StripDebugInfo()
        end
        for i = 1, self.Upvalues.Count do
            self.Upvalues[i - 1].Name = ""
        end
    end,
    
    Verify = function(self)
        VerifyChunk(self)
        for i = 1, self.Protos.Count do
            self.Protos[i - 1]:Verify()
        end
    end,
}
