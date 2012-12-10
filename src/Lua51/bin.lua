local bit
bit = {
	new = function(str)
		return tonumber(str, 2)
	end,
	get = function(num, n, n2)
		if n2 then
			local total = 0
			local digitn = 0
			for i = n, n2 do
				total = total + 2 ^ digitn * bit.get(num, i)
				digitn = digitn + 1
			end
			return total
		else
			local pn = 2^(n-1)
			return (num % (pn + pn) >= pn) and 1 or 0
		end
	end,
	getstring = function(num, mindigit, sep)
		mindigit = mindigit or 0
		local pow = 0
		local tot = 1
		while tot <= num do
			tot = tot * 2
			pow = pow + 1
		end
		---
		if pow < mindigit then pow = mindigit end
		---
		local str = ""
		for i = pow, 1, -1 do
			str = str..bit.get(num, i)..(i==1 and "" or (sep or "-"))
		end
		return str
	end
}

local p2 = {1,2,4,8,16,32,64,128,256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072}
local function keep (x, n) return x % p2[n+1] end
local function srb (x,n) return math.floor(x / p2[n+1]) end
local function slb (x,n) return x * p2[n+1] end

local DumpBinary = {
    -- This is... bad. Only support X86 Standard
	String = function(s)
		if #s ~= 0 then
			return DumpBinary.Int32(#s+1)..s.."\0"
		else
			return "\0\0\0\0";
		end
	end,--[[
	Integer = function(n)
		return DumpBinary.Int32(n)
	end,]]
	Int8 = function(n)
		return string.char(n)
	end,--[[
	Int16 = function(n)
		error("DumpBinary.Int16() Not Implemented")
	end,
	Int32 = function(x)
		local v = ""
		x = math.floor(x)
		if x >= 0 then
			for i = 1, 4 do
			v = v..string.char(x % 256)
			x = math.floor(x / 256)
			end
		else -- x < 0
			x = -x
			local carry = 1
			for i = 1, 4 do
				local c = 255 - (x % 256) + carry
				if c == 256 then c = 0; carry = 1 else carry = 0 end
				v = v..string.char(c)
				x = math.floor(x / 256)
			end
		end
		return v
	end,
	Float64 = function(x)
		local function grab_byte(v)
			return math.floor(v / 256), string.char(math.floor(v) % 256)
		end
		local sign = 0
		if x < 0 then sign = 1; x = -x end
		local mantissa, exponent = math.frexp(x)
		if x == 0 then -- zero
			mantissa, exponent = 0, 0
		elseif x == 1/0 then
			mantissa, exponent = 0, 2047
		else
			mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 53)
			exponent = exponent + 1022
		end
		local v, byte = "" -- convert to bytes
		x = mantissa
		for i = 1,6 do
			x, byte = grab_byte(x)
			v = v..byte -- 47:0
		end
		x, byte = grab_byte(exponent * 16 + x)
		v = v..byte -- 55:48
		x, byte = grab_byte(sign * 128 + x)
		v = v..byte -- 63:56
		return v
	end,]]
    --[[
    Opcode = function(op)
        local c0, c1, c2, c3
        if op.OpcodeType == "AsBx" then op.Bx = op.sBx + 131071 op.OpcodeType = "ABx" end
        if op.OpcodeType == "ABx" then op.C = keep(op.Bx, 9); op.B = srb (op.Bx, 9) end
        c0 = op.OpcodeNumber + slb(keep(op.A, 2), 6)
        c1 = srb(op.A, 2) + slb(keep(op.C, 2), 6)
        c2 = srb(op.C, 2) + slb(keep (op.B, 1), 7)
        c3 = srb(op.B, 1)
        return string.char(c0, c1, c2, c3)
    end
    ]]
    Opcode = function(op)
        local c0, c1, c2, c3
        if op.OpcodeType == "AsBx" then 
            local bx = op.sBx + 131071 
            local c = keep(bx, 9)
            local b = srb(bx, 9)
            c0 = op.OpcodeNumber + slb(keep(op.A, 2), 6)
            c1 = srb(op.A, 2) + slb(keep(c, 2), 6)
            c2 = srb(c, 2) + slb(keep (b, 1), 7)
            c3 = srb(b, 1)
            return string.char(c0, c1, c2, c3)
        end
        if op.OpcodeType == "ABx" then 
            local c = keep(op.Bx, 9)
            local b = srb(op.Bx, 9) 
            c0 = op.OpcodeNumber + slb(keep(op.A, 2), 6)
            c1 = srb(op.A, 2) + slb(keep(c, 2), 6)
            c2 = srb(c, 2) + slb(keep (b, 1), 7)
            c3 = srb(b, 1)
            return string.char(c0, c1, c2, c3)
        end
        c0 = op.OpcodeNumber + slb(keep(op.A, 2), 6)
        c1 = srb(op.A, 2) + slb(keep(op.C, 2), 6)
        c2 = srb(op.C, 2) + slb(keep (op.B, 1), 7)
        c3 = srb(op.B, 1)
        return string.char(c0, c1, c2, c3)
    end
}

return { bit, DumpBinary }
