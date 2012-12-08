@del consteval_test.luac
@cd ..
@LasmCompiler.lua -o samples\consteval_test.luac samples\consteval_test.lasm
@samples\consteval.lua samples\consteval_test.luac
@Decompiler samples\consteval_test.luac
@cd samples
@echo Output:
@consteval_test.luac