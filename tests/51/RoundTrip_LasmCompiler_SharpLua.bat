@cd ..\..
sluac -o LasmCompiler.luac LasmCompiler.lua
slua Decompiler51.lua LasmCompiler.luac >LasmCompiler.lasm
slua LasmCompiler51.lua -o LasmCompiler_Lasm.luac LasmCompiler.lasm
slua -e "pcall(dofile, 'LasmCompiler_Lasm.luac') print('Success!')"
del LasmCompiler.luac
del LasmCompiler.lasm
del LasmCompiler_Lasm.luac