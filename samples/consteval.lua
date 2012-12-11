--[[
TODO: More of the BinExpr opcodes (SUB, MUL, DIV, MOD, etc)
]]

require'LAT'

local fn = arg[1]
if not fn then print"No input file!" return end
local f = io.open(fn, "rb")
if not f then print("Unable to open input file '" .. fn .. "'") return end

local chunk = LAT.Lua51.Disassemble(f:read"*a")
f:close()

local m = chunk.Main
for i = 0, m.Instructions.Count - 1 do
    local i1 = m.Instructions[i]
    if m.Instructions[i - 1] ~= nil and m.Instructions[i - 2] ~= nil and i1 ~= nil then
        if i1.Opcode == "ADD" then
            local i2 = m.Instructions[i - 1]
            local i3 = m.Instructions[i - 2]
            if i2.Opcode == "LOADK" and i3.Opcode == "LOADK" then
                if m.Constants[i2.Bx].Type == "Number" and m.Constants[i3.Bx].Type == "Number" then
                    if (i1.B == i2.A or i1.C == i2.A) or (i1.B == i3.A or i1.C == i3.A) then
                        local x = m.Constants[i2.Bx].Value + m.Constants[i3.Bx].Value
                        local idx = m.Constants:Add(LAT.Lua51.Constant:new("Number", x))
                        m.Instructions:Remove(i1)
                        m.Instructions:Remove(i2)
                        m.Instructions:Remove(i3)
                        local instr = LAT.Lua51.Instruction:new"LOADK"
                        instr.A = i1.A
                        instr.Bx = idx
                        m.Instructions:Add(instr, i - 2) -- first LOADK index
                    end
                end
            end
        end
    end
end
f = io.open(fn, "wb")
f:write(chunk:Compile())
f:close()
