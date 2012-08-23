require"Instruction"
require"bin"
require"Chunk"
require"LuaFile"

function Disassemble(chunk)
    if chunk == nil then
        error("File is nil!")
    end
	local index = 1
	local tab = {}
	local big = false;
    local file = LuaFile:new()
	
	local function GetInt8()		
		local a = chunk:sub(index, index):byte()
		index = index + 1
		return a
	end
	local function GetInt16(str, inx)
		local a = GetInt8()
		local b = GetInt8()
		return 256 * b + a
	end
	local function GetInt32(str, inx)
		local a = GetInt16()
		local b = GetInt16()
		return 65536 * b + a
	end
	local function GetFloat64()
		local a = GetInt32()
		local b = GetInt32()
		if a == b and a == 0 then
			return 0;
		else
			return (-2 * bit.get(b, 32) + 1) * (2 ^ (bit.get(b, 21, 31) - 1023)) * ((bit.get(b, 1, 20) * (2 ^ 32) + a) / (2 ^ 52) + 1)
		end
	end
	
	local function GetString(len)
		local str = chunk:sub(index, index+len-1)
		index = index + len
		return str
	end
	
	local function GetTypeInt()
		local a = GetInt8()
		local b = GetInt8()
		local c = GetInt8()
		local d = GetInt8()
		return d*16777216 + c*65536 + b*256 + a
	end
	local function GetTypeString()
		local tmp = GetInt32()
		if tab.SizeT == 8 then GetInt32() end
		return GetString(tmp):sub(1, -2) -- Strip last '\0'
	end
	local function GetTypeFunction()
		local c = Chunk:new()
		c.Name = GetTypeString()
		c.FirstLine = GetTypeInt()
		c.LastLine = GetTypeInt()
		c.UpvalueCount = GetInt8() -- Upvalues
		c.ArgumentCount = GetInt8()
		c.Vararg = GetInt8()
		c.MaxStackSize = GetInt8()
		
        -- Instructions
		--c.Instructions.Count = GetInt32()
        local count = GetInt32()
        for i = 1, count do
            local op = GetInt32();
            local opcode = bit.get(op, 1, 6)
            local instr = Instruction:new(opcode + 1, i)
            if instr.OpcodeType == "ABC" then
                instr.A = bit.get(op, 7, 14)
                instr.B = bit.get(op, 24, 32)
                instr.C = bit.get(op, 15, 23)
            elseif instr.OpcodeType == "ABx" then
                instr.A = bit.get(op, 7, 14)
                instr.Bx = bit.get(op, 15, 32)
            elseif instr.OpcodeType == "AsBx" then
                instr.A = bit.get(op, 7, 14)
                instr.sBx = bit.get(op, 15, 32) - 131071
            end
            c.Instructions[i - 1] = instr
        end
		
		-- Constants
        --c.Constants.Count = GetInt32()
        count = GetInt32()
        for i = 1, count do
            local cnst = Constant:new()
            local t = GetInt8()
            
            cnst.Number = i-1
            
            if t == 0 then
                cnst.Type = "Nil"
                cnst.Value = ""
            elseif t == 1 then
                cnst.Type = "Bool"
                cnst.Value = GetInt8() ~= 0
            elseif t == 3 then
                cnst.Type = "Number"
                cnst.Value = GetFloat64()
            elseif t == 4 then
                cnst.Type = "String"
                cnst.Value = GetTypeString()
            end
            c.Constants[i - 1] = cnst
        end

        -- Protos
        --c.Protos.Count = GetInt32()
        count = GetInt32()
        for i = 1, count do
            c.Protos[i - 1] = GetTypeFunction()
        end
        
        -- Line numbers
        for i = 1, GetInt32() do 
            c.Instructions[i - 1].LineNumber = GetInt32()
		end
        
        -- Locals
        --c.Locals.Count = GetInt32()
        count = GetInt32()
        for i = 1, count do
            c.Locals[i - 1] = Local:new(GetTypeString(), GetInt32(), GetInt32())
        end
        
        -- Upvalues
        --c.Upvalues.Count = GetInt32()
        count = GetInt32()
        for i = 1, count do 
            c.Upvalues[i - 1] = { Name = GetTypeString() }
        end
		
		return c
	end
	
	file.Identifier = GetString(4) -- \027Lua
    if file.Identifier ~= "\027Lua" then
        error("Not a valid Lua bytecode chunk")
    end
	file.Version = GetInt8() -- 0x51
    if file.Version ~= 0x51 then
        error(string.format("Invalid bytecode version, 0x51 expected, got %x", file.Version))
    end
	file.Format = GetInt8() == 0 and "Official" or "Unofficial"
	file.BigEndian = GetInt8() == 0
	file.IntegerSize = GetInt8()
	file.SizeT = GetInt8() 	
	file.InstructionSize = GetInt8()
	file.NumberSize = GetInt8()
	file.IsFloatingPointNumbers = GetInt8() == 0
	file.Main = GetTypeFunction()
	return file
end
