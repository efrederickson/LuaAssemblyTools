require'LAT'

-- 1.0 - Original
-- 1.1 - makes it not continue attempting to execute chunk if one step fails

print"LASM Interpreter version 1.1"
print"Copyright (C) 2012 LODC"
print"Press <enter> twice (empty line) to run LASM chunk"

while true do
    io.write">> "
    local line = ""
    while true do
        local line2 = io.read"*l"
        if line2 == "" then
            break
        else
            if line == "" then 
                line = line .. line2
            else
                line = line .. "\n" .. line2
            end
        end
        io.write">> "
    end
    local p = LAT.Lua52.Parser:new()
    local ok, ret = pcall(p.Parse, p, line, "LASM Interactive Chunk")
    if not ok then
        print("Syntax Error: " .. ret)
    else
        local bCode 
        local ok, ret2 = pcall(function() bCode = ret:Compile() end)
        if not ok then
            print("Bytecode compilation error: " .. ret2)
        else
            local ok, ret2 = loadstring(bCode)
            if not ok then
                print("Bytecode compilation error: " .. ret2)
            else
                local a, b = pcall(ok)
                if not a then
                    print("Execution error: " .. b)
                else
                    print("Result: " .. (b or "<nothing>"))
                end
            end
        end
    end
end
