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
        return DumpBinary.Int32(#s+1)..s.."\0"
	end,
    
	Int8 = function(n)
		return string.char(n)
	end,
    
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
        if op.OpcodeType == "Ax" then
            local axPos = 7
            local asLen = 26
            
            error("Opcodes of Ax are not supported")
        end
        c0 = op.OpcodeNumber + slb(keep(op.A, 2), 6)
        c1 = srb(op.A, 2) + slb(keep(op.C, 2), 6)
        c2 = srb(op.C, 2) + slb(keep (op.B, 1), 7)
        c3 = srb(op.B, 1)
        return string.char(c0, c1, c2, c3)
    end
}

return { bit, DumpBinary }
