Lua Bytecode/Assembly Tools (LAT) is a Lua bytecode library written in Lua 5.1 (but should be 5.2 compatible)

To use LuaAssemblyTools in your project, just require "LAT".

Inspired by:
LuaDbg (http://www.roblox.com/Item.aspx?id=52358617), 
LASM Compiler Suite (http://www.roblox.com/Item.aspx?id=26966291),
MODS (http://www.roblox.com/Item.aspx?id=44474190 or https://github.com/NecroBumpist/MODS),
ChunkBake (http://luaforge.net/projects/chunkbake),
and ChunkSpy (http://luaforge.net/projects/chunkspy).

Eventually, i hope to have full support for all available Lua versions.
This is not going to happen in the near future though.

Language Implementations
--------------------------------------------------------
2.4-5.0          No
5.1              Yes
5.2              Yes
5.3              No


(If not specified, its for Lua 5.1 and 5.2 operations)
Completed        Operation                        Description
-------------------------------------------------------------------------------------
Yes              Read                             Reads bytecode
Yes              Write                            Writes bytecode
Yes              Edit                             Inject, remove, and change bytecode
Yes              LASM Decompiler                  Decompiles chunks to LASM
Yes              LASM Parser                      Parses LASM and generates LuaFile's
No               Decompiler                       Decompiles bytecode to Lua
No               Version converter (2.4-5.2)      Convert chunks to different versions
Partial [2]      Platform converter               Converts platforms (SizeT, IntegerSize, BigEndian, etc..,)
Yes              Verifier                         Verifies bytecode is valid
Yes              Strip/Remove debugging info      Removes debugging info
Yes              Add/Edit debugging info          Adds and/or edits debugging info

[2] - Might not work correctly. My tests failed, but it can still round-trip x86 standard chunks.