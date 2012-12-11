local function lookupify(tbl)
	for _, v in pairs(tbl) do
		tbl[v] = true
	end
	return tbl
end

local WhiteChars = lookupify{' ', '\n', '\t', '\r'}
--local EscapeLookup = {['\r'] = '\\r', ['\n'] = '\\n', ['\t'] = '\\t', ['"'] = '\\"', ["'"] = "\\'"}
local LowerChars = lookupify{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 
							 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 
							 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
local UpperChars = lookupify{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 
							 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 
							 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}
local Digits = lookupify{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}
local HexDigits = lookupify{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
                            'A', 'a', 'B', 'b', 'C', 'c', 'D', 'd', 'E', 'e', 'F', 'f'}

--local Symbols = lookupify{'+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#'}
local Symbols = lookupify{ '(', ')', '$', ',' }

local Keywords = lookupify{
    '.const', '.local', '.name', '.options', '.local', '.upval', '.upvalue',
    '.stacksize', '.maxstacksize', '.vararg', '.function', '.func', '.end',
    '.params', '.args', '.arguments', '.argcount',
    
    'true', 'false', 'nil', 'null',
};

local Lexer = {
    new = function(self, str, name)
        return setmetatable({ _str = str, _name = name }, { __index = self })
    end,
    
    Lex = function(self, aSource, aName)
        local src = self._str
        if not src then
            src = aSource
        end
        if not src then
            error'No source to lex'
        end
        local streamName = self._name or ""
        if not streamName or (streamName == "" and aName and aName:len() > 0) then streamName = aName end
        local tokens = {}

        local p = 1
        local line = 1
        local char = 1
        
        local function get()
            local c = src:sub(p, p)
            if c == '\n' then
                char = 1
                line = line + 1
            else
                char = char + 1
            end
            p = p + 1
            return c
        end
        local function peek(n)
            n = n or 0
            return src:sub(p+n,p+n)
        end
        local function consume(chars)
            local c = peek()
            for i = 1, #chars do
                if c == chars:sub(i, i) then return get() end
            end
        end

        -- local functions
        local function lexError(err)
            if streamName ~= "" then
                error(streamName .. ":" .. line .. ":" .. char .. ": " .. err)
            else
                error(line .. ":" .. char .. ": " .. err)
            end
        end

        local function tryGetLongString()
            local start = p
            if peek() == '[' then
                local equalsCount = 0
                local depth = 1
                while peek(equalsCount+1) == '=' do
                    equalsCount = equalsCount + 1
                end
                if peek(equalsCount+1) == '[' then
                    --start parsing the string. Strip the starting bit
                    for _ = 0, equalsCount+1 do get() end

                    --get the contents
                    local contentStart = p
                    while true do
                        --check for eof
                        if peek() == '' then
                            lexError("Expected ']"..string.rep('=', equalsCount).."]' near <eof>.", 3)
                        end

                        --check for the end
                        local foundEnd = true
                        if peek() == ']' then
                            for i = 1, equalsCount do
                                if peek(i) ~= '=' then foundEnd = false end
                            end
                            if peek(equalsCount+1) ~= ']' then
                                foundEnd = false
                            end
                        else
                            if peek() == '[' then
                                -- is there an embedded long string?
                                local embedded = true
                                for i = 1, equalsCount do
                                    if peek(i) ~= '=' then
                                        embedded = false
                                        break
                                    end
                                end
                                if peek(equalsCount + 1) == '[' and embedded then
                                    -- oh look, there was
                                    depth = depth + 1
                                    for i = 1, (equalsCount + 2) do
                                        get()
                                    end
                                end
                            end
                            foundEnd = false
                        end
                        --
                        if foundEnd then
                            depth = depth - 1
                            if depth == 0 then
                                break
                            else
                                for i = 1, equalsCount + 2 do
                                    get()
                                end
                            end
                        else
                            get()
                        end
                    end

                    --get the interior string
                    local contentString = src:sub(contentStart, p-1)

                    --found the end. Get rid of the trailing bit
                    for i = 0, equalsCount+1 do get() end

                    --get the exterior string
                    local longString = src:sub(start, p-1)

                    --return the stuff
                    return contentString, longString
                else
                    return nil
                end
            else
                return nil
            end
        end

        -- Lexer
        while true do
            --get leading whitespace. The leading whitespace will include any comments 
            --preceding the token. This prevents the parser needing to deal with comments 
            --separately.
            local leadingWhite = ''
            while true do
                local c = peek()
                if WhiteChars[c] then
                    --whitespace
                    leadingWhite = leadingWhite..get()
                elseif c == ';' then
                    --comment
                    get()
                    leadingWhite = leadingWhite..';'
                    local _, wholeText = tryGetLongString()
                    while peek() ~= '\n' and peek() ~= '' do
                        leadingWhite = leadingWhite .. get()
                    end
                else
                    break
                end
            end

            --get the initial char
            local thisLine = line
            local thisChar = char
            local c = peek()

            --symbol to emit
            local toEmit = nil

            --branch on type
            if c == '' then
                --eof
                toEmit = {Type = 'Eof'}
            elseif UpperChars[c] or LowerChars[c] or c == '_' then
                --ident or keyword
                local start = p
                repeat
                    get()
                    c = peek()
                until not (UpperChars[c] or LowerChars[c] or Digits[c] or c == '_')
                local dat = src:sub(start, p-1)
                if Keywords[dat] then
                    toEmit = {Type = 'Keyword', Data = dat}
                else
                    toEmit = {Type = 'Ident', Data = dat}
                end
            elseif Digits[c] or (peek() == '.' and Digits[peek(1)])  or (peek() == '-' and Digits[peek(1)]) then 
                --number constant
                local start = p
                if c == '-' then get() end
                if c == '0' and peek(1):lower() == 'x' then
                    get()
                    get()
                    while HexDigits[peek()] or peek() == '_' do get() end
                    if consume('PpEe') then
                        consume('+-')
                        while Digits[peek()] do get() end
                    end
                elseif c == '0' and peek(1):lower() == "b" then
                    get()
                    get()
                    while peek() == '0' or peek() == '1' or peek() == '_' do get() end
                elseif c == '0' and peek(1):lower() == "o" then
                    get()
                    get()
                    while Digits[peek()] or peek() == '_'  do get() end
                else
                    while Digits[peek()] or peek() == '_'  do get() end
                    if consume('.') then
                        while Digits[peek()] or peek() == '_' do get() end
                    end
                    if consume('Ee') then
                        consume('+-')
                        while Digits[peek()] do get() end
                    end
                end
                toEmit = {Type = 'Number', Data = src:sub(start, p-1)}
            elseif c == '\'' or c == '\"' then
                local start = p
                --string constant
                local delim = get()
                local contentStart = p
                while true do
                    local c = get()
                    if c == '\\' then
                        get() --get the escape char
                    elseif c == delim then
                        break
                    elseif c == '' then
                        lexError("Unfinished string near <eof>")
                    end
                end
                local content = src:sub(contentStart, p-2)
                local constant = src:sub(start, p-1)
                toEmit = {Type = 'String', Data = constant, Constant = content}
            elseif c == '[' then
                local content, wholetext = tryGetLongString()
                if wholetext then
                    toEmit = {Type = 'String', Data = wholetext, Constant = content}
                else
                    get()
                    toEmit = {Type = 'Symbol', Data = '['}
                end
            elseif c == '.' then
                get()
                c = peek()
                if UpperChars[c] or LowerChars[c] or c == '_' then
                    --ident or keyword
                    local start = p
                    repeat
                        get()
                        c = peek()
                    until not (UpperChars[c] or LowerChars[c] or Digits[c] or c == '_')
                    local dat = '.' .. src:sub(start, p - 1)
                    if Keywords[dat] then
                        toEmit = {Type = 'Keyword', Data = dat}
                    else
                        toEmit = {Type = 'Ident', Data = dat}
                    end
                else
                    toEmit = {Type = 'Symbol', Data = '.'}
                end
            elseif Symbols[c] then
                get()
                toEmit = {Type = 'Symbol', Data = c}
            elseif c == ':' then
                get()
                if peek() == ':' then
                    get()
                    c = peek()
                    if UpperChars[c] or LowerChars[c] or c == '_' then
                        --ident or keyword
                        local start = p
                        repeat
                            get()
                            c = peek()
                        until not (UpperChars[c] or LowerChars[c] or Digits[c] or c == '_')
                        
                        local dat = src:sub(start, p - 1)
                        toEmit = {Type = 'Label', Data = dat}
                        if not peek() == ':' then
                            lexError"':' expected"
                        else
                            get()
                            if not peek() == ':' then
                                lexError"':' expected"
                            else
                                get()
                            end
                        end
                    else
                        lexError"':' expected"
                    end
                else
                    lexError"':' expected"
                end
            else
                lexError("Unexpected Symbol '" .. c .. "'")
            end

            --add the token, after adding some common data
            toEmit.LeadingWhite = leadingWhite
            toEmit.Line = thisLine
            toEmit.Column = thisChar
            tokens[#tokens + 1] = toEmit

            --halt after eof has been read
            if toEmit.Type == 'Eof' then break end
        end

        -- token reader
        local tok = {}
        local savedP = {}
        local p = 1

        --getters
        function tok:Peek(n)
            n = n or 0
            return tokens[math.min(#tokens, p+n)]
        end
        function tok:Get()
            local t = tokens[p]
            p = math.min(p + 1, #tokens)
            return t
        end
        function tok:Is(t)
            return tok:Peek().Type == t
        end

        --save / restore points in the stream
        function tok:Save()
            savedP[#savedP+1] = p
        end
        function tok:Commit()
            savedP[#savedP] = nil
        end
        function tok:Restore()
            p = savedP[#savedP]
            savedP[#savedP] = nil
        end

        --either return a symbol if there is one, or return true if the requested
        --symbol was gotten.
        function tok:ConsumeSymbol(symb)
            local t = self:Peek()
            if t.Type == 'Symbol' then
                if symb then
                    if t.Data == symb then
                        self:Get()
                        return true
                    else
                        return nil
                    end
                else
                    self:Get()
                    return t
                end
            else
                return nil
            end
        end

        function tok:ConsumeKeyword(kw, caseSensitive)
            local t = self:Peek()
            caseSensitive = caseSensitive or false
            if t.Type == 'Keyword' and t.Data == kw then
                self:Get()
                return true
            elseif caseSensitive == false and t.Type == 'Keyword' and t.Data:lower() == kw:lower() then
                self:Get()
                return true
            else
                return nil
            end
        end
        
        function tok:ConsumeIdent(data)
            local t = self:Peek()
            if t.Type == 'Ident' then
                tok:Get()
                if data then
                    return t.Data == data
                else
                    return t.Data
                end
            else
                return nil
            end
        end
        
        function tok:ConsumeSymbols(...)
            local t = self:Peek()
            if t.Type == 'Symbol' then
                local syms = { ... }
                for k, v in pairs(syms) do
                    if v == t.Data then self:Get() return true end
                end
            end
            return false
        end

        function tok:IsKeyword(kw)
            local t = tok:Peek()
            return t.Type == 'Keyword' and t.Data == kw
        end

        function tok:IsSymbol(s)
            local t = tok:Peek()
            return t.Type == 'Symbol' and t.Data == s
        end
        
        function tok:IsIdent(s)
            local t = tok:Peek()
            return t.Type == 'Ident' and t.Data:lower() == s:lower()
        end

        function tok:IsEof()
            return tok:Peek().Type == 'Eof'
        end

        return tok
    end
}

return Lexer
