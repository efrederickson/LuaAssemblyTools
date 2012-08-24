package.path = "./src/?;./src/?.lua" .. package.path
require"disassembler"
dofile"./src/decompiler.lasm.lua"

if #arg == 0 then
    error("No input file specified!")
end
file = Disassemble(io.open(arg[1], "rb"):read"*a")
print("; Decompiled to lasm by LASM Decompiler v1.0")
print("; Decompiler Copyright (C) 2012 LoDC")
print""
print(Decompile.LASM(file))
