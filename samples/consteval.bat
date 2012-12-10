@del consteval_test.luac
@cd ..
@LasmCompiler51.lua -o samples\consteval_test.luac samples\consteval_test.lasm
@samples\consteval.lua samples\consteval_test.luac
@Decompiler51 samples\consteval_test.luac
@cd samples
@echo Output:
@consteval_test.luac