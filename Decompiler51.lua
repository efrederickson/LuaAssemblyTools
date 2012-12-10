require'LAT'

if #arg == 0 then
    error("No input file specified!")
end
file = LAT.Lua51.Disassemble(io.open(arg[1], "rb"):read"*a")
print("; Decompiled to lasm by LASM Decompiler v1.0")
print("; Decompiler Copyright (C) 2012 LoDC")
print""
print(LAT.Lua51.Decompile.LASM(file))
