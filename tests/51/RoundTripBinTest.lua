require"LAT"

-- Takes a luac file, decompiles it, recompiles it, and then loads both chunks to verify.

print"File: "
f = io.open(io.read("*l"), "rb")
if not f then error("Unable to open file") end
binary = f:read("*a")
f:close()

a = LAT.Lua51.Disassemble(binary)
b = a:Compile()
print(loadstring(binary))
print(loadstring(b))
print("Equal:", assert(binary == b))
