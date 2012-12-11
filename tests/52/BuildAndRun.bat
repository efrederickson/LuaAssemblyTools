@cd ..\..
@Lua52bin\lua52 LasmCompiler52.lua -o tests\52\HelloWorld.luac tests\52\HelloWorld.lasm
@echo Output:
@Lua52bin\lua52 tests\52\helloworld.luac
@cd tests\52
