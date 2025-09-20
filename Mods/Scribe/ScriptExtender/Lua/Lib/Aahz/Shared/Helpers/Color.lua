
Helpers = Helpers or {}
Helpers.Color = Helpers.Color or {}
Helpers.ConsoleColorCodes = {
    -- Attributes
    Reset           = "\x1b[0m",
    Bright          = "\x1b[1m",
    Dim             = "\x1b[2m",
    Italic          = "\x1b[3m",  -- non-standard feature
    Underscore      = "\x1b[4m",
    BlinkOn         = "\x1b[5m",
    Reverse         = "\x1b[7m",
    Hidden          = "\x1b[8m",
    BrightOff       = "\x1b[21m",
    UnderscoreOff   = "\x1b[24m",
    BlinkOff        = "\x1b[25m",

    Black   = "\x1b[30m",
    Red     = "\x1b[31m",
    Green   = "\x1b[32m",
    Yellow  = "\x1b[33m",
    Blue    = "\x1b[34m",
    Magenta = "\x1b[35m",
    Cyan    = "\x1b[36m",
    White   = "\x1b[37m",
    Default = "\x1b[39m",

    LightGray   = "\x1b[90m",
    LightRed    = "\x1b[91m",
    LightGreen  = "\x1b[92m",
    LightYellow = "\x1b[93m",
    LightBlue   = "\x1b[94m",
    LightMagenta= "\x1b[95m",
    LightCyan   = "\x1b[96m",
    LightWhite  = "\x1b[97m",

    BGBlack     = "\x1b[40m",
    BGRed       = "\x1b[41m",
    BGGreen     = "\x1b[42m",
    BGYellow    = "\x1b[43m",
    BGBlue      = "\x1b[44m",
    BGMagenta   = "\x1b[45m",
    BGCyan      = "\x1b[46m",
    BGWhite     = "\x1b[47m",
    BGDefault   = "\x1b[49m"
}

---@param hex string
---@param alpha number? 0.0-1.0
---@return vec4
function Helpers.Color.HexToRGBA(hex, alpha)
    hex = hex:gsub("#", "")
    local r,g,b
    alpha = alpha or 1.0

	if hex:len() == 3 then
		r = tonumber('0x'..hex:sub(1,1)) * 17
        g = tonumber('0x'..hex:sub(2,2)) * 17
        b = tonumber('0x'..hex:sub(3,3)) * 17
	elseif hex:len() == 6 then
		r = tonumber('0x'..hex:sub(1,2))
        g = tonumber('0x'..hex:sub(3,4))
        b = tonumber('0x'..hex:sub(5,6))
    end

    r = r or 0
    g = g or 0
    b = b or 0

    return {r,g,b,alpha}
end

---@param hex string
---@return vec3
function Helpers.Color.HexToRGB(hex)
    hex = hex:gsub('#','')
    local r,g,b

	if hex:len() == 3 then
		r = tonumber('0x'..hex:sub(1,1)) * 17
        g = tonumber('0x'..hex:sub(2,2)) * 17
        b = tonumber('0x'..hex:sub(3,3)) * 17
	elseif hex:len() == 6 then
		r = tonumber('0x'..hex:sub(1,2))
        g = tonumber('0x'..hex:sub(3,4))
        b = tonumber('0x'..hex:sub(5,6))
    end

    r = r or 0
    g = g or 0
    b = b or 0

    return {r,g,b}
end

---@param rgb vec3
---@return string
function Helpers.Color.RGBToHex(rgb)
    return string.format('%.2x%.2x%.2x', rgb[1], rgb[2], rgb[3])
end
---@param h integer hue
---@param s integer saturation
---@param v integer value
---@return integer r red
---@return integer g green
---@return integer b blue
function Helpers.Color.HSVToRGB(h, s, v)
    local c = v * s
    local hp = h / 60
    local x = c * (1 - math.abs(hp % 2 - 1))
    local r, g, b = 0, 0, 0

    if     hp >= 0 and hp <= 1 then r, g, b = c, x, 0
    elseif hp >= 1 and hp <= 2 then r, g, b = x, c, 0
    elseif hp >= 2 and hp <= 3 then r, g, b = 0, c, x
    elseif hp >= 3 and hp <= 4 then r, g, b = 0, x, c
    elseif hp >= 4 and hp <= 5 then r, g, b = x, 0, c
    elseif hp >= 5 and hp <= 6 then r, g, b = c, 0, x
    end

    local m = v - c
    return math.floor((r + m) * 255), math.floor((g + m) * 255), math.floor((b + m) * 255)
end

--- Create a table for the RGBA values, normalized to 0-1
--- This is useful because of syntax highlighting that is not present when typing a table directly
---@param r number
---@param g number
---@param b number
---@param a number
---@return table<number>
function Helpers.Color.NormalizedRGBA(r, g, b, a)
    return { r / 255, g / 255, b / 255, a }
end
---normalized version of HexToRGBA
---@param hex string
---@param alpha number
function Helpers.Color.HexToNormalizedRGBA(hex, alpha)
    local h = Helpers.Color.HexToRGBA(hex, alpha)
    return Helpers.Color.NormalizedRGBA(h[1], h[2], h[3], h[4])
end
--- Converts a normalized (0~1) RGBA value to a hex color string without the alpha component
---@param r number 0~1
---@param g number 0~1
---@param b number 0~1
---@return string
function Helpers.Color.NormalizedRGBToHex(r, g, b)
    r = math.floor(r * 255)
    g = math.floor(g * 255)
    b = math.floor(b * 255)
    return string.format("#%02x%02x%02x", r, g, b)
end

---Returns a linearly interpolated color between two hex colors
---@param hex1 string
---@param hex2 string
---@param percent number 0-100
---@return string hex value between "000000" and "FFFFFF"
function Helpers.Color.LerpHex(hex1, hex2, percent)
    percent = Ext.Math.Clamp(percent, 0, 100)
    local rgb = Helpers.Color.HexToRGB(hex1)
    local rgb2 = Helpers.Color.HexToRGB(hex2)
    local rgb3 = {
        math.floor((rgb[1]*(100-percent)/100) + (rgb2[1]*percent/100)),
        math.floor((rgb[2]*(100-percent)/100) + (rgb2[2]*percent/100)),
        math.floor((rgb[3]*(100-percent)/100) + (rgb2[3]*percent/100)),
    }
    return Helpers.Color.RGBToHex(rgb3)
end
---Returns a linearly interpolated color between two RGB/RGBA colors
---@param color1 vec3|vec4
---@param color2 vec3|vec4
---@param percent number 0-100
---@return vec3|vec4 color lerped rgb vec3 or rgba vec4
function Helpers.Color.NormalizedLerp(color1, color2, percent)
    if #color1 == 3 then
        -- assume rgb
        percent = Ext.Math.Clamp(percent, 0, 100)
        local rgb3 = {
            (color1[1]*(100-percent)/100) + (color2[1]*percent/100),
            (color1[2]*(100-percent)/100) + (color2[2]*percent/100),
            (color1[3]*(100-percent)/100) + (color2[3]*percent/100),
        }
        return rgb3
    else
        -- assume rgba
        percent = Ext.Math.Clamp(percent, 0, 100)
        local rgba4 = {
            (color1[1]*(100-percent)/100) + (color2[1]*percent/100),
            (color1[2]*(100-percent)/100) + (color2[2]*percent/100),
            (color1[3]*(100-percent)/100) + (color2[3]*percent/100),
            (color1[4]*(100-percent)/100) + (color2[4]*percent/100),
        }
        return rgba4
    end
end