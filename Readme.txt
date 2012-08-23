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
Yes              LASM Parser                      Parses LASM and generates LuaFile's
No               Decompiler                       Decompiles LuaFile's to Lua
No               DASM Decompiler                  Converts LuaFiles to DASM
No               MSIL Decompiler                  Converts LuaFiles to MSIL
No               JVM Decompiler                   Converts LuaFiles to Java bytecode
No               Version converter (2.4-5.2)      Convert chunks to different versions
No               Platform converter               ChunkSpy does this already... 
Partial          Verifier                         Verifies bytecode is valid
Yes              Strip/Remove debugging info      Removes debugging info
Yes              Add/Edit debugging info          Adds and/or edits debugging info

[1] - May not decompile strings correctly. I'm trying to think of a better way to do this.
