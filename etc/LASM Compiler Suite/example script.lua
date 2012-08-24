wait(0.1)
local chunk = aChunk("MainFunction", 0) { --> the main function should have 0 args
	aGETGLOBAL(0, aK("game")), 
	aGETTABLE(0, 0, aK("Workspace")),	-- get game.Workspace to register 0
	aGETGLOBAL(1, aK("Instance")),
	aGETTABLE(1, 1, aK("new")),
	aLOADK(2, aK("Part")),
	aCALL(1, 2, 2),					-- register 1 = Instance.new("Part")
	aSETTABLE(1, aK("Parent"), 0),	--(register 1).Parent = (register 0)
	--------------------
	---now some math
	aChunk("AddingFunction", 1) {	--takes 1 argument
		aADD(0, 0, aK(10)), --add 10 to first arg
		aRETURN(0, 2), --return result
	},
	aCLOSURE(0, aProto("AddingFunction")), --make an instance of the adding func in register 0
	aGETGLOBAL(1, aK("_G")), --get the global environment
	aSETTABLE(1, aK("AddTen"), 0), --set the global addten to the function
}
local func = chunk.Compile() --compile the chunk
_G.TestFunc = func --save it to _G so it can be called from the command line
