local LAT = LAT

local LuaFile = {
    -- Default to x86 standard
    new = function(self)
        return setmetatable({
            Identifier = "\027Lua",
            Version = 0x52,
            Format = "Official",
            BigEndian = false,
            IntegerSize = 4,
            SizeT = 4,
            InstructionSize = 4,
            NumberSize = 8,
            IsFloatingPoint = true,
            Main = LAT.Lua52.Chunk:new(),
            Tail = string.char(0x19) .. string.char(0x93) .. "\r\n" .. string.char(0x1A) .. "\n",
        }, { __index = self, __newindex = function() error"Cannot set new fields on LuaFile" end })
    end,

    Compile = function(self, verify)
        local c = ""
        c = c .. self.Identifier
        c = c .. LAT.Lua52.DumpBinary.Int8(self.Version) -- Should be 0x51 (Q)
        c = c .. LAT.Lua52.DumpBinary.Int8(self.Format == "Official" and 0 or 1)
        c = c .. LAT.Lua52.DumpBinary.Int8(self.BigEndian and 0 or 1)
        c = c .. LAT.Lua52.DumpBinary.Int8(self.IntegerSize)
        c = c .. LAT.Lua52.DumpBinary.Int8(self.SizeT)
        c = c .. LAT.Lua52.DumpBinary.Int8(self.InstructionSize)
        c = c .. LAT.Lua52.DumpBinary.Int8(self.NumberSize)
        c = c .. LAT.Lua52.DumpBinary.Int8(self.IsFloatingPoint and 0 or 1)
        c = c .. self.Tail
        -- Main function
        c = c .. self.Main:Compile(self, verify)
        return c
    end,
    
    CompileToFunction = function(self)
        return loadstring(self:Compile())
    end,
    
    StripDebugInfo = function(self)
        self.Main:StripDebugInfo()
    end,
    
    Verify = function(self)
        self.Main:Verify()
    end,
}

return LuaFile
