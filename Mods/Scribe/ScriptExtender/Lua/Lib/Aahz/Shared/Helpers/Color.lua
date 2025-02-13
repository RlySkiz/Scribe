
Helpers = Helpers or {}
Helpers.Color = Helpers.Color or {}

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