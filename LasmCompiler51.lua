require'LAT'
print"LASM Compiler version 1.0"
print"Copyright (C) 2012 LODC"

local options = { File = "", Dump = false, OutFile = "", Nocompile = false, Strip = false }
if not arg or #arg == 0 then
    error("Incorrect usage. Please pass an input file in!")
end
local i = 1
while true do
    local a = arg[i]
    local b = a:lower()
    if b == "-o" then
        options.OutFile = arg[i + 1]
        i = i + 1
    elseif b == "-dump" then
        options.Dump = true
    elseif b == "-nocompile" then
        options.Nocompile = true
    elseif b == "-s" or b == "-strip" then
        options.Strip = true
    else
        options.File = a
    end
    i = i + 1
    if i > #arg then break end
end
if options.File == "" then
    error("No input file!")
end
local inFile = io.open(options.File, "r")
if not inFile then error("Unable to open input file") end
local source = inFile:read"*a"
inFile:close()
local p = LAT.Lua51.Parser:new()
local ok, file = pcall(p.Parse, p, source, options.File)
--local ok
--local file = p:Parse(source, options.File)
if not ok then
    error("Unable to parse LASM: " .. file)
    return
end
if options.Strip then
    file:StripDebugInfo()
end
local code = file:Compile()
local ok, err = loadstring(code)
if not ok then
    print("WARNING: Error verifying parsed LASM")
    print("Lua error: ", err)
end
if options.Nocompile == false then
    local f = io.open(options.OutFile == "" and "lasm.luac" or options.OutFile, "wb")
    if not f then error("Unable to open output file '" .. (options.OutFile == "" and "lasm.luac" or options.OutFile .. "'")) end
    print("Output file is at " .. (options.OutFile == "" and "lasm.luac" or options.OutFile))
    f:write(code)
    f:close()
end
if options.Dump then
    LAT.Lua51.Dump(file)
end
