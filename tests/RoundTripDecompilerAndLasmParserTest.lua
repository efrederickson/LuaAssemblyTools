require"LAT"

-- Take a binary file, load it, decompile it to lasm, parse the lasm, compile all chunks to verify

print"File: "
f = io.open(io.read("*l"), "rb")
if not f then error("Unable to open file") end
binary = f:read("*a")
f:close()

a = Disassemble(binary)
str = Decompile.LASM(a) -- a LuaFile
print("Decompiled: " .. str)
print""
p = Parser:new()
b = p:Parse(str)
print(loadstring(binary))
print(loadstring(a:Compile()))
print(loadstring(b:Compile()))

--[[
print(a:Compile() == b:Compile())
print(a:Compile() == binary)
print(b:Compile() == binary)
print("Equal: ", assert(a:Compile() == b:Compile() == binary))
]]
