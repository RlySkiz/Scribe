
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