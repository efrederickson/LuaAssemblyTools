require"Disassembler"
require"LasmParser"
dofile"Decompiler.LASM.lua" -- hate how you can't have '.' in a require...

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
