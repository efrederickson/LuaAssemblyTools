Lua Bytecode/Assembly Tools is a Lua bytecode library written in Lua 5.1

Inspired by:
LuaDbg (http://www.roblox.com/Item.aspx?id=52358617), 
LASM Compiler Suite (http://www.roblox.com/Item.aspx?id=26966291),
MODS (http://www.roblox.com/Item.aspx?id=44474190 or https://github.com/NecroBumpist/MODS),
ChunkBake (http://luaforge.net/projects/chunkbake),
and ChunkSpy (http://luaforge.net/projects/chunkspy).

Eventually, i hope to have full support for all available Lua versions.
This is not going to happen in the near future though.

(If not specified, its for Lua 5.1 operations)
Completed        Operation                        Description
-------------------------------------------------------------------------------------
Yes              Read (Lua 5.1)                   Reads bytecode
Yes              Write                            Writes bytecode
Yes              Edit                             Inject, remove, and change bytecode
Yes [1]          LASM Decompiler                  Decompiles chunks to LASM
Yes [3]          LASM Parser                      Parses LASM and generates LuaFile's
No               Decompiler                       Decompiles LuaFile's to Lua
No               DASM Decompiler                  Converts LuaFiles to DASM
No               MSIL Decompiler                  Converts LuaFiles to MSIL
No               JVM Decompiler                   Converts LuaFiles to Java bytecode
No               Version converter (2.4-5.2)      Convert chunks to different versions
Partial [2]      Platform converter               Converts platforms (SizeT, IntegerSize, BigEndian, etc..,)
Partial          Verifier                         Verifies bytecode is valid
Yes              Strip/Remove debugging info      Removes debugging info
Yes              Add/Edit debugging info          Adds and/or edits debugging info

[1] - Fixed string decompilation.
[2] - Might not work correctly. My tests failed, but it can still round-trip x86 standard chunks.
[3] - TODO: I need to simplify the loading of variables and add '"' checking, and metatables is not working. 
    Which is incredibly lame so i had to use getmetatable(x).__newindex(x, ...). This needs fixed also.