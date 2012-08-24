function _G.CreateLexer(source)
	local lexer = {}
	local ptr = 1
	local ptrstack = {}
	-----
	local function at(i)
		return source:sub(i, i)
	end
	-----
	lexer.IsAlpha = function()
		local c = at(ptr)
		local n = string.byte(c)
		return (n >= 97 and n <= 122) or (n >= 65 and n <= 90) or c == "_"
	end
	lexer.IsDigit = function()
		local n = string.byte(at(ptr))
		return (n >= 48 and n <= 57)
	end
	lexer.Is = function(a)
		if #a == 1 then
			return at(ptr) == a
		else
			return source:sub(ptr, ptr+(#a)-1) == a
		end
	end
	-----
	lexer.Push = function()
		ptrstack[#ptrstack+1] = ptr
	end
	lexer.Pop = function()
		ptr = ptrstack[#ptrstack]
		ptrstack[#ptrstack] = nil
	end
	lexer.Pull = function()
		ptrstack[#ptrstack] = nil
	end
	-----
	return lexer
end
		
