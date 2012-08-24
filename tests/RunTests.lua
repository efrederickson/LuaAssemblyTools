package.path = "../src/?;../src/?.lua;" .. package.path
dofile"roundtripbintest.lua"
dofile"roundtripdecompilerandlasmparsertest.lua"
