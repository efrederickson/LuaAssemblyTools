package.path = "./src/?;./src/?.lua" .. package.path
require"LasmParser"
print"LASM Interpreter version 1.0"
print"Copyright (C) 2012 LODC"
print"Press <enter> twice (empty line) to run LASM chunk"

while true do
    io.write"> "
    local line = ""
    while true do
        local line2 = io.read"*l"
        if line2 == "" then
            break
        else
            line = line .. "\n" .. line2
        end
        io.write">> "
    end
    local p = Parser:new()
    local ok, ret = pcall(p.Parse, p, line)
    if not ok then
        print("Syntax Error: " .. ret)
    end
    local bCode = ret:Compile();
    local ok, ret2 = loadstring(bCode)
    if not ok then
        print("Bytecode compilation error: " .. ret2)
    end
    local a, b = pcall(ok)
    if not a then
        print("Error: " .. b)
    else
        print("Result: " .. (b or "<nothing>"))
    end
end
