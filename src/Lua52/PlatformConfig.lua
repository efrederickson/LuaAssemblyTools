-- Mostly from ChunkSpy. Used in loading chunks and converting them to different platforms.

local Configuration = {  
    ["x86 standard"] = {    
        Description = "x86 Standard (32-bit, little endian, double)",    
        BigEndian = false,             -- 1 = little endian    
        IntegerSize = 4,                -- (data type sizes in bytes)    
        SizeT = 4,    
        InstructionSize = 4,    
        NumberSize = 8,                 -- this & integral identifies the    
        IsFloatingPoint = true,        -- (0) type of lua_Number    
        NumberType = "double",         -- used for lookups  
    },  
    ["big endian int"] = {    
        Description = "(32-bit, big endian, int)",    
        BigEndian = true,
        IntegerSize = 4,
        SizeT = 4,
        InstructionSize = 4,
        NumberSize = 4,
        IsFloatingPoint = false,
        NumberType = "int",  
    },  
    ["amd64"] = {    
        Description = "AMD64 (64-bit, little endian, double)",    
        BigEndian = false, 
        IntegerSize = 4,    
        SizeT = 8,    
        InstructionSize = 4,    
        NumberSize = 8,    
        IsFloatingPoint = true,
        NumberType = "double",  
    },  
    -- you can add more platforms here
}

local ConvertFrom = {}
local ConvertTo = {}

local function grab_byte(v)
  return math.floor(v / 256), string.char(math.floor(v) % 256)
end

-----------------------------------------------------------------------
-- No more TEST_NUMBER in Lua 5.1, uses size_lua_Number + integral
-- LuaFile.NumberSize .. (LuaFile.IsFloatingPoint and 0 or 1)
-----------------------------------------------------------------------
LuaNumberID = {
  ["80"] = "double",         -- IEEE754 double
  ["40"] = "single",         -- IEEE754 single
  ["41"] = "int",            -- int
  ["81"] = "long long",      -- long long
}

-- Converts an 8-byte little-endian string to a IEEE754 double number
ConvertFrom["double"] = function(x)
  local sign = 1
  local mantissa = string.byte(x, 7) % 16
  for i = 6, 1, -1 do mantissa = mantissa * 256 + string.byte(x, i) end
  if string.byte(x, 8) > 127 then sign = -1 end
  local exponent = (string.byte(x, 8) % 128) * 16 +
                   math.floor(string.byte(x, 7) / 16)
  if exponent == 0 then return 0 end
  mantissa = (math.ldexp(mantissa, -52) + 1) * sign
  return math.ldexp(mantissa, exponent - 1023)
end

-- Converts a 4-byte little-endian string to a IEEE754 single number
ConvertFrom["single"] = function(x)
  local sign = 1
  local mantissa = string.byte(x, 3) % 128
  for i = 2, 1, -1 do mantissa = mantissa * 256 + string.byte(x, i) end
  if string.byte(x, 4) > 127 then sign = -1 end
  local exponent = (string.byte(x, 4) % 128) * 2 +
                   math.floor(string.byte(x, 3) / 128)
  if exponent == 0 then return 0 end
  mantissa = (math.ldexp(mantissa, -23) + 1) * sign
  return math.ldexp(mantissa, exponent - 127)
end

-- Converts a little-endian integer string to a number
ConvertFrom["int"] = function(x)
  local sum = 0
  for i = 4, 1, -1 do
    sum = sum * 256 + string.byte(x, i)
  end
  -- test for negative number
  if string.byte(x, 4) > 127 then
    sum = sum - math.ldexp(1, 8 * 4)
  end
  return sum
end

-- WARNING this will fail for large long longs (64-bit numbers)
-- because long longs exceeds the precision of doubles.
ConvertFrom["long long"] = ConvertFrom["int"]

-- Converts a IEEE754 double number to an 8-byte little-endian string
ConvertTo["double"] = function(x)
  local sign = 0
  if x < 0 then sign = 1; x = -x end
  local mantissa, exponent = math.frexp(x)
  if x == 0 then -- zero
    mantissa, exponent = 0, 0
  else
    mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 53)
    exponent = exponent + 1022
  end
  local v, byte = "" -- convert to bytes
  x = mantissa
  for i = 1,6 do
    x, byte = grab_byte(x); v = v..byte -- 47:0
  end
  x, byte = grab_byte(exponent * 16 + x); v = v..byte -- 55:48
  x, byte = grab_byte(sign * 128 + x); v = v..byte -- 63:56
  return v
end

-- Converts a IEEE754 single number to a 4-byte little-endian string
ConvertTo["single"] = function(x)
  local sign = 0
  if x < 0 then sign = 1; x = -x end
  local mantissa, exponent = math.frexp(x)
  if x == 0 then -- zero
    mantissa = 0; exponent = 0
  else
    mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 24)
    exponent = exponent + 126
  end
  local v, byte = "" -- convert to bytes
  x, byte = grab_byte(mantissa); v = v..byte -- 7:0
  x, byte = grab_byte(x); v = v..byte -- 15:8
  x, byte = grab_byte(exponent * 128 + x); v = v..byte -- 23:16
  x, byte = grab_byte(sign * 128 + x); v = v..byte -- 31:24
  return v
end

-- Converts a number to a little-endian integer string
ConvertTo["int"] = function(x)
  local v = ""
  x = math.floor(x)
  if x >= 0 then
    for i = 1, 4 do
      v = v..string.char(x % 256); x = math.floor(x / 256)
    end
  else-- x < 0
    x = -x
    local carry = 1
    for i = 1, 4 do
      local c = 255 - (x % 256) + carry
      if c == 256 then c = 0; carry = 1 else carry = 0 end
      v = v..string.char(c); x = math.floor(x / 256)
    end
  end
  -- optional overflow test; not enabled at the moment
  -- if x > 0 then error("number conversion overflow") end
  return v
end

-- WARNING this will fail for large long longs (64-bit numbers)
-- because long longs exceeds the precision of doubles.
ConvertTo["long long"] = ConvertTo["int"]

local function GetNumberType(file)
    local nt = LuaNumberID[file.NumberSize .. (file.IsFloatingPoint and 0 or 1)]
    if not nt then
        error("Unable to determine Number type")
    end
    return ConvertFrom[nt], ConvertTo[nt]
end

return GetNumberType
