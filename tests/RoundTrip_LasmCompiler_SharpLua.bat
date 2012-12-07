cd ..
sluac -o LasmCompiler.luac LasmCompiler.lua
slua Decompiler.lua LasmCompiler.luac >LasmCompiler.lasm
slua LasmCompiler.lua -o LasmCompiler_Lasm.luac LasmCompiler.lasm
slua -e "pcall(dofile, 'LasmCompiler_Lasm.luac') print('Success!')"
del LasmCompiler.luac
del LasmCompiler.lasm
del LasmCompiler_Lasm.luac