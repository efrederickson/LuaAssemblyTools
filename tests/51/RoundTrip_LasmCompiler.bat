cd ..
luac -o LasmCompiler.luac LasmCompiler.lua
Decompiler LasmCompiler.luac >LasmCompiler.lasm
LasmCompiler -o LasmCompiler_Lasm.luac LasmCompiler.lasm
lua -e "pcall(dofile, 'LasmCompiler_Lasm.luac') print('Success!')"
del LasmCompiler.luac
del LasmCompiler.lasm
del LasmCompiler_Lasm.luac